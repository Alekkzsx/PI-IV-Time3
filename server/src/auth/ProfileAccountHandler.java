// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import bridge.ClientePonteAcademica;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.Json;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Handler unificado para endpoints autenticados de conta, perfil, sessoes, 2FA, logs de seguranca e LGPD:
 * - PATCH  /api/auth/profile
 * - GET    /api/auth/sessions
 * - DELETE /api/auth/sessions/{sessionId}
 * - POST   /api/auth/logout-others
 * - POST   /api/auth/two-factor
 * - POST   /api/auth/backup-codes
 * - GET    /api/auth/security-logs
 * - GET    /api/auth/lgpd-export
 */
public class ProfileAccountHandler implements ManipuladorHttp {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final Set<String> CAMPOS_PERFIL_PERMITIDOS = new HashSet<String>(Arrays.asList(
            "displayName", "socialName", "phone", "personalEmail", "biography",
            "departmentOrCourse", "department", "campus", "semester", "shift", "preferences"
    ));

    private final RepositorioUsuarios repositorio;
    private final ClientePonteAcademica ponte;

    public ProfileAccountHandler() {
        this(RepositorioUsuarios.getInstance(), new ClientePonteAcademica());
    }

    public ProfileAccountHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
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

        String metodo = requisicao.getMetodo().toUpperCase();
        String caminho = requisicao.getCaminho();

        try {
            UsuarioAutenticado usuario = JwtAuthValidator.autenticarObrigatorio(requisicao, this.repositorio, false);

            if ("/api/auth/profile".equals(caminho) && "PATCH".equals(metodo)) {
                tratarAtualizacaoPerfil(requisicao, resposta, usuario);
            } else if ("/api/auth/sessions".equals(caminho) && "GET".equals(metodo)) {
                tratarListarSessoes(resposta, usuario);
            } else if (caminho.startsWith("/api/auth/sessions/") && "DELETE".equals(metodo)) {
                String sessionId = caminho.substring("/api/auth/sessions/".length()).trim();
                tratarRevogarSessao(resposta, usuario, sessionId);
            } else if ("/api/auth/logout-others".equals(caminho) && "POST".equals(metodo)) {
                tratarLogoutOutras(resposta, usuario);
            } else if ("/api/auth/two-factor".equals(caminho) && "POST".equals(metodo)) {
                tratarAlternarDoisFatores(requisicao, resposta, usuario);
            } else if ("/api/auth/backup-codes".equals(caminho) && "POST".equals(metodo)) {
                tratarGerarBackupCodes(resposta, usuario);
            } else if ("/api/auth/security-logs".equals(caminho) && "GET".equals(metodo)) {
                tratarLogsSeguranca(resposta, usuario);
            } else if ("/api/auth/lgpd-export".equals(caminho) && "GET".equals(metodo)) {
                tratarExportacaoLgpd(resposta, usuario);
            } else {
                enviarErro(resposta, 405, "method_not_allowed", "Metodo nao permitido para este endpoint.");
            }
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
            System.err.println("[ACCOUNT] Erro inesperado: " + e.getMessage());
            enviarErro(resposta, 500, "internal_error", "Erro interno no servidor.");
        }
    }

    @SuppressWarnings("unchecked")
    private void tratarAtualizacaoPerfil(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        if (body == null || body.isEmpty()) {
            enviarErro(resp, 400, "invalid_request", "Informe ao menos um campo para atualizar.");
            return;
        }
        Map<String, Object> setFields = new LinkedHashMap<String, Object>();
        for (Map.Entry<String, Object> entry : body.entrySet()) {
            String key = entry.getKey();
            if (!CAMPOS_PERFIL_PERMITIDOS.contains(key)) {
                enviarErro(resp, 400, "invalid_field", "Campo nao permitido no perfil: " + key);
                return;
            }
            Object value = entry.getValue();
            if ("preferences".equals(key)) {
                if (!(value instanceof Map)) {
                    enviarErro(resp, 400, "invalid_preferences", "Campo 'preferences' deve ser um objeto JSON.");
                    return;
                }
                setFields.put("preferences", value);
            } else if (value instanceof String) {
                String texto = ((String) value).trim();
                if ("displayName".equals(key) && (texto.length() < 2 || texto.length() > 120)) {
                    enviarErro(resp, 400, "invalid_display_name", "Nome completo deve ter entre 2 e 120 caracteres.");
                    return;
                }
                setFields.put(key, texto);
            } else if (value != null) {
                enviarErro(resp, 400, "invalid_field", "Valor invalido para o campo: " + key);
                return;
            }
        }
        if (setFields.containsKey("department") && !setFields.containsKey("departmentOrCourse")) {
            setFields.put("departmentOrCourse", setFields.get("department"));
        }
        if (setFields.containsKey("departmentOrCourse") && !setFields.containsKey("department")) {
            setFields.put("department", setFields.get("departmentOrCourse"));
        }

        Document updated = repositorio.atualizarPerfil(usuario.getUserId(), setFields);
        if (updated == null) {
            enviarErro(resp, 404, "user_not_found", "Conta nao encontrada.");
            return;
        }

        if (setFields.get("displayName") instanceof String) {
            ponte.sincronizarUsuario(usuario.getUserId(), null, (String) setFields.get("displayName"));
        }

        UsuarioAutenticado atualizado = repositorio.buscarPorId(usuario.getUserId());
        Map<String, Object> payload = AuthSessionHandler.montarPerfilPublico(atualizado != null ? atualizado : usuario, updated);
        resp.enviarJson(200, Json.escrever(payload));
    }

    private void tratarListarSessoes(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<Document> docs = repositorio.listarSessoesAtivas(usuario.getUserId());
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        for (Document doc : docs) {
            String sid = doc.getString("sessionId");
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("id", sid);
            item.put("sessionId", sid);
            String ua = doc.getString("userAgent");
            item.put("device", ua != null && !ua.isEmpty() ? ua : "Sessao Web / Desktop");
            String ip = doc.getString("ipAddress");
            item.put("ipAddress", ip != null && !ip.isEmpty() ? ip : "127.0.0.1");
            item.put("createdAt", doc.getDate("createdAt"));
            item.put("expiresAt", doc.getDate("expiresAt"));
            item.put("current", Boolean.valueOf(sid != null && sid.equals(usuario.getSessionId())));
            lista.add(item);
        }
        resp.enviarJson(200, Json.escrever(lista));
    }

    private void tratarRevogarSessao(RespostaHttp resp, UsuarioAutenticado usuario, String sessionId) throws IOException {
        if (sessionId == null || sessionId.isEmpty()) {
            enviarErro(resp, 400, "invalid_session", "Sessao invalida.");
            return;
        }
        String decoded = sessionId;
        try {
            decoded = java.net.URLDecoder.decode(sessionId, "UTF-8");
        } catch (Exception ignored) { }
        repositorio.revogarSessaoUsuario(usuario.getUserId(), decoded);
        RevogacaoTokens.getInstance().revogar(decoded, System.currentTimeMillis() + 86_400_000L);
        resp.enviar(204, "");
    }

    private void tratarLogoutOutras(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        repositorio.revogarOutrasSessoes(usuario.getUserId(), usuario.getSessionId());
        resp.enviar(204, "");
    }

    private void tratarAlternarDoisFatores(RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = Json.analisarObjeto(req.getCorpo());
        if (body == null || !(body.get("password") instanceof String) || !(body.get("enabled") instanceof Boolean)) {
            enviarErro(resp, 400, "invalid_request", "Campos 'password' e 'enabled' sao obrigatorios.");
            return;
        }
        String password = (String) body.get("password");
        boolean enabled = ((Boolean) body.get("enabled")).booleanValue();

        if (!repositorio.verificarSenhaAtual(usuario.getUserId(), password)) {
            enviarErro(resp, 401, "invalid_password", "Senha atual incorreta.");
            return;
        }
        if (!repositorio.atualizarDoisFatores(usuario.getUserId(), enabled)) {
            enviarErro(resp, 409, "account_changed", "Conta alterada. Entre novamente.");
            return;
        }
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("enabled", Boolean.valueOf(enabled));
        repositorio.registrarAuditoria(usuario.getUserId(), "two_factor_updated", usuario.getUserId(), det);
        resp.enviar(204, "");
    }

    private void tratarGerarBackupCodes(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<String> codes = new ArrayList<String>();
        List<String> digests = new ArrayList<String>();
        for (int i = 0; i < 6; i++) {
            String code = String.format("AGMRM-%04X-%04X", RANDOM.nextInt(0x10000), RANDOM.nextInt(0x10000));
            codes.add(code);
            digests.add(OtpService.sha256Hex(code));
        }
        repositorio.salvarCodigosBackup(usuario.getUserId(), digests);
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("count", Integer.valueOf(codes.size()));
        repositorio.registrarAuditoria(usuario.getUserId(), "backup_codes_generated", usuario.getUserId(), det);

        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("codes", codes);
        resp.enviarJson(200, Json.escrever(payload));
    }

    private void tratarLogsSeguranca(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<Document> logs = repositorio.listarLogsSeguranca(usuario.getUserId(), 25);
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        for (Document doc : logs) {
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("id", doc.getObjectId("_id").toHexString());
            item.put("action", doc.getString("action"));
            item.put("createdAt", doc.getDate("createdAt"));
            String ip = doc.getString("ipAddress");
            item.put("ipAddress", ip != null && !ip.isEmpty() ? ip : "127.0.0.1");
            Object det = doc.get("details");
            item.put("details", det instanceof Document ? RepositorioUsuarios.documentoParaMapa(det) : new LinkedHashMap<String, Object>());
            lista.add(item);
        }
        resp.enviarJson(200, Json.escrever(lista));
    }

    private void tratarExportacaoLgpd(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Document userDoc = repositorio.buscarDocumentoPorId(usuario.getUserId());
        Map<String, Object> academic = ponte.obterDadosLgpdUsuario(usuario.getUserId());

        List<Document> sessionDocs = repositorio.listarSessoesAtivas(usuario.getUserId());
        List<Map<String, Object>> activeSessions = new ArrayList<Map<String, Object>>();
        for (Document s : sessionDocs) {
            Map<String, Object> m = new LinkedHashMap<String, Object>();
            m.put("sessionId", s.getString("sessionId"));
            m.put("createdAt", s.getDate("createdAt"));
            m.put("expiresAt", s.getDate("expiresAt"));
            activeSessions.add(m);
        }

        List<Document> logDocs = repositorio.listarLogsSeguranca(usuario.getUserId(), 100);
        List<Map<String, Object>> auditTrail = new ArrayList<Map<String, Object>>();
        for (Document d : logDocs) {
            Map<String, Object> item = RepositorioUsuarios.documentoParaMapa(d);
            item.put("id", d.getObjectId("_id").toHexString());
            item.remove("_id");
            auditTrail.add(item);
        }

        Map<String, Object> holder = new LinkedHashMap<String, Object>();
        holder.put("id", usuario.getUserId());
        holder.put("identity", usuario.getIdentity());
        holder.put("displayName", usuario.getDisplayName());
        holder.put("socialName", usuario.getSocialName());
        holder.put("email", usuario.getEmail());
        holder.put("personalEmail", usuario.getPersonalEmail());
        holder.put("phone", usuario.getPhone());
        holder.put("profile", usuario.getProfile());
        holder.put("departmentOrCourse", usuario.getDepartmentOrCourse());
        holder.put("preferences", usuario.getPreferences());
        if (userDoc != null && userDoc.getDate("createdAt") != null) {
            holder.put("createdAt", userDoc.getDate("createdAt"));
        }

        Map<String, Object> export = new LinkedHashMap<String, Object>();
        export.put("exportedAt", new Date());
        export.put("holder", holder);
        export.put("enrollments", academic.get("enrollments") instanceof List ? academic.get("enrollments") : Collections.emptyList());
        export.put("teachingClasses", academic.get("teachingClasses") instanceof List ? academic.get("teachingClasses") : Collections.emptyList());
        export.put("submissions", academic.get("submissions") instanceof List ? academic.get("submissions") : Collections.emptyList());
        export.put("protocols", academic.get("protocols") instanceof List ? academic.get("protocols") : Collections.emptyList());
        export.put("activeSessions", activeSessions);
        export.put("auditTrail", auditTrail);

        resp.enviarJson(200, Json.escrever(export));
    }

    private void enviarErro(RespostaHttp resposta, int status, String codigo, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("code", codigo);
        erro.put("message", mensagem);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
