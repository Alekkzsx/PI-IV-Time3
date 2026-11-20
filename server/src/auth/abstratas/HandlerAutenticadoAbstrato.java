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

    /** @param repositorio repositorio de identidades; null cai no singleton (conveniencia de testes). */
    protected HandlerAutenticadoAbstrato(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    /** Rotas autenticadas sempre recebem headers anti-cache (tokens nao podem ficar em cache). */
    @Override
    protected boolean deveAplicarHeadersAuth() {
        return true;
    }

    /** Gancho RBAC: true exige perfil admin (subclasses administrativas sobrescrevem para true). */
    protected boolean exigirAdmin() {
        return false;
    }

    /**
     * Gancho: true deixa passar usuario com requirePasswordChange pendente.
     * So a rota de troca de senha habilita; as demais bloqueiam ate a senha provisoria ser trocada.
     */
    protected boolean permitirTrocaSenhaPendente() {
        return false;
    }

    /**
     * Guarda de autenticacao (final): valida Bearer JWT + sessao autoritativa no Mongo
     * ANTES de qualquer logica da subclasse. Falha de token/sessao lanca HttpSecurityException
     * (401/403), tratada pelo esqueleto de HandlerHttpAbstrato.
     */
    @Override
    protected final void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        UsuarioAutenticado usuario = exigirAdmin()
                ? JwtAuthValidator.autenticarAdminObrigatorio(requisicao, this.repositorio)
                : JwtAuthValidator.autenticarObrigatorio(requisicao, this.repositorio, permitirTrocaSenhaPendente());
        processarAutenticado(requisicao, resposta, usuario);
    }

    /**
     * Logica do endpoint ja com a identidade autenticada garantida.
     *
     * @param usuario identidade validada (token + sessao + versao), nunca null
     */
    protected abstract void processarAutenticado(
            RequisicaoHttp requisicao,
            RespostaHttp resposta,
            UsuarioAutenticado usuario) throws Exception;
}
