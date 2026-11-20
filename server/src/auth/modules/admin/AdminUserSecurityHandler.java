// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira
package auth.modules.admin;

import auth.abstratas.AdminHandlerAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.email.SmtpCliente;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import auth.utils.OtpService;
import bridge.ClientePonteAcademica;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;

import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Handler administrativo de operacoes de seguranca sobre usuarios:
 * - GET  /api/admin/users/{id}/sessions
 * - POST /api/admin/users/{id}/revoke-sessions
 * - POST /api/admin/users/{id}/reset-password
 */
public class AdminUserSecurityHandler extends AdminHandlerAbstrato {

    public AdminUserSecurityHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        super(repositorio, ponte);
    }

    @Override
    protected void processarAutenticado(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws Exception {
        String[] partes = extrairSegmentosUsuario(req.getCaminho(), resp);
        if (partes == null || partes.length != 2) {
            if (partes != null) responderErro(resp, 404, "not_found", "Rota administrativa nao encontrada.");
            return;
        }
        String userId = partes[0];
        String acao = partes[1].trim();
        String metodo = req.getMetodo().toUpperCase(Locale.ROOT);

        if ("sessions".equals(acao) && "GET".equals(metodo)) {
            tratarSessoesUsuario(resp, userId);
        } else if ("revoke-sessions".equals(acao) && "POST".equals(metodo)) {
            tratarRevogarSessoes(resp, admin, userId);
        } else if ("reset-password".equals(acao) && "POST".equals(metodo)) {
            tratarResetarSenha(req, resp, admin, userId);
        } else {
            responderErro(resp, 404, "not_found", "Rota administrativa nao encontrada.");
        }
    }

    private void tratarSessoesUsuario(RespostaHttp resp, String userId) throws IOException {
        if (repositorio.buscarDocumentoPorId(userId) == null) {
            responderErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        for (Document s : repositorio.listarSessoesAtivas(userId)) {
            String ua = s.getString("userAgent");
            String ip = s.getString("ipAddress");
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("id", s.getObjectId("_id").toHexString());
            item.put("sessionId", s.getString("sessionId"));
            item.put("device", ua != null && !ua.isEmpty() ? ua : "Sessao Web / Desktop");
            item.put("ipAddress", ip != null && !ip.isEmpty() ? ip : "127.0.0.1");
            item.put("createdAt", s.getDate("createdAt"));
            item.put("expiresAt", s.getDate("expiresAt"));
            lista.add(item);
        }
        enviarJson(resp, 200, lista);
    }

    private void tratarRevogarSessoes(
            RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        if (!exigirEscritaAdmin(admin, resp)) return;
        if (repositorio.incrementarSessionVersion(userId) == 0) {
            responderErro(resp, 404, "user_not_found", "Usuario nao encontrado.");
            return;
        }
        repositorio.revogarTodasSessoes(userId);
        repositorio.registrarAuditoria(admin.getUserId(), "sessions_revoked", userId, null);
        resp.enviar(204, "");
    }

    private void tratarResetarSenha(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin, String userId) throws IOException {
        if (!exigirEscritaAdmin(admin, resp)) return;

        Map<String, Object> body = lerJsonObjetoOpcional(req);
        boolean forceNextLogin = !(body.get("forceNextLogin") instanceof Boolean)
                || ((Boolean) body.get("forceNextLogin")).booleanValue();
        boolean revokeActiveSessions = !(body.get("revokeActiveSessions") instanceof Boolean)
                || ((Boolean) body.get("revokeActiveSessions")).booleanValue();

        Document existing = repositorio.buscarDocumentoAtivoPorId(userId);
        if (existing == null) {
            responderErro(resp, 404, "user_not_found", "Usuario ativo nao encontrado.");
            return;
        }

        String identity = existing.getString("identity");
        String email = existing.getString("email");
        String displayName = existing.getString("displayName");
        if (!SmtpCliente.isEmailValido(email)) {
            responderErro(resp, 422, "email_not_registered",
                    "Usuario nao possui um e-mail valido cadastrado no sistema.");
            return;
        }

        String normalizedEmail = email.trim().toLowerCase(Locale.ROOT);
        String otpCode = OtpService.gerarCodigo();
        String otpHash = OtpService.hashOtp(otpCode, AuthHttpUtils.obterSegredoOtp());
        long expira = System.currentTimeMillis() + (long) AuthHttpUtils.obterTtlOtpSegundos() * 1000L;

        if (identity != null && !identity.isEmpty()) {
            repositorio.salvarOtp(identity, otpHash, "RECOVERY", expira);
        }
        repositorio.salvarOtp(normalizedEmail, otpHash, "RECOVERY", expira);
        SmtpCliente.enviarRecuperacaoComResultado(normalizedEmail, otpCode, displayName)
                .whenComplete((resultado, erro) -> repositorio.registrarResultadoEnvioEmail(
                        admin.getUserId(), "admin_recovery_email", normalizedEmail, resultado, erro));

        if (repositorio.atualizarResetSenhaAdmin(userId, forceNextLogin, revokeActiveSessions) == 0) {
            responderErro(resp, 409, "account_changed", "Conta alterada durante a solicitacao.");
            return;
        }
        if (revokeActiveSessions) {
            repositorio.revogarTodasSessoes(userId);
        }
        repositorio.registrarAuditoria(admin.getUserId(), "password_recovery_requested", userId, null);

        Map<String, Object> ok = new LinkedHashMap<String, Object>();
        ok.put("message", "Codigo de recuperacao enviado ao e-mail cadastrado.");
        enviarJson(resp, 202, ok);
    }
}
