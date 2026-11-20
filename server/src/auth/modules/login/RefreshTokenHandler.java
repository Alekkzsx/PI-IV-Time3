// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.login;

import auth.abstratas.HandlerAuthPublicoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.JwtAuthValidator;
import auth.utils.JwtGerador;
import auth.utils.RevogacaoTokens;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.ConfigEnv;

import java.util.Map;

/**
 * Endpoint de renovacao de tokens com rotacao automatica de refresh token.
 * Rota: POST /api/auth/refresh
 */
public class RefreshTokenHandler extends HandlerAuthPublicoAbstrato {

    public RefreshTokenHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public RefreshTokenHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST para renovar tokens.";
    }

    @Override
    protected String codigoErroSeguranca() {
        return "invalid_refresh_token";
    }

    @Override
    protected String tagLog() {
        return "REFRESH";
    }

    @Override
    protected void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        String refreshToken = extrairRefreshToken(requisicao);
        if (refreshToken == null || refreshToken.isEmpty()) {
            responderErro(resposta, 401, "invalid_refresh_token",
                    "Refresh token necessario. Envie no body como 'refreshToken' ou no header Authorization.");
            return;
        }

        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null || segredo.length() < 16) {
            responderErro(resposta, 500, "jwt_config_error", "Segredo JWT nao configurado.");
            return;
        }

        UsuarioAutenticado usuario = JwtAuthValidator.validarToken(refreshToken, segredo, "refresh");
        UsuarioAutenticado usuarioAtualizado = repositorio.buscarPorId(usuario.getUserId());
        if (usuarioAtualizado == null) {
            responderErro(resposta, 401, "invalid_refresh_token", "Usuario nao encontrado ou desativado.");
            return;
        }
        if (usuario.getSessionVersion() != usuarioAtualizado.getSessionVersion()) {
            responderErro(resposta, 401, "invalid_refresh_token",
                    "Sessao invalidada. Todas as sessoes foram revogadas. Realize login novamente.");
            return;
        }

        // Revoga refresh token antigo (rotacao)
        String jtiAntigo = JwtGerador.extrairJti(refreshToken);
        long expiraAntiga = JwtGerador.extrairExpiracaoMillis(refreshToken);
        if (jtiAntigo != null) {
            RevogacaoTokens.getInstance().revogar(jtiAntigo, expiraAntiga);
        }

        Map<String, Object> payload = emitirSessaoEPayloadTokens(
                requisicao,
                usuarioAtualizado,
                usuarioAtualizado.getSessionVersion(),
                requisicao.getCabecalho("x-forwarded-for"),
                false,
                false
        );
        enviarJson(resposta, 200, payload);
    }

    private String extrairRefreshToken(RequisicaoHttp requisicao) {
        try {
            Map<String, Object> body = lerJsonObjetoOpcional(requisicao);
            String token = getString(body, "refreshToken");
            if (token != null && !token.isEmpty()) {
                return token;
            }
        } catch (Exception ignored) { }
        return JwtAuthValidator.extrairBearerToken(requisicao);
    }
}
