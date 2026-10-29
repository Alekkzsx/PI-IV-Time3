// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;

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
        String caminho = requisicao.getCaminho();

        if ("/api/videocall/join".equalsIgnoreCase(caminho)) {
            tratarJoin(requisicao, resposta);
        } else if ("/api/videocall/leave".equalsIgnoreCase(caminho)) {
            tratarLeave(requisicao, resposta);
        } else {
            tratarSinalizacao(requisicao, resposta);
        }
    }

    private void tratarJoin(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Use POST.\"}");
            return;
        }

        Map<String, String> params = HttpUtils.parseFormUrlEncoded(requisicao.getCorpo());
        String roomCode = params.get("roomCode");
        String ra = params.get("ra");
        String name = params.get("name");
        String role = params.get("role");

        if (roomCode == null || ra == null) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametros 'roomCode' e 'ra' sao obrigatorios.\"}");
            return;
        }

        boolean entrou = service.entrarNaSala(roomCode, ra, name, role);
        if (!entrou) {
            resposta.enviarJson(403, "{\"status\":403,\"erro\":\"A sala desta turma ainda nao foi aberta pelo docente responsavel. Aguarde a liberacao.\"}");
            return;
        }

        System.out.println("[VIDEOCALL] " + name + " (" + ra + " - " + role + ") entrou na sala " + roomCode);
        resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Conectado a sala com sucesso.\",\"roomCode\":\"" + roomCode + "\",\"ra\":\"" + ra + "\"}");
    }

    private void tratarLeave(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, String> params = HttpUtils.parseFormUrlEncoded(requisicao.getCorpo());
        String roomCode = params.get("roomCode");
        String ra = params.get("ra");

        if (roomCode != null && ra != null) {
            service.sairDaSala(roomCode, ra);
            System.out.println("[VIDEOCALL] " + ra + " desconectou da sala " + roomCode);
        }
        resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Desconectado da sala.\"}");
    }

    private void tratarSinalizacao(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            // Envio de envelope de sinalizacao SDP ou ICE Candidate
            Map<String, String> params = HttpUtils.parseFormUrlEncoded(requisicao.getCorpo());
            String roomCode = params.get("roomCode");
            String fromRa = params.get("fromRa");
            String toRa = params.get("toRa");
            String type = params.get("type"); // 'offer', 'answer', 'ice-candidate'
            String data = params.get("data");

            if (roomCode == null || fromRa == null || toRa == null || type == null) {
                resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametros incompletos para sinalizacao.\"}");
                return;
            }

            service.enviarSinalizacao(roomCode, fromRa, toRa, type, data != null ? data : "{}");
            resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Sinal despachado com sucesso.\"}");

        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            // Polling para recuperar mensagens pendentes
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
                    .append("\"id\":\"").append(m.id).append("\",")
                    .append("\"fromRa\":\"").append(m.fromRa).append("\",")
                    .append("\"toRa\":\"").append(m.toRa).append("\",")
                    .append("\"type\":\"").append(m.type).append("\",")
                    .append("\"data\":").append(m.data.startsWith("{") ? m.data : "\"" + m.data.replace("\"", "'") + "\"").append(",")
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

