// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.validators;

import security.policies.SecurityConstants;

import java.util.regex.Pattern;

/**
 * Avaliador de entropia de senha no lado do servidor.
 * Avalia a força da senha em 4 vetores de segurança e impõe pontuação mínima >= 3.
 */
public final class ServerPasswordEntropyValidator {

    private ServerPasswordEntropyValidator() {
        // Impedir instanciação
    }

    private static final Pattern UPPER_PATTERN = Pattern.compile("[A-Z]");
    private static final Pattern LOWER_PATTERN = Pattern.compile("[a-z]");
    private static final Pattern DIGIT_PATTERN = Pattern.compile("[0-9]");
    private static final Pattern SPECIAL_PATTERN = Pattern.compile("[!@#$%^&*(),.?\":{}|<>\\-_+=\\[\\]]");

    /**
     * Calcula a pontuação de entropia de senha de 4 fatores (0 a 4).
     */
    public static int calculateScore(String password) {
        if (password == null || password.isEmpty()) {
            return 0;
        }

        int score = 0;
        if (password.length() >= SecurityConstants.MIN_PASSWORD_LENGTH) {
            score++;
        }
        if (UPPER_PATTERN.matcher(password).find() && LOWER_PATTERN.matcher(password).find()) {
            score++;
        }
        if (DIGIT_PATTERN.matcher(password).find()) {
            score++;
        }
        if (SPECIAL_PATTERN.matcher(password).find()) {
            score++;
        }

        return score;
    }

    /**
     * Verifica se a senha atende aos critérios mínimos para atualização de credencial.
     */
    public static boolean isEligibleForSubmission(String password) {
        if (password == null || password.length() < SecurityConstants.MIN_PASSWORD_LENGTH) {
            return false;
        }
        return calculateScore(password) >= SecurityConstants.MIN_REQUIRED_ENTROPY_SCORE;
    }
}

