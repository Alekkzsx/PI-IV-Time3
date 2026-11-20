// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package videocall.modules.legado;

import auth.model.UsuarioAutenticado;
import core.HttpUtils;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.JsonSimples;
import videocall.abstratas.HandlerVideoCallLegadoAbstrato;
import videocall.utils.VideoCallUtils;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Handler legado de ingresso, saida e sinalizacao WebRTC (SDP / ICE Candidates).
 * Endpoints: /api/videocall/join, /api/videocall/leave, /api/videocall/signal
 */
public class VideoCallSignalingHandler extends HandlerVideoCallLegadoAbstrato {

    /** Despacho legado: join/leave/signal (signal aceita POST para enviar e GET para poll). */
    @Override
    protected void processarVideoCall(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws Exception {
        String caminho = requisicao.getCaminho();
        if ("/api/videocall/join".equalsIgnoreCase(caminho)) {
            tratarJoin(requisicao, resposta, usuario);
        } else if ("/api/videocall/leave".equalsIgnoreCase(caminho)) {
            tratarLeave(requisicao, resposta, usuario);
        } else {
            tratarSinalizacao(requisicao, resposta);
        }
    }

    /** POST /join: registra o participante; sala fechada para aluno vira 403 room_not_open. */
    private void tratarJoin(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            responderErro(resposta, 405, "method_not_allowed", "Use POST.");
            return;
        }
        Map<String, String> params = HttpUtils.extrairParametros(requisicao);
        String roomCode = params.get("roomCode");
        String ra = VideoCallUtils.resolverRa(params, usuario, "ra");
        String name = VideoCallUtils.resolverNome(params, usuario, "name");
        String role = VideoCallUtils.resolverPapel(params, usuario, "role");

        if (roomCode == null || ra == null || roomCode.trim().isEmpty() || ra.trim().isEmpty()) {
            responderErro(resposta, 400, "invalid_request", "Parametros 'roomCode' e 'ra' sao obrigatorios.");
            return;
        }
        if (!service.entrarNaSala(roomCode, ra, name, role)) {
            responderErro(resposta, 403, "room_not_open",
                    "A sala desta turma ainda nao foi aberta pelo docente responsavel. Aguarde a liberacao.");
            return;
        }

        System.out.println("[VIDEOCALL] " + name + " (" + ra + " - " + role + ") entrou na sala " + roomCode);
        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("status", Integer.valueOf(200));
        ok.put("mensagem", "Conectado a sala com sucesso.");
        ok.put("roomCode", roomCode);
        ok.put("ra", ra);
        enviarJson(resposta, 200, ok);
    }

    /** /leave: best-effort e idempotente (parametros ausentes nao geram erro, so nao removem ninguem). */
    private void tratarLeave(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        Map<String, String> params = HttpUtils.extrairParametros(requisicao);
        String roomCode = params.get("roomCode");
        String ra = VideoCallUtils.resolverRa(params, usuario, "ra");
        if (roomCode != null && ra != null) {
            service.sairDaSala(roomCode, ra);
            System.out.println("[VIDEOCALL] " + ra + " desconectou da sala " + roomCode);
        }
        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("status", Integer.valueOf(200));
        ok.put("mensagem", "Desconectado da sala.");
        enviarJson(resposta, 200, ok);
    }

    /**
     * /signal: POST enfileira um sinal (offer/answer/ice) para o peer; GET drena a caixa
     * do RA (polling do cliente legado, anterior ao WebSocket).
     */
    private void tratarSinalizacao(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> params = HttpUtils.extrairParametros(requisicao);
            String roomCode = params.get("roomCode");
            String fromRa = params.get("fromRa");
            String toRa = params.get("toRa");
            String type = params.get("type");
            String data = params.get("data");

            if (roomCode == null || fromRa == null || toRa == null || type == null) {
                responderErro(resposta, 400, "invalid_request", "Parametros incompletos para sinalizacao.");
                return;
            }
            service.enviarSinalizacao(roomCode, fromRa, toRa, type, data != null ? data : "{}");
            Map<String, Object> ok = new LinkedHashMap<String, Object>();
            ok.put("status", Integer.valueOf(200));
            ok.put("mensagem", "Sinal despachado com sucesso.");
            enviarJson(resposta, 200, ok);
        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> query = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
            String roomCode = query.get("roomCode");
            String ra = query.get("ra");
            if (roomCode == null || ra == null) {
                responderErro(resposta, 400, "invalid_request", "roomCode e ra sao obrigatorios na query.");
                return;
            }
            List<VideoCallService.SignalingMessage> mensagens = service.buscarSinalizacoes(roomCode, ra);
            // Serializacao manual: data ja e JSON (SDP/ICE) e entra cru; os demais campos sao escapados.
            StringBuilder json = new StringBuilder("{\"status\":200,\"signals\":[");
            boolean primeiro = true;
            for (VideoCallService.SignalingMessage m : mensagens) {
                if (!primeiro) json.append(',');
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
            responderErro(resposta, 405, "method_not_allowed", "Metodo nao permitido.");
        }
    }
}
