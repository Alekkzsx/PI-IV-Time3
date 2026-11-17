// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323
package videocall;

import auth.DatabaseUnavailableException;
import auth.JwtAuthValidator;
import auth.RepositorioUsuarios;
import auth.UsuarioAutenticado;
import bridge.ClientePonteAcademica;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.Json;

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
public class VideoCallMongoHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorioUsuarios;
    private final RepositorioVideoCall repositorioVideoCall;
    private final ClientePonteAcademica ponte;

    public VideoCallMongoHandler() {
        this(RepositorioUsuarios.getInstance(), RepositorioVideoCall.getInstance(), new ClientePonteAcademica());
    }

    public VideoCallMongoHandler(
            RepositorioUsuarios repositorioUsuarios,
            RepositorioVideoCall repositorioVideoCall,
            ClientePonteAcademica ponte) {
        this.repositorioUsuarios = repositorioUsuarios != null ? repositorioUsuarios : RepositorioUsuarios.getInstance();
        this.repositorioVideoCall = repositorioVideoCall != null ? repositorioVideoCall : RepositorioVideoCall.getInstance();
        this.ponte = ponte != null ? ponte : new ClientePonteAcademica();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        String metodo = requisicao.getMetodo().toUpperCase(Locale.ROOT);
        String caminho = requisicao.getCaminho();

        try {
            UsuarioAutenticado usuario = JwtAuthValidator.autenticarObrigatorio(requisicao, repositorioUsuarios, false);

            if ("/api/video-call/rooms".equals(caminho) && "GET".equals(metodo)) {
                tratarListarSalas(resposta, usuario);
            } else if ("/api/video-call/rooms/enter".equals(caminho) && "POST".equals(metodo)) {
                tratarEntrarSala(requisicao, resposta, usuario);
            } else if ("/api/video-call/rooms/close".equals(caminho) && "POST".equals(metodo)) {
                tratarFecharSala(requisicao, resposta, usuario);
            } else if ("/api/video-call/rooms/attendance".equals(caminho) && "POST".equals(metodo)) {
                tratarPresenca(requisicao, resposta, usuario);
            } else {
                enviarErro(resposta, 404, "not_found", "Endpoint de videochamada nao encontrado.");
            }
        } catch (DatabaseUnavailableException e) {
            enviarErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (JwtAuthValidator.HttpSecurityException e) {
            enviarErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (SecurityException e) {
            enviarErro(resposta, 401, "unauthorized", e.getMessage());
        } catch (ClientePonteAcademica.ExcecaoPonteAcademica e) {
            enviarErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (IllegalArgumentException e) {
            enviarErro(resposta, 400, "invalid_request", e.getMessage());
        } catch (Exception e) {
            System.err.println("[VIDEOCALL] Erro inesperado: " + e.getMessage());
            enviarErro(resposta, 500, "internal_error", "Erro interno no servico de videochamada.");
        }
    }

    private void tratarListarSalas(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<Map<String, Object>> turmas = ponte.listarSalasUsuario(
                usuario.getUserId(),
                usuario.getProfile(),
                usuario.getIdentity()
        );
        Set<String> abertas = repositorioVideoCall.listarCodigosSalasAbertas();

        List<Map<String, Object>> respostaLista = new ArrayList<Map<String, Object>>();
        for (Map<String, Object> t : turmas) {
            Map<String, Object> item = new LinkedHashMap<String, Object>(t);
            String rc = t.get("roomCode") != null ? t.get("roomCode").toString().toUpperCase(Locale.ROOT) : "";
            item.put("isOpen", Boolean.valueOf(abertas.contains(rc)));
            respostaLista.add(item);
        }
        resp.enviarJson(200, Json.escrever(respostaLista));
    }

    private void tratarEntrarSala(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        String rawRoomCode = getString(body, "roomCode");
        if (rawRoomCode == null || rawRoomCode.length() < 2 || rawRoomCode.length() > 60) {
            enviarErro(resp, 400, "invalid_request", "Codigo da turma invalido.");
            return;
        }

        Map<String, Object> authSala = ponte.autorizarSala(
                usuario.getUserId(),
                usuario.getProfile(),
                usuario.getIdentity(),
                rawRoomCode
        );
        String roomCode = authSala.get("roomCode") != null
                ? authSala.get("roomCode").toString()
                : RepositorioVideoCall.sanitizeRoomCode(rawRoomCode);
        String classCode = authSala.get("classCode") != null ? authSala.get("classCode").toString() : rawRoomCode;
        String title = authSala.get("title") != null ? authSala.get("title").toString() : classCode;

        boolean opened;
        if (usuario.isDocenteOuAdmin()) {
            repositorioVideoCall.abrirSala(roomCode, classCode, usuario);
            VideoCallService.getInstance().abrirSala(roomCode, usuario.getProfile(), usuario.getDisplayName());
            opened = true;
        } else if (usuario.isAluno()) {
            if (!repositorioVideoCall.salaEstaAberta(roomCode)) {
                enviarErro(resp, 409, "room_not_open", "A videochamada ainda nao foi aberta pelo docente.");
                return;
            }
            opened = false;
        } else {
            enviarErro(resp, 403, "forbidden", "Perfil sem acesso a videochamada.");
            return;
        }

        String ticket = repositorioVideoCall.emitirTicketWebSocket(roomCode);

        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("roomCode", roomCode);
        payload.put("classCode", classCode);
        payload.put("title", title);
        payload.put("opened", Boolean.valueOf(opened));
        payload.put("webSocketTicket", ticket);
        resp.enviarJson(200, Json.escrever(payload));
    }

    private void tratarFecharSala(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        if (!usuario.isDocenteOuAdmin()) {
            enviarErro(resp, 403, "forbidden", "Somente o docente pode encerrar a sala.");
            return;
        }
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        String rawRoomCode = getString(body, "roomCode");
        if (rawRoomCode == null || rawRoomCode.length() < 2 || rawRoomCode.length() > 60) {
            enviarErro(resp, 400, "invalid_request", "Codigo da turma invalido.");
            return;
        }

        String roomCode = RepositorioVideoCall.sanitizeRoomCode(rawRoomCode);
        try {
            Map<String, Object> authSala = ponte.autorizarSala(
                    usuario.getUserId(),
                    usuario.getProfile(),
                    usuario.getIdentity(),
                    rawRoomCode
            );
            if (authSala.get("roomCode") != null) {
                roomCode = authSala.get("roomCode").toString();
            }
        } catch (ClientePonteAcademica.ExcecaoPonteAcademica e) {
            if (e.getStatusHttp() == 403) {
                enviarErro(resp, 403, e.getCodigo(), e.getMessage());
                return;
            }
            // Se turma nao existir na ponte, tenta sanitizado conforme comportamento anterior
        }

        boolean removed = repositorioVideoCall.fecharSala(roomCode, usuario);
        if (!removed) {
            enviarErro(resp, 404, "room_not_open", "Sala nao encontrada ou aberta por outro usuario.");
            return;
        }
        VideoCallService.getInstance().fecharSala(roomCode, usuario.isAdmin() ? "admin" : usuario.getProfile());
        resp.enviar(204, "");
    }

    private void tratarPresenca(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        String rawRoomCode = getString(body, "roomCode");
        String event = getString(body, "event");
        if (rawRoomCode == null || rawRoomCode.length() < 2 || rawRoomCode.length() > 60
                || (!"join".equals(event) && !"leave".equals(event))) {
            enviarErro(resp, 400, "invalid_request", "Dados de telemetria invalidos.");
            return;
        }
        int connectedSeconds = 0;
        if (body.get("connectedSeconds") instanceof Number) {
            connectedSeconds = Math.min(86_400, Math.max(0, ((Number) body.get("connectedSeconds")).intValue()));
        }

        Map<String, Object> authSala = ponte.autorizarSala(
                usuario.getUserId(),
                usuario.getProfile(),
                usuario.getIdentity(),
                rawRoomCode
        );
        String roomCode = authSala.get("roomCode") != null
                ? authSala.get("roomCode").toString()
                : RepositorioVideoCall.sanitizeRoomCode(rawRoomCode);
        String classCode = authSala.get("classCode") != null ? authSala.get("classCode").toString() : rawRoomCode;

        if (usuario.isAluno() && !repositorioVideoCall.salaEstaAberta(roomCode)) {
            enviarErro(resp, 403, "room_access_denied", "Acesso a sala ativa nao autorizado.");
            return;
        }

        repositorioVideoCall.registrarLogPresenca(roomCode, classCode, usuario, event, connectedSeconds);
        if (usuario.isAluno()) {
            ponte.registrarPresencaSala(classCode, usuario.getUserId(), usuario.getIdentity(), "join".equals(event));
        }

        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("ok", Boolean.TRUE);
        ok.put("roomCode", roomCode);
        resp.enviarJson(200, Json.escrever(ok));
    }

    private static String getString(Map<String, Object> map, String key) {
        if (map == null) return null;
        Object val = map.get(key);
        return val instanceof String ? ((String) val).trim() : null;
    }

    private static void enviarErro(RespostaHttp resposta, int status, String codigo, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("code", codigo);
        erro.put("message", mensagem);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
