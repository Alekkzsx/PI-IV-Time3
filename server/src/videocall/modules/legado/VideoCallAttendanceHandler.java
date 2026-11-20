// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall.modules.legado;

import auth.model.UsuarioAutenticado;
import core.HttpUtils;
import core.RequisicaoHttp;
import core.RespostaHttp;
import videocall.abstratas.HandlerVideoCallLegadoAbstrato;
import videocall.utils.VideoCallUtils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Handler legado de consolidacao de presenca e assiduidade discente na videochamada.
 * Endpoint: /api/videocall/attendance
 */
public class VideoCallAttendanceHandler extends HandlerVideoCallLegadoAbstrato {

    @Override
    protected void processarVideoCall(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws Exception {
        Map<String, String> params = "GET".equalsIgnoreCase(requisicao.getMetodo())
                ? HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams())
                : HttpUtils.extrairParametros(requisicao);
        String roomCode = exigirRoomCode(params, resposta, "Parametro 'roomCode' e obrigatorio.");
        if (roomCode == null) return;

        VideoCallService.Room r = service.obterOuCriarSala(roomCode);
        int duracaoTotalMinutos = Math.max(1, r.getTotalDurationMinutes());

        List<Map<String, Object>> attendanceList = new ArrayList<Map<String, Object>>();
        for (VideoCallService.Participant p : r.attendanceHistory) {
            if ("docente".equalsIgnoreCase(p.role) || "admin".equalsIgnoreCase(p.role)) {
                continue;
            }
            long minutosConectado = p.getConnectedMinutes();
            double percentual = VideoCallUtils.calcularPercentualPresenca(minutosConectado, duracaoTotalMinutos);

            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("ra", p.ra);
            item.put("name", p.name);
            item.put("role", p.role);
            item.put("minutesConnected", Long.valueOf(minutosConectado));
            item.put("attendancePercentage", Double.valueOf(percentual));
            item.put("status", VideoCallUtils.classificarStatusPresenca(percentual));
            attendanceList.add(item);
        }

        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("status", Integer.valueOf(200));
        payload.put("roomCode", r.roomCode);
        payload.put("isOpen", Boolean.valueOf(r.isOpen));
        payload.put("totalClassDurationMinutes", Integer.valueOf(duracaoTotalMinutos));
        payload.put("attendanceList", attendanceList);
        enviarJson(resposta, 200, payload);
    }
}
