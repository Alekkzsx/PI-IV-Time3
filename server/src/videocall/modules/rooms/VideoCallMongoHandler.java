// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323
package videocall.modules.rooms;

import auth.abstratas.HandlerAutenticadoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import bridge.ClientePonteAcademica;
import core.RequisicaoHttp;
import core.RespostaHttp;
import videocall.modules.legado.VideoCallService;
import videocall.utils.VideoCallUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * API REST persistida em MongoDB para videochamadas institucionais:
 * - GET  /api/video-call/rooms
 * - POST /api/video-call/rooms/enter
 * - POST /api/video-call/rooms/close
 * - POST /api/video-call/rooms/attendance
 */
public class VideoCallMongoHandler extends HandlerAutenticadoAbstrato {
    private final RepositorioVideoCall repositorioVideoCall;
    private final ClientePonteAcademica ponte;

    public VideoCallMongoHandler() {
        this(RepositorioUsuarios.getInstance(), RepositorioVideoCall.getInstance(), new ClientePonteAcademica());
    }

    public VideoCallMongoHandler(
            RepositorioUsuarios repositorioUsuarios,
            RepositorioVideoCall repositorioVideoCall,
            ClientePonteAcademica ponte) {
        super(repositorioUsuarios);
        this.repositorioVideoCall = repositorioVideoCall != null ? repositorioVideoCall : RepositorioVideoCall.getInstance();
        this.ponte = ponte != null ? ponte : new ClientePonteAcademica();
    }

    /** API de sala nao emite tokens de auth: headers padrao bastam. */
    @Override
    protected boolean deveAplicarHeadersAuth() {
        return false;
    }

    @Override
    protected String tagLog() {
        return "VIDEOCALL";
    }

    /** Despacho por caminho+verbo das 4 rotas persistidas; combinacao desconhecida = 404. */
    @Override
    protected void processarAutenticado(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws Exception {
        String metodo = requisicao.getMetodo().toUpperCase(Locale.ROOT);
        String caminho = requisicao.getCaminho();

        if ("/api/video-call/rooms".equals(caminho) && "GET".equals(metodo)) {
            tratarListarSalas(resposta, usuario);
        } else if ("/api/video-call/rooms/enter".equals(caminho) && "POST".equals(metodo)) {
            tratarEntrarSala(requisicao, resposta, usuario);
        } else if ("/api/video-call/rooms/close".equals(caminho) && "POST".equals(metodo)) {
            tratarFecharSala(requisicao, resposta, usuario);
        } else if ("/api/video-call/rooms/attendance".equals(caminho) && "POST".equals(metodo)) {
            tratarPresenca(requisicao, resposta, usuario);
        } else {
            responderErro(resposta, 404, "not_found", "Endpoint de videochamada nao encontrado.");
        }
    }

    /**
     * GET /rooms: turmas do usuario vindas da ponte academica, enriquecidas com isOpen
     * (cruzamento com as sessoes ao vivo nao expiradas do Mongo).
     */
    private void tratarListarSalas(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<Map<String, Object>> turmas = ponte.listarSalasUsuario(
                usuario.getUserId(), usuario.getProfile(), usuario.getIdentity());
        Set<String> abertas = repositorioVideoCall.listarCodigosSalasAbertas();

        List<Map<String, Object>> respostaLista = new ArrayList<Map<String, Object>>(turmas.size());
        for (Map<String, Object> t : turmas) {
            Map<String, Object> item = new LinkedHashMap<String, Object>(t);
            String rc = t.get("roomCode") != null ? t.get("roomCode").toString().toUpperCase(Locale.ROOT) : "";
            item.put("isOpen", Boolean.valueOf(abertas.contains(rc)));
            respostaLista.add(item);
        }
        enviarJson(resp, 200, respostaLista);
    }

    /**
     * POST /rooms/enter: autoriza o vinculo via ponte -> docente/admin ABRE a sala
     * (Mongo + estado legado em memoria), aluno so entra se ja estiver aberta (409 caso contrario)
     * -> emite o ticket WebSocket de uso unico (60s) que o cliente usa no upgrade /ws/video-call/{sala}.
     */
    private void tratarEntrarSala(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        String rawRoomCode = getString(body, "roomCode");
        if (rawRoomCode == null || rawRoomCode.length() < 2 || rawRoomCode.length() > 60) {
            responderErro(resp, 400, "invalid_request", "Codigo da turma invalido.");
            return;
        }

        Map<String, Object> authSala = ponte.autorizarSala(
                usuario.getUserId(), usuario.getProfile(), usuario.getIdentity(), rawRoomCode);
        String roomCode = authSala.get("roomCode") != null
                ? authSala.get("roomCode").toString() : VideoCallUtils.sanitizeRoomCode(rawRoomCode);
        String classCode = authSala.get("classCode") != null ? authSala.get("classCode").toString() : rawRoomCode;
        String title = authSala.get("title") != null ? authSala.get("title").toString() : classCode;

        boolean opened;
        if (usuario.isDocenteOuAdmin()) {
            // Dupla escrita: Mongo e a autoridade; o service em memoria alimenta o chat/hub legado.
            repositorioVideoCall.abrirSala(roomCode, classCode, usuario);
            VideoCallService.getInstance().abrirSala(roomCode, usuario.getProfile(), usuario.getDisplayName());
            opened = true;
        } else if (usuario.isAluno()) {
            if (!repositorioVideoCall.salaEstaAberta(roomCode)) {
                responderErro(resp, 409, "room_not_open", "A videochamada ainda nao foi aberta pelo docente.");
                return;
            }
            opened = false;
        } else {
            responderErro(resp, 403, "forbidden", "Perfil sem acesso a videochamada.");
            return;
        }

        String ticket = repositorioVideoCall.emitirTicketWebSocket(roomCode);
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("roomCode", roomCode);
        payload.put("classCode", classCode);
        payload.put("title", title);
        payload.put("opened", Boolean.valueOf(opened));
        payload.put("webSocketTicket", ticket);
        enviarJson(resp, 200, payload);
    }

    /**
     * POST /rooms/close: exclusivo docente/admin. Fecha no Mongo com guarda de posse
     * (docente so fecha a propria sala; admin fecha qualquer uma) e espelha no service legado.
     * 403 da ponte e propagado; outros erros da ponte nao impedem o fechamento local.
     */
    private void tratarFecharSala(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        if (!usuario.isDocenteOuAdmin()) {
            responderErro(resp, 403, "forbidden", "Somente o docente pode encerrar a sala.");
            return;
        }
        Map<String, Object> body = lerJsonObjeto(req);
        String rawRoomCode = getString(body, "roomCode");
        if (rawRoomCode == null || rawRoomCode.length() < 2 || rawRoomCode.length() > 60) {
            responderErro(resp, 400, "invalid_request", "Codigo da turma invalido.");
            return;
        }

        String roomCode = VideoCallUtils.sanitizeRoomCode(rawRoomCode);
        try {
            Map<String, Object> authSala = ponte.autorizarSala(
                    usuario.getUserId(), usuario.getProfile(), usuario.getIdentity(), rawRoomCode);
            if (authSala.get("roomCode") != null) {
                roomCode = authSala.get("roomCode").toString();
            }
        } catch (ClientePonteAcademica.ExcecaoPonteAcademica e) {
            if (e.getStatusHttp() == 403) {
                responderErro(resp, 403, e.getCodigo(), e.getMessage());
                return;
            }
        }

        if (!repositorioVideoCall.fecharSala(roomCode, usuario)) {
            responderErro(resp, 404, "room_not_open", "Sala nao encontrada ou aberta por outro usuario.");
            return;
        }
        VideoCallService.getInstance().fecharSala(roomCode, usuario.isAdmin() ? "admin" : usuario.getProfile());
        resp.enviar(204, "");
    }

    /**
     * POST /rooms/attendance: telemetria join/leave do cliente. connectedSeconds e
     * clampado em [0, 86400] (1 dia) contra valores absurdos; aluno so reporta em sala
     * aberta. Grava o log local e, para alunos, propaga a presenca ao backend academico.
     */
    private void tratarPresenca(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        String rawRoomCode = getString(body, "roomCode");
        String event = getString(body, "event");
        if (rawRoomCode == null || rawRoomCode.length() < 2 || rawRoomCode.length() > 60
                || (!"join".equals(event) && !"leave".equals(event))) {
            responderErro(resp, 400, "invalid_request", "Dados de telemetria invalidos.");
            return;
        }
        int connectedSeconds = body.get("connectedSeconds") instanceof Number
                ? Math.min(86_400, Math.max(0, ((Number) body.get("connectedSeconds")).intValue()))
                : 0;

        Map<String, Object> authSala = ponte.autorizarSala(
                usuario.getUserId(), usuario.getProfile(), usuario.getIdentity(), rawRoomCode);
        String roomCode = authSala.get("roomCode") != null
                ? authSala.get("roomCode").toString() : VideoCallUtils.sanitizeRoomCode(rawRoomCode);
        String classCode = authSala.get("classCode") != null ? authSala.get("classCode").toString() : rawRoomCode;

        if (usuario.isAluno() && !repositorioVideoCall.salaEstaAberta(roomCode)) {
            responderErro(resp, 403, "room_access_denied", "Acesso a sala ativa nao autorizado.");
            return;
        }

        repositorioVideoCall.registrarLogPresenca(roomCode, classCode, usuario, event, connectedSeconds);
        if (usuario.isAluno()) {
            ponte.registrarPresencaSala(classCode, usuario.getUserId(), usuario.getIdentity(), "join".equals(event));
        }

        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("ok", Boolean.TRUE);
        ok.put("roomCode", roomCode);
        enviarJson(resp, 200, ok);
    }
}
