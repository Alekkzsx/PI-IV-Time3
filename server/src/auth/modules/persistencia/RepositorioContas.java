// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.persistencia;

import auth.model.UsuarioAutenticado;
import auth.utils.OtpService;
import auth.utils.SenhaHasher;
import com.mongodb.MongoException;
import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.FindOneAndUpdateOptions;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.ReturnDocument;
import com.mongodb.client.model.Sorts;
import com.mongodb.client.model.Updates;
import com.mongodb.client.result.UpdateResult;
import core.ConexaoMongo;
import core.DatabaseUnavailableException;
import core.abstratas.RepositorioMongoAbstrato;
import org.bson.Document;
import org.bson.conversions.Bson;
import org.bson.types.ObjectId;
import utils.BsonUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

/**
 * Repositorio especializado na colecao auth_users (contas, credenciais, perfil, 2FA e consultas admin).
 */
public class RepositorioContas extends RepositorioMongoAbstrato {
    // Hash anti-timing gerado UMA vez no load da classe (600k iteracoes no boot, nao por requisicao);
    // reutilizado em todo login de usuario inexistente para igualar o custo do caminho real.
    private static final String DUMMY_HASH = SenhaHasher.hashDummy();

    public RepositorioContas(ConexaoMongo conexao) {
        super(conexao);
    }

    @Override
    protected String tagLog() {
        return "AUTH-CONTAS";
    }

    /**
     * Indices: normalizedIdentity unico (case-insensitive por normalizacao), email para busca,
     * e em auth_login_limits: key unica + TTL expiresAt (registro de rate limit expira sozinho).
     */
    @Override
    protected void registrarIndices(MongoDatabase db) {
        MongoCollection<Document> users = db.getCollection("auth_users");
        criarIndiceSeguro(users, "idx_auth_users_identity_unique",
                new Document("normalizedIdentity", 1), new IndexOptions().unique(true));
        criarIndiceSeguro(users, "idx_auth_users_email", new Document("email", 1), null);

        MongoCollection<Document> limits = db.getCollection("auth_login_limits");
        criarIndiceSeguro(limits, "idx_auth_login_limits_key_unique",
                new Document("key", 1), new IndexOptions().unique(true));
        criarIndiceSeguro(limits, "idx_auth_login_limits_expiresat",
                new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
    }

    /** @return hash descartavel compartilhado do boot (custo identico ao de um hash real). */
    public String getDummyHash() {
        return DUMMY_HASH;
    }

    /** @return colecao auth_users ou null se offline. */
    public MongoCollection<Document> colecaoUsuariosSeAtiva() {
        return obterColecaoSeAtiva("auth_users");
    }

    /** @return colecao auth_login_limits (rate limit persistido) ou null se offline. */
    public MongoCollection<Document> colecaoLimitesSeAtiva() {
        return obterColecaoSeAtiva("auth_login_limits");
    }

    /**
     * Autenticacao primaria (chamada pelo LoginHandler):
     * busca conta ativa por identidade OU e-mail ($or nos campos normalizados) e
     * verifica a senha. Usuario inexistente/sem hash compara contra o DUMMY_HASH:
     * o PBKDF2 roda SEMPRE, equalizando o tempo de resposta (anti-enumeracao por timing).
     * Sucesso atualiza lastLogin/lastLoginAt (best-effort). Falha de banco vira 503;
     * erro inesperado vira null (credencial invalida, fail-closed).
     *
     * @return identidade autenticada ou null para credenciais invalidas
     */
    public UsuarioAutenticado autenticar(String identidade, String senha) {
        if (identidade == null || identidade.trim().isEmpty()) {
            return null;
        }
        MongoCollection<Document> users = obterColecao("auth_users");
        String normalizedIdentity = identidade.trim().toLowerCase();

        try {
            Document query = new Document("active", true).append("$or", Arrays.asList(
                    new Document("normalizedIdentity", normalizedIdentity),
                    new Document("email", normalizedIdentity),
                    new Document("normalizedEmail", normalizedIdentity)
            ));
            Document user = users.find(query).first();

            // Sem conta (ou sem hash): usa o dummy para gastar o MESMO tempo de CPU.
            String hashParaComparar = DUMMY_HASH;
            if (user != null) {
                String stored = user.getString("passwordHash");
                if (stored != null && !stored.isEmpty()) {
                    hashParaComparar = stored;
                }
            } else {
                System.out.println("[AUTH] Usuario nao encontrado (dummy hash aplicado): " + normalizedIdentity);
            }

            // verificar() roda antes do cheque de user==null: o custo e pago mesmo sem conta.
            if (!SenhaHasher.verificar(senha, hashParaComparar) || user == null) {
                System.out.println("[AUTH] Senha incorreta para: " + normalizedIdentity);
                return null;
            }

            UsuarioAutenticado usuario = construirUsuarioAutenticado(user, normalizedIdentity);
            System.out.println("[AUTH] Login bem-sucedido: " + usuario.getIdentity()
                    + " (" + usuario.getProfile() + ")" + (usuario.isTwoFactorEnabled() ? " [2FA ativo]" : ""));

            Date agora = new Date();
            try {
                users.updateOne(
                        Filters.eq("_id", user.getObjectId("_id")),
                        Updates.combine(Updates.set("lastLogin", agora), Updates.set("lastLoginAt", agora))
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
            return null;
        }
    }

    /** Documento cru por id (inclusive inativos - uso admin); MongoException vira 503. */
    public Document buscarDocumentoPorId(String userId) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return null;
        try {
            return obterColecao("auth_users").find(Filters.eq("_id", new ObjectId(userId.trim()))).first();
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "buscarDocumentoPorId");
        } catch (Exception e) {
            return null;
        }
    }

    /** Documento cru por id filtrando active=true (caminhos que exigem conta ativa). */
    public Document buscarDocumentoAtivoPorId(String userId) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return null;
        try {
            return obterColecao("auth_users").find(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true))
            ).first();
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "buscarDocumentoAtivoPorId");
        } catch (Exception e) {
            return null;
        }
    }

    /** Identidade tipada por ObjectId (apenas conta ativa). */
    public UsuarioAutenticado buscarPorId(String userId) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return null;
        return buscarUsuarioPorFiltro(
                new Document("_id", new ObjectId(userId.trim())).append("active", true),
                userId.trim(), "buscarPorId", false);
    }

    /** Busca por identidade OU e-mail (campos normalizados, collation case-insensitive). */
    public UsuarioAutenticado buscarPorIdentidade(String identidade) {
        if (identidade == null || identidade.trim().isEmpty()) return null;
        String norm = identidade.trim().toLowerCase(Locale.ROOT);
        Document query = new Document("active", true).append("$or", Arrays.asList(
                new Document("normalizedIdentity", norm),
                new Document("email", norm),
                new Document("normalizedEmail", norm)
        ));
        return buscarUsuarioPorFiltro(query, norm, "buscarPorIdentidade", true);
    }

    /** Busca por e-mail (email/normalizedEmail, collation case-insensitive). */
    public UsuarioAutenticado buscarPorEmail(String email) {
        if (email == null || email.trim().isEmpty()) return null;
        String norm = email.trim().toLowerCase(Locale.ROOT);
        Document query = new Document("active", true).append("$or", Arrays.asList(
                new Document("email", norm),
                new Document("normalizedEmail", norm)
        ));
        return buscarUsuarioPorFiltro(query, norm, "buscarPorEmail", true);
    }

    /** Executor comum das buscas: aplica collation quando pedido e traduz falhas (503/null). */
    private UsuarioAutenticado buscarUsuarioPorFiltro(
            Document query, String fallbackIdentity, String contexto, boolean caseInsensitive) {
        try {
            FindIterable<Document> cursor = obterColecao("auth_users").find(query);
            if (caseInsensitive) {
                cursor = cursor.collation(CASE_INSENSITIVE);
            }
            return construirUsuarioAutenticado(cursor.first(), fallbackIdentity);
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, contexto);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro em " + contexto + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * Cadastro programatico (fluxos internos/testes; o painel admin usa inserirDocumento).
     * Valida identidade/perfil/politica de senha e duplicidade; conta nasce ativa,
     * sem 2FA e com sessionVersion=1. Lanca IllegalArgumentException/IllegalStateException
     * em vez de devolver null (chamador precisa distinguir o motivo).
     */
    public UsuarioAutenticado cadastrarUsuario(
            String identidade, String senha, String profile, String displayName, String email) {
        if (identidade == null || identidade.trim().isEmpty()) {
            throw new IllegalArgumentException("Identidade e obrigatoria.");
        }
        if (profile == null || profile.trim().isEmpty()) {
            throw new IllegalArgumentException("Perfil e obrigatorio.");
        }
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(senha);
        if (!validacao.isValido()) {
            throw new IllegalArgumentException(validacao.getMensagem());
        }

        String normalizedIdentity = identidade.trim().toLowerCase();
        String normalizedEmail = email != null ? email.trim().toLowerCase() : "";
        MongoCollection<Document> users = obterColecao("auth_users");

        if (users.find(new Document("normalizedIdentity", normalizedIdentity)).first() != null) {
            throw new IllegalStateException("Identidade ja cadastrada: " + identidade);
        }

        Document novo = new Document()
                .append("identity", identidade.trim())
                .append("normalizedIdentity", normalizedIdentity)
                .append("displayName", displayName != null ? displayName : "")
                .append("email", normalizedEmail)
                .append("normalizedEmail", normalizedEmail)
                .append("profile", profile.trim().toLowerCase())
                .append("passwordHash", SenhaHasher.hash(senha))
                .append("twoFactorEnabled", false)
                .append("twoFactorRequired", false)
                .append("twoFactorSecret", "")
                .append("active", true)
                .append("sessionVersion", 1)
                .append("createdAt", new Date())
                .append("updatedAt", new Date())
                .append("lastLogin", null)
                .append("lastLoginAt", null);

        users.insertOne(novo);
        String userId = novo.getObjectId("_id").toHexString();
        return new UsuarioAutenticado(
                userId, profile.trim().toLowerCase(), "", 1,
                normalizedIdentity, displayName != null ? displayName : "", normalizedEmail, false);
    }

    /**
     * Grava a nova senha (PBKDF2), limpa requirePasswordChange e INCREMENTA sessionVersion:
     * todos os tokens/sessoes antigos deixam de validar imediatamente (logout global).
     *
     * @return true se a conta existia e foi atualizada
     * @throws IllegalArgumentException se a nova senha violar a politica
     */
    public boolean atualizarSenha(String userId, String novaSenha) {
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(novaSenha);
        if (!validacao.isValido()) {
            throw new IllegalArgumentException(validacao.getMensagem());
        }
        try {
            Date agora = new Date();
            UpdateResult result = obterColecao("auth_users").updateOne(
                    Filters.eq("_id", new ObjectId(userId)),
                    Updates.combine(
                            Updates.set("passwordHash", SenhaHasher.hash(novaSenha)),
                            Updates.set("updatedAt", agora),
                            Updates.set("passwordUpdatedAt", agora),
                            Updates.set("requirePasswordChange", false),
                            Updates.inc("sessionVersion", 1)
                    )
            );
            return result.getMatchedCount() > 0;
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao atualizar senha: " + e.getMessage());
            return false;
        }
    }

    /** Conferencia da senha atual (step-up de troca de senha/2FA); erro = false. */
    public boolean verificarSenhaAtual(String userId, String senhaAtual) {
        try {
            Document user = obterColecao("auth_users").find(Filters.eq("_id", new ObjectId(userId))).first();
            if (user == null) return false;
            String hash = user.getString("passwordHash");
            return hash != null && !hash.isEmpty() && SenhaHasher.verificar(senhaAtual, hash);
        } catch (Exception e) {
            return false;
        }
    }

    /** $set dos campos de perfil (whitelist aplicada ANTES, no handler) + updatedAt; devolve o doc pos-update. */
    public Document atualizarPerfil(String userId, Map<String, Object> setFields) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return null;
        Document setDoc = BsonUtils.mapaParaDocumento(setFields);
        setDoc.append("updatedAt", new Date());
        return obterColecao("auth_users").findOneAndUpdate(
                Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true)),
                new Document("$set", setDoc),
                new FindOneAndUpdateOptions().returnDocument(ReturnDocument.AFTER)
        );
    }

    /** Liga/desliga 2FA nos dois campos legados e bumpa sessionVersion (politica vale apos novo login). */
    public boolean atualizarDoisFatores(String userId, boolean enabled) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return false;
        try {
            UpdateResult res = obterColecao("auth_users").updateOne(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true)),
                    Updates.combine(
                            Updates.set("twoFactorRequired", enabled),
                            Updates.set("twoFactorEnabled", enabled),
                            Updates.set("updatedAt", new Date()),
                            Updates.inc("sessionVersion", 1)
                    )
            );
            return res.getMatchedCount() > 0;
        } catch (Exception e) {
            return false;
        }
    }

    /** Substitui o array inteiro de digests: gerar novos codigos invalida todos os anteriores. */
    public boolean salvarCodigosBackup(String userId, List<String> digests) {
        if (userId == null || !ObjectId.isValid(userId.trim())) return false;
        try {
            UpdateResult res = obterColecao("auth_users").updateOne(
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
     * Consumo ATOMICO de backup code: o filtro exige o digest presente no array e o
     * update faz $pull na mesma operacao - duas chamadas concorrentes com o mesmo
     * codigo so conseguem consumir UMA vez. Codigo e normalizado (trim+uppercase).
     */
    public boolean consumirCodigoBackup(String userId, String codigo) {
        if (userId == null || !ObjectId.isValid(userId.trim()) || codigo == null || codigo.trim().isEmpty()) {
            return false;
        }
        String digest = OtpService.sha256Hex(codigo.trim().toUpperCase());
        try {
            Document updated = obterColecao("auth_users").findOneAndUpdate(
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

    // =========================================================================
    // CONSULTAS E MUTACOES ADMINISTRATIVAS
    // =========================================================================

    /**
     * Listagem admin com filtros combinaveis (perfil, active, busca textual em
     * nome/e-mail/identidade). Pattern.quote escapa a busca do usuario: entrada
     * virou literal, sem injecao de regex/ReDoS. Ordenacao estavel (displayName,_id)
     * para paginacao consistente.
     */
    public List<Document> listarUsuariosFiltrados(
            String profile, String activeParam, String search, int offset, int limit) {
        List<Bson> filtros = new ArrayList<Bson>();
        if (profile != null && !profile.isEmpty()) {
            filtros.add(Filters.eq("profile", profile));
        }
        if ("true".equalsIgnoreCase(activeParam)) {
            filtros.add(Filters.eq("active", Boolean.TRUE));
        } else if ("false".equalsIgnoreCase(activeParam)) {
            filtros.add(Filters.eq("active", Boolean.FALSE));
        }
        if (search != null && !search.trim().isEmpty()) {
            Pattern regex = Pattern.compile(Pattern.quote(search.trim()), Pattern.CASE_INSENSITIVE);
            filtros.add(Filters.or(
                    Filters.regex("displayName", regex),
                    Filters.regex("email", regex),
                    Filters.regex("identity", regex)
            ));
        }
        Bson filtroFinal = filtros.isEmpty() ? new Document() : Filters.and(filtros);
        List<Document> docs = new ArrayList<Document>();
        obterColecao("auth_users")
                .find(filtroFinal)
                .sort(Sorts.ascending("displayName", "_id"))
                .skip(offset)
                .limit(limit)
                .into(docs);
        return docs;
    }

    /**
     * Duplicidade cruzada identidade/e-mail nas duas direcoes (evita conta A usar o
     * e-mail da conta B como identidade e vice-versa); ignorarUserId exclui o proprio
     * usuario em edicoes. Collation case-insensitive.
     */
    public boolean existeDuplicidade(String normalizedIdentity, String normalizedEmail, String ignorarUserId) {
        Bson match = Filters.or(
                Filters.eq("normalizedIdentity", normalizedIdentity),
                Filters.eq("email", normalizedEmail),
                Filters.eq("email", normalizedIdentity),
                Filters.eq("normalizedIdentity", normalizedEmail)
        );
        Bson filtro = ignorarUserId != null
                ? Filters.and(Filters.ne("_id", new ObjectId(ignorarUserId)), match)
                : match;
        return obterColecao("auth_users").find(filtro).collation(CASE_INSENSITIVE).first() != null;
    }

    /** Existencia de e-mail (case-insensitive) - pre-check do provisionamento de docentes. */
    public boolean existeEmail(String normalizedEmail) {
        return obterColecao("auth_users")
                .find(Filters.eq("email", normalizedEmail))
                .collation(CASE_INSENSITIVE)
                .first() != null;
    }

    /** Insert cru do documento montado pelo handler; indice unico lanca MongoWriteException em colisao. */
    public void inserirDocumento(Document doc) {
        obterColecao("auth_users").insertOne(doc);
    }

    /** Aplica a lista de Updates em uma operacao atomica e devolve o documento pos-mudanca. */
    public Document atualizarCamposPorId(String userId, List<Bson> updates) {
        return obterColecao("auth_users").findOneAndUpdate(
                Filters.eq("_id", new ObjectId(userId)),
                Updates.combine(updates),
                new FindOneAndUpdateOptions().returnDocument(ReturnDocument.AFTER)
        );
    }

    /** sessionVersion+1 atomico; devolve matchedCount (0 = usuario nao encontrado). */
    public long incrementarSessionVersion(String userId) {
        return obterColecao("auth_users").updateOne(
                Filters.eq("_id", new ObjectId(userId)),
                Updates.inc("sessionVersion", 1)
        ).getMatchedCount();
    }

    /** Marcacao admin do reset: requirePasswordChange conforme flag; version+1 so se revogar sessoes. */
    public long atualizarResetSenhaAdmin(String userId, boolean forceNextLogin, boolean revokeActiveSessions) {
        List<Bson> updates = new ArrayList<Bson>();
        updates.add(Updates.set("requirePasswordChange", Boolean.valueOf(forceNextLogin)));
        updates.add(Updates.set("updatedAt", new Date()));
        if (revokeActiveSessions) {
            updates.add(Updates.inc("sessionVersion", 1));
        }
        return obterColecao("auth_users").updateOne(
                Filters.and(Filters.eq("_id", new ObjectId(userId)), Filters.eq("active", Boolean.TRUE)),
                Updates.combine(updates)
        ).getMatchedCount();
    }

    /** Total de admins ativos - guarda do "ultimo administrador" nas mutacoes admin. */
    public long contarAdminsAtivos() {
        return obterColecao("auth_users").countDocuments(
                Filters.and(Filters.eq("profile", "admin"), Filters.eq("active", Boolean.TRUE)));
    }

    /**
     * Mapper Document -> UsuarioAutenticado (compartilhado com RepositorioSessoes).
     * Resolve aliases legados (identity/normalizedIdentity, departmentOrCourse/department),
     * consolida os dois flags de 2FA e deixa sessionId vazio - quem preenche o jti
     * e a validacao de sessao, nao o documento da conta.
     */
    public static UsuarioAutenticado construirUsuarioAutenticado(Document user, String fallbackIdentity) {
        if (user == null) return null;
        String userId = user.getObjectId("_id").toHexString();
        String profile = user.getString("profile");
        String actualIdentity = primeiroNaoVazio(user.getString("identity"), user.getString("normalizedIdentity"), fallbackIdentity);
        String actualEmail = primeiroNaoVazio(user.getString("email"), user.getString("normalizedEmail"), "");
        String dept = primeiroNaoVazio(user.getString("departmentOrCourse"), user.getString("department"), "");
        boolean twoFa = user.getBoolean("twoFactorEnabled", false) || user.getBoolean("twoFactorRequired", false);
        Map<String, Object> preferences = BsonUtils.documentoParaMapa(user.get("preferences", Document.class));

        return new UsuarioAutenticado(
                userId, profile, "", user.getInteger("sessionVersion", 0),
                actualIdentity, naoNulo(user.getString("displayName")), actualEmail, twoFa,
                dept, naoNulo(user.getString("campus")), naoNulo(user.getString("semester")),
                naoNulo(user.getString("shift")), user.getBoolean("requirePasswordChange", false),
                naoNulo(user.getString("socialName")), naoNulo(user.getString("personalEmail")),
                naoNulo(user.getString("phone")), naoNulo(user.getString("biography")), preferences
        );
    }

    /** Primeiro valor nao vazio da cadeia de aliases; fallback final nunca null. */
    private static String primeiroNaoVazio(String a, String b, String fallback) {
        if (a != null && !a.isEmpty()) return a;
        if (b != null && !b.isEmpty()) return b;
        return fallback != null ? fallback : "";
    }

    /** null -> "" para manter o contrato do model (getters nunca null). */
    private static String naoNulo(String s) {
        return s != null ? s : "";
    }
}
