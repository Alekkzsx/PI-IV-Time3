// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.utils;

import utils.ConfigEnv;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Servico de OTP (One-Time Password) e digests criptograficos implementado com JDK padrao.
 */
public final class OtpService {
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String ALGORITMO_HMAC = "HmacSHA256";

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private OtpService() {}

    /**
     * Gera codigo numerico de tamanho fixo (OTP_CODE_LENGTH, default 6) com SecureRandom.
     * Faixa [10^(n-1), 10^n): garante exatamente n digitos, sem zeros a esquerda
     * (zeros a esquerda confundem o usuario ao digitar e some em alguns clientes).
     */
    public static String gerarCodigo() {
        int length = ConfigEnv.obterInteiro("OTP_CODE_LENGTH", 6);
        int max = (int) Math.pow(10, length);
        int min = (int) Math.pow(10, length - 1);
        int codigo = min + SECURE_RANDOM.nextInt(max - min);
        return String.valueOf(codigo);
    }

    /**
     * HMAC-SHA256 do codigo com o segredo do servidor (Base64).
     * O banco guarda apenas este digest: vazamento do Mongo nao revela os OTPs.
     * HMAC (e nao SHA puro) impede ataque de dicionario: o espaco de 6 digitos e
     * pequeno demais para hash sem chave. Deterministico para permitir comparacao.
     */
    public static String hashOtp(String codigo, String segredo) {
        try {
            Mac mac = Mac.getInstance(ALGORITMO_HMAC);
            SecretKeySpec keySpec = new SecretKeySpec(
                    segredo.getBytes(StandardCharsets.UTF_8), ALGORITMO_HMAC);
            mac.init(keySpec);
            byte[] hash = mac.doFinal(codigo.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao gerar hash OTP: " + e.getMessage(), e);
        }
    }

    /** Confere o codigo digitado contra o digest armazenado em tempo constante. */
    public static boolean validar(String codigoFornecido, String hashArmazenado, String segredo) {
        if (codigoFornecido == null || codigoFornecido.trim().isEmpty()
                || hashArmazenado == null || hashArmazenado.isEmpty()) {
            return false;
        }
        String hashCalculado = hashOtp(codigoFornecido.trim(), segredo);
        return MessageDigest.isEqual(
                hashArmazenado.getBytes(StandardCharsets.UTF_8),
                hashCalculado.getBytes(StandardCharsets.UTF_8)
        );
    }

    /** @return true quando as tentativas atingem AUTH_OTP_MAX_ATTEMPTS (default 3) - OTP deve ser invalidado. */
    public static boolean tentativasExcedidas(int tentativas) {
        int maxTentativas = ConfigEnv.obterInteiro("AUTH_OTP_MAX_ATTEMPTS", 3);
        return tentativas >= maxTentativas;
    }

    /** SHA-256 em hex minusculo; usado como fingerprint de tokens (ex.: reset token de uso unico). */
    public static String sha256Hex(String valor) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest((valor != null ? valor : "").getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                hex.append(String.format("%02x", b & 0xff));
            }
            return hex.toString();
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao calcular SHA-256: " + e.getMessage(), e);
        }
    }
}
