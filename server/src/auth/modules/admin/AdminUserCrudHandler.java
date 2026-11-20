// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira - RA: 25006702
package auth.modules.admin;

import auth.abstratas.AdminHandlerAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.email.SmtpCliente;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import auth.utils.SenhaHasher;
import bridge.ClientePonteAcademica;
import com.mongodb.MongoWriteException;
import com.mongodb.client.model.Updates;
import core.HttpUtils;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import org.bson.conversions.Bson;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Handler administrativo responsavel pelo CRUD e ciclo de vida (ativo/suspenso) de usuarios.
 * Rotas: GET/POST /api/admin/users, GET/PATCH /api/admin/users/{id}, PATCH /api/admin/users/{id}/status
 */
public class AdminUserCrudHandler extends AdminHandlerAbstrato {

    public AdminUserCrudHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        super(repositorio, ponte);
    }

    @Override
    protected void processarAutenticado(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws Exception {
        String metodo = req.getMetodo().toUpperCase(Locale.ROOT);
        String caminho = req.getCaminho();

        if ("/api/admin/users".equals(caminho)) {
            if ("GET".equals(metodo)) {
                tratarListarUsuarios(req, resp);
            } else if ("POST".equals(metodo)) {
                tratarCriarUsuario(req, resp, admin);
            } else {
                responderErro(resp, 405, "method_not_allowed", "Metodo nao permitido.");
            }
            return;
        }

        String[] partes = extrairSegmentosUsuario(caminho, resp);
        if (partes == null) return;
        String userId = partes[0];

        if (partes.length == 1) {
            if ("GET".equals(metodo)) {
                tratarBuscarUsuario(resp, userId);
            } else if ("PATCH".equals(metodo)) {
                tratarAtualizarUsuario(req, resp, admin, userId);
            } else {
                responderErro(resp, 405, "method_not_allowed", "Metodo nao permitido.");
            }
        } else if (partes.length == 2 && "status".equals(partes[1].trim()) && "PATCH".equals(metodo)) {
            tratarAtualizarStatus(req, resp, admin, userId);
        } else {
            responderErro(resp, 404, "not_found", "Rota administrativa nao encontrada.");
        }
    }

    private void tratarListarUsuarios(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, String> query = HttpUtils.parseFormUrlEncoded(req.getQueryParams());
        String rawProfile = query.get("profile");
        String profile = (rawProfile != null && PERFIS_PERMITIDOS.contains(rawProfile.trim().toLowerCase(Locale.ROOT)))
                ? rawProfile.trim().toLowerCase(Locale.ROOT) : null;
        int limit = AuthHttpUtils.parseIntBounded(query.get("limit"), 100, 1, 500);
        int offset = AuthHttpUtils.parseIntBounded(query.get("offset"), 0, 0, 100000);

        List<Document> docs = repositorio.listarUsuariosFiltrados(
                profile, query.get("active"), query.get("search"), offset, limit);
        Map<String, Integer> sessionCounts = repositorio.contarSessoesAtivasPorUsuario(docs);

        List<Map<String, Object>> resultado = new ArrayList<Map<String, Object>>(docs.size());
        for (Document doc : docs) {
            String id = doc.getObjectId("_id").toHexString();
            Map<String, Object> item = AuthHttpUtils.montarUsuarioAdmin(doc);
            Integer count = sessionCounts.get(id);
            item.put("activeSessionsCount", Integer.valueOf(count != null ? count.intValue() : 0));
            resultado.add(item);
        }
        enviarJson(resp, 200, resultado);
    }

    private void tratarBuscarUsuario(RespostaHttp resp, String userId) throws IOException {
        Document user = repositorio.buscarDocumentoPorId(userId);
        if (user == null) {
            responderErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }
        enviarJson(resp, 200, AuthHttpUtils.montarUsuarioAdmin(user));
    }

    private void tratarCriarUsuario(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        String identity = getString(body, "identity");
        String email = getString(body, "email");
        String displayName = getString(body, "displayName");
        String profile = getString(body, "profile");
        String password = getString(body, "password");
        String department = getString(body, "departmentOrCourse");
        boolean twoFactorRequired = Boolean.TRUE.equals(body.get("twoFactorRequired"));

        if (identity == null || identity.length() < 2 || identity.length() > 80) {
            responderErro(resp, 400, "invalid_request", "Identidade institucional invalida.");
            return;
        }
        if (email == null || !email.contains("@") || email.length() > 254) {
            responderErro(resp, 400, "invalid_request", "E-mail institucional invalido.");
            return;
        }
        if (displayName == null || displayName.length() < 2 || displayName.length() > 120) {
            responderErro(resp, 400, "invalid_request", "Nome de exibicao invalido.");
            return;
        }
        if (profile == null || !PERFIS_PERMITIDOS.contains(profile.toLowerCase(Locale.ROOT))) {
            responderErro(resp, 400, "invalid_request", "Perfil institucional invalido.");
            return;
        }
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(password);
        if (!validacao.isValido()) {
            responderErro(resp, 400, "weak_password", validacao.getMensagem());
            return;
        }
        if (!exigirEscritaAdmin(admin, resp)) return;

        String normalizedIdentity = identity.toLowerCase(Locale.ROOT);
        String normalizedEmail = email.toLowerCase(Locale.ROOT);
        String canonicalProfile = profile.toLowerCase(Locale.ROOT);

        if (repositorio.existeDuplicidade(normalizedIdentity, normalizedEmail, null)) {
            responderErro(resp, 409, "user_exists", "E-mail ou identidade institucional ja cadastrado.");
            return;
        }

        Date agora = new Date();
        Document novo = new Document()
                .append("identity", identity)
                .append("normalizedIdentity", normalizedIdentity)
                .append("email", normalizedEmail)
                .append("normalizedEmail", normalizedEmail)
                .append("displayName", displayName)
                .append("profile", canonicalProfile)
                .append("departmentOrCourse", department != null ? department : "")
                .append("department", department != null ? department : "")
                .append("twoFactorRequired", Boolean.valueOf(twoFactorRequired))
                .append("twoFactorEnabled", Boolean.valueOf(twoFactorRequired))
                .append("passwordHash", SenhaHasher.hash(password))
                .append("active", Boolean.TRUE)
                .append("sessionVersion", Integer.valueOf(0))
                .append("requirePasswordChange", Boolean.FALSE)
                .append("createdAt", agora)
                .append("updatedAt", agora);

        try {
            repositorio.inserirDocumentoUsuario(novo);
        } catch (MongoWriteException e) {
            responderErro(resp, 409, "user_exists", "E-mail ou identidade institucional ja cadastrado.");
            return;
        }

        String newId = novo.getObjectId("_id").toHexString();
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("profile", canonicalProfile);
        repositorio.registrarAuditoria(admin.getUserId(), "user_created", newId, det);

        SmtpCliente.enviarBoasVindasComResultado(normalizedEmail, displayName, identity, canonicalProfile, password)
                .whenComplete((resultado, erro) -> repositorio.registrarResultadoEnvioEmail(
                        admin.getUserId(), "admin_welcome_email", normalizedEmail, resultado, erro));
        enviarJson(resp, 201, AuthHttpUtils.montarUsuarioAdmin(novo));
    }

    private void tratarAtualizarUsuario(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        if (body.isEmpty()) {
            responderErro(resp, 400, "invalid_request", "Informe ao menos um campo para atualizar.");
            return;
        }
        if (!exigirEscritaAdmin(admin, resp)) return;

        Document existing = repositorio.buscarDocumentoPorId(userId);
        if (existing == null) {
            responderErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }

        String newIdentity = getString(body, "identity");
        String newEmail = getString(body, "email");
        String newDisplayName = getString(body, "displayName");
        String newProfile = getString(body, "profile");
        String newDepartment = getString(body, "departmentOrCourse");
        Boolean newTwoFactor = body.get("twoFactorRequired") instanceof Boolean
                ? (Boolean) body.get("twoFactorRequired") : null;

        String currentProfile = existing.getString("profile");
        if (newProfile != null) {
            newProfile = newProfile.toLowerCase(Locale.ROOT);
            if (!validarTrocaPerfil(resp, admin, userId, existing, currentProfile, newProfile)) {
                return;
            }
        }

        String finalIdentity = newIdentity != null ? newIdentity : existing.getString("identity");
        String finalNormId = finalIdentity != null ? finalIdentity.toLowerCase(Locale.ROOT) : "";
        String finalEmail = newEmail != null ? newEmail.toLowerCase(Locale.ROOT) : existing.getString("email");

        if (repositorio.existeDuplicidade(finalNormId, finalEmail, userId)) {
            responderErro(resp, 409, "user_exists", "E-mail ou identidade institucional ja cadastrado.");
            return;
        }

        boolean currentTwoFactor = existing.getBoolean("twoFactorRequired", false)
                || existing.getBoolean("twoFactorEnabled", false);
        boolean securityChanged =
                (newProfile != null && !newProfile.equals(currentProfile))
                || (newIdentity != null && !newIdentity.equals(existing.getString("identity")))
                || (newTwoFactor != null && newTwoFactor.booleanValue() != currentTwoFactor)
                || (newEmail != null && !newEmail.equalsIgnoreCase(existing.getString("email")));

        List<Bson> updates = montarAtualizacoes(newIdentity, finalNormId, newEmail, finalEmail,
                newDisplayName, newProfile, newDepartment, newTwoFactor, securityChanged);
        Document updated = repositorio.atualizarCamposUsuario(userId, updates);

        if (securityChanged) {
            repositorio.revogarTodasSessoes(userId);
            String oldNorm = existing.getString("normalizedIdentity");
            if (oldNorm != null) {
                repositorio.removerOtp(oldNorm, "RECOVERY");
            }
        }
        if (newIdentity != null || newDisplayName != null) {
            ponte.sincronizarUsuario(userId, newIdentity, newDisplayName);
        }

        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("fields", new ArrayList<String>(body.keySet()));
        repositorio.registrarAuditoria(admin.getUserId(), "user_updated", userId, det);
        enviarJson(resp, 200, AuthHttpUtils.montarUsuarioAdmin(updated != null ? updated : existing));
    }

    private boolean validarTrocaPerfil(
            RespostaHttp resp,
            UsuarioAutenticado admin,
            String userId,
            Document existing,
            String currentProfile,
            String newProfile) throws IOException {
        if (!PERFIS_PERMITIDOS.contains(newProfile)) {
            responderErro(resp, 400, "invalid_request", "Perfil institucional invalido.");
            return false;
        }
        if (!newProfile.equals(currentProfile) && "admin".equals(currentProfile)) {
            if (userId.equals(admin.getUserId())) {
                responderErro(resp, 409, "self_demotion", "Voce nao pode remover seu proprio perfil administrativo.");
                return false;
            }
            if (existing.getBoolean("active", false) && repositorio.contarAdminsAtivos() <= 1) {
                responderErro(resp, 409, "last_admin", "Nao e possivel remover o ultimo administrador ativo.");
                return false;
            }
        }
        if (!newProfile.equals(currentProfile)) {
            Map<String, Object> vinculos = ponte.consultarVinculosUsuario(userId);
            if (Boolean.TRUE.equals(vinculos.get("hasActiveLinks"))) {
                responderErro(resp, 409, "linked_profile", "Remova os vinculos academicos ativos antes de alterar o perfil.");
                return false;
            }
        }
        return true;
    }

    private List<Bson> montarAtualizacoes(
            String newIdentity, String finalNormId, String newEmail, String finalEmail,
            String newDisplayName, String newProfile, String newDepartment,
            Boolean newTwoFactor, boolean securityChanged) {
        List<Bson> updates = new ArrayList<Bson>();
        if (newIdentity != null) {
            updates.add(Updates.set("identity", newIdentity));
            updates.add(Updates.set("normalizedIdentity", finalNormId));
        }
        if (newEmail != null) {
            updates.add(Updates.set("email", finalEmail));
            updates.add(Updates.set("normalizedEmail", finalEmail));
        }
        if (newDisplayName != null) updates.add(Updates.set("displayName", newDisplayName));
        if (newProfile != null) updates.add(Updates.set("profile", newProfile));
        if (newDepartment != null) {
            updates.add(Updates.set("departmentOrCourse", newDepartment));
            updates.add(Updates.set("department", newDepartment));
        }
        if (newTwoFactor != null) {
            updates.add(Updates.set("twoFactorRequired", newTwoFactor));
            updates.add(Updates.set("twoFactorEnabled", newTwoFactor));
        }
        updates.add(Updates.set("updatedAt", new Date()));
        if (securityChanged) updates.add(Updates.inc("sessionVersion", 1));
        return updates;
    }

    private void tratarAtualizarStatus(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        if (!(body.get("active") instanceof Boolean)) {
            responderErro(resp, 400, "invalid_request", "Campo booleano 'active' e obrigatorio.");
            return;
        }
        boolean active = ((Boolean) body.get("active")).booleanValue();
        String reason = getString(body, "reason");
        if (!exigirEscritaAdmin(admin, resp)) return;

        Document existing = repositorio.buscarDocumentoPorId(userId);
        if (existing == null) {
            responderErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }

        boolean currentlyActive = existing.getBoolean("active", false);
        if (!active && currentlyActive && "admin".equals(existing.getString("profile"))) {
            if (userId.equals(admin.getUserId())) {
                responderErro(resp, 409, "self_suspension", "Voce nao pode suspender sua propria conta.");
                return;
            }
            if (repositorio.contarAdminsAtivos() <= 1) {
                responderErro(resp, 409, "last_admin", "Nao e possivel suspender o ultimo administrador ativo.");
                return;
            }
        }
        if (active == currentlyActive) {
            enviarJson(resp, 200, AuthHttpUtils.montarUsuarioAdmin(existing));
            return;
        }

        List<Bson> updates = new ArrayList<Bson>();
        updates.add(Updates.set("active", Boolean.valueOf(active)));
        updates.add(Updates.set("suspensionReason", active ? null : reason));
        updates.add(Updates.set("updatedAt", new Date()));
        updates.add(Updates.inc("sessionVersion", 1));

        Document updated = repositorio.atualizarCamposUsuario(userId, updates);
        repositorio.revogarTodasSessoes(userId);
        String oldNorm = existing.getString("normalizedIdentity");
        if (oldNorm != null) {
            repositorio.removerOtp(oldNorm, "RECOVERY");
        }
        repositorio.registrarAuditoria(admin.getUserId(), active ? "user_activated" : "user_suspended", userId, null);
        enviarJson(resp, 200, AuthHttpUtils.montarUsuarioAdmin(updated != null ? updated : existing));
    }
}
