// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Constant-time comparison utility mitigating side-channel timing attacks.
 * Prevents attackers from deducing secret tokens or password hashes by measuring string comparison latency.
 */
public final class ConstantTimeComparator {

    private ConstantTimeComparator() {
        // Prevent instantiation
    }

    /**
     * Compares two byte arrays in constant time using {@link MessageDigest#isEqual(byte[], byte[])}.
     */
    public static boolean isEqual(byte[] a, byte[] b) {
        if (a == null || b == null) {
            return a == b;
        }
        return MessageDigest.isEqual(a, b);
    }

    /**
     * Compares two strings in constant time using UTF-8 byte representation.
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
     * Performs synthetic constant-time computational work to normalize execution latency.
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
