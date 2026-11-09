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
        this.repositorio = repositorio;
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"GET".equalsIgnoreCase(requisicao.getMetodo()) && !"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Utilize GET ou POST para verificar sessao.\"}");
            return;
        }

        try {
            UsuarioAutenticado usuario = JwtAuthValidator.autenticarObrigatorio(requisicao);

            // Buscar dados mais atualizados diretamente do MongoDB se disponivel
            UsuarioAutenticado usuarioFinal = null;
            if (repositorio != null && usuario.getUserId() != null && !usuario.getUserId().isEmpty()) {
                usuarioFinal = repositorio.buscarPorId(usuario.getUserId());
            }
            if (usuarioFinal == null && repositorio != null && usuario.getIdentity() != null && !usuario.getIdentity().isEmpty()) {
                usuarioFinal = repositorio.buscarPorIdentidade(usuario.getIdentity());
            }
            UsuarioAutenticado u = usuarioFinal != null ? usuarioFinal : usuario;

            Map<String, Object> payload = new LinkedHashMap<String, Object>();
            payload.put("status", 200);
            payload.put("authenticated", Boolean.TRUE);
            payload.put("id", u.getUserId());
            payload.put("userId", u.getUserId());
            payload.put("profile", u.getProfile());
            if (!u.getSessionId().isEmpty()) {
                payload.put("sessionId", u.getSessionId());
            }
            if (!u.getIdentity().isEmpty()) {
                payload.put("identity", u.getIdentity());
            }
            if (!u.getDisplayName().isEmpty()) {
                payload.put("displayName", u.getDisplayName());
            }
            if (!u.getEmail().isEmpty()) {
                payload.put("email", u.getEmail());
            }
            payload.put("departmentOrCourse", u.getDepartmentOrCourse());
            payload.put("department", u.getDepartmentOrCourse());
            payload.put("campus", !u.getCampus().isEmpty() ? u.getCampus() : "Campus Central");
            payload.put("semester", !u.getSemester().isEmpty() ? u.getSemester() : "2026/2");
            payload.put("shift", u.getShift());
            payload.put("twoFactorRequired", u.isTwoFactorEnabled());
            payload.put("requirePasswordChange", Boolean.FALSE);
            payload.put("preferences", new LinkedHashMap<String, Object>());

            resposta.enviarJson(200, Json.escrever(payload));
        } catch (SecurityException e) {
            Map<String, Object> erro = new LinkedHashMap<String, Object>();
            erro.put("status", 401);
            erro.put("authenticated", Boolean.FALSE);
            erro.put("erro", e.getMessage());
            erro.put("message", e.getMessage());
            resposta.enviarJson(401, Json.escrever(erro));
        }
    }
}

