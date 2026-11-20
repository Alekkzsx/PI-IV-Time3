// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.abstratas;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import auth.utils.JwtGerador;
import core.RequisicaoHttp;
import core.abstratas.HandlerHttpAbstrato;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Classe abstrata para fluxos publicos de credenciais (login, 2FA, refresh e recuperacao).
 * Centraliza a emissao de par de tokens + persistencia de sessao + payload padronizado,
 * evitando duplicacao entre LoginHandler, TwoFactorHandler, RefreshTokenHandler e RecoveryHandler.
 */
public abstract class HandlerAuthPublicoAbstrato extends HandlerHttpAbstrato {
    protected final RepositorioUsuarios repositorio;

    protected HandlerAuthPublicoAbstrato(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    protected String metodoPermitido() {
        return "POST";
    }

    /**
     * Emite novo par de tokens (access + refresh), registra a sessao no MongoDB
     * e monta o payload JSON padronizado de autenticacao concluida.
     */
    protected Map<String, Object> emitirSessaoEPayloadTokens(
            RequisicaoHttp requisicao,
            UsuarioAutenticado usuario,
            int sessionVersion,
            String ipCliente,
            boolean incluirCamposAcademicos,
            boolean incluirSuccess) {
        JwtGerador.ParTokens parTokens = JwtGerador.gerarParTokens(usuario, sessionVersion);
        String jtiAccess = JwtGerador.extrairJti(parTokens.getAccessToken());
        long expiraAccessMillis = JwtGerador.extrairExpiracaoMillis(parTokens.getAccessToken());
        String userAgent = requisicao.getCabecalho("user-agent");
        if (jtiAccess != null) {
            this.repositorio.criarSessao(usuario.getUserId(), jtiAccess, expiraAccessMillis, userAgent, ipCliente);
        }

        Map<String, Object> payloadUsuario = AuthHttpUtils.montarPayloadUsuario(usuario, incluirCamposAcademicos);
        Map<String, Object> resposta = new LinkedHashMap<String, Object>();
        resposta.put("status", Integer.valueOf(200));
        if (incluirSuccess) {
            resposta.put("success", Boolean.TRUE);
        }
        resposta.put("accessToken", parTokens.getAccessToken());
        resposta.put("token", parTokens.getAccessToken());
        resposta.put("refreshToken", parTokens.getRefreshToken());
        resposta.put("usuario", payloadUsuario);
        resposta.put("user", payloadUsuario);
        return resposta;
    }
}
