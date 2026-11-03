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
 * Endpoint nativo de inspecao e validacao de sessao autenticada no servidor Java.
 * Rota: GET /api/auth/session
 */
public class AuthSessionHandler implements ManipuladorHttp {

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        if (!"GET".equalsIgnoreCase(requisicao.getMetodo()) && !"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Utilize GET ou POST para verificar sessao.\"}");
            return;
        }

        try {
            UsuarioAutenticado usuario = JwtAuthValidator.autenticarObrigatorio(requisicao);
            Map<String, Object> payload = new LinkedHashMap<String, Object>();
            payload.put("status", 200);
            payload.put("authenticated", Boolean.TRUE);
            payload.put("userId", usuario.getUserId());
            payload.put("profile", usuario.getProfile());
            if (!usuario.getSessionId().isEmpty()) {
                payload.put("sessionId", usuario.getSessionId());
            }
            if (!usuario.getIdentity().isEmpty()) {
                payload.put("identity", usuario.getIdentity());
            }
            if (!usuario.getDisplayName().isEmpty()) {
                payload.put("displayName", usuario.getDisplayName());
            }
            resposta.enviarJson(200, Json.escrever(payload));
        } catch (SecurityException e) {
            Map<String, Object> erro = new LinkedHashMap<String, Object>();
            erro.put("status", 401);
            erro.put("authenticated", Boolean.FALSE);
            erro.put("erro", e.getMessage());
            resposta.enviarJson(401, Json.escrever(erro));
        }
    }
}

