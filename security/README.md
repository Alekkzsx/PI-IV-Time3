# Security — Enterprise Defense Architecture & Governance (AGMRM)

> **Central Security Module**: `.../PI-IV-Time3/security/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Defense-in-Depth, Clean Architecture, Zero Unnecessary External Dependencies  

---

## 1. Architectural Overview & Purpose

The `security` module centralizes the enterprise **Defense-in-Depth** architecture and cyber governance policies of the AGMRM platform. It protects authentication workflows, credential recovery mechanisms, and HTTP socket communications against critical vulnerabilities (OWASP Top 10), including:

- Brute-force attacks and credential stuffing.
- SQL Injection (SQLi) and Cross-Site Scripting (XSS).
- Side-channel timing attacks on credential and token validation.
- User identity harvesting and account enumeration across student, teacher, and admin roles.
- Session hijacking and ephemeral token tampering.
- Memory amplification and Denial-of-Service (DoS) via inflated HTTP payloads.

---

## 2. Directory Structure

The module structure strictly aligns with Dart/Flutter package standards and enterprise Java backend conventions:

```
.../PI-IV-Time3/security/
├── lib/                          # Client-side defenses (Dart / Flutter)
│   ├── auth/                     # Authentication controllers and defensive state guards
│   │   ├── lockout_state.dart
│   │   ├── rate_limiter.dart
│   │   ├── timing_attack_mitigation.dart
│   │   └── token_lifecycle_manager.dart
│   ├── policies/                 # Invariants and opaque response policies
│   │   ├── generic_feedback_policy.dart
│   │   └── security_constants.dart
│   ├── validators/               # Input sanitizers and password entropy scorers
│   │   ├── input_sanitizer.dart
│   │   └── password_entropy_validator.dart
│   ├── widgets/                  # Institutional UI defensive components
│   │   ├── lockout_countdown_banner.dart
│   │   └── token_timer_widget.dart
│   └── security.dart             # Unified package barrel export
├── test/                         # 37 native automated tests (unit and integration)
│   ├── cross_feature_security_test.dart
│   ├── e2e_test_runner.dart
│   ├── generic_feedback_test.dart
│   ├── input_sanitizer_test.dart
│   ├── m1_adversarial_challenge_test.dart
│   ├── password_entropy_test.dart
│   ├── rate_limiter_test.dart
│   ├── real_world_attack_workload_test.dart
│   ├── security_constants_test.dart
│   ├── timing_attack_test.dart
│   └── token_lifecycle_test.dart
├── server/                       # Server-side security filters (Java SE)
│   ├── src/security/
│   │   ├── auth/                 # AccountLockoutManager, ConstantTimeComparator, EphemeralRecoveryTokenManager
│   │   ├── middleware/           # SecurityHeadersFilter, BoundedBodyReader, ServerErrorSanitizer
│   │   ├── policies/             # GenericFeedbackPolicy, SecurityConstants
│   │   └── validators/           # ServerInputSanitizer, ServerPasswordEntropyValidator
│   └── test/                     # Adversarial and stress tests for Java server
│       ├── M1AdversarialChallengeTest.java
│       └── SecurityServerTestSuite.java
├── analysis_options.yaml         # Strict linter rules
├── pubspec.yaml                  # agmrm_security package manifest
└── README.md                     # Security technical manual (this file)
```

---

## 3. Four Tiers of Defensive Protection

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TIER 1: CLIENT DEFENSE                          │
│                    (Flutter Client / security/lib/)                    │
│  • Interactive 30-second lockout countdown banner                      │
│  • 4-factor password entropy validation (Score >= 3)                   │
│  • Ephemeral recovery token countdown timer (300s TTL)                 │
│  • Pre-flight input sanitization of ID, email, and strings (XSS/SQLi)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ TLS 1.3 / HTTPS
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      TIER 2: DEFENSIVE MIDDLEWARE                      │
│                   (security/server/src/security/middleware/)           │
│  • HTTP defensive security headers (nosniff, DENY, CSP, HSTS)          │
│  • Strict 64 KB payload boundary (65,536 bytes -> HTTP 413)            │
│  • Error sanitizer suppressing internal stack traces and DB logs       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    TIER 3: INSTITUTIONAL POLICIES                      │
│                     (security/server/src/security/policies/)           │
│  • Opaque anti-enumeration responses identical for valid and fake IDs   │
│  • Centralized numeric invariants and regimental boundaries            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   TIER 4: RESILIENCE & HARDENING                       │
│                      (security/server/src/security/auth/)              │
│  • Constant-time string comparator (side-channel mitigation)           │
│  • Rate limiter with 30s lockout after 5 consecutive auth failures     │
│  • OTP token invalidation and session revocation after 3 bad attempts  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Running Security Tests

Thanks to the standardized `test/` directory layout, all automated tests execute using standard Flutter tooling:

```bash
# Execute security test suite (37 automated tests)
cd .../PI-IV-Time3/security
flutter test

# Execute static analysis (0 issues)
flutter analyze
```

---

## 5. Frontend Integration

The `agmrm_security` package is linked as a local path dependency in `.../PI-IV-Time3/frontend/pubspec.yaml`:

```yaml
dependencies:
  agmrm_security:
    path: ../security
```

Any update to security policies, rate-limit thresholds, or defensive widgets instantly reflects across the Flutter application during `flutter run`.
