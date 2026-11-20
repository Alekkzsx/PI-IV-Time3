// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.abstratas;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.JwtAuthValidator;
import core.RequisicaoHttp;
import core.RespostaHttp;
import core.abstratas.HandlerHttpAbstrato;

/**
 * Classe abstrata para handlers que exigem usuario autenticado via Bearer JWT
 * com validacao autoritativa de sessao no MongoDB.
 */
public abstract class HandlerAutenticadoAbstrato extends HandlerHttpAbstrato {
    protected final RepositorioUsuarios repositorio;

    protected HandlerAutenticadoAbstrato(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    protected boolean deveAplicarHeadersAuth() {
        return true;
    }

    protected boolean exigirAdmin() {
        return false;
    }

    protected boolean permitirTrocaSenhaPendente() {
        return false;
    }

    @Override
    protected final void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        UsuarioAutenticado usuario = exigirAdmin()
                ? JwtAuthValidator.autenticarAdminObrigatorio(requisicao, this.repositorio)
                : JwtAuthValidator.autenticarObrigatorio(requisicao, this.repositorio, permitirTrocaSenhaPendente());
        processarAutenticado(requisicao, resposta, usuario);
    }

    /**
     * Logica do endpoint ja com a identidade autenticada garantida.
     */
    protected abstract void processarAutenticado(
            RequisicaoHttp requisicao,
            RespostaHttp resposta,
            UsuarioAutenticado usuario) throws Exception;
}
