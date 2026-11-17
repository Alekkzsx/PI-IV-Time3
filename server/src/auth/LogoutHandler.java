// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.Json;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint de logout institucional.
 * Rota: POST /api/auth/logout
 *
 * Revoga o token access atual adicionando seu JTI a blacklist (RevogacaoTokens).
 * Opcionalmente revoga tambem o refresh token se fornecido no body.
 *
 * Body: { "refreshToken": "string" (opcional) }
 * Header: Authorization: Bearer <access_token>
 *
 * Response 200: { "status": 200, "message": "Logout realizado com sucesso." }
 * Response 401: { "erro": "..." }
 */
public class LogoutHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public LogoutHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public LogoutHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            enviarErro(resposta, 405, "Utilize POST para logout.");
            return;
        }

        try {
            // Extrair e validar o access token do header
            String accessToken = JwtAuthValidator.extrairBearerToken(requisicao);
            if (accessToken == null) {
                enviarErro(resposta, 401, "Token de autenticacao necessario.");
                return;
            }

            String segredo = utils.ConfigEnv.obter("AUTH_JWT_SECRET", null);
            if (segredo == null || segredo.length() < 16) {
                enviarErro(resposta, 500, "Segredo JWT nao configurado.");
                return;
            }

            // Validar o access token (verifica assinatura, expiracao e blacklist)
            UsuarioAutenticado usuario;
            try {
                usuario = JwtAuthValidator.validarToken(accessToken, segredo, null);
            } catch (SecurityException e) {
                // Mesmo token invalido, tentar extrair JTI para revogar (token expirado mas ainda na blacklist)
                String jti = JwtGerador.extrairJti(accessToken);
                long expiraMillis = JwtGerador.extrairExpiracaoMillis(accessToken);
                if (jti != null && expiraMillis > 0) {
                    RevogacaoTokens.getInstance().revogar(jti, expiraMillis);
                }
                enviarErro(resposta, 401, e.getMessage());
                return;
            }

            // Adicionar JTI do access token a blacklist
            String jtiAccess = JwtGerador.extrairJti(accessToken);
            long expiraAccessMillis = JwtGerador.extrairExpiracaoMillis(accessToken);
            if (jtiAccess != null) {
                RevogacaoTokens.getInstance().revogar(jtiAccess, expiraAccessMillis);
            }

            // Revogar sessao persistida no MongoDB e auditar
            if (jtiAccess != null) {
                try {
                    repositorio.revogarSessao(jtiAccess);
                    repositorio.registrarAuditoria(usuario.getUserId(), "logout", usuario.getUserId(), null);
                } catch (Exception e) {
                    System.err.println("[LOGOUT] Erro ao revogar sessao no MongoDB: " + e.getMessage());
                }
            }

            // Verificar se refresh token foi enviado no body para revogar tambem
            try {
                String corpo = requisicao.getCorpo();
                if (corpo != null && !corpo.trim().isEmpty()) {
                    Map<String, Object> body = Json.analisarObjeto(corpo);
                    Object refreshTokenObj = body.get("refreshToken");
                    if (refreshTokenObj instanceof String) {
                        String refreshToken = (String) refreshTokenObj;
                        String jtiRefresh = JwtGerador.extrairJti(refreshToken);
                        long expiraRefreshMillis = JwtGerador.extrairExpiracaoMillis(refreshToken);
                        if (jtiRefresh != null) {
                            RevogacaoTokens.getInstance().revogar(jtiRefresh, expiraRefreshMillis);
                        }
                    }
                }
            } catch (Exception e) {
                // Body invalido nao impede o logout do access token
                System.err.println("[LOGOUT] Body invalido, ignorando: " + e.getMessage());
            }

            System.out.println("[LOGOUT] Logout realizado para usuario: " + usuario.getUserId());

            Map<String, Object> resp = new LinkedHashMap<String, Object>();
            resp.put("status", 200);
            resp.put("message", "Logout realizado com sucesso.");
            resposta.enviarJson(200, Json.escrever(resp));

        } catch (DatabaseUnavailableException e) {
            HttpUtils.enviarErroJson(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (SecurityException e) {
            enviarErro(resposta, 401, e.getMessage());
        } catch (Exception e) {
            System.err.println("[LOGOUT] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "Erro interno no servidor.");
        }
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("code", status == 401 ? "unauthorized" : "invalid_request");
        erro.put("message", mensagem);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
