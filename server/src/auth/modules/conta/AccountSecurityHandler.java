// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package auth.modules.conta;

import auth.abstratas.HandlerAutenticadoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.OtpService;
import auth.utils.RevogacaoTokens;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.BsonUtils;

import java.io.IOException;
import java.net.URLDecoder;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Handler de seguranca da conta autenticada: sessoes ativas, logout remoto, 2FA,
 * codigos de backup e historico de logs de seguranca.
 */
public class AccountSecurityHandler extends HandlerAutenticadoAbstrato {
    // SecureRandom para os codigos de backup (nao Math.random: previsibilidade = conta comprometida).
    private static final SecureRandom RANDOM = new SecureRandom();

    public AccountSecurityHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected String tagLog() {
        return "ACCOUNT-SECURITY";
    }

    /**
     * Tabela de rotas do grupo seguranca:
     * GET /sessions | DELETE /sessions/{id} | POST /logout-others |
     * POST /two-factor | POST /backup-codes | GET /security-logs.
     */
    @Override
    protected void processarAutenticado(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws Exception {
        String metodo = req.getMetodo().toUpperCase(Locale.ROOT);
        String caminho = req.getCaminho();

        if ("/api/auth/sessions".equals(caminho) && "GET".equals(metodo)) {
            tratarListarSessoes(resp, usuario);
        } else if (caminho.startsWith("/api/auth/sessions/") && "DELETE".equals(metodo)) {
            tratarRevogarSessao(resp, usuario, caminho.substring("/api/auth/sessions/".length()).trim());
        } else if ("/api/auth/logout-others".equals(caminho) && "POST".equals(metodo)) {
            repositorio.revogarOutrasSessoes(usuario.getUserId(), usuario.getSessionId());
            resp.enviar(204, "");
        } else if ("/api/auth/two-factor".equals(caminho) && "POST".equals(metodo)) {
            tratarAlternarDoisFatores(req, resp, usuario);
        } else if ("/api/auth/backup-codes".equals(caminho) && "POST".equals(metodo)) {
            tratarGerarBackupCodes(resp, usuario);
        } else if ("/api/auth/security-logs".equals(caminho) && "GET".equals(metodo)) {
            tratarLogsSeguranca(resp, usuario);
        } else {
            responderErro(resp, 405, "method_not_allowed", "Metodo nao permitido para este endpoint.");
        }
    }

    /** Lista sessoes ativas com device/IP e flag current (compara com o jti desta requisicao). */
    private void tratarListarSessoes(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        for (Document doc : repositorio.listarSessoesAtivas(usuario.getUserId())) {
            String sid = doc.getString("sessionId");
            String ua = doc.getString("userAgent");
            String ip = doc.getString("ipAddress");
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("id", sid);
            item.put("sessionId", sid);
            item.put("device", ua != null && !ua.isEmpty() ? ua : "Sessao Web / Desktop");
            item.put("ipAddress", ip != null && !ip.isEmpty() ? ip : "127.0.0.1");
            item.put("createdAt", doc.getDate("createdAt"));
            item.put("expiresAt", doc.getDate("expiresAt"));
            item.put("current", Boolean.valueOf(sid != null && sid.equals(usuario.getSessionId())));
            lista.add(item);
        }
        enviarJson(resp, 200, lista);
    }

    /**
     * DELETE /sessions/{id}: revoga a sessao escolhida no Mongo e coloca o jti na blacklist.
     * O horizonte de 24h na blacklist e so um teto defensivo de limpeza - quem manda na
     * validade real e o exp do proprio JWT.
     */
    private void tratarRevogarSessao(RespostaHttp resp, UsuarioAutenticado usuario, String sessionId) throws IOException {
        if (sessionId == null || sessionId.isEmpty()) {
            responderErro(resp, 400, "invalid_session", "Sessao invalida.");
            return;
        }
        String decoded = sessionId;
        try {
            decoded = URLDecoder.decode(sessionId, "UTF-8");
        } catch (Exception ignored) { }
        repositorio.revogarSessaoUsuario(usuario.getUserId(), decoded);
        RevogacaoTokens.getInstance().revogar(decoded, System.currentTimeMillis() + 86_400_000L);
        resp.enviar(204, "");
    }

    /**
     * POST /two-factor: liga/desliga o 2FA exigindo REAUTENTICACAO com a senha atual
     * (step-up: sessao roubada sem a senha nao consegue desativar o segundo fator).
     */
    private void tratarAlternarDoisFatores(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        Map<String, Object> body = lerJsonObjeto(req);
        if (!(body.get("password") instanceof String) || !(body.get("enabled") instanceof Boolean)) {
            responderErro(resp, 400, "invalid_request", "Campos 'password' e 'enabled' sao obrigatorios.");
            return;
        }
        String password = (String) body.get("password");
        boolean enabled = ((Boolean) body.get("enabled")).booleanValue();

        if (!repositorio.verificarSenhaAtual(usuario.getUserId(), password)) {
            responderErro(resp, 401, "invalid_password", "Senha atual incorreta.");
            return;
        }
        if (!repositorio.atualizarDoisFatores(usuario.getUserId(), enabled)) {
            responderErro(resp, 409, "account_changed", "Conta alterada. Entre novamente.");
            return;
        }
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("enabled", Boolean.valueOf(enabled));
        repositorio.registrarAuditoria(usuario.getUserId(), "two_factor_updated", usuario.getUserId(), det);
        resp.enviar(204, "");
    }

    /**
     * POST /backup-codes: gera 6 codigos de uso unico no formato AGMRM-XXXX-XXXX
     * (dois grupos de 16 bits aleatorios). O banco guarda apenas o SHA-256 de cada um;
     * o texto puro aparece UMA unica vez nesta resposta (gerar de novo invalida os antigos).
     */
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
        enviarJson(resp, 200, payload);
    }

    /** GET /security-logs: ultimos 25 eventos de auditoria do proprio usuario (id/action/data/IP/detalhes). */
    private void tratarLogsSeguranca(RespostaHttp resp, UsuarioAutenticado usuario) throws IOException {
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        for (Document doc : repositorio.listarLogsSeguranca(usuario.getUserId(), 25)) {
            String ip = doc.getString("ipAddress");
            Object det = doc.get("details");
            Map<String, Object> item = new LinkedHashMap<String, Object>();
            item.put("id", doc.getObjectId("_id").toHexString());
            item.put("action", doc.getString("action"));
            item.put("createdAt", doc.getDate("createdAt"));
            item.put("ipAddress", ip != null && !ip.isEmpty() ? ip : "127.0.0.1");
            item.put("details", det instanceof Document ? BsonUtils.documentoParaMapa(det) : new LinkedHashMap<String, Object>());
            lista.add(item);
        }
        enviarJson(resp, 200, lista);
    }
}
