# Server — Zero-Dependency Native Java HTTP & WebSocket Server (AGMRM)

> **Core Server Module**: `.../PI-IV-Time3/server/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Pure Java SE standard library (Java 8+), Zero external dependencies, Deterministic TCP sockets & RFC 6455 WebSockets, Clean OO Architecture (`abstratas/` + `modules/` + `utils/`)

The `server` module contains the native, autonomous, and high-performance HTTP & WebSocket server developed for the **Integrated Educational Platform AGMRM** (*PI-IV Team 3*).

It operates 100% on the **Java SE standard library** (compiled with `--release 8`, compatible with Java 8 through 25) with zero heavy frameworks (no Spring, Quarkus, Maven, JUnit, or Tomcat).

**Primary Responsibilities (Bounded Context on Port `8080`)**:
- **Authoritative Identity & Access Management**: Complete login system (PBKDF2/BCrypt verification, JWT HS256 access/refresh/recovery tokens, 2FA + backup codes, single-use OTP recovery, password change, profile/preferences/sessions/LGPD export, and admin user management + teacher provisioning)
- **Video Conferencing & Real-Time Signaling**: Persisted rooms and single-use WebSocket tickets (`academic_live_sessions`, `video_call_ws_tickets`, `video_call_attendance_logs`) via `/api/video-call/rooms*`, RFC 6455 `/ws/video-call/{roomCode}`, chat sync, and legacy `/api/videocall/*` telemetry
- **Internal Bridge Consumer**: Calls `backend/` (`:3001`) at `/api/internal/academic/*` with `X-Internal-Service-Secret` (`ClientePonteAcademica`) to authorize academic class membership, list allowed classrooms, and fetch LGPD/dossier academic summaries

---

## 🏛️ Modular OO Architecture (`abstratas/` + `modules/` + `utils/`)

Every major domain (`core`, `auth`, `videocall`) follows the same predictable, self-documenting structure:
- **`abstratas/`** — Abstract base classes implementing *Template Method*, *Strategy/Chain of Responsibility* and polymorphic HTTP error handling.
- **`modules/`** — Cohesive concrete modules grouped by feature (each file focused on a single responsibility).
- **`utils/`** — Reusable helper functions and cryptographic primitives shared across modules.

```text
.../PI-IV-Time3/server/
├── bin/                                              # Compiled Java 8 bytecode (.class)
├── lib/                                              # MongoDB Java Sync Driver JARs
├── src/
│   ├── Main.java                                     # Central route index (Saude, Auth, Admin, VideoCall)
│   ├── utils/                                        # Global reusable utilities
│   │   ├── BsonUtils.java                            # Document <-> Map/List recursive conversion
│   │   ├── ConfigEnv.java                            # Master root .env reader
│   │   ├── Json.java                                 # Full RFC 8259 JSON parser/serializer
│   │   ├── JsonSimples.java                          # String escaping & flat JSON helper
│   │   └── RedeUtils.java                            # Stream UTF-8, URL encode, IP extraction, loopback
│   ├── core/                                         # Native HTTP socket engine & MongoDB infrastructure
│   │   ├── abstratas/
│   │   │   ├── ExcecaoHttpAbstrata.java              # Polymorphic HTTP exception base (statusHttp + codigo)
│   │   │   ├── HandlerHttpAbstrato.java              # Template Method HTTP (CORS, OPTIONS, 405, catch)
│   │   │   └── RepositorioMongoAbstrato.java         # Template Method MongoDB (indexes, failover, errors)
│   │   ├── ConexaoMongo.java                         # MongoClient, SRV->Direct failover & health cache
│   │   ├── DatabaseUnavailableException.java         # 503 exception for DNS/network blocked MongoDB
│   │   ├── HealthHandler.java                        # GET /health and /health/ready
│   │   ├── HttpUtils.java                            # CORS & defensive security headers
│   │   ├── ManipuladorHttp.java                      # HTTP handler contract interface
│   │   ├── RequisicaoHttp.java                       # TCP socket HTTP/1.1 request parser
│   │   ├── ResilientDnsClient.java                   # JNDI + DNS-over-HTTPS (DoH) resolver
│   │   ├── RespostaHttp.java                         # Native HTTP/1.1 response writer
│   │   └── ServidorHttpNativo.java                   # ServerSocket, ThreadPool, routing & WS upgrade
│   ├── auth/                                         # Identity, sessions, account, admin & resilient e-mail
│   │   ├── abstratas/
│   │   │   ├── HandlerAutenticadoAbstrato.java       # Mandatory JWT + MongoDB session guard
│   │   │   ├── HandlerAuthPublicoAbstrato.java       # Shared token/session issuance for public auth flows
│   │   │   ├── AdminHandlerAbstrato.java             # Mandatory admin RBAC + bridge + write-guard
│   │   │   ├── CanalEnvioEmailAbstrato.java          # Resilient e-mail channel contract (Tier 1/2/3)
│   │   │   ├── CanalHttpsEmailAbstrato.java          # Shared HTTPS POST JSON transport (Tier 2)
│   │   │   └── TemplateEmailAbstrato.java            # Single institutional HTML layout + XSS escaping
│   │   ├── model/
│   │   │   └── UsuarioAutenticado.java               # Authenticated identity model
│   │   ├── utils/
│   │   │   ├── AuthHttpUtils.java                    # Email masking, constant latency, user/profile DTOs
│   │   │   ├── BCrypt.java                           # Standard Blowfish/BCrypt implementation
│   │   │   ├── JwtAuthValidator.java                 # HS256 JWT validation + MongoDB session check
│   │   │   ├── JwtGerador.java                       # Unified HS256 token generator (access/refresh/recovery)
│   │   │   ├── LimitadorTentativas.java              # Progressive anti-brute-force rate limiter
│   │   │   ├── OtpService.java                       # 6-digit SecureRandom OTP + HMAC-SHA256 + SHA-256
│   │   │   ├── RevogacaoTokens.java                  # In-memory JTI revocation blacklist
│   │   │   └── SenhaHasher.java                      # PBKDF2WithHmacSHA256 (600k) + BCrypt verification
│   │   └── modules/
│   │       ├── login/                                # LoginHandler, TwoFactorHandler, RefreshTokenHandler, LogoutHandler, AuthSessionHandler
│   │       ├── conta/                                # ProfileAccountHandler, ProfileHandler, AccountSecurityHandler, ChangePasswordHandler, RecoveryHandler
│   │       ├── admin/                                # AdminUsersHandler, AdminUserCrudHandler, AdminUserSecurityHandler, AdminUserDossierHandler, AdminTeacherHandler, EmailDiagnosticHandler
│   │       ├── persistencia/                         # RepositorioUsuarios (Facade), RepositorioContas, RepositorioSessoes, RepositorioOtps, RepositorioAuditoria
│   │       └── email/                                # SmtpCliente (Facade), MensagemEmail, CircuitBreakerSmtp, CanalSmtpNativo, CanalResendEmail, CanalBrevoEmail, CanalWebhookEmail, CanalOutboxLocal, TemplateEmail*
│   ├── videocall/                                    # Video conferencing REST, persistence & WebRTC hub
│   │   ├── abstratas/
│   │   │   └── HandlerVideoCallLegadoAbstrato.java   # Optional JWT + VideoCallService base handler
│   │   ├── utils/
│   │   │   └── VideoCallUtils.java                   # Room code sanitizer, participant resolution & attendance math
│   │   └── modules/
│   │       ├── rooms/                                # VideoCallMongoHandler, RepositorioVideoCall, TicketWebSocketValidator
│   │       ├── legado/                               # VideoCallService, VideoCallRoomHandler, VideoCallSignalingHandler, VideoCallInteractionHandler, VideoCallAttendanceHandler
│   │       └── hub/                                  # SalaVideoHub, RegistradorChat, RegistradorEnvelope
│   ├── bridge/                                       # Authenticated internal HTTP client (:3001)
│   │   └── ClientePonteAcademica.java
│   └── websocket/                                    # Pure RFC 6455 WebSocket engine
│       ├── AtendenteWebSocket.java
│       ├── ConexaoWebSocket.java
│       ├── HandshakeWebSocket.java
│       ├── OuvinteWebSocket.java
│       └── QuadroWebSocket.java
└── tests/                                            # Zero-dependency Java test suites (17 suites)
    ├── SuiteTestesServidor.java
    ├── auth/                                         # 9 auth/network/email suites
    ├── core/                                         # HttpUtilsCorsTeste + ArquiteturaAbstrataTeste
    ├── utils/                                        # ConfigEnvTeste + JsonTeste
    ├── videocall/hub/                                # HubTeste + RegistradorChatTeste
    └── websocket/                                    # HandshakeTeste + QuadroTeste
```

---

## 🧩 10 Abstract Classes (OO Pillars)

| Abstract Class | Package | Pattern | Responsibility |
|---|---|---|---|
| `ExcecaoHttpAbstrata` | `core.abstratas` | Polymorphism | Unifies HTTP status + error code across `DatabaseUnavailableException`, `HttpSecurityException` and `ExcecaoPonteAcademica` |
| `HandlerHttpAbstrato` | `core.abstratas` | Template Method | Standardizes CORS, security headers, `OPTIONS 204`, `405` validation, JSON helpers and polymorphic error handling |
| `RepositorioMongoAbstrato` | `core.abstratas` | Template Method | Centralizes MongoDB database access, async safe index creation (`85`/`86` conflict handling) and error translation |
| `HandlerAutenticadoAbstrato` | `auth.abstratas` | Template Method | Enforces Bearer JWT + MongoDB active session validation before invoking subclasses |
| `HandlerAuthPublicoAbstrato` | `auth.abstratas` | Template Method | Centralizes token pair issuance, session persistence and standard auth payload assembly |
| `AdminHandlerAbstrato` | `auth.abstratas` | Template Method | Enforces `admin` profile, injects `ClientePonteAcademica`, validates write-guard and user IDs |
| `CanalEnvioEmailAbstrato` | `auth.abstratas` | Strategy / Chain | Common delivery contract for Tier 1 (SMTP), Tier 2 (HTTPS) and Tier 3 (Outbox) |
| `CanalHttpsEmailAbstrato` | `auth.abstratas` | Template Method | Shared HTTPS POST JSON transport with optional 302 redirect handling for Resend, Brevo and Webhook |
| `TemplateEmailAbstrato` | `auth.abstratas` | Template Method | Single institutional HTML layout with built-in XSS escaping shared across all 4 e-mail templates |
| `HandlerVideoCallLegadoAbstrato` | `videocall.abstratas` | Template Method | Optional JWT authentication and `VideoCallService` helpers for legacy `/api/videocall/*` routes |

---

## 🚀 Compiling & Running

### Manual Execution (Linux / macOS)
```bash
cd server
find src -name "*.java" > /tmp/server_src.txt
javac --release 8 -encoding UTF-8 -cp "lib/*" -d bin @/tmp/server_src.txt
java -Dfile.encoding=UTF-8 -cp "bin:lib/*" Main
```

### Automated Native Test Suite (17 Suites)
```bash
cd server
mkdir -p /tmp/server_test_bin
find src tests -name "*.java" > /tmp/server_all.txt
javac --release 8 -encoding UTF-8 -cp "lib/*" -d /tmp/server_test_bin @/tmp/server_all.txt
java -Dfile.encoding=UTF-8 -cp "/tmp/server_test_bin:lib/*" SuiteTestesServidor
```

**Test Suites (17/17)**:
1. `ConfigEnvTeste` — Master `.env` loading and validation
2. `JsonTeste` — Full JSON & JsonSimples parsing/serialization
3. `HandshakeTeste` — RFC 6455 `Sec-WebSocket-Accept`
4. `QuadroTeste` — RFC 6455 framing & masking
5. `RegistradorChatTeste` — WebSocket chat recording & sync
6. `HubTeste` — Live WebSocket hub routing & room isolation
7. `JwtAuthValidatorTeste` — HS256 JWT validation, revocation, password-change guard & RBAC
8. `SenhaHasherTeste` — PBKDF2WithHmacSHA256 & BCrypt verification + complexity rules
9. `RevogacaoTokensTeste` — In-memory JTI blacklist & expiration cleanup
10. `LimitadorTentativasTeste` — Progressive anti-brute-force lockout
11. `OtpServiceTeste` — 6-digit OTP generation, HMAC storage & validation
12. `RecoveryHandlerTeste` — Single-use recovery reset grant & anti-replay
13. `HandlerLifecycleTeste` — Shared DB pool preservation across handlers
14. `HttpUtilsCorsTeste` — Dynamic origin resolution & Private Network Access
15. `ResilientNetworkTeste` — DNS-over-HTTPS (DoH) parsing & HTTP 503 network diagnostics
16. `SmtpClienteTeste` — RFC 5321 CRLF/dot-stuffing, AUTH LOGIN/PLAIN, Webhook validation & Circuit Breaker
17. `ArquiteturaAbstrataTeste` — Abstract classes (*Template Method*, HTTP exceptions, e-mail channels/templates) & shared utils

---

## 📡 Registered API Endpoints Catalog

Base URL: `http://localhost:8080`

| Group | Method | Endpoint | Handler |
|---|---|---|---|
| **Health** | `GET` | `/health`, `/health/ready` | `HealthHandler` |
| **Login** | `POST` | `/api/auth/login`, `/logout`, `/refresh`, `/verify-two-factor` | `auth.modules.login.*` |
| **Session** | `GET` / `POST` | `/api/auth/session`, `/api/auth/me` | `AuthSessionHandler` |
| **Account** | `PATCH` / `GET` / `POST` / `DELETE` | `/api/auth/profile`, `/lgpd-export`, `/sessions*`, `/logout-others`, `/two-factor`, `/backup-codes`, `/security-logs` | `ProfileAccountHandler` (`ProfileHandler` + `AccountSecurityHandler`) |
| **Password** | `POST` | `/api/auth/send-recovery-otp`, `/verify-recovery-otp`, `/reset-password`, `/change-password` | `RecoveryHandler`, `ChangePasswordHandler` |
| **Admin** | `GET` / `POST` / `PATCH` | `/api/admin/users*`, `/api/admin/teachers`, `/api/auth/email-diagnostic` | `AdminUsersHandler` (4 sub-handlers), `EmailDiagnosticHandler` |
| **VideoCall (Mongo)** | `GET` / `POST` | `/api/video-call/rooms`, `/enter`, `/close`, `/attendance` | `VideoCallMongoHandler` |
| **VideoCall (Legacy)** | `GET` / `POST` | `/api/videocall/rooms`, `/open`, `/close`, `/join`, `/leave`, `/signal`, `/hand-raise`, `/chat`, `/attendance` | `videocall.modules.legado.*` |
| **WebSocket** | `WS` | `/ws/video-call/{roomCode}?ticket=...` | `ServidorHttpNativo` + `SalaVideoHub` |
