// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.middleware;

import security.policies.SecurityConstants;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Defensive stream reader enforcing a strict 64 KB (65,536 bytes) request body ceiling.
 * Rejects oversized payloads to prevent buffer bloat and memory exhaustion attacks (HTTP 413).
 */
public class BoundedBodyReader {

    public static final int MAX_BODY_BYTES = SecurityConstants.MAX_REQUEST_BODY_SIZE_BYTES; // 64 KB

    public static class PayloadTooLargeException extends IOException {
        public PayloadTooLargeException(String message) {
            super(message);
        }
    }

    /**
     * Reads the input stream up to the 64 KB threshold.
     * @throws PayloadTooLargeException if declaredContentLength or streamed bytes exceed 65,536 bytes.
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

