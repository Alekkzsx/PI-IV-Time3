// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsavel pela consulta e controle de abertura/fechamento das salas de videochamada.
 * Endpoints: /api/videocall/rooms, /api/videocall/open, /api/videocall/close
 */
public class VideoCallRoomHandler implements ManipuladorHttp {

    private final VideoCallService service = VideoCallService.getInstance();

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);
        String caminho = requisicao.getCaminho();

        if ("/api/videocall/open".equalsIgnoreCase(caminho)) {
            tratarAberturaSala(requisicao, resposta);
        } else if ("/api/videocall/close".equalsIgnoreCase(caminho)) {
            tratarFechamentoSala(requisicao, resposta);
        } else {
            tratarListagemSalas(requisicao, resposta);
        }
    }

    private void tratarListagemSalas(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        StringBuilder json = new StringBuilder("{\"status\":200,\"rooms\":[");
        Map<String, VideoCallService.Room> salas = service.listarSalas();
        boolean primeiro = true;

        for (VideoCallService.Room r : salas.values()) {
            if (!primeiro) json.append(",");
            primeiro = false;

            json.append("{")
                .append("\"roomCode\":\"").append(r.roomCode).append("\",")
                .append("\"isOpen\":").append(r.isOpen).append(",")
                .append("\"openedByRole\":\"").append(r.openedByRole != null ? r.openedByRole : "").append("\",")
                .append("\"openedByName\":\"").append(r.openedByName != null ? r.openedByName : "").append("\",")
                .append("\"activeParticipantsCount\":").append(r.activeParticipants.size()).append(",")
                .append("\"totalDurationMinutes\":").append(r.getTotalDurationMinutes())
                .append("}");
        }
        json.append("]}");
        resposta.enviarJson(200, json.toString());
    }

    private void tratarAberturaSala(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Utilize POST para abrir sala.\"}");
            return;
        }

        Map<String, String> params = HttpUtils.parseFormUrlEncoded(requisicao.getCorpo());
        String roomCode = params.get("roomCode");
        String role = params.get("role");
        String name = params.get("name");

        if (roomCode == null || roomCode.trim().isEmpty()) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametro 'roomCode' e obrigatorio.\"}");
            return;
        }

        boolean sucesso = service.abrirSala(roomCode, role, name);
        if (!sucesso) {
            System.out.println("[SEGURANCA] Tentativa de abertura nao autorizada para sala " + roomCode + " pelo papel: " + role);
            resposta.enviarJson(403, "{\"status\":403,\"erro\":\"Acesso negado: Apenas docentes ou administradores tem autorizacao para abrir a sala desta turma.\"}");
            return;
        }

        System.out.println("[VIDEOCALL] Sala " + roomCode + " ABERTA com sucesso por " + name + " (" + role + ")");
        resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Sala aberta com sucesso.\",\"roomCode\":\"" + roomCode + "\",\"isOpen\":true}");
    }

    private void tratarFechamentoSala(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviarJson(405, "{\"status\":405,\"erro\":\"Utilize POST para fechar sala.\"}");
            return;
        }

        Map<String, String> params = HttpUtils.parseFormUrlEncoded(requisicao.getCorpo());
        String roomCode = params.get("roomCode");
        String role = params.get("role");

        if (roomCode == null) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametro 'roomCode' e obrigatorio.\"}");
            return;
        }

        boolean sucesso = service.fecharSala(roomCode, role);
        if (!sucesso) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Nao foi possivel fechar a sala especificada.\"}");
            return;
        }

        System.out.println("[VIDEOCALL] Sala " + roomCode + " ENCERRADA.");
        resposta.enviarJson(200, "{\"status\":200,\"mensagem\":\"Sala encerrada com sucesso.\",\"roomCode\":\"" + roomCode + "\",\"isOpen\":false}");
    }
}

