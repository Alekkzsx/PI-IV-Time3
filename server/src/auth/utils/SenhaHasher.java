// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.utils;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;

/**
 * Hasher de senhas institucional implementado 100% com a biblioteca padrao do JDK.
 * Utiliza PBKDF2WithHmacSHA256 (recomendacao OWASP 2023) com suporte a verificacao BCrypt.
 */
public final class SenhaHasher {
    private static final int ITERACOES_PADRAO = 600_000;
    private static final int TAMANHO_CHAVE_BITS = 256;
    private static final int TAMANHO_SALT_BYTES = 16;
    private static final String ALGORITMO = "PBKDF2WithHmacSHA256";
    private static final SecureRandom RANDOM = new SecureRandom();

    private SenhaHasher() {}

    public static String hash(String senha) {
        if (senha == null || senha.isEmpty()) {
            throw new IllegalArgumentException("Senha nao pode ser vazia.");
        }
        byte[] salt = new byte[TAMANHO_SALT_BYTES];
        RANDOM.nextBytes(salt);
        byte[] hash = pbkdf2(senha.toCharArray(), salt, ITERACOES_PADRAO, TAMANHO_CHAVE_BITS);
        Base64.Encoder encoder = Base64.getEncoder();
        return ITERACOES_PADRAO + ":" + encoder.encodeToString(salt) + ":" + encoder.encodeToString(hash);
    }

    public static boolean verificar(String senha, String hashArmazenado) {
        if (senha == null || senha.isEmpty() || hashArmazenado == null || hashArmazenado.isEmpty()) {
            return false;
        }
        if (hashArmazenado.startsWith("$2a$") || hashArmazenado.startsWith("$2b$") || hashArmazenado.startsWith("$2y$")) {
            return BCrypt.checkpw(senha, hashArmazenado);
        }
        String[] partes = hashArmazenado.split(":");
        if (partes.length != 3) {
            return false;
        }
        int iteracoes;
        try {
            iteracoes = Integer.parseInt(partes[0]);
        } catch (NumberFormatException e) {
            return false;
        }
        if (iteracoes < 1000) {
            return false;
        }
        byte[] salt;
        byte[] hashEsperado;
        try {
            Base64.Decoder decoder = Base64.getDecoder();
            salt = decoder.decode(partes[1]);
            hashEsperado = decoder.decode(partes[2]);
        } catch (IllegalArgumentException e) {
            return false;
        }
        if (salt.length == 0 || hashEsperado.length == 0) {
            return false;
        }
        byte[] hashCalculado = pbkdf2(senha.toCharArray(), salt, iteracoes, hashEsperado.length * 8);
        return MessageDigest.isEqual(hashEsperado, hashCalculado);
    }

    public static String hashDummy() {
        byte[] salt = new byte[TAMANHO_SALT_BYTES];
        RANDOM.nextBytes(salt);
        byte[] hash = pbkdf2("dummy-password-never-match".toCharArray(), salt, ITERACOES_PADRAO, TAMANHO_CHAVE_BITS);
        Base64.Encoder encoder = Base64.getEncoder();
        return ITERACOES_PADRAO + ":" + encoder.encodeToString(salt) + ":" + encoder.encodeToString(hash);
    }

    private static byte[] pbkdf2(char[] senha, byte[] salt, int iteracoes, int bitsChave) {
        try {
            PBEKeySpec spec = new PBEKeySpec(senha, salt, iteracoes, bitsChave);
            SecretKeyFactory factory = SecretKeyFactory.getInstance(ALGORITMO);
            return factory.generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new IllegalStateException("Falha critica ao gerar PBKDF2: " + e.getMessage(), e);
        }
    }

    public static ResultadoValidacao validarComplexidade(String senha) {
        int minLength = utils.ConfigEnv.obterInteiro("PASSWORD_MIN_LENGTH", 8);
        int maxLength = utils.ConfigEnv.obterInteiro("PASSWORD_MAX_LENGTH", 128);
        boolean requireUpper = "true".equalsIgnoreCase(utils.ConfigEnv.obter("REQUIRE_UPPERCASE", "true"));
        boolean requireLower = "true".equalsIgnoreCase(utils.ConfigEnv.obter("REQUIRE_LOWERCASE", "true"));
        boolean requireDigit = "true".equalsIgnoreCase(utils.ConfigEnv.obter("REQUIRE_DIGIT", "true"));
        boolean requireSpecial = "true".equalsIgnoreCase(utils.ConfigEnv.obter("REQUIRE_SPECIAL_CHAR", "true"));
        return validarComplexidade(senha, minLength, maxLength, requireUpper, requireLower, requireDigit, requireSpecial);
    }

    public static ResultadoValidacao validarComplexidade(
            String senha,
            int minLength,
            int maxLength,
            boolean requireUpper,
            boolean requireLower,
            boolean requireDigit,
            boolean requireSpecial) {
        if (senha == null || senha.isEmpty()) {
            return new ResultadoValidacao(false, "Senha nao pode ser vazia.");
        }
        if (senha.length() < minLength) {
            return new ResultadoValidacao(false, "Senha deve ter pelo menos " + minLength + " caracteres.");
        }
        if (senha.length() > maxLength) {
            return new ResultadoValidacao(false, "Senha excede o tamanho maximo de " + maxLength + " caracteres.");
        }
        if (requireUpper && !contemMaiuscula(senha)) {
            return new ResultadoValidacao(false, "Senha deve conter pelo menos uma letra maiuscula.");
        }
        if (requireLower && !contemMinuscula(senha)) {
            return new ResultadoValidacao(false, "Senha deve conter pelo menos uma letra minuscula.");
        }
        if (requireDigit && !contemDigito(senha)) {
            return new ResultadoValidacao(false, "Senha deve conter pelo menos um digito numerico.");
        }
        if (requireSpecial && !contemCaractereEspecial(senha)) {
            return new ResultadoValidacao(false, "Senha deve conter pelo menos um caractere especial (!@#$%^&*...).");
        }
        return new ResultadoValidacao(true, "Senha valida.");
    }

    private static boolean contemMaiuscula(String s) {
        for (int i = 0; i < s.length(); i++) {
            if (Character.isUpperCase(s.charAt(i))) return true;
        }
        return false;
    }

    private static boolean contemMinuscula(String s) {
        for (int i = 0; i < s.length(); i++) {
            if (Character.isLowerCase(s.charAt(i))) return true;
        }
        return false;
    }

    private static boolean contemDigito(String s) {
        for (int i = 0; i < s.length(); i++) {
            if (Character.isDigit(s.charAt(i))) return true;
        }
        return false;
    }

    private static boolean contemCaractereEspecial(String s) {
        for (int i = 0; i < s.length(); i++) {
            if (!Character.isLetterOrDigit(s.charAt(i))) return true;
        }
        return false;
    }

    public static final class ResultadoValidacao {
        private final boolean valido;
        private final String mensagem;

        public ResultadoValidacao(boolean valido, String mensagem) {
            this.valido = valido;
            this.mensagem = mensagem;
        }

        public boolean isValido() { return valido; }
        public String getMensagem() { return mensagem; }
    }
}
