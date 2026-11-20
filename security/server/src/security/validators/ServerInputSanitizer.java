// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.validators;

import security.policies.SecurityConstants;

import java.util.regex.Pattern;

/**
 * Sanitizador de entrada no lado do servidor para identidades acadêmicas, e-mails e senhas.
 * Remove bytes nulos, caracteres de controle não imprimíveis e bloqueia padrões de injeção XSS/SQLi.
 */
public final class ServerInputSanitizer {

    private ServerInputSanitizer() {
        // Impedir instanciação
    }

    private static final Pattern SCRIPT_PATTERN = Pattern.compile(
        "<script\\b[^<]*(?:(?!<\\/script>)<[^<]*)*<\\/script>|<[^>]+(on\\w+|javascript:)[^>]*>",
        Pattern.CASE_INSENSITIVE
    );

    private static final Pattern SQL_META_PATTERN = Pattern.compile(
        "('|--|/\\*|\\*/|;|xp_|union\\s+select|drop\\s+table)",
        Pattern.CASE_INSENSITIVE
    );

    private static final Pattern NULL_BYTE_PATTERN = Pattern.compile("(\\x00|%00|\\u0000)");

    private static final Pattern CONTROL_CHARS_PATTERN = Pattern.compile("[\\x01-\\x1F\\x7F]");

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    );

    /**
     * Remove bytes nulos, caracteres de controle não imprimíveis e espaços em branco nas extremidades.
     */
    public static String sanitizeString(String input) {
        if (input == null || input.isEmpty()) {
            return input == null ? "" : input;
        }
        String cleaned = NULL_BYTE_PATTERN.matcher(input).replaceAll("");
        cleaned = CONTROL_CHARS_PATTERN.matcher(cleaned).replaceAll("");
        return cleaned.trim();
    }

    /**
     * Verifica se a entrada contém vetores de exploração maliciosos (XSS, metadados SQL, bytes nulos).
     */
    public static boolean hasDangerousPatterns(String input) {
        if (input == null || input.isEmpty()) return false;
        if (NULL_BYTE_PATTERN.matcher(input).find()) return true;
        if (SCRIPT_PATTERN.matcher(input).find()) return true;
        return SQL_META_PATTERN.matcher(input).find();
    }

    /**
     * Sanitiza e valida a identidade acadêmica (RA/Matrícula).
     * @throws IllegalArgumentException se o comprimento exceder os limites ou houver padrões maliciosos.
     */
    public static String sanitizeIdentity(String identity) {
        String cleaned = sanitizeString(identity);
        if (cleaned.length() > SecurityConstants.MAX_IDENTITY_LENGTH) {
            throw new IllegalArgumentException("Identity exceeds maximum length: " + SecurityConstants.MAX_IDENTITY_LENGTH);
        }
        if (hasDangerousPatterns(cleaned)) {
            throw new IllegalArgumentException("Invalid characters detected in identity");
        }
        return cleaned;
    }

    /**
     * Sanitiza e valida o endereço de e-mail institucional.
     * @throws IllegalArgumentException se o formato do e-mail for inválido ou exceder os limites.
     */
    public static String sanitizeEmail(String email) {
        String cleaned = sanitizeString(email);
        if (cleaned.length() > SecurityConstants.MAX_EMAIL_LENGTH) {
            throw new IllegalArgumentException("Email exceeds maximum length: " + SecurityConstants.MAX_EMAIL_LENGTH);
        }
        if (!EMAIL_PATTERN.matcher(cleaned).matches()) {
            throw new IllegalArgumentException("Invalid email format");
        }
        return cleaned;
    }

    /**
     * Remove bytes nulos e impõe o limite máximo de comprimento da senha.
     */
    public static String sanitizePassword(String password) {
        if (password == null) return "";
        String cleaned = NULL_BYTE_PATTERN.matcher(password).replaceAll("");
        if (cleaned.length() > SecurityConstants.MAX_PASSWORD_LENGTH) {
            throw new IllegalArgumentException("Password exceeds maximum length: " + SecurityConstants.MAX_PASSWORD_LENGTH);
        }
        return cleaned;
    }
}

