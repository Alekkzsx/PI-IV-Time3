// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall;

import auth.JwtAuthValidator;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.JsonSimples;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsavel pelo rastreamento e consolidacao de presenca e assiduidade discente na videochamada.
 * Endpoint: /api/videocall/attendance
 */
public class VideoCallAttendanceHandler implements ManipuladorHttp {

    private final VideoCallService service = VideoCallService.getInstance();

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        try {
            JwtAuthValidator.autenticarOpcional(requisicao);
        } catch (SecurityException e) {
            resposta.enviarJson(401, "{\"status\":401,\"erro\":" + JsonSimples.escapar(e.getMessage()) + "}");
            return;
        }

        Map<String, String> query = "GET".equalsIgnoreCase(requisicao.getMetodo())
                ? HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams())
                : HttpUtils.extrairParametros(requisicao);
        String roomCode = query.get("roomCode");

        if (roomCode == null || roomCode.trim().isEmpty()) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Parametro 'roomCode' e obrigatorio.\"}");
            return;
        }

        VideoCallService.Room r = service.obterOuCriarSala(roomCode);
        int duracaoTotalMinutos = Math.max(1, r.getTotalDurationMinutes());

        StringBuilder json = new StringBuilder("{");
        json.append("\"status\":200,")
            .append("\"roomCode\":").append(JsonSimples.escapar(r.roomCode)).append(",")
            .append("\"isOpen\":").append(r.isOpen).append(",")
            .append("\"totalClassDurationMinutes\":").append(duracaoTotalMinutos).append(",")
            .append("\"attendanceList\":[");

        boolean primeiro = true;
        for (VideoCallService.Participant p : r.attendanceHistory) {
            if ("docente".equalsIgnoreCase(p.role) || "admin".equalsIgnoreCase(p.role)) {
                continue; // Relatorio de frequencia foca nos discentes
            }

            if (!primeiro) json.append(",");
            primeiro = false;

            long minutosConectado = p.getConnectedMinutes();
            double percentual = ((double) minutosConectado / duracaoTotalMinutos) * 100.0;
            if (percentual > 100.0) percentual = 100.0;
            percentual = Math.round(percentual * 10.0) / 10.0;

            String statusPresenca;
            if (percentual >= 75.0) {
                statusPresenca = "PRESENCA_INTEGRAL";
            } else if (percentual >= 50.0) {
                statusPresenca = "MEIA_PRESENCA";
            } else {
                statusPresenca = "FALTA_AUTOMATICA";
            }

            json.append("{")
                .append("\"ra\":").append(JsonSimples.escapar(p.ra)).append(",")
                .append("\"name\":").append(JsonSimples.escapar(p.name)).append(",")
                .append("\"role\":").append(JsonSimples.escapar(p.role)).append(",")
                .append("\"minutesConnected\":").append(minutosConectado).append(",")
                .append("\"attendancePercentage\":").append(percentual).append(",")
                .append("\"status\":").append(JsonSimples.escapar(statusPresenca))
                .append("}");
        }

        json.append("]}");
        resposta.enviarJson(200, json.toString());
    }
}
