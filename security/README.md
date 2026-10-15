# Security — Enterprise Defense Architecture & Governance (AGMRM)

> **Central Security Module**: `security/`  
> **Ecosystem**: AGMRM Integrated Educational Platform (*Plataforma Educacional Integrada* — PI-IV Time 3)  
> **Engineering Standards**: Clean Architecture, SOLID Principles, Zero Unnecessary External Dependencies  

---

## 1. Architectural Purpose & Overview

The `security/` module centralizes the enterprise **Defense-in-Depth** architecture and cybersecurity governance policies for the AGMRM Integrated Educational Platform. This module is engineered to protect critical authentication (**Login**) and credential recovery (**Forgot / Reset Password**) workflows against hostile cyber threats, including:

- Automated brute-force attacks and credential stuffing.
- Cross-Site Scripting (XSS) and SQL injection (SQLi) attempts.
- Side-channel timing attacks on identity validation.
- User and academic identity enumeration attacks.
- Ephemeral recovery token tampering, replay, and session hijacking.
- Denial of Service (DoS) and memory exhaustion attacks via oversized payloads.

All defense components, governance policies, input sanitizers, HTTP control middlewares, configuration templates, and automated test suites reside strictly in a self-contained structure within the `security/` directory.

---

## 2. Modular Subpackage Architecture

The `security/` ecosystem is structured into clean, modular subpackages featuring symmetrical and interoperable implementations across the client (Dart/Flutter) and server (Native Java SE with zero third-party framework overhead):

```
security/
├── .env.example                               # Secure environment configuration template
├── README.md                                  # Architecture and governance manual (this file)
├── pubspec.yaml                               # Dart/Flutter package manifest for client-side integration
├── analysis_options.yaml                      # Dart static analysis and linter configuration
├── lib/                                       # Client-side defense implementations (Dart)
│   ├── security.dart                          # Unified export barrel for client security package
│   ├── policies/                              # Governance policies and immutable constants
│   │   ├── security_constants.dart            # Immutable parameters (TTL, thresholds, retry limits)
│   │   └── generic_feedback_policy.dart       # Opaque response messages preventing user enumeration
│   ├── validators/                            # Client-side input and complexity validators
│   │   ├── input_sanitizer.dart               # Sanitizer neutralizing XSS, SQLi, and null bytes
│   │   └── password_entropy_validator.dart    # 4-factor password entropy evaluator (score >= 3 threshold)
│   ├── auth/                                  # Authentication state machines and token controllers
│   │   ├── rate_limiter.dart                  # Client rate limiter (5 failed attempts -> 30s lockout)
│   │   ├── lockout_state.dart                 # Immutable lockout state model
│   │   ├── timing_attack_mitigation.dart      # Artificial latency normalizer and cryptographic work
│   │   └── token_lifecycle_manager.dart       # 300s TTL token tracker with 3-attempt OTP invalidation
│   └── widgets/                               # Security-focused presentation widgets (Flutter)
│       ├── lockout_countdown_banner.dart      # Interactive lockout banner with real-time countdown
│       └── token_timer_widget.dart            # Visual indicator tracking recovery token expiration
├── auth/                                      # Server-side native authentication guards (Java SE)
│   ├── AccountLockoutManager.java             # Thread-safe in-memory brute-force lockout tracker
│   ├── ConstantTimeComparator.java            # Constant-time byte comparison (MessageDigest.isEqual)
│   └── EphemeralRecoveryTokenManager.java     # Ephemeral token lifecycle manager (5-minute TTL)
├── middleware/                                # Native HTTP server filters and middlewares (Java SE)
│   ├── SecurityHeadersFilter.java             # Injects nosniff, DENY, CSP, and CORS headers
│   ├── BoundedBodyReader.java                 # Strict 64 KB request payload ceiling (HTTP 413)
│   └── ServerErrorSanitizer.java              # Suppresses JVM stack traces and internal paths
├── validators/                                # Server-side input sanitizers (Java SE)
│   ├── ServerInputSanitizer.java              # Sanitization for RA, email, password, and null bytes
│   └── ServerPasswordEntropyValidator.java    # Server-side password entropy evaluator (0 to 4 score)
├── policies/                                  # Server-side security governance and constants (Java SE)
│   ├── SecurityConstants.java                 # Numerical invariants and HTTP header specifications
│   ├── GenericFeedbackPolicy.java             # Uniform opaque response generator
│   └── SecurityConfig.java                    # Environment configuration loader with secure fallbacks
└── tests/                                     # Comprehensive automated test suites (Tiers 1 to 4)
    ├── security_constants_test.dart           # Unit tests for security invariants
    ├── generic_feedback_test.dart             # Anti-user enumeration verification suite
    ├── rate_limiter_test.dart                 # Rate limiter unit and state machine tests
    ├── token_lifecycle_test.dart              # Token expiration and revocation test suite
    ├── input_sanitizer_test.dart              # Malicious payload sanitization test suite
    ├── password_entropy_test.dart             # Password strength calculation test suite
    ├── timing_attack_test.dart                # Timing attack latency equalization tests
    ├── CrossFeatureSecurityTest.dart          # Cross-tier integration test suite (Tier 3)
    ├── RealWorldAttackWorkloadTest.dart       # High-throughput attack simulation suite (Tier 4)
    ├── SecurityServerTestSuite.java           # Native Java test runner for server guards
    └── run_all_tests.sh                       # Master bash runner executing all test suites
```

---

## 3. Defense-in-Depth Architecture (4 Tiers)

Platform security operates across four complementary, interconnected defensive tiers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TIER 1: CLIENT DEFENSE                          │
│                    (Flutter Client / security/lib/)                    │
│  • Interactive 30-second lockout countdown banner                      │
│  • Real-time 4-factor password entropy validation (Score >= 3)         │
│  • Synchronous 300s TTL recovery token countdown indicator             │
│  • Pre-flight input sanitization on academic IDs (RA) and emails       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ TLS 1.3 / HTTPS
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               TIER 2: NETWORK & DEFENSIVE MIDDLEWARE                   │
│                     (security/middleware/)                             │
│  • Security response headers (nosniff, DENY, CSP, HSTS)                │
│  • Strict 64 KB request body ceiling (65,536 bytes -> HTTP 413)        │
│  • Zero JVM stack trace leakage in JSON error responses                │
│  • Hardened CORS header governance                                     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Filtered Request
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             TIER 3: AUTHENTICATION & RECOVERY GUARDS                   │
│                  (security/auth/ & validators/)                        │
│  • Brute-force mitigation: 5 failed attempts -> 30s lockout cooldown   │
│  • Token lifecycle: strict 5-minute (300s) TTL expiration              │
│  • Automatic recovery session revocation after 3 invalid OTP attempts  │
│  • Anti-user enumeration via identical opaque feedback responses       │
│  • Side-channel protection via constant-time comparison and jitter     │
│  • Input sanitization stripping <script>, SQL escapes, and null bytes  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Governance
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             TIER 4: SECRETS, CONFIGURATION & POLICIES                  │
│                     (security/policies/ & .env)                        │
│  • Strict environment variable governance via .env.example             │
│  • Zero hardcoded credentials, private keys, or secrets in git         │
│  • Centralized branch protection and CODEOWNERS code review policies   │
│  • Immutable constants and timeout thresholds                          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Threat Modeling Matrix (STRIDE & Mitigations)

Risk assessment following the **STRIDE** methodology maps attack vectors to the defensive controls implemented across `security/`:

| STRIDE Category | Threat Vector in Educational Context | Defensive Component | Countermeasure & Defensive Behavior |
|---|---|---|---|
| **S — Spoofing** | Attacker attempts to guess student or faculty credentials using automated brute force or credential stuffing. | `security/auth/AccountLockoutManager.java` & `rate_limiter.dart` | Immediate 30-second lockout after 5 consecutive failed attempts. Immediate rejection of new attempts with HTTP 429 during cooldown. |
| **S — Spoofing** | Brute force of the 6-digit recovery PIN/OTP code ($10^6$ combinations). | `security/auth/EphemeralRecoveryTokenManager.java` & `token_lifecycle_manager.dart` | Immediate session revocation and token invalidation after 3 incorrect verification attempts. |
| **T — Tampering** | Injection of `<script>` tags, SQL meta-characters, or control characters into RA, email, or password fields. | `security/validators/ServerInputSanitizer.java` & `input_sanitizer.dart` | Neutralization of HTML tags, SQL comment/quote sequences, and complete removal of null bytes (`\0`, `%00`). |
| **T — Tampering** | Reuse or modification of expired password reset tokens to hijack credentials. | `security/auth/EphemeralRecoveryTokenManager.java` | Strict 300-second (5-minute) TTL; unconditional rejection of tokens submitted after expiry. |
| **R — Repudiation** | User denies performing administrative actions, password resets, or authentication attempts. | `security/policies/SecurityConfig.java` & Structured Logging | Immutable audit logging with timestamps, client IP hashing, and attempt counters. |
| **I — Information Disclosure** | User enumeration: attacker queries endpoints to discover registered RAs and emails based on error message differences. | `security/lib/policies/generic_feedback_policy.dart` & `GenericFeedbackPolicy.java` | Identical opaque responses returned for both registered and unregistered identifiers. |
| **I — Information Disclosure** | Side-channel timing attack: attacker analyzes response latency to deduce account existence or credential correctness. | `security/auth/ConstantTimeComparator.java` & `timing_attack_mitigation.dart` | Constant-time evaluation using `MessageDigest.isEqual` combined with latency normalization jitter. |
| **I — Information Disclosure** | Leaking JVM internal stack traces, file paths, or class names through unhandled runtime exceptions. | `security/middleware/ServerErrorSanitizer.java` | Global exception containment; standardized RFC 7807 JSON error responses without stack traces. |
| **D — Denial of Service** | Flooding native server sockets with multi-megabyte request bodies to exhaust JVM heap memory. | `security/middleware/BoundedBodyReader.java` | Content-Length validation and stream cutoff at exactly 64 KB (65,536 bytes). Early abort with HTTP 413. |
| **E — Elevation of Privilege** | Setting weak or trivial passwords ("123456", "admin") to facilitate account compromise. | `security/validators/ServerPasswordEntropyValidator.java` & `password_entropy_validator.dart` | Mandatory 4-factor password scoring (length, uppercase, lowercase, numbers/symbols); rejection if score < 3. |

---

## 5. Environment Configuration & Governance (`.env.example`)

Standardized security environment parameters are defined in `security/.env.example`:

```properties
# Native HTTP Server Configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
REQUEST_TIMEOUT_SECONDS=30

# Request Body Size Ceiling (64 KB = 65,536 bytes)
MAX_REQUEST_BODY_SIZE_BYTES=65536

# CORS Governance
ALLOWED_ORIGINS=*
CORS_ALLOWED_METHODS=GET, POST, PUT, DELETE, OPTIONS

# Brute-Force & Account Lockout Mitigation
MAX_FAILED_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_SECONDS=30

# Ephemeral Recovery Token Lifecycle (5 minutes TTL)
RECOVERY_TOKEN_TTL_SECONDS=300
MAX_VERIFICATION_ATTEMPTS=3

# Timing Attack Mitigation
STANDARDIZED_AUTH_LATENCY_MS=1000
STANDARDIZED_AUTH_JITTER_MS=25

# Password Complexity Policies
PASSWORD_MIN_LENGTH=8
PASSWORD_MIN_ENTROPY_SCORE=3

# Cryptographic Keys (RFC 7519)
JWT_SECRET=super_secret_high_entropy_signing_key_at_least_32_chars_2026
```

---

## 6. Build, Test, and Verification Procedures

### 6.1 Running Client-Side Dart / Flutter Test Suites
To verify unit and integration tests for client components:
```bash
cd /home/alekkzsx/Documents/Github/PI-IV-Time3/security
flutter pub get
flutter analyze
flutter test tests/
```

### 6.2 Compiling and Running Server-Side Java Tests
Native Java components adhere strictly to the zero-external-dependency rule (compilable using standard JDK):
```bash
cd /home/alekkzsx/Documents/Github/PI-IV-Time3/security
javac policies/*.java auth/*.java middleware/*.java validators/*.java
```

### 6.3 Unified Test Suite Execution
To execute the comprehensive end-to-end verification script:
```bash
bash /home/alekkzsx/Documents/Github/PI-IV-Time3/security/tests/run_all_tests.sh
```

---

## 7. Standards & Compliance Alignment

- **OWASP Top 10 API Security Risks (2023)**: Mitigations for Broken Object Level Authorization (API1), Broken Authentication (API2), Unrestricted Resource Consumption (API4), and Security Misconfiguration (API8).
- **STRIDE Threat Modeling Framework**: Systematic risk assessment applied across all platform surfaces.
- **Academic Integrity Standards**: Source code files include appropriate developer attribution comments in compliance with institutional guidelines, while architecture and governance documentation remains platform-centric.
