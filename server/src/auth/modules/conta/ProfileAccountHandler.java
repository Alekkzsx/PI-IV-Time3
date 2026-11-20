// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.conta;

import auth.modules.persistencia.RepositorioUsuarios;
import bridge.ClientePonteAcademica;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;

import java.io.IOException;

/**
 * Roteador fino que agrupa as rotas de perfil/LGPD (ProfileHandler)
 * e seguranca da conta (AccountSecurityHandler).
 *
 * Padrao Facade: implementa ManipuladorHttp diretamente (sem Template Method proprio)
 * porque seu unico trabalho e despachar pelo caminho - cada handler interno aplica
 * seu proprio ciclo de vida/autenticacao.
 */
public class ProfileAccountHandler implements ManipuladorHttp {
    private final ProfileHandler profileHandler;
    private final AccountSecurityHandler securityHandler;

    public ProfileAccountHandler() {
        this(RepositorioUsuarios.getInstance(), new ClientePonteAcademica());
    }

    /** @param ponte ponte academica usada pelo ProfileHandler no export LGPD/sync de nome. */
    public ProfileAccountHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        this.profileHandler = new ProfileHandler(repositorio, ponte);
        this.securityHandler = new AccountSecurityHandler(repositorio);
    }

    /** Despacho: /profile e /lgpd-export -> perfil; demais rotas do grupo -> seguranca da conta. */
    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        String caminho = requisicao.getCaminho();
        if ("/api/auth/profile".equals(caminho) || "/api/auth/lgpd-export".equals(caminho)) {
            profileHandler.handle(requisicao, resposta);
        } else {
            securityHandler.handle(requisicao, resposta);
        }
    }
}
