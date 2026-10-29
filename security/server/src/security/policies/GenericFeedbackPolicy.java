// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.policies;

/**
 * Policy enforcing opaque, anti-enumeration user feedback across authentication,
 * credential recovery, input validation, and server error handling.
 */
public final class GenericFeedbackPolicy {

    private GenericFeedbackPolicy() {
        // Prevent instantiation
    }

    // ─── VERBATIM STATIC MESSAGES ───

    public static final String AUTH_FAILURE_MESSAGE =
        "Credenciais inválidas. Verifique seu identificador e senha.";

    public static final String PASSWORD_RESET_REQUESTED_MESSAGE =
        "Se o identificador informado estiver cadastrado em nosso sistema, as instruções de recuperação foram enviadas.";

    public static final String RECOVERY_REQUEST_SUCCESS_MESSAGE =
        "Se o identificador informado estiver cadastrado no sistema, as instruções e o código de verificação foram enviados para o e-mail institucional.";

    public static final String EXPIRED_TOKEN_MESSAGE =
        "Código de verificação expirado. Solicite um novo código.";

    public static final String TOKEN_EXPIRED_MESSAGE =
        "O código de verificação expirou. Solicite um novo código para continuar.";

    public static final String REVOKED_SESSION_MESSAGE =
        "Sessão de recuperação revogada por excesso de tentativas. Solicite um novo código.";

    public static final String TOKEN_REVOKED_MESSAGE =
        "Número máximo de tentativas incorretas excedido. Por segurança, a sessão foi cancelada. Solicite uma nova recuperação.";

    public static final String WEAK_PASSWORD_MESSAGE =
        "A nova senha não atende aos requisitos mínimos de segurança (mínimo 8 caracteres, maiúsculas, minúsculas, números e caracteres especiais).";

    public static final String PASSWORD_TOO_WEAK_MESSAGE =
        "A senha não atende aos requisitos mínimos de segurança (pontuação mínima: " +
        SecurityConstants.MIN_REQUIRED_ENTROPY_SCORE + "/4).";

    public static final String PASSWORD_RESET_SUCCESS_MESSAGE =
        "Senha redefinida com sucesso. Faça login com a nova senha.";

    public static final String BAD_REQUEST_PAYLOAD_MESSAGE =
        "Dados da requisição inválidos.";

    public static final String INVALID_PAYLOAD_MESSAGE =
        "Dados de requisição inválidos ou fora do formato permitido.";

    public static final String PAYLOAD_TOO_LARGE_MESSAGE =
        "Tamanho da requisição excede o limite permitido de 64 KB.";

    public static final String INTERNAL_ERROR_MESSAGE =
        "Ocorreu um erro interno ao processar a solicitação. Tente novamente mais tarde.";

    public static final String INTERNAL_SERVER_ERROR_MESSAGE =
        "Ocorreu um erro no processamento da solicitação. Tente novamente mais tarde.";

    public static final String ACCOUNT_LOCKED_MESSAGE =
        "Acesso temporariamente bloqueado por excesso de tentativas.";

    // ─── DYNAMIC FORMATTING HELPERS ───

    /**
     * Generates the standardized lockout message with the exact remaining seconds.
     */
    public static String getLockoutMessage(int remainingSeconds) {
        int sanitized = Math.max(0, remainingSeconds);
        String unit = (sanitized == 1) ? "segundo" : "segundos";
        return "Muitas tentativas incorretas. Tente novamente em " + sanitized + " " + unit + ".";
    }

    /**
     * Generates the standardized countdown message displayed during active lockout banner.
     */
    public static String getLockoutCountdownMessage(int remainingSeconds) {
        int sanitized = Math.max(0, remainingSeconds);
        return "Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde " + sanitized + " segundos.";
    }

    /**
     * Generates the standardized invalid OTP code message with remaining attempts.
     */
    public static String getInvalidOtpCodeMessage(int remainingAttempts) {
        int sanitized = Math.max(0, remainingAttempts);
        return "Código de verificação incorreto. Tentativas restantes: " + sanitized + ".";
    }

    /**
     * Sanitizes an incoming error or exception object to prevent leaking
     * internal database errors, missing user exceptions, or JVM stack traces to the UI.
     */
    public static String sanitizeErrorMessage(Throwable error) {
        if (error == null) {
            return AUTH_FAILURE_MESSAGE;
        }
        return sanitizeErrorMessage(error.getMessage());
    }

    /**
     * Sanitizes an incoming error string to prevent leaking internal details.
     * Standardizes output into opaque, anti-enumeration categories.
     */
    public static String sanitizeErrorMessage(String error) {
        if (error == null) {
            return AUTH_FAILURE_MESSAGE;
        }
        String raw = error.trim();
        if (raw.isEmpty()) {
            return AUTH_FAILURE_MESSAGE;
        }
        String message = raw.toLowerCase();

        // 1. Account Lockout & Login Rate Limiting (Authentication Context)
        if (message.contains("bloque") ||
            message.contains("lockout") ||
            message.contains("temporariamente") ||
            message.contains("cooldown") ||
            message.contains("limite de tentativas de login") ||
            message.contains("excesso de tentativas de login") ||
            ((message.contains("login") || message.contains("autentica")) &&
                (message.contains("excesso") || message.contains("limite")))) {
            return ACCOUNT_LOCKED_MESSAGE;
        }

        // 2. Ephemeral Token Expiration (Recovery Context)
        if (message.contains("expir")) {
            return TOKEN_EXPIRED_MESSAGE;
        }

        // 3. Verification Code / OTP Attempts & Session Revocation (Recovery Context)
        // Context-scoped: requires verification/OTP keywords together with attempt/exhaustion keywords,
        // or explicit revocation terms. Never leaks into pure authentication/login workflows.
        boolean hasOtpContext = message.contains("codigo") ||
            message.contains("código") ||
            message.contains("otp") ||
            message.contains("verificacao") ||
            message.contains("verificação");
        boolean hasAttemptContext = message.contains("tentativa") ||
            message.contains("exced") ||
            message.contains("limite") ||
            message.contains("esgotad");

        if (message.contains("revog") || (hasOtpContext && hasAttemptContext)) {
            return TOKEN_REVOKED_MESSAGE;
        }

        // 4. Password Entropy & Minimum Complexity (Password Context)
        if (message.contains("senha") &&
            (message.contains("fraca") ||
             message.contains("fraco") ||
             message.contains("entropia") ||
             message.contains("weak") ||
             message.contains("requisito") ||
             message.contains("complexidade"))) {
            return PASSWORD_TOO_WEAK_MESSAGE;
        }

        // 5. Payload Bounds & Size Limits (Transport / Middleware Context)
        if (message.contains("tamanho") ||
            message.contains("payload") ||
            message.contains("64") ||
            message.contains("413") ||
            message.contains("corpo da requisi")) {
            return INVALID_PAYLOAD_MESSAGE;
        }

        // 6. Default catch-all anti-enumeration fallback
        return AUTH_FAILURE_MESSAGE;
    }
}
