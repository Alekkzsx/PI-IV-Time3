// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
package auth.modules.persistencia;

import auth.model.UsuarioAutenticado;
import com.mongodb.MongoException;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Sorts;
import core.ConexaoMongo;
import core.abstratas.RepositorioMongoAbstrato;
import org.bson.Document;
import org.bson.types.ObjectId;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Repositorio especializado na colecao auth_sessions (ciclo de vida e validacao autoritativa de sessoes).
 */
public class RepositorioSessoes extends RepositorioMongoAbstrato {

    public RepositorioSessoes(ConexaoMongo conexao) {
        super(conexao);
    }

    @Override
    protected String tagLog() {
        return "AUTH-SESSOES";
    }

    /** Indices: sessionId unico (um registro por jti), userId para listagens e TTL em expiresAt. */
    @Override
    protected void registrarIndices(MongoDatabase db) {
        MongoCollection<Document> sessions = db.getCollection("auth_sessions");
        criarIndiceSeguro(sessions, "idx_auth_sessions_sessionid_unique",
                new Document("sessionId", 1), new IndexOptions().unique(true));
        criarIndiceSeguro(sessions, "idx_auth_sessions_userid", new Document("userId", 1), null);
        // expireAfter(0): o Mongo apaga o documento exatamente no instante expiresAt.
        criarIndiceSeguro(sessions, "idx_auth_sessions_expiresat",
                new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
    }

    /** @return colecao auth_sessions ou null se o banco estiver offline. */
    public MongoCollection<Document> colecaoSessoesSeAtiva() {
        return obterColecaoSeAtiva("auth_sessions");
    }

    /**
     * Registra a sessao do access token (jti) com metadados de dispositivo.
     * Best-effort: falha e so logada - sem o registro, a proxima requisicao falha
     * fail-closed na validacao autoritativa (nao ha como "logar sem sessao").
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
            obterColecao("auth_sessions").insertOne(sessao);
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao criar sessao: " + e.getMessage());
        }
    }

    /** Checagem simples de existencia: ativa (active != false) e nao expirada; erro = false (fail-closed). */
    public boolean sessaoAtiva(String sessionId) {
        if (sessionId == null || sessionId.trim().isEmpty()) return false;
        try {
            Document sessao = obterColecao("auth_sessions").find(
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
     * Validacao AUTORITATIVA da sessao (camada 2 do JwtAuthValidator), na ordem:
     * 1. ObjectId valido e jti presente;
     * 2. usuario ativo + sessao ativa/no prazo (mesma conta);
     * 3. sessionVersion e perfil do token iguais aos do banco;
     * 4. requirePasswordChange bloqueia tudo exceto a rota de troca (403).
     * Sucesso devolve a identidade FRESCA do banco (nao o snapshot do token).
     * MongoException vira 503 (failover); erro inesperado vira 401 (fail-closed).
     */
    public RepositorioUsuarios.ResultadoValidacaoSessao validarSessaoCompleta(
            String userId,
            String sessionId,
            int tokenVersion,
            String tokenProfile,
            boolean permitirTrocaSenhaPendente) {
        if (userId == null || !ObjectId.isValid(userId.trim())) {
            return RepositorioUsuarios.ResultadoValidacaoSessao.erro(
                    401, "invalid_token", "Identificador de usuario invalido.");
        }
        if (sessionId == null || sessionId.trim().isEmpty()) {
            return RepositorioUsuarios.ResultadoValidacaoSessao.erro(
                    401, "session_revoked", "Sessao ausente. Realize login novamente.");
        }
        MongoDatabase db = garantirBancoAtivo();
        try {
            Document userDoc = db.getCollection("auth_users").find(
                    Filters.and(Filters.eq("_id", new ObjectId(userId.trim())), Filters.eq("active", true))
            ).first();
            Document sessionDoc = db.getCollection("auth_sessions").find(
                    Filters.and(
                            Filters.eq("sessionId", sessionId.trim()),
                            Filters.eq("userId", userId.trim()),
                            Filters.ne("active", false),
                            Filters.gt("expiresAt", new Date())
                    )
            ).first();

            if (userDoc == null || sessionDoc == null) {
                return RepositorioUsuarios.ResultadoValidacaoSessao.erro(
                        401, "session_revoked", "Sessao encerrada. Entre novamente.");
            }
            int dbVersion = userDoc.getInteger("sessionVersion", 0);
            String dbProfile = userDoc.getString("profile");
            if (dbVersion != tokenVersion || dbProfile == null || !dbProfile.equalsIgnoreCase(tokenProfile)) {
                return RepositorioUsuarios.ResultadoValidacaoSessao.erro(
                        401, "session_revoked", "Sessao encerrada. Entre novamente.");
            }
            boolean requirePwdChange = userDoc.getBoolean("requirePasswordChange", false);
            if (requirePwdChange && !permitirTrocaSenhaPendente) {
                return RepositorioUsuarios.ResultadoValidacaoSessao.erro(
                        403, "password_change_required", "Altere sua senha para continuar.");
            }

            UsuarioAutenticado base = RepositorioContas.construirUsuarioAutenticado(userDoc, userId);
            UsuarioAutenticado completo = new UsuarioAutenticado(
                    base.getUserId(), base.getProfile(), sessionId.trim(), dbVersion,
                    base.getIdentity(), base.getDisplayName(), base.getEmail(), base.isTwoFactorEnabled(),
                    base.getDepartmentOrCourse(), base.getCampus(), base.getSemester(), base.getShift(),
                    requirePwdChange, base.getSocialName(), base.getPersonalEmail(),
                    base.getPhone(), base.getBiography(), base.getPreferences()
            );
            return RepositorioUsuarios.ResultadoValidacaoSessao.ok(completo);
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "validarSessaoCompleta");
        } catch (Exception e) {
            return RepositorioUsuarios.ResultadoValidacaoSessao.erro(
                    401, "session_revoked", "Nao foi possivel validar a sessao.");
        }
    }

    /** Sessoes ativas do usuario, mais recentes primeiro (tela "dispositivos conectados"). */
    public List<Document> listarSessoesAtivas(String userId) {
        List<Document> lista = new ArrayList<Document>();
        try {
            obterColecao("auth_sessions").find(
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

    /** Contagem em lote para a listagem admin: UMA query com $in + agregacao em memoria (evita N+1). */
    public Map<String, Integer> contarSessoesAtivasPorUsuario(List<Document> users) {
        Map<String, Integer> counts = new HashMap<String, Integer>();
        if (users == null || users.isEmpty()) {
            return counts;
        }
        List<String> ids = new ArrayList<String>(users.size());
        for (Document u : users) {
            ids.add(u.getObjectId("_id").toHexString());
        }
        List<Document> activeSessions = new ArrayList<Document>();
        obterColecao("auth_sessions").find(
                Filters.and(
                        Filters.in("userId", ids),
                        Filters.ne("active", false),
                        Filters.gt("expiresAt", new Date())
                )
        ).into(activeSessions);

        for (Document s : activeSessions) {
            String uid = s.getString("userId");
            if (uid != null) {
                Integer current = counts.get(uid);
                counts.put(uid, Integer.valueOf((current != null ? current.intValue() : 0) + 1));
            }
        }
        return counts;
    }

    /** Revogacao escopada ao dono: filtro userId impede revogar sessao de outra conta. */
    public void revogarSessaoUsuario(String userId, String sessionId) {
        try {
            obterColecao("auth_sessions").deleteOne(
                    Filters.and(Filters.eq("sessionId", sessionId), Filters.eq("userId", userId)));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar sessao do usuario: " + e.getMessage());
        }
    }

    /** "Sair dos outros dispositivos": apaga todas as sessoes exceto a atual. */
    public void revogarOutrasSessoes(String userId, String currentSessionId) {
        try {
            obterColecao("auth_sessions").deleteMany(
                    Filters.and(Filters.eq("userId", userId), Filters.ne("sessionId", currentSessionId)));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar outras sessoes: " + e.getMessage());
        }
    }

    /** Revogar = DELETAR o registro (sem soft-flag): a ausencia ja reprova na validacao. */
    public void revogarSessao(String sessionId) {
        try {
            obterColecao("auth_sessions").deleteOne(Filters.eq("sessionId", sessionId));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar sessao: " + e.getMessage());
        }
    }

    /** Logout global persistido (troca de senha, suspensao, acao admin). */
    public void revogarTodasSessoes(String userId) {
        try {
            obterColecao("auth_sessions").deleteMany(Filters.eq("userId", userId));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao revogar todas as sessoes: " + e.getMessage());
        }
    }
}
