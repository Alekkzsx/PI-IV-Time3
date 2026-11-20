// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall.modules.legado;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
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
 * Handler legado responsavel pela listagem, abertura e fechamento das salas em memoria.
 * Endpoints: /api/videocall/rooms, /api/videocall/open, /api/videocall/close
 */
public class VideoCallRoomHandler extends HandlerVideoCallLegadoAbstrato {

    public VideoCallRoomHandler() {
        super(null);
    }

    public VideoCallRoomHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    /** Despacho legado: /open e /close exigem POST; qualquer outro caminho cai na listagem. */
    @Override
    protected void processarVideoCall(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws Exception {
        String caminho = requisicao.getCaminho();
        if ("/api/videocall/open".equalsIgnoreCase(caminho)) {
            tratarAberturaSala(requisicao, resposta, usuario);
        } else if ("/api/videocall/close".equalsIgnoreCase(caminho)) {
            tratarFechamentoSala(requisicao, resposta, usuario);
        } else {
            tratarListagemSalas(resposta);
        }
    }

    /** GET /rooms: fotografia das salas em memoria (estado, quem abriu, participantes, duracao). */
    private void tratarListagemSalas(RespostaHttp resposta) throws IOException {
        List<Map<String, Object>> rooms = new ArrayList<Map<String, Object>>();
        for (VideoCallService.Room r : service.listarSalas().values()) {
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("roomCode", r.roomCode);
            item.put("isOpen", Boolean.valueOf(r.isOpen));
            item.put("openedByRole", r.openedByRole != null ? r.openedByRole : "");
            item.put("openedByName", r.openedByName != null ? r.openedByName : "");
            item.put("activeParticipantsCount", Integer.valueOf(r.activeParticipants.size()));
            item.put("totalDurationMinutes", Integer.valueOf(r.getTotalDurationMinutes()));
            rooms.add(item);
        }
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("status", Integer.valueOf(200));
        payload.put("rooms", rooms);
        enviarJson(resposta, 200, payload);
    }

    /** POST /open: papel resolvido com precedencia do JWT; service recusa papeis sem permissao (403 + log). */
    private void tratarAberturaSala(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            responderErro(resposta, 405, "method_not_allowed", "Utilize POST para abrir sala.");
            return;
        }
        Map<String, String> params = HttpUtils.extrairParametros(requisicao);
        String roomCode = exigirRoomCode(params, resposta, "Parametro 'roomCode' e obrigatorio.");
        if (roomCode == null) return;

        String role = VideoCallUtils.resolverPapel(params, usuario, "role");
        String name = VideoCallUtils.resolverNome(params, usuario, "name");

        if (!service.abrirSala(roomCode, role, name)) {
            System.out.println("[SEGURANCA] Tentativa de abertura nao autorizada para sala " + roomCode + " pelo papel: " + role);
            responderErro(resposta, 403, "forbidden",
                    "Acesso negado: Apenas docentes ou administradores tem autorizacao para abrir a sala desta turma.");
            return;
        }

        System.out.println("[VIDEOCALL] Sala " + roomCode + " ABERTA com sucesso por " + name + " (" + role + ")");
        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("status", Integer.valueOf(200));
        ok.put("mensagem", "Sala aberta com sucesso.");
        ok.put("roomCode", roomCode);
        ok.put("isOpen", Boolean.TRUE);
        enviarJson(resposta, 200, ok);
    }

    /** POST /close: usuario autenticado precisa ser docente/admin; sala inexistente/fechada vira 400. */
    private void tratarFechamentoSala(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws IOException {
        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            responderErro(resposta, 405, "method_not_allowed", "Utilize POST para fechar sala.");
            return;
        }
        Map<String, String> params = HttpUtils.extrairParametros(requisicao);
        String roomCode = exigirRoomCode(params, resposta, "Parametro 'roomCode' e obrigatorio.");
        if (roomCode == null) return;

        if (usuario != null && !usuario.isDocenteOuAdmin()) {
            responderErro(resposta, 403, "forbidden",
                    "Acesso negado: Somente docentes ou administradores podem encerrar a sala.");
            return;
        }
        String role = VideoCallUtils.resolverPapel(params, usuario, "role");
        if (!service.fecharSala(roomCode, role)) {
            responderErro(resposta, 400, "invalid_request", "Nao foi possivel fechar a sala especificada.");
            return;
        }

        System.out.println("[VIDEOCALL] Sala " + roomCode + " ENCERRADA.");
        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("status", Integer.valueOf(200));
        ok.put("mensagem", "Sala encerrada com sucesso.");
        ok.put("roomCode", roomCode);
        ok.put("isOpen", Boolean.FALSE);
        enviarJson(resposta, 200, ok);
    }
}
