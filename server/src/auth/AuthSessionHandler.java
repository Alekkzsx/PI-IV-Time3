// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.Json;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint nativo de inspecao e validacao de sessao autenticada no servidor Java.
 * Rotas suportadas:
 * - GET /api/auth/session
 * - GET /api/auth/me
 */
public class AuthSessionHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public AuthSessionHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public AuthSessionHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"GET".equalsIgnoreCase(requisicao.getMetodo()) && !"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"code\":\"method_not_allowed\",\"message\":\"Utilize GET ou POST para verificar sessao.\",\"erro\":\"Utilize GET ou POST para verificar sessao.\"}");
            return;
        }

        try {
            // /api/auth/me e /api/auth/session sao permitidos mesmo com requirePasswordChange=true para acionar troca obrigatoria na UI.
            UsuarioAutenticado u = JwtAuthValidator.autenticarObrigatorio(requisicao, this.repositorio, true);
            Document doc = this.repositorio.buscarDocumentoAtivoPorId(u.getUserId());

            Map<String, Object> payload = montarPerfilPublico(u, doc);
            payload.put("status", 200);
            payload.put("authenticated", Boolean.TRUE);
            if (!u.getSessionId().isEmpty()) {
                payload.put("sessionId", u.getSessionId());
            }

            resposta.enviarJson(200, Json.escrever(payload));
        } catch (DatabaseUnavailableException e) {
            enviarErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (JwtAuthValidator.HttpSecurityException e) {
            enviarErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (SecurityException e) {
            enviarErro(resposta, 401, "unauthorized", e.getMessage());
        }
    }

    public static Map<String, Object> montarPerfilPublico(UsuarioAutenticado u, Document doc) {
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("id", u.getUserId());
        payload.put("userId", u.getUserId());
        payload.put("identity", u.getIdentity());
        payload.put("displayName", u.getDisplayName());
        payload.put("socialName", u.getSocialName());
        payload.put("email", u.getEmail());
        payload.put("personalEmail", u.getPersonalEmail());
        payload.put("phone", u.getPhone());
        payload.put("biography", u.getBiography());
        payload.put("profile", u.getProfile());
        payload.put("departmentOrCourse", u.getDepartmentOrCourse());
        payload.put("department", u.getDepartmentOrCourse());
        payload.put("campus", !u.getCampus().isEmpty() ? u.getCampus() : "Campus Central");
        payload.put("semester", !u.getSemester().isEmpty() ? u.getSemester() : "2026/2");
        payload.put("shift", u.getShift());
        payload.put("requirePasswordChange", Boolean.valueOf(u.isRequirePasswordChange()));
        payload.put("twoFactorRequired", Boolean.valueOf(u.isTwoFactorEnabled()));
        payload.put("twoFactorEnabled", Boolean.valueOf(u.isTwoFactorEnabled()));
        payload.put("preferences", u.getPreferences() != null ? u.getPreferences() : new LinkedHashMap<String, Object>());
        payload.put("lastLogin", doc != null ? (doc.getDate("lastLogin") != null ? doc.getDate("lastLogin") : doc.getDate("lastLoginAt")) : null);
        return payload;
    }

    private static void enviarErro(RespostaHttp resposta, int status, String code, String message) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("authenticated", Boolean.FALSE);
        erro.put("code", code);
        erro.put("message", message);
        erro.put("erro", message);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}

