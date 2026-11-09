// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import org.bson.Document;
import org.bson.types.ObjectId;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.Updates;

import utils.ConfigEnv;

import com.mongodb.MongoCommandException;

import java.util.Date;

/**
 * Repositorio de usuarios conectado diretamente ao MongoDB.
 * Responsavel por autenticacao de credenciais com hash PBKDF2, consulta de perfis,
 * cadastro de novos usuarios, atualizacao de senhas e protecao contra enumeracao.
 *
 * Todas as comparacoes de senha sao feitas via SenhaHasher.verificar() com
 * comparacao em tempo constante para mitigar timing attacks.
 */
public class RepositorioUsuarios {
    private MongoClient client;
    private MongoDatabase database;
    private MongoCollection<Document> usersCollection;
    private MongoCollection<Document> sessionsCollection;
    private MongoCollection<Document> otpCollection;

    private static volatile RepositorioUsuarios INSTANCIA_COMPARTILHADA;
    private static volatile boolean INDICES_INICIALIZADOS = false;

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

    public RepositorioUsuarios() {
        String uri = ConfigEnv.obter("MONGODB_URI", null);
        String dbName = ConfigEnv.obter("MONGODB_DATABASE", "agmrm");

        if (uri == null || uri.trim().isEmpty()) {
            throw new IllegalStateException("MONGODB_URI nao configurado no .env");
        }

        System.out.println("[AUTH] Conectando ao MongoDB: " + dbName);
        this.client = MongoClients.create(uri);
        this.database = client.getDatabase(dbName);
        this.usersCollection = database.getCollection("auth_users");
        this.sessionsCollection = database.getCollection("auth_sessions");
        this.otpCollection = database.getCollection("auth_otps");

        // Criar indices para performance e unicidade uma unica vez no boot
        if (!INDICES_INICIALIZADOS) {
            synchronized (RepositorioUsuarios.class) {
                if (!INDICES_INICIALIZADOS) {
                    criarIndiceSeguro(usersCollection, "idx_auth_users_identity_unique",
                            new Document("normalizedIdentity", 1),
                            new com.mongodb.client.model.IndexOptions().unique(true));
                    criarIndiceSeguro(usersCollection, "idx_auth_users_email",
                            new Document("email", 1), null);
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
                    INDICES_INICIALIZADOS = true;
                }
            }
        }

        System.out.println("[AUTH] Conexao MongoDB estabelecida com sucesso.");
    }

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

            // Atualizar ultimo login
            usersCollection.updateOne(
                    Filters.eq("_id", user.getObjectId("_id")),
                    Updates.set("lastLoginAt", new Date())
            );

            return usuario;

        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao autenticar usuario: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    /**
     * Busca usuario por ID.
     */
    public UsuarioAutenticado buscarPorId(String userId) {
        try {
            Document query = new Document("_id", new ObjectId(userId))
                    .append("active", true);
            Document user = usersCollection.find(query).first();
            return construirUsuarioAutenticado(user, userId);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao buscar usuario por ID: " + e.getMessage());
            return null;
        }
    }

    /**
     * Busca usuario por identidade normalizada (case-insensitive).
     */
    public UsuarioAutenticado buscarPorIdentidade(String identidade) {
        if (identidade == null || identidade.trim().isEmpty()) {
            return null;
        }
        String normalizedIdentity = identidade.trim().toLowerCase();
        try {
            // Busca por normalizedIdentity OU email OU normalizedEmail
            Document query = new Document("active", true).append("$or", java.util.Arrays.asList(
                    new Document("normalizedIdentity", normalizedIdentity),
                    new Document("email", normalizedIdentity),
                    new Document("normalizedEmail", normalizedIdentity)
            ));
            Document user = usersCollection.find(query).first();
            return construirUsuarioAutenticado(user, normalizedIdentity);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao buscar por identidade: " + e.getMessage());
            return null;
        }
    }

    /**
     * Busca usuario por endereco de email.
     */
    public UsuarioAutenticado buscarPorEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return null;
        }
        String normalizedEmail = email.trim().toLowerCase();
        try {
            Document query = new Document("active", true).append("$or", java.util.Arrays.asList(
                    new Document("email", normalizedEmail),
                    new Document("normalizedEmail", normalizedEmail),
                    new Document("normalizedIdentity", normalizedEmail)
            ));
            Document user = usersCollection.find(query).first();
            return construirUsuarioAutenticado(user, normalizedEmail);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao buscar por email: " + e.getMessage());
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
                shift != null ? shift : ""
        );
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
                .append("normalizedIdentity", normalizedIdentity)
                .append("displayName", displayName != null ? displayName : "")
                .append("email", normalizedEmail)
                .append("profile", profile.trim().toLowerCase())
                .append("passwordHash", hashedPassword)
                .append("twoFactorEnabled", false)
                .append("twoFactorSecret", "")
                .append("active", true)
                .append("sessionVersion", 1)
                .append("createdAt", new Date())
                .append("updatedAt", new Date())
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
            usersCollection.updateOne(
                    Filters.eq("_id", new ObjectId(userId)),
                    Updates.combine(
                            Updates.set("passwordHash", hashedPassword),
                            Updates.set("updatedAt", new Date()),
                            // Incrementar versao da sessao para invalidar tokens antigos
                            Updates.inc("sessionVersion", 1)
                    )
            );
            System.out.println("[AUTH] Senha atualizada para usuario: " + userId);
            return true;
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
        try {
            Document sessao = new Document()
                    .append("sessionId", sessionId)
                    .append("userId", userId)
                    .append("active", true)
                    .append("createdAt", new Date())
                    .append("expiresAt", new Date(expiresAtMillis));
            sessionsCollection.insertOne(sessao);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao criar sessao: " + e.getMessage());
        }
    }

    /**
     * Verifica se uma sessao existe e esta ativa.
     */
    public boolean sessaoAtiva(String sessionId) {
        try {
            Document sessao = sessionsCollection.find(
                    Filters.and(
                            Filters.eq("sessionId", sessionId),
                            Filters.eq("active", true)
                    )
            ).first();
            return sessao != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Revoga (desativa) uma sessao.
     */
    public void revogarSessao(String sessionId) {
        try {
            sessionsCollection.updateOne(
                    Filters.eq("sessionId", sessionId),
                    Updates.set("active", false)
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar sessao: " + e.getMessage());
        }
    }

    /**
     * Revoga todas as sessoes de um usuario (logout global).
     */
    public void revogarTodasSessoes(String userId) {
        try {
            sessionsCollection.updateMany(
                    Filters.eq("userId", userId),
                    Updates.set("active", false)
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar todas as sessoes: " + e.getMessage());
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
