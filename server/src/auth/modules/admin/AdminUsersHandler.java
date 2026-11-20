// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira
package auth.modules.admin;

import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import bridge.ClientePonteAcademica;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;

import java.io.IOException;
import java.util.Map;

/**
 * Roteador fino de administracao de identidades que delega cada subdominio
 * para seu handler especializado (CRUD, Seguranca, Dossie LGPD e Docentes).
 */
public class AdminUsersHandler implements ManipuladorHttp {
    private final AdminUserCrudHandler crudHandler;
    private final AdminUserSecurityHandler securityHandler;
    private final AdminUserDossierHandler dossierHandler;
    private final AdminTeacherHandler teacherHandler;

    public AdminUsersHandler() {
        this(RepositorioUsuarios.getInstance(), new ClientePonteAcademica());
    }

    public AdminUsersHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        this.crudHandler = new AdminUserCrudHandler(repositorio, ponte);
        this.securityHandler = new AdminUserSecurityHandler(repositorio, ponte);
        this.dossierHandler = new AdminUserDossierHandler(repositorio, ponte);
        this.teacherHandler = new AdminTeacherHandler(repositorio, ponte);
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        String caminho = requisicao.getCaminho();
        if ("/api/admin/teachers".equals(caminho)) {
            teacherHandler.handle(requisicao, resposta);
            return;
        }
        if ("/api/admin/users".equals(caminho)) {
            crudHandler.handle(requisicao, resposta);
            return;
        }
        if (caminho.startsWith("/api/admin/users/")) {
            String[] partes = caminho.substring("/api/admin/users/".length()).split("/");
            if (partes.length == 2) {
                String acao = partes[1].trim();
                if ("sessions".equals(acao) || "revoke-sessions".equals(acao) || "reset-password".equals(acao)) {
                    securityHandler.handle(requisicao, resposta);
                    return;
                }
                if ("dossier".equals(acao)) {
                    dossierHandler.handle(requisicao, resposta);
                    return;
                }
            }
            crudHandler.handle(requisicao, resposta);
            return;
        }

        HttpUtils.aplicarHeadersCors(requisicao, resposta);
        HttpUtils.aplicarHeadersAuth(resposta);
        HttpUtils.enviarErroJson(resposta, 404, "not_found", "Endpoint nao encontrado.");
    }

    public static Map<String, Object> publicUser(Document document) {
        return AuthHttpUtils.montarUsuarioAdmin(document);
    }
}
