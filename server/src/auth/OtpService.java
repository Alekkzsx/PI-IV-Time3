// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import utils.ConfigEnv;

/**
 * Servico de OTP (One-Time Password) implementado 100% com a biblioteca padrao do JDK.
 * Utilizado para autenticacao de dois fatores (2FA) e recuperacao de senha.
 *
 * Caracteristicas:
 * - Codigos de 6 digitos gerados com SecureRandom
 * - Hash HMAC-SHA256 para armazenamento seguro
 * - Validacao em tempo constante (MessageDigest.isEqual)
 * - TTL configuravel via .env (AUTH_OTP_TTL_SECONDS)
 * - Maximo de tentativas configuravel (AUTH_OTP_MAX_ATTEMPTS)
 */
public final class OtpService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String ALGORITMO_HMAC = "HmacSHA256";

    private OtpService() {}

    /**
     * Gera um codigo OTP de 6 digitos numericamente seguro.
     * Usa SecureRandom para garantir imprevisibilidade criptografica.
     *
     * @return String de 6 digitos (ex: "042891").
     */
    public static String gerarCodigo() {
        int length = ConfigEnv.obterInteiro("OTP_CODE_LENGTH", 6);
        int max = (int) Math.pow(10, length);
        int min = (int) Math.pow(10, length - 1);
        int codigo = min + SECURE_RANDOM.nextInt(max - min);
        return String.valueOf(codigo);
    }

    /**
     * Gera um hash HMAC-SHA256 do codigo OTP para armazenamento seguro.
     * O hash usa o segredo configurado em AUTH_OTP_SECRET.
     *
     * @param codigo   Codigo OTP em texto plano.
     * @param segredo  Segredo HMAC (do .env AUTH_OTP_SECRET).
     * @return Hash Base64 do HMAC-SHA256.
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

    /**
     * Valida um codigo OTP contra o hash armazenado.
     * Comparacao em tempo constante para mitigar timing attacks.
     *
     * @param codigoFornecido Codigo digitado pelo usuario.
     * @param hashArmazenado  Hash armazenado no MongoDB.
     * @param segredo         Segredo HMAC para recalcular o hash.
     * @return true se o codigo corresponde ao hash.
     */
    public static boolean validar(String codigoFornecido, String hashArmazenado, String segredo) {
        if (codigoFornecido == null || codigoFornecido.trim().isEmpty()
                || hashArmazenado == null || hashArmazenado.isEmpty()) {
            return false;
        }

        String hashCalculado = hashOtp(codigoFornecido.trim(), segredo);

        // Comparacao em tempo constante
        return MessageDigest.isEqual(
                hashArmazenado.getBytes(StandardCharsets.UTF_8),
                hashCalculado.getBytes(StandardCharsets.UTF_8)
        );
    }

    /**
     * Verifica se o numero maximo de tentativas foi excedido.
     *
     * @param tentativas      Numero de tentativas ja realizadas.
     * @return true se o maximo foi excedido.
     */
    public static boolean tentativasExcedidas(int tentativas) {
        int maxTentativas = ConfigEnv.obterInteiro("AUTH_OTP_MAX_ATTEMPTS", 3);
        return tentativas >= maxTentativas;
    }
}
