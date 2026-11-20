// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Utilitário de comparação em tempo constante para mitigar ataques de canal lateral por temporização (timing attacks).
 * Impede que invasores deduzam tokens secretos ou hashes de senha medindo a latência da comparação de strings.
 */
public final class ConstantTimeComparator {

    private ConstantTimeComparator() {
        // Impedir instanciação
    }

    /**
     * Compara dois arrays de bytes em tempo constante usando {@link MessageDigest#isEqual(byte[], byte[])}.
     */
    public static boolean isEqual(byte[] a, byte[] b) {
        if (a == null || b == null) {
            return a == b;
        }
        return MessageDigest.isEqual(a, b);
    }

    /**
     * Compara duas strings em tempo constante usando representação em bytes UTF-8.
     */
    public static boolean isEqual(String a, String b) {
        if (a == null || b == null) {
            return a == b;
        }
        byte[] aBytes = a.getBytes(StandardCharsets.UTF_8);
        byte[] bBytes = b.getBytes(StandardCharsets.UTF_8);
        return MessageDigest.isEqual(aBytes, bBytes);
    }

    /**
     * Executa trabalho computacional sintético em tempo constante para normalizar a latência de execução.
     */
    public static void executeSyntheticWork(int iterations) {
        int accumulator = 0;
        for (int i = 0; i < iterations; i++) {
            accumulator ^= (i * 31);
        }
        if (accumulator == -999999) {
            System.out.print("");
        }
    }
}

