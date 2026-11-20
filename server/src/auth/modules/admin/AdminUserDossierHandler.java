// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package auth.modules.admin;

import auth.abstratas.AdminHandlerAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import bridge.ClientePonteAcademica;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.BsonUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Handler administrativo responsavel pelo dossie consolidado de usuario (Identidade + Ponte Academica + Auditoria).
 * Rota: GET /api/admin/users/{id}/dossier
 */
public class AdminUserDossierHandler extends AdminHandlerAbstrato {

    public AdminUserDossierHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        super(repositorio, ponte);
    }

    @Override
    protected String metodoPermitido() {
        return "GET";
    }

    /**
     * GET /users/{id}/dossier: consolida identidade (auth_users), dados academicos
     * (ponte :3001) e trilha de auditoria (100 eventos) numa unica resposta.
     * A propria consulta do admin e auditada (dossier_viewed) - acesso a dados de
     * terceiros tambem deixa rastro.
     */
    @Override
    protected void processarAutenticado(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws Exception {
        String[] partes = extrairSegmentosUsuario(req.getCaminho(), resp);
        if (partes == null) return;
        String userId = partes[0];

        Document user = repositorio.buscarDocumentoPorId(userId);
        if (user == null) {
            responderErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }

        Map<String, Object> academic = ponte.obterDadosLgpdUsuario(userId);
        List<Map<String, Object>> auditLogs = new ArrayList<Map<String, Object>>();
        for (Document doc : repositorio.listarLogsSeguranca(userId, 100)) {
            Map<String, Object> item = BsonUtils.documentoParaMapa(doc);
            item.put("id", doc.getObjectId("_id").toHexString());
            item.remove("_id");
            auditLogs.add(item);
        }

        repositorio.registrarAuditoria(admin.getUserId(), "dossier_viewed", userId, null);

        // classes/teachingClasses: nomes antigos e novos do mesmo dado no backend academico.
        Object classesList = academic.get("classes") instanceof List ? academic.get("classes")
                : (academic.get("teachingClasses") instanceof List ? academic.get("teachingClasses") : Collections.emptyList());

        Map<String, Object> dossier = new LinkedHashMap<String, Object>();
        dossier.put("user", AuthHttpUtils.montarUsuarioAdmin(user));
        dossier.put("classes", classesList);
        dossier.put("enrollments", academic.get("enrollments") instanceof List ? academic.get("enrollments") : Collections.emptyList());
        dossier.put("protocols", academic.get("protocols") instanceof List ? academic.get("protocols") : Collections.emptyList());
        dossier.put("grades", academic.get("grades") instanceof List ? academic.get("grades") : Collections.emptyList());
        dossier.put("auditLogs", auditLogs);

        enviarJson(resp, 200, dossier);
    }
}
