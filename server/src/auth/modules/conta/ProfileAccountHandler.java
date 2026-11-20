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
 */
public class ProfileAccountHandler implements ManipuladorHttp {
    private final ProfileHandler profileHandler;
    private final AccountSecurityHandler securityHandler;

    public ProfileAccountHandler() {
        this(RepositorioUsuarios.getInstance(), new ClientePonteAcademica());
    }

    public ProfileAccountHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        this.profileHandler = new ProfileHandler(repositorio, ponte);
        this.securityHandler = new AccountSecurityHandler(repositorio);
    }

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
