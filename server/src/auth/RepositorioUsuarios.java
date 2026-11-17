// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import org.bson.Document;
import org.bson.types.ObjectId;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.FindOneAndUpdateOptions;
import com.mongodb.client.model.ReturnDocument;
import com.mongodb.client.model.Sorts;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;

import utils.ConfigEnv;

import com.mongodb.Block;
import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.MongoCommandException;
import com.mongodb.MongoException;
import com.mongodb.connection.ClusterSettings;
import com.mongodb.connection.SocketSettings;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Repositorio de usuarios conectado diretamente ao MongoDB.
 * Responsavel por autenticacao de credenciais, sessoes, OTPs, auditoria e administracao de contas.
 */
public class RepositorioUsuarios {
    private static final int SERVER_SELECTION_TIMEOUT_MS = 5_000;
    private static final int SOCKET_TIMEOUT_MS = 10_000;
    private static final long HEALTH_CACHE_TTL_MS = 5_000L;

    private volatile MongoClient client;
    private volatile MongoDatabase database;
    private volatile MongoCollection<Document> usersCollection;
    private volatile MongoCollection<Document> sessionsCollection;
    private volatile MongoCollection<Document> otpCollection;
    private volatile MongoCollection<Document> auditLogsCollection;
    private volatile MongoCollection<Document> loginLimitsCollection;
    private volatile MongoCollection<Document> writeGuardCollection;
    private volatile MongoCollection<Document> emailOutboxCollection;
    private final String dbNameConfigurado;
    private final String uriPrincipalConfigurada;
    private final String uriDiretaConfigurada;
    private final ResilientDnsClient dnsClient = new ResilientDnsClient();
    private volatile boolean usandoUriDireta = false;
    private volatile long ultimoCheckSaudeAt = 0L;
    private volatile boolean ultimoCheckSaudeOk = false;
    private volatile String ultimoErroBancoCodigo = "";
    private volatile String ultimoErroBancoMsg = "";

    private static volatile RepositorioUsuarios INSTANCIA_COMPARTILHADA;
    private static volatile boolean INDICES_INICIALIZADOS = false;

    public static final class EstadoSaudeBanco {
        public final boolean disponivel;
        public final String codigo;
        public final String detalhe;

        public EstadoSaudeBanco(boolean disponivel, String codigo, String detalhe) {
            this.disponivel = disponivel;
            this.codigo = codigo;
            this.detalhe = detalhe;
        }
    }

    // Hash dummy pre-computado para evitar timing attacks ao procurar usuarios inexistentes
    private static final String DUMMY_HASH = SenhaHasher.hashDummy();

    public static RepositorioUsuarios getInstance() {
        if (INSTANCIA_COMPARTILHADA == null) {
            synchronized (RepositorioUsuarios.class) {
                if (INSTANCIA_COMPARTILHADA == null) {
                    INSTANCIA_COMPARTILHADA = new RepositorioUsuarios();
                }
            }
        }
        return INSTANCIA_COMPARTILHADA;
    }

    /**
     * Retorna a instancia compartilhada apenas se ja tiver sido inicializada (util para fallback em testes offline).
     */
    public static RepositorioUsuarios getInstanciaSeInicializada() {
        return INSTANCIA_COMPARTILHADA;
    }

    public RepositorioUsuarios() {
        this(true);
    }

    /**
     * Construtor protegido para dubles de teste offline sem conexao ao MongoDB.
     */
    protected RepositorioUsuarios(boolean conectar) {
        if (!conectar) {
            this.dbNameConfigurado = "agmrm";
            this.uriPrincipalConfigurada = null;
            this.uriDiretaConfigurada = null;
            return;
        }
        String uri = ConfigEnv.obter("MONGODB_URI", null);
        String directUri = ConfigEnv.obter("MONGODB_DIRECT_URI", null);
        if ((uri == null || uri.trim().isEmpty()) && (directUri == null || directUri.trim().isEmpty())) {
            throw new IllegalStateException("MONGODB_URI nao configurado no .env");
        }
        this.dbNameConfigurado = ConfigEnv.obter("MONGODB_DATABASE", "agmrm");
        this.uriPrincipalConfigurada = uri != null && !uri.trim().isEmpty() ? uri.trim() : directUri.trim();
        this.uriDiretaConfigurada = directUri != null && !directUri.trim().isEmpty() ? directUri.trim() : null;

        System.out.println("[AUTH] Conectando ao MongoDB: " + dbNameConfigurado);
        inicializarCliente(this.uriPrincipalConfigurada, false);

        if (INSTANCIA_COMPARTILHADA == null) {
            INSTANCIA_COMPARTILHADA = this;
        }

        inicializarIndicesAsync();
        System.out.println("[AUTH] Cliente MongoDB inicializado com DNS resiliente e timeout rapido ("
                + SERVER_SELECTION_TIMEOUT_MS + "ms).");
    }

    private synchronized void inicializarCliente(String connectionUri, boolean direta) {
        if (connectionUri == null || connectionUri.trim().isEmpty()) {
            return;
        }
        MongoClient anterior = this.client;
        try {
            ConnectionString cs = new ConnectionString(connectionUri.trim());
            MongoClientSettings.Builder builder = MongoClientSettings.builder()
                    .applyConnectionString(cs)
                    .applyToClusterSettings(new Block<ClusterSettings.Builder>() {
                        @Override
                        public void apply(ClusterSettings.Builder cluster) {
                            cluster.serverSelectionTimeout(SERVER_SELECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS);
                        }
                    })
                    .applyToSocketSettings(new Block<SocketSettings.Builder>() {
                        @Override
                        public void apply(SocketSettings.Builder socket) {
                            socket.connectTimeout(SERVER_SELECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS)
                                  .readTimeout(SOCKET_TIMEOUT_MS, TimeUnit.MILLISECONDS);
                        }
                    });
            if (connectionUri.trim().startsWith("mongodb+srv://")) {
                builder.dnsClient(this.dnsClient);
            }
            MongoClient novoClient = MongoClients.create(builder.build());
            MongoDatabase novoDb = novoClient.getDatabase(this.dbNameConfigurado);
            this.client = novoClient;
            this.database = novoDb;
            this.usersCollection = novoDb.getCollection("auth_users");
            this.sessionsCollection = novoDb.getCollection("auth_sessions");
            this.otpCollection = novoDb.getCollection("auth_otps");
            this.auditLogsCollection = novoDb.getCollection("admin_audit_logs");
            this.loginLimitsCollection = novoDb.getCollection("auth_login_limits");
            this.writeGuardCollection = novoDb.getCollection("admin_write_guard");
            this.emailOutboxCollection = novoDb.getCollection("email_outbox");
            this.usandoUriDireta = direta;
            if (anterior != null && anterior != novoClient) {
                try { anterior.close(); } catch (Exception ignored) { }
            }
        } catch (RuntimeException e) {
            if (!direta && this.uriDiretaConfigurada != null) {
                System.err.println("[AUTH] Falha na URI SRV principal (" + e.getMessage() + "). Tentando MONGODB_DIRECT_URI...");
                inicializarCliente(this.uriDiretaConfigurada, true);
                return;
            }
            DatabaseUnavailableException unavailable = DatabaseUnavailableException.fromThrowable(e);
            this.ultimoErroBancoCodigo = unavailable.getCodigo();
            this.ultimoErroBancoMsg = unavailable.getMessage();
            this.ultimoCheckSaudeOk = false;
            System.err.println("[MONGO-NET] Nao foi possivel inicializar cliente MongoDB no boot: " + unavailable.getMessage());
        }
    }

    private void inicializarIndicesAsync() {
        if (INDICES_INICIALIZADOS) {
            return;
        }
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                garantirIndices();
            }
        }, "mongo-indexes-init");
        t.setDaemon(true);
        t.start();
    }

    private void garantirIndices() {
        if (INDICES_INICIALIZADOS || this.database == null) {
            return;
        }
        synchronized (RepositorioUsuarios.class) {
            if (INDICES_INICIALIZADOS) {
                return;
            }
            try {
                this.database.runCommand(new Document("ping", 1));
                this.ultimoCheckSaudeAt = System.currentTimeMillis();
                this.ultimoCheckSaudeOk = true;
                this.ultimoErroBancoCodigo = "";
                this.ultimoErroBancoMsg = "";

                criarIndiceSeguro(usersCollection, "idx_auth_users_identity_unique",
                        new Document("normalizedIdentity", 1),
                        new com.mongodb.client.model.IndexOptions().unique(true));
                criarIndiceSeguro(usersCollection, "idx_auth_users_email",
                        new Document("email", 1), null);
                criarIndiceSeguro(sessionsCollection, "idx_auth_sessions_sessionid_unique",
                        new Document("sessionId", 1),
                        new com.mongodb.client.model.IndexOptions().unique(true));
                criarIndiceSeguro(sessionsCollection, "idx_auth_sessions_userid",
                        new Document("userId", 1), null);
                criarIndiceSeguro(sessionsCollection, "idx_auth_sessions_expiresat",
                        new Document("expiresAt", 1),
                        new com.mongodb.client.model.IndexOptions().expireAfter(0L, java.util.concurrent.TimeUnit.SECONDS));
                criarIndiceSeguro(otpCollection, "idx_auth_otps_identity",
                        new Document("identity", 1), null);
                criarIndiceSeguro(otpCollection, "idx_auth_otps_expiresat",
                        new Document("expiresAt", 1),
                        new com.mongodb.client.model.IndexOptions().expireAfter(0L, java.util.concurrent.TimeUnit.SECONDS));
                criarIndiceSeguro(loginLimitsCollection, "idx_auth_login_limits_key_unique",
                        new Document("key", 1),
                        new com.mongodb.client.model.IndexOptions().unique(true));
                criarIndiceSeguro(loginLimitsCollection, "idx_auth_login_limits_expiresat",
                        new Document("expiresAt", 1),
                        new com.mongodb.client.model.IndexOptions().expireAfter(0L, java.util.concurrent.TimeUnit.SECONDS));
                criarIndiceSeguro(auditLogsCollection, "idx_admin_audit_logs_createdat",
                        new Document("createdAt", -1), null);
                criarIndiceSeguro(emailOutboxCollection, "idx_email_outbox_expiresat",
                        new Document("expiresAt", 1),
                        new com.mongodb.client.model.IndexOptions().expireAfter(0L, java.util.concurrent.TimeUnit.SECONDS));
                INDICES_INICIALIZADOS = true;
                System.out.println("[AUTH] Conexao e indices MongoDB verificados com sucesso.");
            } catch (Exception e) {
                if (!this.usandoUriDireta && this.uriDiretaConfigurada != null) {
                    System.err.println("[MONGO-NET] Ping SRV falhou; alternando para MONGODB_DIRECT_URI...");
                    inicializarCliente(this.uriDiretaConfigurada, true);
                } else {
                    DatabaseUnavailableException unavailable = DatabaseUnavailableException.fromThrowable(e);
                    this.ultimoCheckSaudeAt = System.currentTimeMillis();
                    this.ultimoCheckSaudeOk = false;
                    this.ultimoErroBancoCodigo = unavailable.getCodigo();
                    this.ultimoErroBancoMsg = unavailable.getMessage();
                    System.err.println("[MONGO-NET] MongoDB inacessivel na inicializacao: " + unavailable.getMessage());
                }
            }
        }
    }

    /**
     * Verifica rapidamente (com cache de 5s) se o MongoDB Atlas esta acessivel na rede atual.
     */
    public EstadoSaudeBanco verificarSaudeBanco() {
        if (this.uriPrincipalConfigurada == null) {
            return new EstadoSaudeBanco(false, "database_unconfigured", "Repositorio offline.");
        }
        long agora = System.currentTimeMillis();
        if (agora - this.ultimoCheckSaudeAt < HEALTH_CACHE_TTL_MS && this.ultimoCheckSaudeAt > 0L) {
            return new EstadoSaudeBanco(this.ultimoCheckSaudeOk, this.ultimoErroBancoCodigo, this.ultimoErroBancoMsg);
        }
        if (this.database == null) {
            inicializarCliente(this.uriPrincipalConfigurada, false);
        }
        if (this.database == null) {
            this.ultimoCheckSaudeAt = agora;
            return new EstadoSaudeBanco(false, this.ultimoErroBancoCodigo, this.ultimoErroBancoMsg);
        }
        try {
            this.database.runCommand(new Document("ping", 1));
            this.ultimoCheckSaudeAt = System.currentTimeMillis();
            this.ultimoCheckSaudeOk = true;
            this.ultimoErroBancoCodigo = "";
            this.ultimoErroBancoMsg = "";
            if (!INDICES_INICIALIZADOS) {
                inicializarIndicesAsync();
            }
            return new EstadoSaudeBanco(true, "ok", "");
        } catch (Exception e) {
            if (!this.usandoUriDireta && this.uriDiretaConfigurada != null) {
                inicializarCliente(this.uriDiretaConfigurada, true);
                if (this.database != null) {
                    try {
                        this.database.runCommand(new Document("ping", 1));
                        this.ultimoCheckSaudeAt = System.currentTimeMillis();
                        this.ultimoCheckSaudeOk = true;
                        this.ultimoErroBancoCodigo = "";
                        this.ultimoErroBancoMsg = "";
                        return new EstadoSaudeBanco(true, "ok", "");
                    } catch (Exception ignoredDirect) { }
                }
            }
            DatabaseUnavailableException unavailable = DatabaseUnavailableException.fromThrowable(e);
            this.ultimoCheckSaudeAt = System.currentTimeMillis();
            this.ultimoCheckSaudeOk = false;
            this.ultimoErroBancoCodigo = unavailable.getCodigo();
            this.ultimoErroBancoMsg = unavailable.getMessage();
            return new EstadoSaudeBanco(false, unavailable.getCodigo(), unavailable.getMessage());
        }
    }

    private void garantirColecoesAtivas() {
        if (this.usersCollection == null) {
            if (this.uriPrincipalConfigurada != null) {
                inicializarCliente(this.uriPrincipalConfigurada, false);
            }
            if (this.usersCollection == null) {
                throw new DatabaseUnavailableException(
                        503,
                        this.ultimoErroBancoCodigo.isEmpty() ? "database_unavailable" : this.ultimoErroBancoCodigo,
                        this.ultimoErroBancoMsg.isEmpty()
                                ? "Banco de dados inacessivel a partir desta rede."
                                : this.ultimoErroBancoMsg,
                        null
                );
            }
        }
    }

    private RuntimeException tratarFalhaMongo(MongoException e, String contexto) {
        if (!this.usandoUriDireta && this.uriDiretaConfigurada != null) {
            DatabaseUnavailableException prelim = DatabaseUnavailableException.fromThrowable(e);
            if ("database_dns_blocked".equals(prelim.getCodigo())) {
                System.err.println("[MONGO-NET] Falha DNS SRV em " + contexto + "; tentando MONGODB_DIRECT_URI...");
                inicializarCliente(this.uriDiretaConfigurada, true);
            }
        }
        DatabaseUnavailableException unavailable = DatabaseUnavailableException.fromThrowable(e);
        this.ultimoCheckSaudeAt = System.currentTimeMillis();
        this.ultimoCheckSaudeOk = false;
        this.ultimoErroBancoCodigo = unavailable.getCodigo();
        this.ultimoErroBancoMsg = unavailable.getMessage();
        System.err.println("[MONGO-NET] " + contexto + ": " + unavailable.getMessage() + " (" + e.getMessage() + ")");
        return unavailable;
    }

    public MongoDatabase getDatabase() { return database; }
    public MongoCollection<Document> getUsersCollection() { return usersCollection; }
    public MongoCollection<Document> getSessionsCollection() { return sessionsCollection; }
    public MongoCollection<Document> getOtpCollection() { return otpCollection; }
    public MongoCollection<Document> getAuditLogsCollection() { return auditLogsCollection; }
    public MongoCollection<Document> getLoginLimitsCollection() { return loginLimitsCollection; }
    public MongoCollection<Document> getWriteGuardCollection() { return writeGuardCollection; }
    public MongoCollection<Document> getEmailOutboxCollection() { return emailOutboxCollection; }

    /**
     * Cria um indice de forma segura, lidando com conflitos de indices pre-existentes.
     * Se um indice com o mesmo nome mas especificacoes diferentes ja existir (erro 86),
     * o indice antigo e removido e recriado com as novas especificacoes.
     *
     * @param collection Colecao MongoDB alvo.
     * @param indexName  Nome explicito e descritivo para o indice.
     * @param keys       Especificacao das chaves do indice.
     * @param options    Opcoes adicionais (unique, expireAfter, etc), pode ser null.
     */
    private void criarIndiceSeguro(MongoCollection<Document> collection, String indexName,
                                    Document keys, com.mongodb.client.model.IndexOptions options) {
        try {
            if (options == null) {
                options = new com.mongodb.client.model.IndexOptions();
            }
            options.name(indexName);
            collection.createIndex(keys, options);
            System.out.println("[AUTH] Indice criado com sucesso: " + indexName);
        } catch (MongoCommandException e) {
            if (e.getErrorCode() == 86) {
                // IndexKeySpecsConflict: mesmo nome, especificacoes diferentes
                System.out.println("[AUTH] Conflito de indice detectado (" + indexName
                        + "), removendo e recriando com novas especificacoes...");
                try {
                    collection.dropIndex(indexName);
                    if (options == null) {
                        options = new com.mongodb.client.model.IndexOptions();
                    }
                    options.name(indexName);
                    collection.createIndex(keys, options);
                    System.out.println("[AUTH] Indice recriado com sucesso: " + indexName);
                } catch (Exception retryEx) {
                    System.err.println("[AUTH] Erro ao recriar indice " + indexName + ": "
                            + retryEx.getMessage());
                }
            } else if (e.getErrorCode() == 85) {
                // IndexOptionsConflict: mesmo spec, nome diferente - indice ja existe
                System.out.println("[AUTH] Indice ja existe com especificacoes compativeis: "
                        + indexName);
            } else {
                System.err.println("[AUTH] Erro ao criar indice " + indexName + " (code "
                        + e.getErrorCode() + "): " + e.getMessage());
            }
        } catch (Exception e) {
            System.err.println("[AUTH] Erro inesperado ao criar indice " + indexName
                    + ": " + e.getMessage());
        }
    }

    /**
     * Autentica usuario por identidade e senha usando hash PBKDF2.
     * Sempre executa o mesmo custo computacional, seja o usuario encontrado ou nao,
     * para evitar ataques de enumeracao por temporizacao.
     *
     * @return UsuarioAutenticado se valido, null caso contrario.
     */
    public UsuarioAutenticado autenticar(String identidade, String senha) {
        if (identidade == null || identidade.trim().isEmpty()) {
            return null;
        }
        garantirColecoesAtivas();

        String normalizedIdentity = identidade.trim().toLowerCase();

        try {
            // Buscar usuario por normalizedIdentity OU email OU normalizedEmail
            Document query = new Document("active", true).append("$or", java.util.Arrays.asList(
                    new Document("normalizedIdentity", normalizedIdentity),
                    new Document("email", normalizedIdentity),
                    new Document("normalizedEmail", normalizedIdentity)
            ));
            Document user = usersCollection.find(query).first();

            // Definir o hash de comparacao: real ou dummy (protecao contra enumeracao)
            String hashParaComparar;
            if (user != null) {
                hashParaComparar = user.getString("passwordHash");
                if (hashParaComparar == null || hashParaComparar.isEmpty()) {
                    hashParaComparar = DUMMY_HASH;
                }
            } else {
                // Usuario nao encontrado: usa dummy hash para gastar o mesmo tempo
                hashParaComparar = DUMMY_HASH;
                System.out.println("[AUTH] Usuario nao encontrado (dummy hash aplicado): " + normalizedIdentity);
            }

            // Verificar senha com comparacao em tempo constante
            boolean senhaValida = SenhaHasher.verificar(senha, hashParaComparar);

            if (!senhaValida) {
                System.out.println("[AUTH] Senha incorreta para: " + normalizedIdentity);
                return null;
            }

            // Usuario nao encontrado mas senha dummy passou? Nao deveria acontecer,
            // mas por seguranca verificamos novamente
            if (user == null) {
                return null;
            }

            // Construir objeto de usuario autenticado com dados reais do MongoDB
            UsuarioAutenticado usuario = construirUsuarioAutenticado(user, normalizedIdentity);

            System.out.println("[AUTH] Login bem-sucedido: " + usuario.getIdentity() + " (" + usuario.getProfile() + ")"
                    + (usuario.isTwoFactorEnabled() ? " [2FA ativo]" : ""));

            // Atualizar ultimo login (mantendo lastLogin e lastLoginAt sincronizados)
            Date agora = new Date();
            try {
                usersCollection.updateOne(
                        Filters.eq("_id", user.getObjectId("_id")),
                        Updates.combine(
                                Updates.set("lastLogin", agora),
                                Updates.set("lastLoginAt", agora)
                        )
                );
            } catch (MongoException updateEx) {
                System.err.println("[AUTH] Aviso ao atualizar lastLogin: " + updateEx.getMessage());
            }

            return usuario;

        } catch (DatabaseUnavailableException e) {
            throw e;
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "autenticar");
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao autenticar usuario: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Busca documento BSON bruto do usuario por ID (inclusive suspensos, para Admin).
     */
    public Document buscarDocumentoPorId(String userId) {
        if (userId == null || !ObjectId.isValid(userId.trim())) {
            return null;
        }
        garantirColecoesAtivas();
        try {
            return usersCollection.find(Filters.eq("_id", new ObjectId(userId.trim()))).first();
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "buscarDocumentoPorId");
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Busca documento BSON do usuario ativo por ID.
     */
    public Document buscarDocumentoAtivoPorId(String userId) {
        if (userId == null || !ObjectId.isValid(userId.trim())) {
            return null;
        }
        garantirColecoesAtivas();
        try {
            return usersCollection.find(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true))
            ).first();
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "buscarDocumentoAtivoPorId");
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Busca usuario por ID.
     */
    public UsuarioAutenticado buscarPorId(String userId) {
        if (userId == null || !ObjectId.isValid(userId.trim())) {
            return null;
        }
        return buscarUsuarioPorFiltro(
                new Document("_id", new ObjectId(userId.trim())).append("active", true),
                userId.trim(),
                "buscarPorId"
        );
    }

    /**
     * Busca usuario por identidade normalizada (case-insensitive).
     */
    public UsuarioAutenticado buscarPorIdentidade(String identidade) {
        if (identidade == null || identidade.trim().isEmpty()) {
            return null;
        }
        String normalizedIdentity = identidade.trim().toLowerCase();
        Document query = new Document("active", true).append("$or", java.util.Arrays.asList(
                new Document("normalizedIdentity", normalizedIdentity),
                new Document("email", normalizedIdentity),
                new Document("normalizedEmail", normalizedIdentity)
        ));
        return buscarUsuarioPorFiltro(query, normalizedIdentity, "buscarPorIdentidade");
    }

    /**
     * Busca usuario por endereco de email.
     */
    public UsuarioAutenticado buscarPorEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return null;
        }
        String normalizedEmail = email.trim().toLowerCase();
        Document query = new Document("active", true).append("$or", java.util.Arrays.asList(
                new Document("email", normalizedEmail),
                new Document("normalizedEmail", normalizedEmail),
                new Document("normalizedIdentity", normalizedEmail)
        ));
        return buscarUsuarioPorFiltro(query, normalizedEmail, "buscarPorEmail");
    }

    private UsuarioAutenticado buscarUsuarioPorFiltro(Document query, String fallbackIdentity, String contexto) {
        garantirColecoesAtivas();
        try {
            Document user = usersCollection.find(query).first();
            return construirUsuarioAutenticado(user, fallbackIdentity);
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, contexto);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro em " + contexto + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * Converte um Document BSON do MongoDB para UsuarioAutenticado preservando metadados academicos.
     */
    private UsuarioAutenticado construirUsuarioAutenticado(Document user, String fallbackIdentity) {
        if (user == null) return null;

        String userId = user.getObjectId("_id").toHexString();
        String profile = user.getString("profile");
        String actualIdentity = user.getString("identity");
        if (actualIdentity == null || actualIdentity.isEmpty()) {
            actualIdentity = user.getString("normalizedIdentity");
        }
        if (actualIdentity == null || actualIdentity.isEmpty()) {
            actualIdentity = fallbackIdentity;
        }
        String displayName = user.getString("displayName");
        String actualEmail = user.getString("email");
        if (actualEmail == null || actualEmail.isEmpty()) {
            actualEmail = user.getString("normalizedEmail");
        }
        boolean twoFactorEnabled = user.getBoolean("twoFactorEnabled", false)
                || user.getBoolean("twoFactorRequired", false);
        int sessionVersion = user.getInteger("sessionVersion", 0);

        String dept = user.getString("departmentOrCourse");
        if (dept == null || dept.isEmpty()) {
            dept = user.getString("department");
        }
        String campus = user.getString("campus");
        String semester = user.getString("semester");
        String shift = user.getString("shift");
        boolean requirePasswordChange = user.getBoolean("requirePasswordChange", false);
        String socialName = user.getString("socialName");
        String personalEmail = user.getString("personalEmail");
        String phone = user.getString("phone");
        String biography = user.getString("biography");
        Map<String, Object> preferences = documentoParaMapa(user.get("preferences", Document.class));

        return new UsuarioAutenticado(
                userId,
                profile,
                "",
                sessionVersion,
                actualIdentity != null ? actualIdentity : "",
                displayName != null ? displayName : "",
                actualEmail != null ? actualEmail : "",
                twoFactorEnabled,
                dept != null ? dept : "",
                campus != null ? campus : "",
                semester != null ? semester : "",
                shift != null ? shift : "",
                requirePasswordChange,
                socialName != null ? socialName : "",
                personalEmail != null ? personalEmail : "",
                phone != null ? phone : "",
                biography != null ? biography : "",
                preferences
        );
    }

    @SuppressWarnings("unchecked")
    public static Map<String, Object> documentoParaMapa(Object obj) {
        if (!(obj instanceof Document)) {
            return Collections.emptyMap();
        }
        Document doc = (Document) obj;
        Map<String, Object> mapa = new LinkedHashMap<String, Object>();
        for (Map.Entry<String, Object> entry : doc.entrySet()) {
            Object val = entry.getValue();
            if (val instanceof Document) {
                mapa.put(entry.getKey(), documentoParaMapa(val));
            } else if (val instanceof List) {
                List<Object> converted = new ArrayList<Object>();
                for (Object item : (List<Object>) val) {
                    if (item instanceof Document) {
                        converted.add(documentoParaMapa(item));
                    } else if (item instanceof ObjectId) {
                        converted.add(((ObjectId) item).toHexString());
                    } else {
                        converted.add(item);
                    }
                }
                mapa.put(entry.getKey(), converted);
            } else if (val instanceof ObjectId) {
                mapa.put(entry.getKey(), ((ObjectId) val).toHexString());
            } else {
                mapa.put(entry.getKey(), val);
            }
        }
        return mapa;
    }

    @SuppressWarnings("unchecked")
    public static Document mapaParaDocumento(Map<String, Object> mapa) {
        Document doc = new Document();
        if (mapa == null) return doc;
        for (Map.Entry<String, Object> entry : mapa.entrySet()) {
            Object val = entry.getValue();
            if (val instanceof Map) {
                doc.append(entry.getKey(), mapaParaDocumento((Map<String, Object>) val));
            } else {
                doc.append(entry.getKey(), val);
            }
        }
        return doc;
    }

    /**
     * Cadastra um novo usuario com hash PBKDF2.
     *
     * @param identidade Identidade unica do usuario (normalizada para lowercase).
     * @param senha      Senha em texto plano (sera hasheada com PBKDF2).
     * @param profile    Perfil institucional (aluno, docente, admin).
     * @param displayName Nome de exibicao do usuario.
     * @param email      Endereco de email do usuario.
     * @return UsuarioAutenticado do usuario cadastrado.
     * @throws IllegalStateException se a identidade ja esta em uso.
     * @throws IllegalArgumentException se a senha nao atende a complexidade minima.
     */
    public UsuarioAutenticado cadastrarUsuario(String identidade, String senha, String profile,
                                                String displayName, String email) {
        if (identidade == null || identidade.trim().isEmpty()) {
            throw new IllegalArgumentException("Identidade e obrigatoria.");
        }
        if (profile == null || profile.trim().isEmpty()) {
            throw new IllegalArgumentException("Perfil e obrigatorio.");
        }

        // Validar complexidade da senha
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(senha);
        if (!validacao.isValido()) {
            throw new IllegalArgumentException(validacao.getMensagem());
        }

        String normalizedIdentity = identidade.trim().toLowerCase();
        String normalizedEmail = email != null ? email.trim().toLowerCase() : "";

        // Verificar se ja existe
        Document existente = usersCollection.find(
                new Document("normalizedIdentity", normalizedIdentity)
        ).first();
        if (existente != null) {
            throw new IllegalStateException("Identidade ja cadastrada: " + identidade);
        }

        String hashedPassword = SenhaHasher.hash(senha);

        Document novo = new Document()
                .append("identity", identidade.trim())
                .append("normalizedIdentity", normalizedIdentity)
                .append("displayName", displayName != null ? displayName : "")
                .append("email", normalizedEmail)
                .append("profile", profile.trim().toLowerCase())
                .append("passwordHash", hashedPassword)
                .append("twoFactorEnabled", false)
                .append("twoFactorRequired", false)
                .append("twoFactorSecret", "")
                .append("active", true)
                .append("sessionVersion", 1)
                .append("createdAt", new Date())
                .append("updatedAt", new Date())
                .append("lastLogin", null)
                .append("lastLoginAt", null);

        usersCollection.insertOne(novo);

        String userId = novo.getObjectId("_id").toHexString();

        System.out.println("[AUTH] Usuario cadastrado: " + normalizedIdentity + " (" + profile + ")");

        return new UsuarioAutenticado(
                userId,
                profile.trim().toLowerCase(),
                "",
                1,
                normalizedIdentity,
                displayName != null ? displayName : "",
                normalizedEmail,
                false
        );
    }

    /**
     * Atualiza a senha de um usuario apos validacao de complexidade.
     *
     * @param userId  ID do usuario.
     * @param novaSenha Nova senha em texto plano.
     * @return true se atualizada com sucesso.
     */
    public boolean atualizarSenha(String userId, String novaSenha) {
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(novaSenha);
        if (!validacao.isValido()) {
            throw new IllegalArgumentException(validacao.getMensagem());
        }

        String hashedPassword = SenhaHasher.hash(novaSenha);

        try {
            Date agora = new Date();
            com.mongodb.client.result.UpdateResult result = usersCollection.updateOne(
                    Filters.eq("_id", new ObjectId(userId)),
                    Updates.combine(
                            Updates.set("passwordHash", hashedPassword),
                            Updates.set("updatedAt", agora),
                            Updates.set("passwordUpdatedAt", agora),
                            Updates.set("requirePasswordChange", false),
                            // Incrementar versao da sessao para invalidar tokens antigos
                            Updates.inc("sessionVersion", 1)
                    )
            );
            System.out.println("[AUTH] Senha atualizada para usuario: " + userId);
            return result.getMatchedCount() > 0;
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao atualizar senha: " + e.getMessage());
            return false;
        }
    }

    /**
     * Verifica se a senha atual do usuario esta correta (para alteracao de senha).
     */
    public boolean verificarSenhaAtual(String userId, String senhaAtual) {
        try {
            Document user = usersCollection.find(
                    Filters.eq("_id", new ObjectId(userId))
            ).first();
            if (user == null) return false;

            String hashArmazenado = user.getString("passwordHash");
            if (hashArmazenado == null || hashArmazenado.isEmpty()) {
                return false;
            }
            return SenhaHasher.verificar(senhaAtual, hashArmazenado);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Retorna o hash dummy para ser usado em comparacoes externas quando necessario.
     */
    public String getDummyHash() {
        return DUMMY_HASH;
    }

    // =========================================================================
    // SESSOES PERSISTIDAS NO MONGODB
    // =========================================================================

    /**
     * Cria uma sessao persistida no MongoDB.
     */
    public void criarSessao(String userId, String sessionId, long expiresAtMillis) {
        criarSessao(userId, sessionId, expiresAtMillis, null, null);
    }

    /**
     * Cria uma sessao persistida no MongoDB com metadados de dispositivo e IP.
     */
    public void criarSessao(String userId, String sessionId, long expiresAtMillis, String userAgent, String ipAddress) {
        try {
            Document sessao = new Document()
                    .append("sessionId", sessionId)
                    .append("userId", userId)
                    .append("active", true)
                    .append("createdAt", new Date())
                    .append("expiresAt", new Date(expiresAtMillis));
            if (userAgent != null && !userAgent.trim().isEmpty()) {
                sessao.append("userAgent", userAgent.trim());
            }
            if (ipAddress != null && !ipAddress.trim().isEmpty()) {
                sessao.append("ipAddress", ipAddress.trim());
            }
            sessionsCollection.insertOne(sessao);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao criar sessao: " + e.getMessage());
        }
    }

    /**
     * Verifica se uma sessao existe, nao expirou e esta ativa.
     */
    public boolean sessaoAtiva(String sessionId) {
        if (sessionId == null || sessionId.trim().isEmpty()) return false;
        try {
            Document sessao = sessionsCollection.find(
                    Filters.and(
                            Filters.eq("sessionId", sessionId.trim()),
                            Filters.ne("active", false),
                            Filters.gt("expiresAt", new Date())
                    )
            ).first();
            return sessao != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Resultado detalhado da conferencia de sessao JWT no MongoDB.
     */
    public static final class ResultadoValidacaoSessao {
        public final boolean valida;
        public final int statusHttp;
        public final String codigo;
        public final String mensagem;
        public final UsuarioAutenticado usuario;

        private ResultadoValidacaoSessao(boolean valida, int statusHttp, String codigo, String mensagem, UsuarioAutenticado usuario) {
            this.valida = valida;
            this.statusHttp = statusHttp;
            this.codigo = codigo;
            this.mensagem = mensagem;
            this.usuario = usuario;
        }

        public static ResultadoValidacaoSessao ok(UsuarioAutenticado usuario) {
            return new ResultadoValidacaoSessao(true, 200, "ok", "", usuario);
        }

        public static ResultadoValidacaoSessao erro(int statusHttp, String codigo, String mensagem) {
            return new ResultadoValidacaoSessao(false, statusHttp, codigo, mensagem, null);
        }
    }

    /**
     * Valida conta ativa, sessionVersion, perfil e sessao persistida no MongoDB.
     */
    public ResultadoValidacaoSessao validarSessaoCompleta(
            String userId,
            String sessionId,
            int tokenVersion,
            String tokenProfile,
            boolean permitirTrocaSenhaPendente) {
        if (userId == null || !ObjectId.isValid(userId.trim())) {
            return ResultadoValidacaoSessao.erro(401, "invalid_token", "Identificador de usuario invalido.");
        }
        if (sessionId == null || sessionId.trim().isEmpty()) {
            return ResultadoValidacaoSessao.erro(401, "session_revoked", "Sessao ausente. Realize login novamente.");
        }
        garantirColecoesAtivas();
        try {
            Document userDoc = usersCollection.find(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true))
            ).first();
            Document sessionDoc = sessionsCollection.find(
                    Filters.and(
                            Filters.eq("sessionId", sessionId.trim()),
                            Filters.eq("userId", userId.trim()),
                            Filters.ne("active", false),
                            Filters.gt("expiresAt", new Date())
                    )
            ).first();

            if (userDoc == null || sessionDoc == null) {
                return ResultadoValidacaoSessao.erro(401, "session_revoked", "Sessao encerrada. Entre novamente.");
            }

            int dbVersion = userDoc.getInteger("sessionVersion", 0);
            String dbProfile = userDoc.getString("profile");
            if (dbVersion != tokenVersion || dbProfile == null || !dbProfile.equalsIgnoreCase(tokenProfile)) {
                return ResultadoValidacaoSessao.erro(401, "session_revoked", "Sessao encerrada. Entre novamente.");
            }

            boolean requirePwdChange = userDoc.getBoolean("requirePasswordChange", false);
            if (requirePwdChange && !permitirTrocaSenhaPendente) {
                return ResultadoValidacaoSessao.erro(403, "password_change_required", "Altere sua senha para continuar.");
            }

            UsuarioAutenticado base = construirUsuarioAutenticado(userDoc, userId);
            UsuarioAutenticado completo = new UsuarioAutenticado(
                    base.getUserId(),
                    base.getProfile(),
                    sessionId.trim(),
                    dbVersion,
                    base.getIdentity(),
                    base.getDisplayName(),
                    base.getEmail(),
                    base.isTwoFactorEnabled(),
                    base.getDepartmentOrCourse(),
                    base.getCampus(),
                    base.getSemester(),
                    base.getShift(),
                    requirePwdChange,
                    base.getSocialName(),
                    base.getPersonalEmail(),
                    base.getPhone(),
                    base.getBiography(),
                    base.getPreferences()
            );
            return ResultadoValidacaoSessao.ok(completo);
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "validarSessaoCompleta");
        } catch (Exception e) {
            return ResultadoValidacaoSessao.erro(401, "session_revoked", "Nao foi possivel validar a sessao.");
        }
    }

    /**
     * Lista sessoes ativas e nao expiradas de um usuario, ordenadas da mais recente para a mais antiga.
     */
    public List<Document> listarSessoesAtivas(String userId) {
        List<Document> lista = new ArrayList<Document>();
        try {
            sessionsCollection.find(
                    Filters.and(
                            Filters.eq("userId", userId),
                            Filters.ne("active", false),
                            Filters.gt("expiresAt", new Date())
                    )
            ).sort(Sorts.descending("createdAt")).into(lista);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao listar sessoes: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Revoga uma sessao especifica garantindo pertencimento ao userId.
     */
    public void revogarSessaoUsuario(String userId, String sessionId) {
        try {
            sessionsCollection.deleteOne(
                    Filters.and(Filters.eq("sessionId", sessionId), Filters.eq("userId", userId))
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar sessao do usuario: " + e.getMessage());
        }
    }

    /**
     * Revoga todas as outras sessoes de um usuario preservando a atual.
     */
    public void revogarOutrasSessoes(String userId, String currentSessionId) {
        try {
            sessionsCollection.deleteMany(
                    Filters.and(
                            Filters.eq("userId", userId),
                            Filters.ne("sessionId", currentSessionId)
                    )
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar outras sessoes: " + e.getMessage());
        }
    }

    /**
     * Revoga (remove) uma sessao pelo sessionId.
     */
    public void revogarSessao(String sessionId) {
        try {
            sessionsCollection.deleteOne(Filters.eq("sessionId", sessionId));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar sessao: " + e.getMessage());
        }
    }

    /**
     * Revoga todas as sessoes de um usuario (logout global).
     */
    public void revogarTodasSessoes(String userId) {
        try {
            sessionsCollection.deleteMany(Filters.eq("userId", userId));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar todas as sessoes: " + e.getMessage());
        }
    }

    /**
     * Consome de forma atomica um codigo de backup SHA-256 (AGMRM-XXXX-XXXX) armazenado em auth_users.
     */
    @SuppressWarnings("unchecked")
    public boolean consumirCodigoBackup(String userId, String codigo) {
        if (userId == null || !ObjectId.isValid(userId.trim()) || codigo == null || codigo.trim().isEmpty()) {
            return false;
        }
        String digest = OtpService.sha256Hex(codigo.trim().toUpperCase());
        try {
            Document updated = usersCollection.findOneAndUpdate(
                    Filters.and(
                            Filters.eq("_id", new ObjectId(userId.trim())),
                            Filters.eq("active", true),
                            Filters.eq("backupCodeDigests", digest)
                    ),
                    Updates.combine(
                            Updates.pull("backupCodeDigests", digest),
                            Updates.set("updatedAt", new Date())
                    )
            );
            return updated != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Emite e persiste um grant de uso unico para reset de senha.
     */
    public void emitirGrantRecuperacao(String normalizedIdentity, String jtiHash, long expiresAtMillis) {
        try {
            otpCollection.deleteMany(
                    Filters.and(Filters.eq("identity", normalizedIdentity.toLowerCase()), Filters.eq("tipo", "RESET_GRANT"))
            );
            Document grant = new Document()
                    .append("identity", normalizedIdentity.toLowerCase())
                    .append("otpHash", jtiHash)
                    .append("tipo", "RESET_GRANT")
                    .append("tentativas", 0)
                    .append("createdAt", new Date())
                    .append("expiresAt", new Date(expiresAtMillis));
            otpCollection.insertOne(grant);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao emitir grant de recuperacao: " + e.getMessage());
        }
    }

    /**
     * Consome atomicamente um grant de recuperacao, impedindo replay do recovery token.
     */
    public boolean consumirGrantRecuperacao(String jtiHash) {
        if (jtiHash == null || jtiHash.isEmpty()) return false;
        try {
            Document consumed = otpCollection.findOneAndDelete(
                    Filters.and(
                            Filters.eq("tipo", "RESET_GRANT"),
                            Filters.eq("otpHash", jtiHash),
                            Filters.gt("expiresAt", new Date())
                    )
            );
            return consumed != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Atualiza campos de perfil e preferencias do titular no MongoDB.
     */
    public Document atualizarPerfil(String userId, Map<String, Object> setFields) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return null;
        Document setDoc = mapaParaDocumento(setFields);
        setDoc.append("updatedAt", new Date());
        return usersCollection.findOneAndUpdate(
                Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true)),
                new Document("$set", setDoc),
                new FindOneAndUpdateOptions().returnDocument(ReturnDocument.AFTER)
        );
    }

    /**
     * Ativa ou desativa 2FA, incrementando sessionVersion e revogando todas as sessoes ativas.
     */
    public boolean atualizarDoisFatores(String userId, boolean enabled) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return false;
        try {
            com.mongodb.client.result.UpdateResult res = usersCollection.updateOne(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true)),
                    Updates.combine(
                            Updates.set("twoFactorRequired", enabled),
                            Updates.set("twoFactorEnabled", enabled),
                            Updates.set("updatedAt", new Date()),
                            Updates.inc("sessionVersion", 1)
                    )
            );
            if (res.getMatchedCount() > 0) {
                revogarTodasSessoes(userId.trim());
                return true;
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Substitui os digests SHA-256 dos codigos de backup do usuario.
     */
    public boolean salvarCodigosBackup(String userId, List<String> digests) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return false;
        try {
            com.mongodb.client.result.UpdateResult res = usersCollection.updateOne(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true)),
                    Updates.combine(
                            Updates.set("backupCodeDigests", digests),
                            Updates.set("backupCodesGeneratedAt", new Date()),
                            Updates.set("updatedAt", new Date())
                    )
            );
            return res.getMatchedCount() > 0;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Registra evento de auditoria na colecao compartilhada admin_audit_logs.
     */
    public void registrarAuditoria(String actorId, String action, String target, Map<String, Object> details, String ipAddress) {
        try {
            Document doc = new Document()
                    .append("actorId", actorId != null ? actorId : "system")
                    .append("action", action)
                    .append("target", target != null ? target : "")
                    .append("details", details != null ? mapaParaDocumento(details) : new Document())
                    .append("createdAt", new Date());
            if (ipAddress != null && !ipAddress.trim().isEmpty()) {
                doc.append("ipAddress", ipAddress.trim());
            }
            auditLogsCollection.insertOne(doc);
        } catch (Exception e) {
            System.err.println("[AUDIT] Erro ao registrar auditoria: " + e.getMessage());
        }
    }

    public void registrarAuditoria(String actorId, String action, String target, Map<String, Object> details) {
        registrarAuditoria(actorId, action, target, details, null);
    }

    /**
     * Lista os logs de seguranca relacionados a um usuario.
     */
    public List<Document> listarLogsSeguranca(String userId, int limit) {
        List<Document> logs = new ArrayList<Document>();
        try {
            auditLogsCollection.find(
                    Filters.or(Filters.eq("actorId", userId), Filters.eq("target", userId))
            ).sort(Sorts.descending("createdAt")).limit(limit).into(logs);
        } catch (Exception e) {
            System.err.println("[AUDIT] Erro ao listar logs de seguranca: " + e.getMessage());
        }
        return logs;
    }

    /**
     * Incrementa o contador global admin_write_guard e valida que o ator continua administrador ativo.
     */
    public boolean registrarEscritaAdmin(String adminId) {
        if (adminId == null || !ObjectId.isValid(adminId.trim())) return false;
        try {
            writeGuardCollection.updateOne(
                    Filters.eq("_id", "admin"),
                    Updates.inc("revision", 1),
                    new UpdateOptions().upsert(true)
            );
            Document adminDoc = usersCollection.find(
                    Filters.and(
                            Filters.eq("_id", new ObjectId(adminId.trim())),
                            Filters.eq("profile", "admin"),
                            Filters.eq("active", true)
                    )
            ).first();
            return adminDoc != null;
        } catch (Exception e) {
            return false;
        }
    }

    // =========================================================================
    // OTPs (CÓDIGOS DE VERIFICAÇÃO)
    // =========================================================================

    /**
     * Salva um codigo OTP com hash HMAC para verificacao posterior.
     */
    public void salvarOtp(String identity, String otpHash, String tipo, long expiresAtMillis) {
        try {
            // Limpar OTPs anteriores do mesmo tipo para esta identidade
            otpCollection.deleteMany(
                    Filters.and(
                            Filters.eq("identity", identity.toLowerCase()),
                            Filters.eq("tipo", tipo)
                    )
            );

            Document otp = new Document()
                    .append("identity", identity.toLowerCase())
                    .append("otpHash", otpHash)
                    .append("tipo", tipo)
                    .append("tentativas", 0)
                    .append("createdAt", new Date())
                    .append("expiresAt", new Date(expiresAtMillis));
            otpCollection.insertOne(otp);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao salvar OTP: " + e.getMessage());
        }
    }

    /**
     * Busca e valida um OTP pelo hash.
     *
     * @return Document do OTP se valido, null se expirado ou nao encontrado.
     */
    public Document buscarOtp(String identity, String tipo) {
        try {
            return otpCollection.find(
                    Filters.and(
                            Filters.eq("identity", identity.toLowerCase()),
                            Filters.eq("tipo", tipo)
                    )
            ).sort(new Document("createdAt", -1))
                    .first();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Incrementa o contador de tentativas de um OTP.
     */
    public void incrementarTentativasOtp(String identity, String tipo) {
        try {
            otpCollection.updateOne(
                    Filters.and(
                            Filters.eq("identity", identity.toLowerCase()),
                            Filters.eq("tipo", tipo)
                    ),
                    Updates.inc("tentativas", 1)
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao incrementar tentativas OTP: " + e.getMessage());
        }
    }

    /**
     * Remove um OTP apos verificacao bem-sucedida.
     */
    public void removerOtp(String identity, String tipo) {
        try {
            otpCollection.deleteMany(
                    Filters.and(
                            Filters.eq("identity", identity.toLowerCase()),
                            Filters.eq("tipo", tipo)
                    )
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao remover OTP: " + e.getMessage());
        }
    }

    public void fechar() {
        // No-op para manter o pool compartilhado ativo durante as requisicoes HTTP
    }

    public void encerrarDefinitivo() {
        if (client != null) {
            client.close();
            System.out.println("[AUTH] Conexao MongoDB fechada em definitivo.");
        }
    }
}
