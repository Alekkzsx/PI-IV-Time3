// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.ConfigEnv;
import utils.Json;

import org.bson.Document;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint de recuperacao de senha via OTP.
 *
 * Rotas suportadas:
 * - POST /api/auth/send-recovery-otp: Envia codigo de recuperacao por email.
 *   Body: { "email": "string" } ou { "identity": "string" }
 *
 * - POST /api/auth/verify-recovery-otp: Valida codigo de recuperacao.
 *   Body: { "identity": "string", "code": "string" }
 *   Response 200: { "recoveryToken": "..." } (JWT temporario para reset)
 *
 * - POST /api/auth/reset-password: Redefine a senha usando o recovery token.
 *   Body: { "recoveryToken": "string", "novaSenha": "string" }
 *
 * Response 200: Sucesso
 * Response 400: Dados invalidos
 * Response 401: Codigo invalido/expirado
 * Response 404: Usuario nao encontrado (mensagens opacas para evitar enumeracao)
 */
public class RecoveryHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public RecoveryHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public RecoveryHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            enviarErro(resposta, 405, "Utilize POST.");
            return;
        }

        String caminho = requisicao.getCaminho();

        try {
            if (caminho.endsWith("/send-recovery-otp")) {
                handleSendRecoveryOtp(requisicao, resposta);
            } else if (caminho.endsWith("/verify-recovery-otp")) {
                handleVerifyRecoveryOtp(requisicao, resposta);
            } else if (caminho.endsWith("/reset-password")) {
                handleResetPassword(requisicao, resposta);
            } else {
                enviarErro(resposta, 404, "Endpoint de recuperacao nao encontrado.");
            }
        } catch (IllegalArgumentException e) {
            enviarErro(resposta, 400, "Corpo da requisicao invalido: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[RECOVERY] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "Erro interno no servidor.");
        }
    }

    // =========================================================================
    // POST /api/auth/send-recovery-otp
    // =========================================================================
    private void handleSendRecoveryOtp(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
        if (corpo == null) corpo = new LinkedHashMap<String, Object>();

        String email = getString(corpo, "email");
        String identity = getString(corpo, "identity");

        // Mensagem opaca independente de existir ou nao (evita enumeracao)
        String mensagemOpaca = "Se a conta existir, um codigo de recuperacao sera enviado.";

        RepositorioUsuarios repo = this.repositorio;
        UsuarioAutenticado usuario = null;

        if (email != null && !email.isEmpty()) {
            usuario = repo.buscarPorEmail(email);
        } else if (identity != null && !identity.isEmpty()) {
            usuario = repo.buscarPorIdentidade(identity);
        }

        if (usuario == null) {
            aplicarLatenciaPadronizada();
            // Retornar 200 com mensagem opaca (nao revelar se o usuario existe)
            Map<String, Object> resp = new LinkedHashMap<String, Object>();
            resp.put("status", 200);
            resp.put("success", true);
            resp.put("expiresInSeconds", 300);
            resp.put("message", mensagemOpaca);
            resposta.enviarJson(200, Json.escrever(resp));
            return;
        }

        // Gerar e enviar OTP
        String otpCode = OtpService.gerarCodigo();
        String otpSecret = ConfigEnv.obter("AUTH_OTP_SECRET",
                "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890");
        String otpHash = OtpService.hashOtp(otpCode, otpSecret);

        long ttlOtp = (long) ConfigEnv.obterInteiro("AUTH_OTP_TTL_SECONDS", 300) * 1000L;
        long expiraEmMillis = System.currentTimeMillis() + ttlOtp;

        // Salvar OTP associado à identidade canônica do usuário
        repo.salvarOtp(usuario.getIdentity(), otpHash, "RECOVERY", expiraEmMillis);

        // Se a requisição informou um identificador ou email diferente da identidade oficial, salvar sob esses aliases também
        if (identity != null && !identity.trim().isEmpty() && !identity.trim().equalsIgnoreCase(usuario.getIdentity())) {
            repo.salvarOtp(identity.trim().toLowerCase(), otpHash, "RECOVERY", expiraEmMillis);
        }
        if (email != null && !email.trim().isEmpty() && !email.trim().equalsIgnoreCase(usuario.getIdentity())) {
            repo.salvarOtp(email.trim().toLowerCase(), otpHash, "RECOVERY", expiraEmMillis);
        }
        if (!usuario.getEmail().isEmpty() && !usuario.getEmail().equalsIgnoreCase(usuario.getIdentity())) {
            repo.salvarOtp(usuario.getEmail().toLowerCase(), otpHash, "RECOVERY", expiraEmMillis);
        }

        // Enviar email
        if (!usuario.getEmail().isEmpty()) {
            try {
                SmtpCliente.enviarRecuperacao(usuario.getEmail(), otpCode, usuario.getDisplayName());
            } catch (Exception e) {
                System.err.println("[RECOVERY] Falha ao enviar OTP por email: " + e.getMessage());
            }
        }

        aplicarLatenciaPadronizada();

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", 200);
        resp.put("success", true);
        resp.put("expiresInSeconds", 300);
        resp.put("message", mensagemOpaca);
        if (!usuario.getEmail().isEmpty()) {
            resp.put("maskedEmail", mascararEmail(usuario.getEmail()));
            resp.put("email", usuario.getEmail());
        }
        resp.put("identity", usuario.getIdentity());
        if (!usuario.getDisplayName().isEmpty()) {
            resp.put("displayName", usuario.getDisplayName());
        }
        resp.put("profile", usuario.getProfile());
        if (!usuario.getDepartmentOrCourse().isEmpty()) {
            resp.put("departmentOrCourse", usuario.getDepartmentOrCourse());
        }
        resposta.enviarJson(200, Json.escrever(resp));
    }

    // =========================================================================
    // POST /api/auth/verify-recovery-otp
    // =========================================================================
    private void handleVerifyRecoveryOtp(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
        if (corpo == null) corpo = new LinkedHashMap<String, Object>();

        String identity = getString(corpo, "identity");
        String code = getString(corpo, "code");

        if (identity == null || identity.trim().isEmpty()) {
            enviarErro(resposta, 400, "Campo 'identity' e obrigatorio.");
            return;
        }
        if (code == null || code.trim().isEmpty()) {
            enviarErro(resposta, 400, "Campo 'code' e obrigatorio.");
            return;
        }

        String normalizedIdentity = identity.trim().toLowerCase();
        String otpSecret = ConfigEnv.obter("AUTH_OTP_SECRET",
                "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890");

        RepositorioUsuarios repo = this.repositorio;

        Document otpDoc = repo.buscarOtp(normalizedIdentity, "RECOVERY");
        if (otpDoc == null) {
            UsuarioAutenticado usuarioAux = repo.buscarPorEmail(normalizedIdentity);
            if (usuarioAux != null) {
                otpDoc = repo.buscarOtp(usuarioAux.getIdentity(), "RECOVERY");
            }
        }
        if (otpDoc == null) {
            UsuarioAutenticado usuarioAux = repo.buscarPorIdentidade(normalizedIdentity);
            if (usuarioAux != null && !usuarioAux.getEmail().isEmpty()) {
                otpDoc = repo.buscarOtp(usuarioAux.getEmail().toLowerCase(), "RECOVERY");
            }
        }
        if (otpDoc == null) {
            enviarErro(resposta, 401, "Codigo de recuperacao expirado ou nao encontrado.");
            return;
        }

        int tentativas = otpDoc.getInteger("tentativas", 0);
        if (OtpService.tentativasExcedidas(tentativas)) {
            repo.removerOtp(normalizedIdentity, "RECOVERY");
            enviarErro(resposta, 429, "Numero maximo de tentativas excedido. Solicite um novo codigo.");
            return;
        }

        java.util.Date expiresAt = otpDoc.getDate("expiresAt");
        if (expiresAt != null && expiresAt.getTime() < System.currentTimeMillis()) {
            repo.removerOtp(normalizedIdentity, "RECOVERY");
            enviarErro(resposta, 401, "Codigo de recuperacao expirado.");
            return;
        }

        String hashArmazenado = otpDoc.getString("otpHash");
        boolean valido = OtpService.validar(code, hashArmazenado, otpSecret);

        if (!valido) {
            repo.incrementarTentativasOtp(normalizedIdentity, "RECOVERY");
            enviarErro(resposta, 401, "Codigo de recuperacao invalido.");
            return;
        }

        // OTP valido! Gerar recovery token (JWT temporario de 15 minutos)
        repo.removerOtp(normalizedIdentity, "RECOVERY");

        UsuarioAutenticado usuario = repo.buscarPorIdentidade(normalizedIdentity);
        if (usuario == null) {
            usuario = repo.buscarPorEmail(normalizedIdentity);
        }
        if (usuario == null) {
            enviarErro(resposta, 401, "Usuario nao encontrado.");
            return;
        }

        // Gerar recovery token (tipo especial com TTL curto)
        String recoveryToken = gerarRecoveryToken(usuario);

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", 200);
        resp.put("valid", true);
        resp.put("resetToken", recoveryToken);
        resp.put("recoveryToken", recoveryToken);
        resp.put("expiresIn", 900); // 15 minutos
        resp.put("identity", usuario.getIdentity());
        resp.put("displayName", usuario.getDisplayName());
        resp.put("email", usuario.getEmail());
        resp.put("profile", usuario.getProfile());
        resp.put("departmentOrCourse", usuario.getDepartmentOrCourse());
        resp.put("campus", usuario.getCampus());
        resp.put("semester", usuario.getSemester());
        resp.put("shift", usuario.getShift());
        resposta.enviarJson(200, Json.escrever(resp));
    }

    // =========================================================================
    // POST /api/auth/reset-password
    // =========================================================================
    private void handleResetPassword(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
        if (corpo == null) corpo = new LinkedHashMap<String, Object>();

        String recoveryToken = getString(corpo, "resetToken");
        if (recoveryToken == null || recoveryToken.trim().isEmpty()) {
            recoveryToken = getString(corpo, "recoveryToken");
        }
        String novaSenha = getString(corpo, "newPassword");
        if (novaSenha == null || novaSenha.trim().isEmpty()) {
            novaSenha = getString(corpo, "novaSenha");
        }

        if (recoveryToken == null || recoveryToken.trim().isEmpty()) {
            enviarErro(resposta, 400, "Campo 'resetToken' (ou 'recoveryToken') e obrigatorio.");
            return;
        }
        if (novaSenha == null || novaSenha.trim().isEmpty()) {
            enviarErro(resposta, 400, "Campo 'newPassword' (ou 'novaSenha') e obrigatorio.");
            return;
        }

        // Validar recovery token
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null) {
            enviarErro(resposta, 500, "Segredo JWT nao configurado.");
            return;
        }

        UsuarioAutenticado usuario;
        try {
            usuario = JwtAuthValidator.validarToken(recoveryToken, segredo, "recovery");
        } catch (SecurityException e) {
            enviarErro(resposta, 401, "Token de recuperacao invalido ou expirado: " + e.getMessage());
            return;
        }

        // Validar complexidade da nova senha
        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(novaSenha);
        if (!validacao.isValido()) {
            enviarErro(resposta, 400, validacao.getMensagem());
            return;
        }

        // Atualizar senha no MongoDB
        RepositorioUsuarios repo = this.repositorio;
        boolean atualizado = repo.atualizarSenha(usuario.getUserId(), novaSenha);

        if (atualizado) {
            // Revogar todas as sessoes existentes do usuario
            repo.revogarTodasSessoes(usuario.getUserId());
        }

        if (!atualizado) {
            enviarErro(resposta, 500, "Falha ao atualizar senha.");
            return;
        }

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", 200);
        resp.put("success", true);
        resp.put("message", "Senha redefinida com sucesso. Realize login novamente.");
        resposta.enviarJson(200, Json.escrever(resp));
    }

    // =========================================================================
    // HELPERS
    // =========================================================================

    /**
     * Gera um recovery token JWT temporario (TTL: 15 minutos, tipo: "recovery").
     */
    private String gerarRecoveryToken(UsuarioAutenticado usuario) {
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        long ttl = 900; // 15 minutos

        long agora = System.currentTimeMillis() / 1000;
        String jti = java.util.UUID.randomUUID().toString();

        Map<String, Object> header = new LinkedHashMap<String, Object>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("sub", usuario.getUserId());
        payload.put("profile", usuario.getProfile());
        payload.put("identity", usuario.getIdentity());
        payload.put("jti", jti);
        payload.put("type", "recovery");
        payload.put("iat", agora);
        payload.put("exp", agora + ttl);

        java.util.Base64.Encoder urlEncoder = java.util.Base64.getUrlEncoder().withoutPadding();
        String headerEnc = urlEncoder.encodeToString(Json.escrever(header).getBytes(java.nio.charset.StandardCharsets.UTF_8));
        String payloadEnc = urlEncoder.encodeToString(Json.escrever(payload).getBytes(java.nio.charset.StandardCharsets.UTF_8));

        String assinatura = "";
        try {
            javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA256");
            javax.crypto.spec.SecretKeySpec keySpec = new javax.crypto.spec.SecretKeySpec(
                    segredo.getBytes(java.nio.charset.StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(keySpec);
            byte[] sig = mac.doFinal((headerEnc + "." + payloadEnc).getBytes(java.nio.charset.StandardCharsets.UTF_8));
            assinatura = urlEncoder.encodeToString(sig);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao assinar recovery token: " + e.getMessage());
        }

        return headerEnc + "." + payloadEnc + "." + assinatura;
    }

    private String getString(Map<String, Object> mapa, String chave) {
        Object valor = mapa.get(chave);
        if (valor instanceof String) return ((String) valor).trim();
        return null;
    }

    private String mascararEmail(String email) {
        if (email == null || email.isEmpty()) return "";
        int arroba = email.indexOf('@');
        if (arroba <= 1) return email;
        String user = email.substring(0, arroba);
        String domain = email.substring(arroba + 1);
        if (user.length() <= 2) {
            return user.charAt(0) + "***@" + domain;
        }
        return user.charAt(0) + "***" + user.charAt(user.length() - 1) + "@" + domain;
    }

    private void aplicarLatenciaPadronizada() {
        long latenciaAlvo = ConfigEnv.obterInteiro("STANDARDIZED_AUTH_LATENCY_MS", 1000);
        try { Thread.sleep(latenciaAlvo); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
