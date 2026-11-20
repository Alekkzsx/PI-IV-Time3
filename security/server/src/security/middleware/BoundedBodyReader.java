// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.middleware;

import security.policies.SecurityConstants;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Leitor de fluxo defensivo que impõe um limite estrito de 64 KB (65.536 bytes) para o corpo da requisição.
 * Rejeita payloads excedentes para prevenir ataques de inchaço de buffer e exaustão de memória (HTTP 413).
 */
public class BoundedBodyReader {

    public static final int MAX_BODY_BYTES = SecurityConstants.MAX_REQUEST_BODY_SIZE_BYTES; // 64 KB

    public static class PayloadTooLargeException extends IOException {
        public PayloadTooLargeException(String message) {
            super(message);
        }
    }

    /**
     * Lê o fluxo de entrada até o limite de 64 KB.
     * @throws PayloadTooLargeException se declaredContentLength ou os bytes recebidos excederem 65.536 bytes.
     */
    public static byte[] readBoundedStream(InputStream in, long declaredContentLength) throws IOException {
        if (declaredContentLength > MAX_BODY_BYTES) {
            throw new PayloadTooLargeException("Payload exceeds 64 KB ceiling: " + declaredContentLength);
        }

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[SecurityConstants.BUFFER_CHUNK_SIZE_BYTES];
        int read;
        int totalBytes = 0;

        while ((read = in.read(buffer)) != -1) {
            totalBytes += read;
            if (totalBytes > MAX_BODY_BYTES) {
                throw new PayloadTooLargeException("Payload byte stream exceeded 64 KB ceiling");
            }
            baos.write(buffer, 0, read);
        }
        return baos.toByteArray();
    }
}

