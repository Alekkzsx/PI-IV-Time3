// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira
package auth;

import bridge.ClientePonteAcademica;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import com.mongodb.MongoWriteException;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.model.Collation;
import com.mongodb.client.model.CollationStrength;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.FindOneAndUpdateOptions;
import com.mongodb.client.model.ReturnDocument;
import com.mongodb.client.model.Sorts;
import com.mongodb.client.model.Updates;
import org.bson.Document;
import org.bson.conversions.Bson;
import org.bson.types.ObjectId;
import utils.ConfigEnv;
import utils.Json;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Handler administrativo de identidades, contas, sessoes e dossie (LGPD):
 * - GET    /api/admin/users
 * - GET    /api/admin/users/{id}
 * - POST   /api/admin/users
 * - PATCH  /api/admin/users/{id}
 * - PATCH  /api/admin/users/{id}/status
 * - GET    /api/admin/users/{id}/sessions
 * - POST   /api/admin/users/{id}/revoke-sessions
 * - POST   /api/admin/users/{id}/reset-password
 * - GET    /api/admin/users/{id}/dossier
 * - POST   /api/admin/teachers
 */
public class AdminUsersHandler implements ManipuladorHttp {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final Collation CASE_INSENSITIVE = Collation.builder()
            .locale("en")
            .collationStrength(CollationStrength.SECONDARY)
            .build();
    private static final Set<String> PERFIS_PERMITIDOS = new HashSet<String>(Arrays.asList("aluno", "docente", "admin"));

    private final RepositorioUsuarios repositorio;
    private final ClientePonteAcademica ponte;

    public AdminUsersHandler() {
        this(RepositorioUsuarios.getInstance(), new ClientePonteAcademica());
    }

    public AdminUsersHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
        this.ponte = ponte != null ? ponte : new ClientePonteAcademica();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);
        HttpUtils.aplicarHeadersAuth(resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        String metodo = requisicao.getMetodo().toUpperCase(Locale.ROOT);
        String caminho = requisicao.getCaminho();

        try {
            UsuarioAutenticado admin = JwtAuthValidator.autenticarAdminObrigatorio(requisicao, repositorio);

            if ("/api/admin/teachers".equals(caminho)) {
                if ("POST".equals(metodo)) {
                    tratarCriarDocente(requisicao, resposta, admin);
                } else {
                    enviarErro(resposta, 405, "method_not_allowed", "Metodo nao permitido neste servidor.");
                }
                return;
            }

            if ("/api/admin/users".equals(caminho)) {
                if ("GET".equals(metodo)) {
                    tratarListarUsuarios(requisicao, resposta);
                } else if ("POST".equals(metodo)) {
                    tratarCriarUsuario(requisicao, resposta, admin);
                } else {
                    enviarErro(resposta, 405, "method_not_allowed", "Metodo nao permitido.");
                }
                return;
            }

            if (caminho.startsWith("/api/admin/users/")) {
                String resto = caminho.substring("/api/admin/users/".length());
                String[] partes = resto.split("/");
                String userId = partes.length >= 1 ? partes[0].trim() : "";
                if (!ObjectId.isValid(userId)) {
                    enviarErro(resposta, 400, "invalid_id", "Identificador invalido.");
                    return;
                }

                if (partes.length == 1) {
                    if ("GET".equals(metodo)) {
                        tratarBuscarUsuario(resposta, userId);
                    } else if ("PATCH".equals(metodo)) {
                        tratarAtualizarUsuario(requisicao, resposta, admin, userId);
                    } else {
                        enviarErro(resposta, 405, "method_not_allowed", "Metodo nao permitido.");
                    }
                    return;
                }

                if (partes.length == 2) {
                    String acao = partes[1].trim();
                    if ("status".equals(acao) && "PATCH".equals(metodo)) {
                        tratarAtualizarStatus(requisicao, resposta, admin, userId);
                    } else if ("sessions".equals(acao) && "GET".equals(metodo)) {
                        tratarSessoesUsuario(resposta, userId);
                    } else if ("revoke-sessions".equals(acao) && "POST".equals(metodo)) {
                        tratarRevogarSessoesUsuario(resposta, admin, userId);
                    } else if ("reset-password".equals(acao) && "POST".equals(metodo)) {
                        tratarResetarSenhaUsuario(requisicao, resposta, admin, userId);
                    } else if ("dossier".equals(acao) && "GET".equals(metodo)) {
                        tratarDossieUsuario(resposta, admin, userId);
                    } else {
                        enviarErro(resposta, 404, "not_found", "Rota administrativa nao encontrada.");
                    }
                    return;
                }
            }

            enviarErro(resposta, 404, "not_found", "Endpoint nao encontrado.");
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
            System.err.println("[ADMIN-USERS] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "internal_error", "Erro interno no servidor.");
        }
    }

    private void tratarListarUsuarios(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, String> query = HttpUtils.parseFormUrlEncoded(req.getQueryParams());
        List<Bson> filtros = new ArrayList<Bson>();

        String profile = query.get("profile");
        if (profile != null && PERFIS_PERMITIDOS.contains(profile.trim().toLowerCase(Locale.ROOT))) {
            filtros.add(Filters.eq("profile", profile.trim().toLowerCase(Locale.ROOT)));
        }

        String activeParam = query.get("active");
        if ("true".equalsIgnoreCase(activeParam)) {
            filtros.add(Filters.eq("active", Boolean.TRUE));
        } else if ("false".equalsIgnoreCase(activeParam)) {
            filtros.add(Filters.eq("active", Boolean.FALSE));
        }

        String search = query.get("search");
        if (search != null && !search.trim().isEmpty()) {
            String escaped = Pattern.quote(search.trim());
            Pattern regex = Pattern.compile(escaped, Pattern.CASE_INSENSITIVE);
            filtros.add(Filters.or(
                    Filters.regex("displayName", regex),
                    Filters.regex("email", regex),
                    Filters.regex("identity", regex)
            ));
        }

        int limit = parseIntBounded(query.get("limit"), 100, 1, 500);
        int offset = parseIntBounded(query.get("offset"), 0, 0, 100000);

        Bson filtroFinal = filtros.isEmpty() ? new Document() : Filters.and(filtros);
        List<Document> docs = new ArrayList<Document>();
        repositorio.getUsersCollection()
                .find(filtroFinal)
                .sort(Sorts.ascending("displayName", "_id"))
                .skip(offset)
                .limit(limit)
                .into(docs);

        Map<String, Integer> sessionCounts = contarSessoesAtivasPorUsuario(docs);
        List<Map<String, Object>> resultado = new ArrayList<Map<String, Object>>();
        for (Document doc : docs) {
            String id = doc.getObjectId("_id").toHexString();
            Map<String, Object> item = publicUser(doc);
            Integer count = sessionCounts.get(id);
            item.put("activeSessionsCount", Integer.valueOf(count != null ? count.intValue() : 0));
            resultado.add(item);
        }
        resp.enviarJson(200, Json.escrever(resultado));
    }

    private void tratarBuscarUsuario(RespostaHttp resp, String userId) throws IOException {
        Document user = repositorio.buscarDocumentoPorId(userId);
        if (user == null) {
            enviarErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }
        resp.enviarJson(200, Json.escrever(publicUser(user)));
    }

    private void tratarCriarUsuario(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        String identity = getString(body, "identity");
        String email = getString(body, "email");
        String displayName = getString(body, "displayName");
        String profile = getString(body, "profile");
        String password = getString(body, "password");
        String department = getString(body, "departmentOrCourse");
        boolean twoFactorRequired = Boolean.TRUE.equals(body.get("twoFactorRequired"));

        if (identity == null || identity.length() < 2 || identity.length() > 80) {
            enviarErro(resp, 400, "invalid_request", "Identidade institucional invalida.");
            return;
        }
        if (email == null || !email.contains("@") || email.length() > 254) {
            enviarErro(resp, 400, "invalid_request", "E-mail institucional invalido.");
            return;
        }
        if (displayName == null || displayName.length() < 2 || displayName.length() > 120) {
            enviarErro(resp, 400, "invalid_request", "Nome de exibicao invalido.");
            return;
        }
        if (profile == null || !PERFIS_PERMITIDOS.contains(profile.toLowerCase(Locale.ROOT))) {
            enviarErro(resp, 400, "invalid_request", "Perfil institucional invalido.");
            return;
        }
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(password);
        if (!validacao.isValido()) {
            enviarErro(resp, 400, "weak_password", validacao.getMensagem());
            return;
        }
        if (!repositorio.registrarEscritaAdmin(admin.getUserId())) {
            enviarErro(resp, 403, "forbidden", "Acesso administrativo revogado.");
            return;
        }

        String normalizedIdentity = identity.toLowerCase(Locale.ROOT);
        String normalizedEmail = email.toLowerCase(Locale.ROOT);
        String canonicalProfile = profile.toLowerCase(Locale.ROOT);

        Document duplicate = repositorio.getUsersCollection().find(
                Filters.or(
                        Filters.eq("normalizedIdentity", normalizedIdentity),
                        Filters.eq("email", normalizedEmail),
                        Filters.eq("email", normalizedIdentity),
                        Filters.eq("normalizedIdentity", normalizedEmail)
                )
        ).collation(CASE_INSENSITIVE).first();

        if (duplicate != null) {
            enviarErro(resp, 409, "user_exists", "E-mail ou identidade institucional ja cadastrado.");
            return;
        }

        Date agora = new Date();
        Document novo = new Document()
                .append("identity", identity)
                .append("normalizedIdentity", normalizedIdentity)
                .append("email", normalizedEmail)
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
            repositorio.getUsersCollection().insertOne(novo);
        } catch (MongoWriteException e) {
            enviarErro(resp, 409, "user_exists", "E-mail ou identidade institucional ja cadastrado.");
            return;
        }

        String newId = novo.getObjectId("_id").toHexString();
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("profile", canonicalProfile);
        repositorio.registrarAuditoria(admin.getUserId(), "user_created", newId, det);

        SmtpCliente.enviarBoasVindas(normalizedEmail, displayName, identity, canonicalProfile, password);
        resp.enviarJson(201, Json.escrever(publicUser(novo)));
    }

    private void tratarAtualizarUsuario(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        if (body == null || body.isEmpty()) {
            enviarErro(resp, 400, "invalid_request", "Informe ao menos um campo para atualizar.");
            return;
        }
        if (!repositorio.registrarEscritaAdmin(admin.getUserId())) {
            enviarErro(resp, 403, "forbidden", "Acesso administrativo revogado.");
            return;
        }

        Document existing = repositorio.buscarDocumentoPorId(userId);
        if (existing == null) {
            enviarErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }

        String newIdentity = getString(body, "identity");
        String newEmail = getString(body, "email");
        String newDisplayName = getString(body, "displayName");
        String newProfile = getString(body, "profile");
        String newDepartment = getString(body, "departmentOrCourse");
        Boolean newTwoFactor = body.get("twoFactorRequired") instanceof Boolean ? (Boolean) body.get("twoFactorRequired") : null;

        String currentProfile = existing.getString("profile");
        if (newProfile != null) {
            newProfile = newProfile.toLowerCase(Locale.ROOT);
            if (!PERFIS_PERMITIDOS.contains(newProfile)) {
                enviarErro(resp, 400, "invalid_request", "Perfil institucional invalido.");
                return;
            }
            if (!newProfile.equals(currentProfile) && "admin".equals(currentProfile)) {
                if (userId.equals(admin.getUserId())) {
                    enviarErro(resp, 409, "self_demotion", "Voce nao pode remover seu proprio perfil administrativo.");
                    return;
                }
                if (existing.getBoolean("active", false) && contarAdminsAtivos() <= 1) {
                    enviarErro(resp, 409, "last_admin", "Nao e possivel remover o ultimo administrador ativo.");
                    return;
                }
            }
            if (!newProfile.equals(currentProfile)) {
                Map<String, Object> vinculos = ponte.consultarVinculosUsuario(userId);
                if (Boolean.TRUE.equals(vinculos.get("hasActiveLinks"))) {
                    enviarErro(resp, 409, "linked_profile", "Remova os vinculos academicos ativos antes de alterar o perfil.");
                    return;
                }
            }
        }

        String finalIdentity = newIdentity != null ? newIdentity : existing.getString("identity");
        String finalNormalizedIdentity = finalIdentity != null ? finalIdentity.toLowerCase(Locale.ROOT) : "";
        String finalEmail = newEmail != null ? newEmail.toLowerCase(Locale.ROOT) : existing.getString("email");

        Document duplicate = repositorio.getUsersCollection().find(
                Filters.and(
                        Filters.ne("_id", new ObjectId(userId)),
                        Filters.or(
                                Filters.eq("normalizedIdentity", finalNormalizedIdentity),
                                Filters.eq("email", finalEmail),
                                Filters.eq("email", finalNormalizedIdentity),
                                Filters.eq("normalizedIdentity", finalEmail)
                        )
                )
        ).collation(CASE_INSENSITIVE).first();
        if (duplicate != null) {
            enviarErro(resp, 409, "user_exists", "E-mail ou identidade institucional ja cadastrado.");
            return;
        }

        boolean currentTwoFactor = existing.getBoolean("twoFactorRequired", false) || existing.getBoolean("twoFactorEnabled", false);
        boolean securityChanged =
                (newProfile != null && !newProfile.equals(currentProfile))
                || (newIdentity != null && !newIdentity.equals(existing.getString("identity")))
                || (newTwoFactor != null && newTwoFactor.booleanValue() != currentTwoFactor)
                || (newEmail != null && !newEmail.equalsIgnoreCase(existing.getString("email")));

        List<Bson> updates = new ArrayList<Bson>();
        if (newIdentity != null) {
            updates.add(Updates.set("identity", newIdentity));
            updates.add(Updates.set("normalizedIdentity", finalNormalizedIdentity));
        }
        if (newEmail != null) {
            updates.add(Updates.set("email", finalEmail));
        }
        if (newDisplayName != null) {
            updates.add(Updates.set("displayName", newDisplayName));
        }
        if (newProfile != null) {
            updates.add(Updates.set("profile", newProfile));
        }
        if (newDepartment != null) {
            updates.add(Updates.set("departmentOrCourse", newDepartment));
            updates.add(Updates.set("department", newDepartment));
        }
        if (newTwoFactor != null) {
            updates.add(Updates.set("twoFactorRequired", newTwoFactor));
            updates.add(Updates.set("twoFactorEnabled", newTwoFactor));
        }
        updates.add(Updates.set("updatedAt", new Date()));
        if (securityChanged) {
            updates.add(Updates.inc("sessionVersion", 1));
        }

        Document updated = repositorio.getUsersCollection().findOneAndUpdate(
                Filters.eq("_id", new ObjectId(userId)),
                Updates.combine(updates),
                new FindOneAndUpdateOptions().returnDocument(ReturnDocument.AFTER)
        );

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

        resp.enviarJson(200, Json.escrever(publicUser(updated != null ? updated : existing)));
    }

    private void tratarAtualizarStatus(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        if (body == null || !(body.get("active") instanceof Boolean)) {
            enviarErro(resp, 400, "invalid_request", "Campo booleano 'active' e obrigatorio.");
            return;
        }
        boolean active = ((Boolean) body.get("active")).booleanValue();
        String reason = getString(body, "reason");

        if (!repositorio.registrarEscritaAdmin(admin.getUserId())) {
            enviarErro(resp, 403, "forbidden", "Acesso administrativo revogado.");
            return;
        }

        Document existing = repositorio.buscarDocumentoPorId(userId);
        if (existing == null) {
            enviarErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }

        boolean currentlyActive = existing.getBoolean("active", false);
        if (!active && currentlyActive && "admin".equals(existing.getString("profile"))) {
            if (userId.equals(admin.getUserId())) {
                enviarErro(resp, 409, "self_suspension", "Voce nao pode suspender sua propria conta.");
                return;
            }
            if (contarAdminsAtivos() <= 1) {
                enviarErro(resp, 409, "last_admin", "Nao e possivel suspender o ultimo administrador ativo.");
                return;
            }
        }

        if (active == currentlyActive) {
            resp.enviarJson(200, Json.escrever(publicUser(existing)));
            return;
        }

        Document updated = repositorio.getUsersCollection().findOneAndUpdate(
                Filters.eq("_id", new ObjectId(userId)),
                Updates.combine(
                        Updates.set("active", Boolean.valueOf(active)),
                        Updates.set("suspensionReason", active ? null : reason),
                        Updates.set("updatedAt", new Date()),
                        Updates.inc("sessionVersion", 1)
                ),
                new FindOneAndUpdateOptions().returnDocument(ReturnDocument.AFTER)
        );
        repositorio.revogarTodasSessoes(userId);
        String oldNorm = existing.getString("normalizedIdentity");
        if (oldNorm != null) {
            repositorio.removerOtp(oldNorm, "RECOVERY");
        }
        repositorio.registrarAuditoria(admin.getUserId(), active ? "user_activated" : "user_suspended", userId, null);
        resp.enviarJson(200, Json.escrever(publicUser(updated != null ? updated : existing)));
    }

    private void tratarSessoesUsuario(RespostaHttp resp, String userId) throws IOException {
        if (repositorio.buscarDocumentoPorId(userId) == null) {
            enviarErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }
        List<Document> docs = repositorio.listarSessoesAtivas(userId);
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        for (Document s : docs) {
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("id", s.getObjectId("_id").toHexString());
            item.put("sessionId", s.getString("sessionId"));
            String ua = s.getString("userAgent");
            item.put("device", ua != null && !ua.isEmpty() ? ua : "Sessao Web / Desktop");
            String ip = s.getString("ipAddress");
            item.put("ipAddress", ip != null && !ip.isEmpty() ? ip : "127.0.0.1");
            item.put("createdAt", s.getDate("createdAt"));
            item.put("expiresAt", s.getDate("expiresAt"));
            lista.add(item);
        }
        resp.enviarJson(200, Json.escrever(lista));
    }

    private void tratarRevogarSessoesUsuario(RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        if (!repositorio.registrarEscritaAdmin(admin.getUserId())) {
            enviarErro(resp, 403, "forbidden", "Acesso administrativo revogado.");
            return;
        }
        long matched = repositorio.getUsersCollection().updateOne(
                Filters.eq("_id", new ObjectId(userId)),
                Updates.inc("sessionVersion", 1)
        ).getMatchedCount();
        if (matched == 0) {
            enviarErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }
        repositorio.revogarTodasSessoes(userId);
        repositorio.registrarAuditoria(admin.getUserId(), "sessions_revoked", userId, null);
        resp.enviar(204, "");
    }

    private void tratarResetarSenhaUsuario(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        if (!repositorio.registrarEscritaAdmin(admin.getUserId())) {
            enviarErro(resp, 403, "forbidden", "Acesso administrativo revogado.");
            return;
        }
        Map<String, Object> body = new LinkedHashMap<String, Object>();
        if (req.getCorpo() != null && !req.getCorpo().trim().isEmpty()) {
            body = Json.analisarObjeto(req.getCorpo());
        }
        boolean forceNextLogin = !(body.get("forceNextLogin") instanceof Boolean) || ((Boolean) body.get("forceNextLogin")).booleanValue();
        boolean revokeActiveSessions = !(body.get("revokeActiveSessions") instanceof Boolean) || ((Boolean) body.get("revokeActiveSessions")).booleanValue();

        Document existing = repositorio.buscarDocumentoAtivoPorId(userId);
        if (existing == null) {
            enviarErro(resp, 404, "user_not_found", "Usuario ativo nao encontrado.");
            return;
        }

        String identity = existing.getString("identity");
        String email = existing.getString("email");
        String displayName = existing.getString("displayName");

        String otpCode = OtpService.gerarCodigo();
        String otpSecret = ConfigEnv.obter("AUTH_OTP_SECRET",
                "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890");
        String otpHash = OtpService.hashOtp(otpCode, otpSecret);
        long ttlOtp = (long) ConfigEnv.obterInteiro("AUTH_OTP_TTL_SECONDS", 300) * 1000L;
        long expira = System.currentTimeMillis() + ttlOtp;

        if (identity != null && !identity.isEmpty()) {
            repositorio.salvarOtp(identity, otpHash, "RECOVERY", expira);
        }
        if (email != null && !email.isEmpty()) {
            repositorio.salvarOtp(email, otpHash, "RECOVERY", expira);
            SmtpCliente.enviarRecuperacao(email, otpCode, displayName);
        }

        List<Bson> updates = new ArrayList<Bson>();
        updates.add(Updates.set("requirePasswordChange", Boolean.valueOf(forceNextLogin)));
        updates.add(Updates.set("updatedAt", new Date()));
        if (revokeActiveSessions) {
            updates.add(Updates.inc("sessionVersion", 1));
        }

        long matched = repositorio.getUsersCollection().updateOne(
                Filters.and(Filters.eq("_id", new ObjectId(userId)), Filters.eq("active", Boolean.TRUE)),
                Updates.combine(updates)
        ).getMatchedCount();
        if (matched == 0) {
            enviarErro(resp, 409, "account_changed", "Conta alterada durante a solicitacao.");
            return;
        }
        if (revokeActiveSessions) {
            repositorio.revogarTodasSessoes(userId);
        }
        repositorio.registrarAuditoria(admin.getUserId(), "password_recovery_requested", userId, null);

        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("message", "Codigo de recuperacao enviado ao e-mail cadastrado.");
        resp.enviarJson(202, Json.escrever(ok));
    }

    private void tratarDossieUsuario(RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        Document user = repositorio.buscarDocumentoPorId(userId);
        if (user == null) {
            enviarErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }

        Map<String, Object> academic = ponte.obterDadosLgpdUsuario(userId);

        List<Document> logDocs = repositorio.listarLogsSeguranca(userId, 100);
        List<Map<String, Object>> auditLogs = new ArrayList<Map<String, Object>>();
        for (Document doc : logDocs) {
            Map<String, Object> item = RepositorioUsuarios.documentoParaMapa(doc);
            item.put("id", doc.getObjectId("_id").toHexString());
            item.remove("_id");
            auditLogs.add(item);
        }

        repositorio.registrarAuditoria(admin.getUserId(), "dossier_viewed", userId, null);

        Object classesList = academic.get("classes") instanceof List ? academic.get("classes")
                : (academic.get("teachingClasses") instanceof List ? academic.get("teachingClasses") : Collections.emptyList());

        Map<String, Object> dossier = new LinkedHashMap<String, Object>();
        dossier.put("user", publicUser(user));
        dossier.put("classes", classesList);
        dossier.put("enrollments", academic.get("enrollments") instanceof List ? academic.get("enrollments") : Collections.emptyList());
        dossier.put("protocols", academic.get("protocols") instanceof List ? academic.get("protocols") : Collections.emptyList());
        dossier.put("grades", academic.get("grades") instanceof List ? academic.get("grades") : Collections.emptyList());
        dossier.put("auditLogs", auditLogs);

        resp.enviarJson(200, Json.escrever(dossier));
    }

    private void tratarCriarDocente(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        String name = getString(body, "name");
        if (name == null) name = getString(body, "displayName");
        String email = getString(body, "email");
        String department = getString(body, "department");
        if (department == null) department = getString(body, "departmentOrCourse");

        if (name == null || name.length() < 2 || email == null || !email.contains("@") || department == null || department.length() < 2) {
            enviarErro(resp, 400, "invalid_request", "Dados do docente invalidos.");
            return;
        }
        String normalizedEmail = email.toLowerCase(Locale.ROOT);
        Document existingEmail = repositorio.getUsersCollection().find(
                Filters.eq("email", normalizedEmail)
        ).collation(CASE_INSENSITIVE).first();
        if (existingEmail != null) {
            enviarErro(resp, 409, "email_exists", "Ja existe uma conta com esse e-mail.");
            return;
        }

        byte[] idBytes = new byte[5];
        RANDOM.nextBytes(idBytes);
        StringBuilder hex = new StringBuilder("DOC-");
        for (byte b : idBytes) hex.append(String.format("%02X", b & 0xff));
        String identity = hex.toString();

        String tempPassword = String.format("Agmrm@%06d", RANDOM.nextInt(1000000));
        Date agora = new Date();
        Document teacher = new Document()
                .append("identity", identity)
                .append("normalizedIdentity", identity.toLowerCase(Locale.ROOT))
                .append("email", normalizedEmail)
                .append("displayName", name)
                .append("profile", "docente")
                .append("passwordHash", SenhaHasher.hash(tempPassword))
                .append("active", Boolean.TRUE)
                .append("sessionVersion", Integer.valueOf(0))
                .append("requirePasswordChange", Boolean.TRUE)
                .append("twoFactorRequired", Boolean.FALSE)
                .append("twoFactorEnabled", Boolean.FALSE)
                .append("department", department)
                .append("departmentOrCourse", department)
                .append("createdBy", admin.getUserId())
                .append("createdAt", agora)
                .append("updatedAt", agora);

        try {
            repositorio.getUsersCollection().insertOne(teacher);
        } catch (MongoWriteException e) {
            enviarErro(resp, 409, "identity_exists", "Nao foi possivel gerar uma identidade unica. Tente novamente.");
            return;
        }

        repositorio.registrarAuditoria(admin.getUserId(), "teacher_created", teacher.getObjectId("_id").toHexString(), null);
        SmtpCliente.enviarBoasVindas(normalizedEmail, name, identity, "docente", tempPassword);

        Map<String, Object> result = new LinkedHashMap<String, Object>();
        result.put("identity", identity);
        result.put("name", name);
        result.put("email", normalizedEmail);
        result.put("department", department);
        result.put("profile", "docente");
        resp.enviarJson(201, Json.escrever(result));
    }

    private long contarAdminsAtivos() {
        return repositorio.getUsersCollection().countDocuments(
                Filters.and(Filters.eq("profile", "admin"), Filters.eq("active", Boolean.TRUE))
        );
    }

    private Map<String, Integer> contarSessoesAtivasPorUsuario(List<Document> users) {
        Map<String, Integer> counts = new HashMap<String, Integer>();
        if (users.isEmpty()) return counts;
        List<String> ids = new ArrayList<String>();
        for (Document u : users) {
            ids.add(u.getObjectId("_id").toHexString());
        }
        MongoCollection<Document> sessions = repositorio.getSessionsCollection();
        List<Document> activeSessions = new ArrayList<Document>();
        sessions.find(
                Filters.and(
                        Filters.in("userId", ids),
                        Filters.ne("active", false),
                        Filters.gt("expiresAt", new Date())
                )
        ).into(activeSessions);

        for (Document s : activeSessions) {
            String uid = s.getString("userId");
            if (uid != null) {
                Integer current = counts.get(uid);
                counts.put(uid, Integer.valueOf((current != null ? current.intValue() : 0) + 1));
            }
        }
        return counts;
    }

    public static Map<String, Object> publicUser(Document document) {
        Map<String, Object> map = new LinkedHashMap<String, Object>();
        map.put("id", document.getObjectId("_id").toHexString());
        map.put("identity", document.getString("identity") != null ? document.getString("identity") : document.getString("normalizedIdentity"));
        map.put("email", document.getString("email"));
        map.put("displayName", document.getString("displayName"));
        map.put("profile", document.getString("profile"));
        map.put("active", Boolean.valueOf(document.getBoolean("active", false)));
        String dept = document.getString("departmentOrCourse");
        if (dept == null) dept = document.getString("department");
        map.put("departmentOrCourse", dept != null ? dept : "");
        boolean twoFa = document.getBoolean("twoFactorRequired", false) || document.getBoolean("twoFactorEnabled", false);
        map.put("twoFactorRequired", Boolean.valueOf(twoFa));
        map.put("suspensionReason", document.get("suspensionReason"));
        Date lastLogin = document.getDate("lastLogin") != null ? document.getDate("lastLogin") : document.getDate("lastLoginAt");
        map.put("lastLogin", lastLogin);
        map.put("requirePasswordChange", Boolean.valueOf(document.getBoolean("requirePasswordChange", false)));
        return map;
    }

    private static int parseIntBounded(String raw, int defaultVal, int min, int max) {
        if (raw == null || raw.trim().isEmpty()) return defaultVal;
        try {
            int val = Integer.parseInt(raw.trim());
            return Math.max(min, Math.min(max, val));
        } catch (NumberFormatException e) {
            return defaultVal;
        }
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
