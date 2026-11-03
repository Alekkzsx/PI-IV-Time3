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
import java.util.Map;

/**
 * Handler responsavel pelas interacoes em tempo real da videochamada (fila de mao levantada e chat).
 * Endpoints: /api/videocall/hand-raise, /api/videocall/chat
 */
public class VideoCallInteractionHandler implements ManipuladorHttp {

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
        if ("/api/videocall/hand-raise".equalsIgnoreCase(caminho)) {
            tratarMaoLevantada(requisicao, resposta);
        } else if ("/api/videocall/chat".equalsIgnoreCase(caminho)) {
            tratarChat(requisicao, resposta, usuario);
        } else {
            resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Endpoint de interacao desconhecido.\"}");
        }
    }

    private void tratarMaoLevantada(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> params = HttpUtils.extrairParametros(requisicao);
            String roomCode = params.get("roomCode");
            String ra = params.get("ra");
            String action = params.containsKey("action") ? params.get("action") : "toggle";

            if (roomCode == null || ra == null) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"roomCode e ra sao obrigatorios.\"}");
                return;
            }

            VideoCallService.Room r = service.obterOuCriarSala(roomCode);
            VideoCallService.Participant p = r.activeParticipants.get(ra);
            if (p == null) {
                resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Participante nao localizado na sala.\"}");
                return;
            }

            boolean novoEstado = "raise".equalsIgnoreCase(action) ? true
                    : ("lower".equalsIgnoreCase(action) ? false : !p.isHandRaised);

            service.alternarMaoLevantada(roomCode, ra, novoEstado);

            System.out.println("[VIDEOCALL] Mao levantada: " + p.name + " (" + ra + ") -> " + (novoEstado ? "LEVANTADA" : "ABAIXADA"));
            resposta.enviarJson(200, "{\"status\":200,\"isHandRaised\":" + novoEstado + ",\"queuePosition\":" + (r.handRaiseQueue.indexOf(ra) + 1) + "}");

        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> query = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
            String roomCode = query.get("roomCode");

            if (roomCode == null) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"roomCode e obrigatorio.\"}");
                return;
            }

            VideoCallService.Room r = service.obterOuCriarSala(roomCode);
            StringBuilder json = new StringBuilder("{\"status\":200,\"roomCode\":" + JsonSimples.escapar(roomCode) + ",\"queue\":[");
            boolean primeiro = true;

            for (String ra : r.handRaiseQueue) {
                VideoCallService.Participant p = r.activeParticipants.get(ra);
                if (p != null) {
                    if (!primeiro) json.append(",");
                    primeiro = false;
                    json.append("{")
                        .append("\"ra\":").append(JsonSimples.escapar(p.ra)).append(",")
                        .append("\"name\":").append(JsonSimples.escapar(p.name)).append(",")
                        .append("\"handRaisedAt\":").append(p.handRaisedAt)
                        .append("}");
                }
            }
            json.append("]}");
            resposta.enviarJson(200, json.toString());

        } else {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Metodo nao permitido.\"}");
        }
    }

    private void tratarChat(RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> params = HttpUtils.extrairParametros(requisicao);
            String roomCode = params.get("roomCode");
            String senderRa = params.get("senderRa");
            if ((senderRa == null || senderRa.trim().isEmpty()) && usuario != null) {
                senderRa = !usuario.getIdentity().isEmpty() ? usuario.getIdentity() : usuario.getUserId();
            }
            String senderName = params.get("senderName");
            String senderRole = usuario != null ? usuario.getProfile() : params.get("senderRole");
            String message = params.get("message");

            if (roomCode == null || senderRa == null || message == null || message.trim().isEmpty()) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Dados incompletos para envio de mensagem.\"}");
                return;
            }

            service.adicionarMensagemChat(
                    roomCode,
                    senderRa,
                    senderName != null ? senderName : senderRa,
                    senderRole != null ? senderRole : "aluno",
                    message.trim());
            resposta.enviarJson(201, "{\"status\":201,\"mensagem\":\"Mensagem enviada com sucesso.\"}");

        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> query = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
            String roomCode = query.get("roomCode");

            if (roomCode == null) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"roomCode e obrigatorio.\"}");
                return;
            }

            VideoCallService.Room r = service.obterOuCriarSala(roomCode);
            StringBuilder json = new StringBuilder("{\"status\":200,\"messages\":[");
            boolean primeiro = true;

            for (VideoCallService.ChatMessage msg : r.chatHistory) {
                if (!primeiro) json.append(",");
                primeiro = false;

                json.append("{")
                    .append("\"id\":").append(JsonSimples.escapar(msg.id)).append(",")
                    .append("\"senderRa\":").append(JsonSimples.escapar(msg.senderRa)).append(",")
                    .append("\"senderName\":").append(JsonSimples.escapar(msg.senderName)).append(",")
                    .append("\"senderRole\":").append(JsonSimples.escapar(msg.senderRole)).append(",")
                    .append("\"message\":").append(JsonSimples.escapar(msg.message)).append(",")
                    .append("\"timeFormatted\":").append(JsonSimples.escapar(msg.timeFormatted))
                    .append("}");
            }
            json.append("]}");
            resposta.enviarJson(200, json.toString());

        } else {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Metodo nao permitido.\"}");
        }
    }
}
