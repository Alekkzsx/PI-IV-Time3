// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package videocall.abstratas;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.JwtAuthValidator;
import core.RequisicaoHttp;
import core.RespostaHttp;
import core.abstratas.HandlerHttpAbstrato;
import videocall.modules.legado.VideoCallService;

import java.io.IOException;
import java.util.Map;

/**
 * Classe abstrata base para os handlers legados em memoria de videochamada (/api/videocall/*).
 *
 * Centraliza:
 * - Acesso ao VideoCallService;
 * - Autenticacao JWT opcional (com prioridade dos claims do token sobre parametros do corpo);
 * - Validacao padrao de roomCode obrigatorio.
 */
public abstract class HandlerVideoCallLegadoAbstrato extends HandlerHttpAbstrato {
    protected final VideoCallService service = VideoCallService.getInstance();
    protected final RepositorioUsuarios repositorio;

    /** Sem repositorio injetado: usa o singleton preguicoso (nao forca conexao no boot). */
    protected HandlerVideoCallLegadoAbstrato() {
        this(null);
    }

    protected HandlerVideoCallLegadoAbstrato(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio;
    }

    @Override
    protected String tagLog() {
        return "VIDEOCALL-LEGADO";
    }

    /**
     * Guarda legada (final): autenticacao OPCIONAL - sem token o usuario e null
     * (compatibilidade com clientes antigos), mas token presente e sempre validado.
     * As subclasses recebem o usuario e decidem o que exigir.
     */
    @Override
    protected final void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        RepositorioUsuarios repo = this.repositorio != null
                ? this.repositorio
                : RepositorioUsuarios.getInstanciaSeInicializada();
        UsuarioAutenticado usuario = JwtAuthValidator.autenticarOpcional(requisicao, repo);
        processarVideoCall(requisicao, resposta, usuario);
    }

    /** Logica do endpoint legado; usuario pode ser null (rotas historicamente publicas). */
    protected abstract void processarVideoCall(
            RequisicaoHttp requisicao,
            RespostaHttp resposta,
            UsuarioAutenticado usuario) throws Exception;

    /** Extrai roomCode obrigatorio dos parametros; ausente responde 400 e devolve null. */
    protected String exigirRoomCode(Map<String, String> params, RespostaHttp resposta, String mensagemErro)
            throws IOException {
        String roomCode = params != null ? params.get("roomCode") : null;
        if (roomCode == null || roomCode.trim().isEmpty()) {
            responderErro(resposta, 400, "invalid_request", mensagemErro);
            return null;
        }
        return roomCode.trim();
    }
}
