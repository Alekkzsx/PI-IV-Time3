# Security — Enterprise Defense Architecture & Governance

The `security` module centralizes cybersecurity policies, defensive controls, threat models, and environment hardening guidelines for the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3).

---

## 🛡️ Architectural Purpose & Scope

Information security in AGMRM is designed as a foundational cross-cutting concern rather than an isolated perimeter. This module provides institutional standards and architectural guardrails spanning every tier of the ecosystem:
1. **Client-Side Defense**: Guarding user credentials, mitigating credential stuffing, and enforcing session boundaries in the Flutter client (`frontend/`).
2. **Server-Side Hardening**: Enforcing request boundaries, sanitization, input size constraints, and header hygiene in the native Java server (`server/`) and enterprise backend (`backend/`).
3. **Pipeline & Governance Security**: Enforcing branch protection, code ownership reviews, and automated gatekeeping via GitHub Actions (`.github/`).
4. **Secrets & Environment Governance**: Zero credential leakage across version control via enterprise-grade `.gitignore` rules.

---

## 📂 Current Repository State & Structural Reservation

On disk, the `security` directory currently contains a versioned placeholder:

```
security/
├── .gitkeep                      # Git placeholder maintaining directory structure
└── README.md                     # Security architecture documentation (this file)
```

### Why is `.gitkeep` Present?
In the initial development phase:
- Security mechanisms are embedded directly into active components (e.g. `SecurityAlertBanner` and `InputValidators` in the Flutter client; exception containment and CORS headers in `HttpUtils.java`).
- The `security/` directory is versioned via `.gitkeep` to serve as the designated home for dedicated, standalone institutional artifacts (such as environment configuration templates `.env.example`, formal vulnerability disclosure policies, audit logs, and compliance attestations) as the platform scales toward production deployment.

---

## 🧱 Defense-in-Depth Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TIER 1: CLIENT DEFENSE                          │
│                           (Flutter Client)                             │
│  • 5-Minute Token TTL (SecurityAlertBanner)                            │
│  • 4-Factor Password Scoring (PasswordStrengthIndicator)               │
│  • Pre-flight Format & RFC Email Sanitization (InputValidators)        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ TLS 1.3 / HTTPS
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        TIER 2: NETWORK & GATEWAY                       │
│                           (Reverse Proxy / CORS)                       │
│  • CORS Header Controls (Access-Control-Allow-*)                       │
│  • Rate Limiting & Anti-Brute-Force Throttling                         │
│  • Connection Isolation & Request Size Limits (Max 64KB)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Internal Dispatch
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        TIER 3: SERVER & APPLICATION                    │
│                      (Native Java & Future Backend)                    │
│  • Thread Exception Isolation (Try-Catch per Request)                  │
│  • Strict Type Casting & Integer Range Bounds                          │
│  • Parameterized SQL Queries / ORM Protection against SQL Injection    │
│  • Role-Based Access Control (RBAC: Aluno, Docente, Admin)             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Encrypted Storage
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        TIER 4: SECRETS & REPOSITORY                    │
│                       (GitHub & Environment Policy)                    │
│  • Zero Hardcoded Secrets (Enforced via .gitignore)                    │
│  • Branch Protection: PR to main restricted to develop                 │
│  • Mandatory Code Owner Reviews (CODEOWNERS: @Alekkzsx & @Guilherme)   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🔒 Layered Defensive Controls

### 1. Client-Side Defensive Controls (`frontend/`)
- **Strict Recovery Token Lifetime**: Recovery tokens and security PINs enforce a strict **5-minute Time-To-Live (TTL)**. This window is visually signaled to the student through `SecurityAlertBanner` to counter link hijacking and credential interception.
- **Dynamic Credential Complexity**: Implemented via `PasswordStrengthIndicator`, validating passwords across four distinct vectors:
  1. Minimum length of 8 characters.
  2. Mixed-case alphabetic characters (both uppercase and lowercase).
  3. Numeric digits ($0-9$).
  4. Special characters and symbols (`!@#$%^&*()_+-=[]{}|;:,.<>?`).
- **Input Sanitization**: Pre-flight validation executed by `InputValidators` verifies that student IDs (RA/Matrícula) meet character constraints and emails match RFC standard patterns before triggering network round-trips, preventing malformed payload amplification.

### 2. Server-Side Defensive Controls (`server/` & `backend/`)
- **CORS Hardening**: Centralized in `HttpUtils.aplicarHeadersCors()`. Outgoing HTTP responses explicitly declare allowed origins and methods (`GET, POST, PUT, DELETE, OPTIONS`), preventing unauthorized cross-origin browser interactions.
- **Thread & Exception Isolation**: All parsing operations across `TesteTiposHandler`, `PresencaHandler`, `TarefasHandler`, and `BoletimHandler` execute inside isolated `try-catch` blocks. Malformed payloads trigger an HTTP `400 Bad Request` without propagating uncaught runtime exceptions or terminating the server thread.
- **Denial of Service (DoS) Mitigation**:
  - Request body buffering with maximum byte threshold limits (64 KB ceiling).
  - Explicit read timeouts (30-second ceiling) to mitigate slowloris connection-holding attacks.
- **SQL Injection Prevention**: Future backend data persistence layers will enforce 100% parameterized queries via JPA/Hibernate or raw prepared statements; string concatenation in SQL execution is strictly forbidden.

### 3. Secrets & Configuration Governance
- **Zero Hardcoded Credentials**: No database passwords, private encryption keys, API tokens, or credentials may be committed to version control.
- **`.gitignore` Hardening**: Root `.gitignore` explicitly excludes:
  - `.env`, `.env.local`, `.env.*.local`, `.env.production`
  - Java `.class` files, `.jar`, `.war`, and build artifacts
  - Private IDE settings and OS cache files
- **Safe Template Specification**: Environment variables must be documented exclusively via sanitized template files (e.g. `.env.example`) containing dummy placeholders:
  ```properties
  # AGMRM Environment Template (.env.example)
  SERVER_PORT=8080
  DATABASE_URL=jdbc:postgresql://localhost:5432/agmrm_db
  DATABASE_USER=agmrm_app
  DATABASE_PASSWORD=CHANGE_ME_IN_PRODUCTION
  JWT_SECRET=MINIMUM_32_CHARACTERS_HEX_SECRET_KEY
  TOKEN_TTL_MINUTES=5
  ```

---

## 🎯 Threat Modeling & Risk Analysis

The platform security model is assessed using the **STRIDE** methodology:

| Threat Category | Potential Attack Vector | AGMRM Defensive Countermeasure | Risk Severity |
|---|---|---|---|
| **S — Spoofing** | Attacker impersonates student or teacher during login. | Multi-role authentication tabs, validated academic registration (RA), password complexity enforcement, planned JWT authentication. | High |
| **T — Tampering** | Tampering with grade values or attendance percentages via HTTP requests. | Strict server-side recalculation in `BoletimHandler` and `PresencaHandler`; inputs are bounded and validated regardless of client claims. | Critical |
| **R — Repudiation** | User denies performing an action (e.g. submitting assignment or altering attendance). | Server logs with timestamps, explicit teacher override tags (`Ajuste Manual do Professor`), immutable audit trails planned in backend. | Medium |
| **I — Information Disclosure** | Leaking sensitive student data, passwords, or stack traces in responses. | Generic error messages (`400 Bad Request`, `Dados invalidos`) without raw JVM stack traces; obscured password fields in UI. | High |
| **D — Denial of Service** | Flooding native server with malformed payloads or large bodies. | Connection isolation, minimal memory footprint of native Java server, 64KB body caps, CORS pre-flight handling. | Medium |
| **E — Elevation of Privilege** | Student attempting to execute teacher manual attendance overrides. | Role-based separation between Student, Faculty, and Admin in UI; future backend token role claims validation. | Critical |

---

## 📋 Vulnerability Management Policy

### Reporting Security Issues
If a security vulnerability or sensitive flaw is identified within any module of this repository:
1. **Do NOT open a public GitHub Issue.**
2. Privately notify the repository maintainers:
   - Alex Gabriel Soares Sousa (`@Alekkzsx`)
   - Guilherme Henrique Moreira (`@GuilhermeMoreira07`)
3. Provide full reproduction steps, payload samples, and affected component paths.
4. Maintainers will triage, test a patch in a private branch, and release a fix via the standard Gitflow pipeline (`develop` $\rightarrow$ `main`).
