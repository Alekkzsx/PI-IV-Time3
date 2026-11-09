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
 * Endpoint de renovacao de tokens (refresh).
 * Rota: POST /api/auth/refresh
 *
 * Recebe um refresh token valido e retorna um novo par de tokens (access + refresh).
 * O refresh token antigo e revogado (rotacao automatica para mitigar roubo de tokens).
 *
 * Body: { "refreshToken": "string" }
 * ou Header: Authorization: Bearer <refresh_token>
 *
 * Response 200: { "token": "...", "refreshToken": "...", "usuario": {...} }
 * Response 401: { "erro": "..." }
 */
public class RefreshTokenHandler implements ManipuladorHttp {

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            enviarErro(resposta, 405, "Utilize POST para renovar tokens.");
            return;
        }

        try {
            // Extrair refresh token do body ou header
            String refreshToken = null;

            // Tentar extrair do body JSON
            try {
                String corpo = requisicao.getCorpo();
                if (corpo != null && !corpo.trim().isEmpty()) {
                    Map<String, Object> body = Json.analisarObjeto(corpo);
                    Object tokenObj = body.get("refreshToken");
                    if (tokenObj instanceof String) {
                        refreshToken = ((String) tokenObj).trim();
                    }
                }
            } catch (Exception e) {
                // Fallback para header Bearer
            }

            // Fallback: header Authorization Bearer
            if (refreshToken == null || refreshToken.isEmpty()) {
                refreshToken = JwtAuthValidator.extrairBearerToken(requisicao);
            }

            if (refreshToken == null || refreshToken.isEmpty()) {
                enviarErro(resposta, 401, "Refresh token necessario. Envie no body como 'refreshToken' ou no header Authorization.");
                return;
            }

            String segredo = utils.ConfigEnv.obter("AUTH_JWT_SECRET", null);
            if (segredo == null || segredo.length() < 16) {
                enviarErro(resposta, 500, "Segredo JWT nao configurado.");
                return;
            }

            // Validar o refresh token (tipo deve ser "refresh")
            UsuarioAutenticado usuario = JwtAuthValidator.validarToken(refreshToken, segredo, "refresh");

            // Verificar versao da sessao contra o MongoDB
            RepositorioUsuarios repo = new RepositorioUsuarios();
            UsuarioAutenticado usuarioAtualizado = repo.buscarPorId(usuario.getUserId());
            if (usuarioAtualizado == null) {
                repo.fechar();
                enviarErro(resposta, 401, "Usuario nao encontrado ou desativado.");
                return;
            }

            // Verificar versao da sessao (ver)
            if (usuario.getSessionVersion() < usuarioAtualizado.getSessionVersion()) {
                repo.fechar();
                enviarErro(resposta, 401, "Sessao invalidada. Todas as sessoes foram revogadas. Realize login novamente.");
                return;
            }

            // Revogar o refresh token antigo (rotacao)
            String jtiAntigo = JwtGerador.extrairJti(refreshToken);
            long expiraAntiga = JwtGerador.extrairExpiracaoMillis(refreshToken);
            if (jtiAntigo != null) {
                RevogacaoTokens.getInstance().revogar(jtiAntigo, expiraAntiga);
            }

            // Gerar novo par de tokens
            int sessionVersion = usuarioAtualizado.getSessionVersion();
            JwtGerador.ParTokens novosTokens = JwtGerador.gerarParTokens(usuarioAtualizado, sessionVersion);

            // Persistir nova sessao
            String novoJti = JwtGerador.extrairJti(novosTokens.getAccessToken());
            long novaExpiracao = JwtGerador.extrairExpiracaoMillis(novosTokens.getAccessToken());
            if (novoJti != null) {
                repo.criarSessao(usuarioAtualizado.getUserId(), novoJti, novaExpiracao);
            }
            repo.fechar();

            // Construir resposta
            Map<String, Object> payloadUsuario = new LinkedHashMap<String, Object>();
            payloadUsuario.put("id", usuarioAtualizado.getUserId());
            payloadUsuario.put("identidade", usuarioAtualizado.getIdentity());
            payloadUsuario.put("perfil", usuarioAtualizado.getProfile());
            if (!usuarioAtualizado.getDisplayName().isEmpty()) {
                payloadUsuario.put("nome", usuarioAtualizado.getDisplayName());
            }
            if (!usuarioAtualizado.getEmail().isEmpty()) {
                payloadUsuario.put("email", usuarioAtualizado.getEmail());
            }

            Map<String, Object> resp = new LinkedHashMap<String, Object>();
            resp.put("status", 200);
            resp.put("token", novosTokens.getAccessToken());
            resp.put("refreshToken", novosTokens.getRefreshToken());
            resp.put("usuario", payloadUsuario);

            resposta.enviarJson(200, Json.escrever(resp));

        } catch (SecurityException e) {
            enviarErro(resposta, 401, e.getMessage());
        } catch (IllegalArgumentException e) {
            enviarErro(resposta, 400, "Corpo da requisicao invalido: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[REFRESH] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "Erro interno no servidor.");
        }
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
