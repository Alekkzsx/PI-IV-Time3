// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.conta;

import auth.abstratas.HandlerAutenticadoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import bridge.ClientePonteAcademica;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.BsonUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Handler de perfil e privacidade (LGPD) do usuario autenticado.
 * Rotas: PATCH /api/auth/profile e GET /api/auth/lgpd-export
 */
public class ProfileHandler extends HandlerAutenticadoAbstrato {
    private static final Set<String> CAMPOS_PERFIL_PERMITIDOS = new HashSet<String>(Arrays.asList(
            "displayName", "socialName", "phone", "personalEmail", "biography",
            "departmentOrCourse", "department", "campus", "semester", "shift", "preferences"
    ));

    private final ClientePonteAcademica ponte;

    public ProfileHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        super(repositorio);
        this.ponte = ponte != null ? ponte : new ClientePonteAcademica();
    }

    @Override
    protected String tagLog() {
        return "ACCOUNT-PROFILE";
    }

    @Override
    protected void processarAutenticado(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws Exception {
        String metodo = req.getMetodo().toUpperCase(Locale.ROOT);
        String caminho = req.getCaminho();
        if ("/api/auth/profile".equals(caminho) && "PATCH".equals(metodo)) {
            tratarAtualizacaoPerfil(req, resp, usuario);
        } else if ("/api/auth/lgpd-export".equals(caminho) && "GET".equals(metodo)) {
            tratarExportacaoLgpd(resp, usuario);
        } else {
            responderErro(resp, 405, "method_not_allowed", "Metodo nao permitido para este endpoint.");
        }
    }

    private void tratarAtualizacaoPerfil(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        if (body.isEmpty()) {
            responderErro(resp, 400, "invalid_request", "Informe ao menos um campo para atualizar.");
            return;
        }
        Map<String, Object> setFields = new LinkedHashMap<String, Object>();
        for (Map.Entry<String, Object> entry : body.entrySet()) {
            String key = entry.getKey();
            if (!CAMPOS_PERFIL_PERMITIDOS.contains(key)) {
                responderErro(resp, 400, "invalid_field", "Campo nao permitido no perfil: " + key);
                return;
            }
            Object value = entry.getValue();
            if ("preferences".equals(key)) {
                if (!(value instanceof Map)) {
                    responderErro(resp, 400, "invalid_preferences", "Campo 'preferences' deve ser um objeto JSON.");
                    return;
                }
                setFields.put("preferences", value);
            } else if (value instanceof String) {
                String texto = ((String) value).trim();
                if ("displayName".equals(key) && (texto.length() < 2 || texto.length() > 120)) {
                    responderErro(resp, 400, "invalid_display_name", "Nome completo deve ter entre 2 e 120 caracteres.");
                    return;
                }
                setFields.put(key, texto);
            } else if (value != null) {
                responderErro(resp, 400, "invalid_field", "Valor invalido para o campo: " + key);
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
            responderErro(resp, 404, "user_not_found", "Conta nao encontrada.");
            return;
        }
        if (setFields.get("displayName") instanceof String) {
            ponte.sincronizarUsuario(usuario.getUserId(), null, (String) setFields.get("displayName"));
        }
        UsuarioAutenticado atualizado = repositorio.buscarPorId(usuario.getUserId());
        enviarJson(resp, 200, AuthHttpUtils.montarPerfilPublico(atualizado != null ? atualizado : usuario, updated));
    }

    private void tratarExportacaoLgpd(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Document userDoc = repositorio.buscarDocumentoPorId(usuario.getUserId());
        Map<String, Object> academic = ponte.obterDadosLgpdUsuario(usuario.getUserId());

        List<Map<String, Object>> activeSessions = new ArrayList<Map<String, Object>>();
        for (Document s : repositorio.listarSessoesAtivas(usuario.getUserId())) {
            Map<String, Object> m = new LinkedHashMap<String, Object>();
            m.put("sessionId", s.getString("sessionId"));
            m.put("createdAt", s.getDate("createdAt"));
            m.put("expiresAt", s.getDate("expiresAt"));
            activeSessions.add(m);
        }

        List<Map<String, Object>> auditTrail = new ArrayList<Map<String, Object>>();
        for (Document d : repositorio.listarLogsSeguranca(usuario.getUserId(), 100)) {
            Map<String, Object> item = BsonUtils.documentoParaMapa(d);
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
        export.put("enrollments", listaOuVazia(academic.get("enrollments")));
        export.put("teachingClasses", listaOuVazia(academic.get("teachingClasses")));
        export.put("submissions", listaOuVazia(academic.get("submissions")));
        export.put("protocols", listaOuVazia(academic.get("protocols")));
        export.put("activeSessions", activeSessions);
        export.put("auditTrail", auditTrail);
        enviarJson(resp, 200, export);
    }

    private static Object listaOuVazia(Object valor) {
        return valor instanceof List ? valor : Collections.emptyList();
    }
}
