// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.login;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.JwtAuthValidator;
import auth.utils.JwtGerador;
import auth.utils.RevogacaoTokens;
import core.RequisicaoHttp;
import core.RespostaHttp;
import core.abstratas.HandlerHttpAbstrato;
import utils.ConfigEnv;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint de logout institucional (blacklist de JTI + revogacao da sessao persistida).
 * Rota: POST /api/auth/logout
 */
public class LogoutHandler extends HandlerHttpAbstrato {
    private final RepositorioUsuarios repositorio;

    public LogoutHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public LogoutHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    protected String metodoPermitido() {
        return "POST";
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST para logout.";
    }

    @Override
    protected String tagLog() {
        return "LOGOUT";
    }

    /**
     * Logout em duas camadas: blacklist em memoria (efeito imediato) + revogacao da
     * sessao no Mongo (duravel, sobrevive a restart). Mesmo token INVALIDO/expirado e
     * colocado na blacklist por defesa em profundidade. O refresh token opcional do
     * body tambem e revogado para impedir renovacao pos-logout.
     */
    @Override
    protected void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        String accessToken = JwtAuthValidator.extrairBearerToken(requisicao);
        if (accessToken == null) {
            responderErro(resposta, 401, "unauthorized", "Token de autenticacao necessario.");
            return;
        }
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null || segredo.length() < 16) {
            responderErro(resposta, 500, "jwt_config_error", "Segredo JWT nao configurado.");
            return;
        }

        UsuarioAutenticado usuario;
        try {
            usuario = JwtAuthValidator.validarToken(accessToken, segredo, null);
        } catch (SecurityException e) {
            // Token ja invalido: ainda assim registra o jti na blacklist (barato e defensivo).
            revogarTokenNaBlacklist(accessToken);
            responderErro(resposta, 401, "unauthorized", e.getMessage());
            return;
        }

        String jtiAccess = revogarTokenNaBlacklist(accessToken);
        if (jtiAccess != null) {
            try {
                // Revogacao duravel: derruba a sessao no Mongo; falha aqui nao desfaz a blacklist.
                repositorio.revogarSessao(jtiAccess);
                repositorio.registrarAuditoria(usuario.getUserId(), "logout", usuario.getUserId(), null);
            } catch (Exception e) {
                System.err.println("[LOGOUT] Erro ao revogar sessao no MongoDB: " + e.getMessage());
            }
        }

        revogarRefreshOpcional(requisicao);

        System.out.println("[LOGOUT] Logout realizado para usuario: " + usuario.getUserId());
        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", Integer.valueOf(200));
        resp.put("message", "Logout realizado com sucesso.");
        enviarJson(resposta, 200, resp);
    }

    /** Extrai jti/exp do token e registra na blacklist; devolve o jti para revogar a sessao. */
    private String revogarTokenNaBlacklist(String token) {
        String jti = JwtGerador.extrairJti(token);
        long expira = JwtGerador.extrairExpiracaoMillis(token);
        if (jti != null && expira > 0) {
            RevogacaoTokens.getInstance().revogar(jti, expira);
        }
        return jti;
    }

    /** Best-effort: se o cliente mandou refreshToken no body, revoga tambem (body invalido e ignorado). */
    private void revogarRefreshOpcional(RequisicaoHttp requisicao) {
        try {
            Map<String, Object> body = lerJsonObjetoOpcional(requisicao);
            String refreshToken = getString(body, "refreshToken");
            if (refreshToken != null && !refreshToken.isEmpty()) {
                revogarTokenNaBlacklist(refreshToken);
            }
        } catch (Exception e) {
            System.err.println("[LOGOUT] Body invalido, ignorando: " + e.getMessage());
        }
    }
}
