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

    /** @param repositorio repositorio de identidades; null cai no singleton (conveniencia de testes). */
    protected HandlerAuthPublicoAbstrato(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    /** Fluxos de credenciais so aceitam POST (credenciais nunca viajam em query string). */
    @Override
    protected String metodoPermitido() {
        return "POST";
    }

    /**
     * Emite novo par de tokens (access + refresh), registra a sessao no MongoDB
     * e monta o payload JSON padronizado de autenticacao concluida.
     *
     * A sessao e indexada pelo jti do ACCESS token: e ele que JwtAuthValidator consulta
     * a cada requisicao; revogar a sessao invalida o token mesmo antes do exp.
     *
     * @param sessionVersion        versao atual da sessao do usuario (muda na troca de senha)
     * @param ipCliente             IP para auditoria da sessao
     * @param incluirCamposAcademicos inclui curso/campus/semestre/turno no payload do usuario
     * @param incluirSuccess        adiciona "success": true (compatibilidade com clientes antigos)
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
        // Aliases duplicados (token/accessToken e user/usuario): compatibilidade entre
        // versoes do frontend Flutter e consumidores legados da API.
        resposta.put("accessToken", parTokens.getAccessToken());
        resposta.put("token", parTokens.getAccessToken());
        resposta.put("refreshToken", parTokens.getRefreshToken());
        resposta.put("usuario", payloadUsuario);
        resposta.put("user", payloadUsuario);
        return resposta;
    }
}
