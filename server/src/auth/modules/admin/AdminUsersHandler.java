// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira - RA: 25006702
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
 *
 * Padrao Facade: implementa ManipuladorHttp direto e so despacha; cada sub-handler
 * herda AdminHandlerAbstrato e aplica RBAC admin + write-guard por conta propria.
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

    /**
     * Tabela de despacho:
     * /api/admin/teachers -> provisionamento de docentes;
     * /api/admin/users -> CRUD (lista/criacao);
     * /api/admin/users/{id}/sessions|revoke-sessions|reset-password -> seguranca;
     * /api/admin/users/{id}/dossier -> dossie;
     * /api/admin/users/{id}[/...] -> CRUD (get/update/delete).
     */
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

        // Fora da arvore admin: 404 manual com CORS/auth headers (nao passa pelo Template Method).
        HttpUtils.aplicarHeadersCors(requisicao, resposta);
        HttpUtils.aplicarHeadersAuth(resposta);
        HttpUtils.enviarErroJson(resposta, 404, "not_found", "Endpoint nao encontrado.");
    }

    /** Delegador legado: serializacao segura de usuario para o painel admin (sem passwordHash). */
    public static Map<String, Object> publicUser(Document document) {
        return AuthHttpUtils.montarUsuarioAdmin(document);
    }
}
