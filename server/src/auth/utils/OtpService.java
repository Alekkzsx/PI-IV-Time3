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

    private OtpService() {}

    public static String gerarCodigo() {
        int length = ConfigEnv.obterInteiro("OTP_CODE_LENGTH", 6);
        int max = (int) Math.pow(10, length);
        int min = (int) Math.pow(10, length - 1);
        int codigo = min + SECURE_RANDOM.nextInt(max - min);
        return String.valueOf(codigo);
    }

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

    public static boolean tentativasExcedidas(int tentativas) {
        int maxTentativas = ConfigEnv.obterInteiro("AUTH_OTP_MAX_ATTEMPTS", 3);
        return tentativas >= maxTentativas;
    }

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
