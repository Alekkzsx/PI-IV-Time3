// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package videocall.modules.legado;

import auth.model.UsuarioAutenticado;
import core.HttpUtils;
import core.RequisicaoHttp;
import core.RespostaHttp;
import videocall.abstratas.HandlerVideoCallLegadoAbstrato;
import videocall.utils.VideoCallUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Handler legado de interacoes em tempo real (fila de mao levantada e chat).
 * Endpoints: /api/videocall/hand-raise, /api/videocall/chat
 */
public class VideoCallInteractionHandler extends HandlerVideoCallLegadoAbstrato {

    /** Despacho: /hand-raise (fila de perguntas) e /chat (mensagens); resto 404. */
    @Override
    protected void processarVideoCall(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws Exception {
        String caminho = requisicao.getCaminho();
        if ("/api/videocall/hand-raise".equalsIgnoreCase(caminho)) {
            tratarMaoLevantada(requisicao, resposta);
        } else if ("/api/videocall/chat".equalsIgnoreCase(caminho)) {
            tratarChat(requisicao, resposta, usuario);
        } else {
            responderErro(resposta, 404, "not_found", "Endpoint de interacao desconhecido.");
        }
    }

    /**
     * /hand-raise: POST alterna o estado (action raise/lower/toggle) e devolve a posicao
     * na fila FIFO (1-based; 0 = fora da fila); GET lista a fila na ordem de chegada.
     */
    private void tratarMaoLevantada(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> params = HttpUtils.extrairParametros(requisicao);
            String roomCode = params.get("roomCode");
            String ra = params.get("ra");
            String action = params.containsKey("action") ? params.get("action") : "toggle";
            if (roomCode == null || ra == null) {
                responderErro(resposta, 400, "invalid_request", "roomCode e ra sao obrigatorios.");
                return;
            }
            VideoCallService.Room r = service.obterOuCriarSala(roomCode);
            VideoCallService.Participant p = r.activeParticipants.get(ra);
            if (p == null) {
                responderErro(resposta, 404, "not_found", "Participante nao localizado na sala.");
                return;
            }
            // toggle inverte o estado atual; raise/lower forcam o estado pedido.
            boolean novoEstado = "raise".equalsIgnoreCase(action) ? true
                    : ("lower".equalsIgnoreCase(action) ? false : !p.isHandRaised);
            service.alternarMaoLevantada(roomCode, ra, novoEstado);

            System.out.println("[VIDEOCALL] Mao levantada: " + p.name + " (" + ra + ") -> "
                    + (novoEstado ? "LEVANTADA" : "ABAIXADA"));
            Map<String, Object> ok = new LinkedHashMap<String, Object>();
            ok.put("status", Integer.valueOf(200));
            ok.put("isHandRaised", Boolean.valueOf(novoEstado));
            ok.put("queuePosition", Integer.valueOf(r.handRaiseQueue.indexOf(ra) + 1));
            enviarJson(resposta, 200, ok);
        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> query = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
            String roomCode = exigirRoomCode(query, resposta, "roomCode e obrigatorio.");
            if (roomCode == null) return;

            VideoCallService.Room r = service.obterOuCriarSala(roomCode);
            List<Map<String, Object>> queue = new ArrayList<Map<String, Object>>();
            for (String ra : r.handRaiseQueue) {
                VideoCallService.Participant p = r.activeParticipants.get(ra);
                if (p != null) {
                    Map<String, Object> item = new LinkedHashMap<String, Object>();
                    item.put("ra", p.ra);
                    item.put("name", p.name);
                    item.put("handRaisedAt", Long.valueOf(p.handRaisedAt));
                    queue.add(item);
                }
            }
            Map<String, Object> ok = new LinkedHashMap<String, Object>();
            ok.put("status", Integer.valueOf(200));
            ok.put("roomCode", roomCode);
            ok.put("queue", queue);
            enviarJson(resposta, 200, ok);
        } else {
            responderErro(resposta, 405, "method_not_allowed", "Metodo nao permitido.");
        }
    }

    /**
     * /chat: POST acrescenta mensagem (remetente/papel resolvidos com precedencia do JWT,
     * nome/papel ausentes caem em RA/"aluno"); GET devolve o historico completo da sala.
     */
    private void tratarChat(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> params = HttpUtils.extrairParametros(requisicao);
            String roomCode = params.get("roomCode");
            String senderRa = VideoCallUtils.resolverRa(params, usuario, "senderRa");
            String senderName = params.get("senderName");
            String senderRole = VideoCallUtils.resolverPapel(params, usuario, "senderRole");
            String message = params.get("message");

            if (roomCode == null || senderRa == null || message == null || message.trim().isEmpty()) {
                responderErro(resposta, 400, "invalid_request", "Dados incompletos para envio de mensagem.");
                return;
            }
            service.adicionarMensagemChat(roomCode, senderRa,
                    senderName != null ? senderName : senderRa,
                    senderRole != null ? senderRole : "aluno",
                    message.trim());
            Map<String, Object> ok = new LinkedHashMap<String, Object>();
            ok.put("status", Integer.valueOf(201));
            ok.put("mensagem", "Mensagem enviada com sucesso.");
            enviarJson(resposta, 201, ok);
        } else if ("GET".equalsIgnoreCase(requisicao.getMetodo())) {
            Map<String, String> query = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
            String roomCode = exigirRoomCode(query, resposta, "roomCode e obrigatorio.");
            if (roomCode == null) return;

            VideoCallService.Room r = service.obterOuCriarSala(roomCode);
            List<Map<String, Object>> messages = new ArrayList<Map<String, Object>>();
            for (VideoCallService.ChatMessage msg : r.chatHistory) {
                Map<String, Object> item = new LinkedHashMap<String, Object>();
                item.put("id", msg.id);
                item.put("senderRa", msg.senderRa);
                item.put("senderName", msg.senderName);
                item.put("senderRole", msg.senderRole);
                item.put("message", msg.message);
                item.put("timeFormatted", msg.timeFormatted);
                messages.add(item);
            }
            Map<String, Object> ok = new LinkedHashMap<String, Object>();
            ok.put("status", Integer.valueOf(200));
            ok.put("messages", messages);
            enviarJson(resposta, 200, ok);
        } else {
            responderErro(resposta, 405, "method_not_allowed", "Metodo nao permitido.");
        }
    }
}
