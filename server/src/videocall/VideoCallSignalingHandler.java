// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall;

import auth.JwtAuthValidator;
import auth.UsuarioAutenticado;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.JsonSimples;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Handler responsavel pelo ingresso, desistencia e sinalizacao WebRTC (SDP / ICE Candidates).
 * Endpoints: /api/videocall/join, /api/videocall/leave, /api/videocall/signal
 */
public class VideoCallSignalingHandler implements ManipuladorHttp {

    private final VideoCallService service = VideoCallService.getInstance();

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        UsuarioAutenticado usuario;
        try {
            usuario = JwtAuthValidator.autenticarOpcional(requisicao);
        } catch (SecurityException e) {
            resposta.enviarJson(401, "{\"status\":401,\"erro\":" + JsonSimples.escapar(e.getMessage()) + "}");
            return;
        }

        String caminho = requisicao.getCaminho();
        if ("/api/videocall/join".equalsIgnoreCase(caminho)) {
            tratarJoin(requisicao, resposta, usuario);
        } else if ("/api/videocall/leave".equalsIgnoreCase(caminho)) {
            tratarLeave(requisicao, resposta, usuario);
        } else {
            tratarSinalizacao(requisicao, resposta);
        }
    }

    private void tratarJoin(RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Use POST.\"}");
            return;
        }

        Map<String, String> params = HttpUtils.extrairParametros(requisicao);
        String roomCode = params.get("roomCode");
        String ra = params.get("ra");
        if ((ra == null || ra.trim().isEmpty()) && usuario != null) {
            ra = !usuario.getIdentity().isEmpty() ? usuario.getIdentity() : usuario.getUserId();
        }
        String name = params.get("name");
        if ((name == null || name.trim().isEmpty()) && usuario != null && !usuario.getDisplayName().isEmpty()) {
            name = usuario.getDisplayName();
        }
        String role = usuario != null ? usuario.getProfile() : params.get("role");

        if (roomCode == null || ra == null || roomCode.trim().isEmpty() || ra.trim().isEmpty()) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametros 'roomCode' e 'ra' sao obrigatorios.\"}");
            return;
        }

        boolean entrou = service.entrarNaSala(roomCode, ra, name, role);
        if (!entrou) {
            resposta.enviarJson(403, "{\"status\":403,\"erro\":\"A sala desta turma ainda nao foi aberta pelo docente responsavel. Aguarde a liberacao.\"}");
            return;
        }

        System.out.println("[VIDEOCALL] " + name + " (" + ra + " - " + role + ") entrou na sala " + roomCode);
        resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Conectado a sala com sucesso.\",\"roomCode\":"
                + JsonSimples.escapar(roomCode) + ",\"ra\":" + JsonSimples.escapar(ra) + "}");
    }

    private void tratarLeave(RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        Map<String, String> params = HttpUtils.extrairParametros(requisicao);
        String roomCode = params.get("roomCode");
        String ra = params.get("ra");
        if ((ra == null || ra.trim().isEmpty()) && usuario != null) {
            ra = !usuario.getIdentity().isEmpty() ? usuario.getIdentity() : usuario.getUserId();
        }

        if (roomCode != null && ra != null) {
            service.sairDaSala(roomCode, ra);
            System.out.println("[VIDEOCALL] " + ra + " desconectou da sala " + roomCode);
        }
        resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Desconectado da sala.\"}");
    }

    private void tratarSinalizacao(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> params = HttpUtils.extrairParametros(requisicao);
            String roomCode = params.get("roomCode");
            String fromRa = params.get("fromRa");
            String toRa = params.get("toRa");
            String type = params.get("type");
            String data = params.get("data");

            if (roomCode == null || fromRa == null || toRa == null || type == null) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametros incompletos para sinalizacao.\"}");
                return;
            }

            service.enviarSinalizacao(roomCode, fromRa, toRa, type, data != null ? data : "{}");
            resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Sinal despachado com sucesso.\"}");

        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> query = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
            String roomCode = query.get("roomCode");
            String ra = query.get("ra");

            if (roomCode == null || ra == null) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"roomCode e ra sao obrigatorios na query.\"}");
                return;
            }

            List<VideoCallService.SignalingMessage> mensagens = service.buscarSinalizacoes(roomCode, ra);
            StringBuilder json = new StringBuilder("{\"status\":200,\"signals\":[");
            boolean primeiro = true;

            for (VideoCallService.SignalingMessage m : mensagens) {
                if (!primeiro) json.append(",");
                primeiro = false;

                json.append("{")
                    .append("\"id\":").append(JsonSimples.escapar(m.id)).append(",")
                    .append("\"fromRa\":").append(JsonSimples.escapar(m.fromRa)).append(",")
                    .append("\"toRa\":").append(JsonSimples.escapar(m.toRa)).append(",")
                    .append("\"type\":").append(JsonSimples.escapar(m.type)).append(",")
                    .append("\"data\":").append(m.data.startsWith("{") ? m.data : JsonSimples.escapar(m.data)).append(",")
                    .append("\"timestamp\":").append(m.timestamp)
                    .append("}");
            }
            json.append("]}");
            resposta.enviarJson(200, json.toString());

        } else {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Metodo nao permitido.\"}");
        }
    }
}
