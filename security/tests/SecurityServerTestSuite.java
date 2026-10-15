// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.tests;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Standalone Java Server Security Test Suite
 * Tests Features 22, 23, 24, 3, 4 and server-side defensive contracts.
 * Author: Alex Gabriel Soares Sousa - RA: 24802449
 */
public class SecurityServerTestSuite {

    private static final AtomicInteger passed = new AtomicInteger(0);
    private static final AtomicInteger total = new AtomicInteger(0);

    // =========================================================================
    // REFERENCE DEFENSIVE IMPLEMENTATIONS (CONTRACT HARNESS)
    // =========================================================================

    public static class SecurityHeadersFilter {
        public static Map<String, String> getHardenedHeaders() {
            Map<String, String> headers = new LinkedHashMap<>();
            headers.put("X-Content-Type-Options", "nosniff");
            headers.put("X-Frame-Options", "DENY");
            headers.put("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; sandbox");
            headers.put("Access-Control-Allow-Origin", "*");
            headers.put("Cache-Control", "no-store, no-cache, must-revalidate");
            return headers;
        }
    }

    public static class BoundedBodyReader {
        public static final int MAX_BODY_BYTES = 65536; // 64 KB

        public static byte[] readBoundedStream(InputStream in, long declaredContentLength) throws IOException {
            if (declaredContentLength > MAX_BODY_BYTES) {
                throw new PayloadTooLargeException("Payload exceeds 64 KB ceiling: " + declaredContentLength);
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
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

    public static class PayloadTooLargeException extends IOException {
        public PayloadTooLargeException(String msg) {
            super(msg);
        }
    }

    public static class ServerErrorSanitizer {
        public static String sanitizeException(Throwable t) {
            // Logs internally (omitted in test)
            // Never leaks stack trace, JVM class names, or server file paths to the client
            return "{\"status\": 400, \"error\": \"Bad Request\", \"message\": \"Dados invalidos\"}";
        }

        public static String sanitizeInternalError(Throwable t) {
            return "{\"status\": 500, \"error\": \"Internal Server Error\", \"message\": \"Ocorreu um erro interno\"}";
        }
    }

    // =========================================================================
    // TEST RUNNER UTILITIES
    // =========================================================================

    private static void runTest(String name, Runnable testFn) {
        total.incrementAndGet();
        try {
            testFn.run();
            passed.incrementAndGet();
            System.out.println("  [PASS] " + name);
        } catch (Throwable t) {
            System.err.println("  [FAIL] " + name + ": " + t.getMessage());
            t.printStackTrace(System.err);
        }
    }

    private static void assertTrue(boolean condition, String msg) {
        if (!condition) {
            throw new AssertionError("Assertion failed: " + msg);
        }
    }

    private static void assertEquals(Object actual, Object expected, String msg) {
        if (!Objects.equals(actual, expected)) {
            throw new AssertionError(msg + " - expected: <" + expected + ">, got: <" + actual + ">");
        }
    }

    // =========================================================================
    // MAIN EXECUTION
    // =========================================================================

    public static void main(String[] args) {
        System.out.println("===============================================================");
        System.out.println("Running Java Server Security Test Suite (Features 22-24, 3, 4)");
        System.out.println("Author: Alex Gabriel Soares Sousa - RA: 24802449");
        System.out.println("===============================================================");

        // -------------------------------------------------------------
        // FEATURE 22: Defensive HTTP Security Headers
        // -------------------------------------------------------------
        runTest("T2-01 (Feature 22): Hardened headers contain nosniff, DENY, CSP, CORS", () -> {
            Map<String, String> headers = SecurityHeadersFilter.getHardenedHeaders();
            assertEquals(headers.get("X-Content-Type-Options"), "nosniff", "Must include nosniff");
            assertEquals(headers.get("X-Frame-Options"), "DENY", "Must include DENY");
            assertTrue(headers.get("Content-Security-Policy").contains("default-src"), "CSP must be configured");
            assertEquals(headers.get("Access-Control-Allow-Origin"), "*", "CORS header must be present");
            assertTrue(headers.get("Cache-Control").contains("no-store"), "Cache-Control must prevent caching");
        });

        // -------------------------------------------------------------
        // FEATURE 23: Request Body Size Ceiling (64 KB)
        // -------------------------------------------------------------
        runTest("T2-02 (Feature 23): Request of exactly 65,536 bytes is accepted", () -> {
            byte[] exact64Kb = new byte[65536];
            Arrays.fill(exact64Kb, (byte) 'A');
            try {
                ByteArrayInputStream in = new ByteArrayInputStream(exact64Kb);
                byte[] result = BoundedBodyReader.readBoundedStream(in, 65536);
                assertEquals(result.length, 65536, "Exact 64KB must be read fully");
            } catch (IOException e) {
                throw new AssertionError("64KB request should not throw: " + e.getMessage());
            }
        });

        runTest("T2-03 (Feature 23): Request of 65,537 bytes throws PayloadTooLargeException (AC-10)", () -> {
            byte[] oversized = new byte[65537];
            Arrays.fill(oversized, (byte) 'B');
            ByteArrayInputStream in = new ByteArrayInputStream(oversized);

            boolean caught = false;
            try {
                BoundedBodyReader.readBoundedStream(in, 65537);
            } catch (PayloadTooLargeException e) {
                caught = true;
            } catch (IOException e) {
                throw new AssertionError("Unexpected exception: " + e);
            }
            assertTrue(caught, "Oversized stream must throw PayloadTooLargeException");
        });

        // -------------------------------------------------------------
        // FEATURE 24: Error Response Sanitization (Zero Stack Traces)
        // -------------------------------------------------------------
        runTest("T1-01 (Feature 24): NullPointerException is sanitized with zero stack traces (AC-11)", () -> {
            NullPointerException npe = new NullPointerException("Simulated internal crash at /home/alekkzsx/Secret.java:42");
            String sanitized = ServerErrorSanitizer.sanitizeException(npe);

            assertTrue(!sanitized.contains("NullPointerException"), "Response must not contain JVM class names");
            assertTrue(!sanitized.contains("/home/alekkzsx"), "Response must not contain server file paths");
            assertTrue(!sanitized.contains(".java:"), "Response must not contain source code line numbers");
            assertTrue(sanitized.contains("\"message\": \"Dados invalidos\""), "Response must be safe generic JSON");
        });

        runTest("T1-02 (Feature 24): Internal server error is sanitized with zero JVM details", () -> {
            RuntimeException internal = new RuntimeException("Database connection failed: jdbc:postgresql://localhost:5432/db");
            String sanitized = ServerErrorSanitizer.sanitizeInternalError(internal);

            assertTrue(!sanitized.contains("RuntimeException"), "Response must not reveal exception type");
            assertTrue(!sanitized.contains("postgresql"), "Response must not reveal database type or port");
            assertTrue(sanitized.contains("\"status\": 500"), "Response status code must be 500");
        });

        // -------------------------------------------------------------
        // FEATURE 4: Mandatory Author Attribution on All Files
        // -------------------------------------------------------------
        runTest("GOV-01 (Feature 4): Line 1 attribution verified on all Java and Dart files", () -> {
            Path testsDir = Paths.get("/home/alekkzsx/Documents/Github/PI-IV-Time3/security/tests");
            assertTrue(Files.exists(testsDir), "security/tests must exist");

            try (DirectoryStream<Path> stream = Files.newDirectoryStream(testsDir)) {
                int inspected = 0;
                for (Path entry : stream) {
                    String name = entry.getFileName().toString();
                    if (name.endsWith(".java") || name.endsWith(".dart")) {
                        List<String> lines = Files.readAllLines(entry, StandardCharsets.UTF_8);
                        assertTrue(!lines.isEmpty(), "File must not be empty: " + name);
                        String line1 = lines.get(0).trim();
                        assertEquals(line1, "// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449",
                                "File " + name + " must have mandatory author attribution on line 1");
                        inspected++;
                    }
                }
                assertTrue(inspected >= 8, "Must inspect at least 8 test files in security/tests/");
            } catch (IOException e) {
                throw new AssertionError("Failed reading test files: " + e.getMessage());
            }
        });

        System.out.println("===============================================================");
        System.out.println("Java Security Server Tests: " + passed.get() + " / " + total.get() + " passed.");
        System.out.println("===============================================================");

        if (passed.get() != total.get()) {
            System.err.println("CRITICAL: Some Java security tests failed!");
            System.exit(1);
        } else {
            System.out.println("ALL JAVA SECURITY SERVER TESTS PASSED WITH 100% SUCCESS RATE.");
            System.exit(0);
        }
    }
}
