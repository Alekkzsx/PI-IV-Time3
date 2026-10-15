// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.validators;

import security.policies.SecurityConstants;

import java.util.regex.Pattern;

/**
 * Server-side input sanitizer for academic identities, emails, and passwords.
 * Strips null bytes, non-printable control characters, and blocks XSS/SQLi injection patterns.
 */
public final class ServerInputSanitizer {

    private ServerInputSanitizer() {
        // Prevent instantiation
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
     * Strips null bytes, non-printable control characters, and leading/trailing whitespace.
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
     * Checks if the input contains malicious exploit vectors (XSS, SQL meta, null bytes).
     */
    public static boolean hasDangerousPatterns(String input) {
        if (input == null || input.isEmpty()) return false;
        if (NULL_BYTE_PATTERN.matcher(input).find()) return true;
        if (SCRIPT_PATTERN.matcher(input).find()) return true;
        return SQL_META_PATTERN.matcher(input).find();
    }

    /**
     * Sanitizes and validates academic identity (RA/Matrícula).
     * @throws IllegalArgumentException if length exceeds bounds or malicious patterns exist.
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
     * Sanitizes and validates institutional email address.
     * @throws IllegalArgumentException if email format is invalid or exceeds bounds.
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
     * Strips null bytes and enforces maximum password bounds.
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
