// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.persistencia;

import auth.model.UsuarioAutenticado;
import auth.modules.email.SmtpCliente;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import core.ConexaoMongo;
import org.bson.Document;
import org.bson.conversions.Bson;
import utils.BsonUtils;

import java.util.List;
import java.util.Map;

/**
 * Fachada unificada de persistencia do dominio Auth.
 * Compoe ConexaoMongo + os 4 repositorios especializados (Contas, Sessoes, OTPs e Auditoria),
 * mantendo construtor protegido para dubles de teste offline.
 */
public class RepositorioUsuarios {
    private static volatile RepositorioUsuarios INSTANCIA_COMPARTILHADA;

    private final ConexaoMongo conexao;
    private final RepositorioContas contas;
    private final RepositorioSessoes sessoes;
    private final RepositorioOtps otps;
    private final RepositorioAuditoria auditoria;

    public static final class ResultadoValidacaoSessao {
        public final boolean valida;
        public final int statusHttp;
        public final String codigo;
        public final String mensagem;
        public final UsuarioAutenticado usuario;

        private ResultadoValidacaoSessao(
                boolean valida, int statusHttp, String codigo, String mensagem, UsuarioAutenticado usuario) {
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

    public static RepositorioUsuarios getInstanciaSeInicializada() {
        return INSTANCIA_COMPARTILHADA;
    }

    public RepositorioUsuarios() {
        this(true);
    }

    /**
     * Construtor protegido para dubles de teste offline sem conexao real ao MongoDB.
     */
    protected RepositorioUsuarios(boolean conectar) {
        if (!conectar) {
            this.conexao = null;
            this.contas = null;
            this.sessoes = null;
            this.otps = null;
            this.auditoria = null;
            return;
        }
        this.conexao = ConexaoMongo.getInstance();
        this.contas = new RepositorioContas(this.conexao);
        this.sessoes = new RepositorioSessoes(this.conexao);
        this.otps = new RepositorioOtps(this.conexao);
        this.auditoria = new RepositorioAuditoria(this.conexao);
        if (INSTANCIA_COMPARTILHADA == null) {
            INSTANCIA_COMPARTILHADA = this;
        }
        inicializarIndicesAsync();
    }

    private void inicializarIndicesAsync() {
        contas.inicializarIndicesAsync("auth-contas-idx");
        sessoes.inicializarIndicesAsync("auth-sessoes-idx");
        otps.inicializarIndicesAsync("auth-otps-idx");
        auditoria.inicializarIndicesAsync("auth-auditoria-idx");
    }

    public ConexaoMongo getConexao() { return conexao; }
    public RepositorioContas getContas() { return contas; }
    public RepositorioSessoes getSessoes() { return sessoes; }
    public RepositorioOtps getOtps() { return otps; }
    public RepositorioAuditoria getAuditoria() { return auditoria; }

    public ConexaoMongo.EstadoSaudeBanco verificarSaudeBanco() {
        if (conexao == null) {
            return new ConexaoMongo.EstadoSaudeBanco(false, "database_unconfigured", "Repositorio offline.");
        }
        return conexao.verificarSaudeBanco();
    }

    public MongoDatabase getDatabase() { return conexao != null ? conexao.getDatabase() : null; }
    public MongoCollection<Document> getUsersCollection() { return contas != null ? contas.colecaoUsuariosSeAtiva() : null; }
    public MongoCollection<Document> getSessionsCollection() { return sessoes != null ? sessoes.colecaoSessoesSeAtiva() : null; }
    public MongoCollection<Document> getOtpCollection() { return otps != null ? otps.colecaoOtpsSeAtiva() : null; }
    public MongoCollection<Document> getAuditLogsCollection() { return auditoria != null ? auditoria.colecaoAuditoriaSeAtiva() : null; }
    public MongoCollection<Document> getLoginLimitsCollection() { return contas != null ? contas.colecaoLimitesSeAtiva() : null; }
    public MongoCollection<Document> getWriteGuardCollection() { return auditoria != null ? auditoria.colecaoWriteGuardSeAtiva() : null; }
    public MongoCollection<Document> getEmailOutboxCollection() { return auditoria != null ? auditoria.colecaoEmailOutboxSeAtiva() : null; }

    // Delegacoes para RepositorioContas
    public UsuarioAutenticado autenticar(String identidade, String senha) { return contas.autenticar(identidade, senha); }
    public Document buscarDocumentoPorId(String userId) { return contas.buscarDocumentoPorId(userId); }
    public Document buscarDocumentoAtivoPorId(String userId) { return contas.buscarDocumentoAtivoPorId(userId); }
    public UsuarioAutenticado buscarPorId(String userId) { return contas.buscarPorId(userId); }
    public UsuarioAutenticado buscarPorIdentidade(String identidade) { return contas.buscarPorIdentidade(identidade); }
    public UsuarioAutenticado buscarPorEmail(String email) { return contas.buscarPorEmail(email); }
    public UsuarioAutenticado cadastrarUsuario(String id, String senha, String profile, String nome, String email) {
        return contas.cadastrarUsuario(id, senha, profile, nome, email);
    }
    public boolean atualizarSenha(String userId, String novaSenha) { return contas.atualizarSenha(userId, novaSenha); }
    public boolean verificarSenhaAtual(String userId, String senhaAtual) { return contas.verificarSenhaAtual(userId, senhaAtual); }
    public String getDummyHash() { return contas != null ? contas.getDummyHash() : auth.utils.SenhaHasher.hashDummy(); }
    public Document atualizarPerfil(String userId, Map<String, Object> setFields) { return contas.atualizarPerfil(userId, setFields); }
    public boolean atualizarDoisFatores(String userId, boolean enabled) {
        boolean ok = contas.atualizarDoisFatores(userId, enabled);
        if (ok) revogarTodasSessoes(userId.trim());
        return ok;
    }
    public boolean salvarCodigosBackup(String userId, List<String> digests) { return contas.salvarCodigosBackup(userId, digests); }
    public boolean consumirCodigoBackup(String userId, String codigo) { return contas.consumirCodigoBackup(userId, codigo); }
    public List<Document> listarUsuariosFiltrados(String p, String a, String s, int o, int l) { return contas.listarUsuariosFiltrados(p, a, s, o, l); }
    public boolean existeDuplicidade(String normId, String normEmail, String ignoreId) { return contas.existeDuplicidade(normId, normEmail, ignoreId); }
    public boolean existeEmail(String normEmail) { return contas.existeEmail(normEmail); }
    public void inserirDocumentoUsuario(Document doc) { contas.inserirDocumento(doc); }
    public Document atualizarCamposUsuario(String userId, List<Bson> updates) { return contas.atualizarCamposPorId(userId, updates); }
    public long incrementarSessionVersion(String userId) { return contas.incrementarSessionVersion(userId); }
    public long atualizarResetSenhaAdmin(String userId, boolean forceNext, boolean revoke) { return contas.atualizarResetSenhaAdmin(userId, forceNext, revoke); }
    public long contarAdminsAtivos() { return contas.contarAdminsAtivos(); }

    // Delegacoes para RepositorioSessoes
    public void criarSessao(String userId, String sessionId, long expiresAtMillis) { criarSessao(userId, sessionId, expiresAtMillis, null, null); }
    public void criarSessao(String userId, String sessionId, long expiresAtMillis, String ua, String ip) { sessoes.criarSessao(userId, sessionId, expiresAtMillis, ua, ip); }
    public boolean sessaoAtiva(String sessionId) { return sessoes.sessaoAtiva(sessionId); }
    public ResultadoValidacaoSessao validarSessaoCompleta(String uid, String sid, int ver, String prof, boolean allowPwd) {
        return sessoes.validarSessaoCompleta(uid, sid, ver, prof, allowPwd);
    }
    public List<Document> listarSessoesAtivas(String userId) { return sessoes.listarSessoesAtivas(userId); }
    public Map<String, Integer> contarSessoesAtivasPorUsuario(List<Document> users) { return sessoes.contarSessoesAtivasPorUsuario(users); }
    public void revogarSessaoUsuario(String userId, String sessionId) { sessoes.revogarSessaoUsuario(userId, sessionId); }
    public void revogarOutrasSessoes(String userId, String currentSessionId) { sessoes.revogarOutrasSessoes(userId, currentSessionId); }
    public void revogarSessao(String sessionId) { sessoes.revogarSessao(sessionId); }
    public void revogarTodasSessoes(String userId) { sessoes.revogarTodasSessoes(userId); }

    // Delegacoes para RepositorioOtps
    public void salvarOtp(String identity, String otpHash, String tipo, long expiresAtMillis) { otps.salvarOtp(identity, otpHash, tipo, expiresAtMillis); }
    public Document buscarOtp(String identity, String tipo) { return otps.buscarOtp(identity, tipo); }
    public void incrementarTentativasOtp(String identity, String tipo) { otps.incrementarTentativasOtp(identity, tipo); }
    public void removerOtp(String identity, String tipo) { otps.removerOtp(identity, tipo); }
    public void emitirGrantRecuperacao(String normId, String jtiHash, long exp) { otps.emitirGrantRecuperacao(normId, jtiHash, exp); }
    public boolean consumirGrantRecuperacao(String jtiHash) { return otps.consumirGrantRecuperacao(jtiHash); }

    // Delegacoes para RepositorioAuditoria
    public void registrarAuditoria(String actorId, String action, String target, Map<String, Object> details, String ip) {
        auditoria.registrarAuditoria(actorId, action, target, details, ip);
    }
    public void registrarAuditoria(String actorId, String action, String target, Map<String, Object> details) {
        registrarAuditoria(actorId, action, target, details, null);
    }
    public void registrarResultadoEnvioEmail(String actor, String ev, String dest, SmtpCliente.ResultadoEnvioEmail res, Throwable err) {
        auditoria.registrarResultadoEnvioEmail(actor, ev, dest, res, err);
    }
    public List<Document> listarLogsSeguranca(String userId, int limit) { return auditoria.listarLogsSeguranca(userId, limit); }
    public boolean registrarEscritaAdmin(String adminId) { return auditoria.registrarEscritaAdmin(adminId); }

    public static Map<String, Object> documentoParaMapa(Object obj) { return BsonUtils.documentoParaMapa(obj); }
    public static Document mapaParaDocumento(Map<String, Object> mapa) { return BsonUtils.mapaParaDocumento(mapa); }

    public void fechar() {
        // No-op: pool compartilhado permanece ativo entre requisicoes HTTP
    }

    public void encerrarDefinitivo() {
        if (conexao != null) {
            conexao.encerrarDefinitivo();
        }
    }
}
