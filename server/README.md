# Server — Zero-Dependency Native Java HTTP & WebSocket Server (AGMRM)

> **Core Server Module**: `.../PI-IV-Time3/server/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Pure Java SE standard library (Java 8+), Zero external dependencies, Deterministic TCP sockets & RFC 6455 WebSockets  

The `server` module contains the native, autonomous, and high-performance HTTP & WebSocket server developed for the **Integrated Educational Platform AGMRM** (*PI-IV Team 3*).

It operates 100% on the **Java SE standard library** (compatible with Java 8 through 21+) with zero third-party dependencies or heavy application containers (no Spring, Quarkus, Maven, JUnit, or Tomcat).

**Primary Responsibilities (Bounded Context on Port `8080`)**:
- **Authoritative Identity & Access Management**: Complete login system (PBKDF2/BCrypt verification, JWT HS256 access/refresh tokens, 2FA + backup codes, single-use OTP recovery, password change, profile/preferences/sessions/LGPD export, and admin user management + teacher provisioning)
- **Video Conferencing & Real-Time Signaling**: Persisted rooms and single-use WebSocket tickets (`academic_live_sessions`, `video_call_ws_tickets`, `video_call_attendance_logs`) via `/api/video-call/rooms*`, RFC 6455 `/ws/video-call/{roomCode}`, chat sync, and legacy `/api/videocall/*` telemetry
- **Internal Bridge Consumer**: Calls `backend/` (`:3001`) at `/api/internal/academic/*` with `X-Internal-Service-Secret` (`ClientePonteAcademica`) to authorize academic class membership, list allowed classrooms, and fetch LGPD/dossier academic summaries

---

## 🏛️ Modular Architecture and Organization

The server is structured into cohesive packages with strict separation of concerns:

```text
.../PI-IV-Time3/server/
├── bin/                                    # Compiled Java 8 bytecode (.class)
├── src/                                    # Modular Java source code
│   ├── Main.java                           # Central entry point and orchestrator on port 8080
│   ├── core/                               # Native HTTP socket abstractions, Request/Response, and CORS
│   │   ├── HttpUtils.java
│   │   ├── ManipuladorHttp.java
│   │   ├── RequisicaoHttp.java
│   │   ├── RespostaHttp.java
│   │   └── ServidorHttpNativo.java
│   ├── auth/                               # Identity, sessions, 2FA, recovery, profile, admin users
│   │   ├── AdminUsersHandler.java
│   │   ├── AuthSessionHandler.java
│   │   ├── ChangePasswordHandler.java
│   │   ├── EmailDiagnosticHandler.java
│   │   ├── JwtAuthValidator.java
│   │   ├── JwtGerador.java
│   │   ├── LimitadorTentativas.java
│   │   ├── LoginHandler.java
│   │   ├── LogoutHandler.java
│   │   ├── OtpService.java
│   │   ├── ProfileAccountHandler.java
│   │   ├── RecoveryHandler.java
│   │   ├── RefreshTokenHandler.java
│   │   ├── RepositorioUsuarios.java
│   │   ├── RevogacaoTokens.java
│   │   ├── SenhaHasher.java
│   │   ├── SmtpCliente.java
│   │   ├── TwoFactorHandler.java
│   │   └── UsuarioAutenticado.java
│   ├── bridge/                             # Internal HTTP client to backend (/api/internal/academic/*)
│   │   └── ClientePonteAcademica.java
│   ├── websocket/                          # RFC 6455 handshake, frames, and socket lifecycle
│   │   ├── AtendenteWebSocket.java
│   │   ├── ConexaoWebSocket.java
│   │   ├── HandshakeWebSocket.java
│   │   ├── OuvinteWebSocket.java
│   │   └── QuadroWebSocket.java
│   ├── utils/                              # Environment loader & JSON parsing/serialization
│   │   ├── ConfigEnv.java
│   │   ├── Json.java
│   │   └── JsonSimples.java
│   └── videocall/                          # Video Conference REST + MongoDB persistence, WebRTC hub & Attendance
│       ├── hub/
│       │   ├── RegistradorChat.java
│       │   ├── RegistradorEnvelope.java
│       │   └── SalaVideoHub.java
│       ├── RepositorioVideoCall.java
│       ├── TicketWebSocketValidator.java
│       ├── VideoCallAttendanceHandler.java
│       ├── VideoCallInteractionHandler.java
│       ├── VideoCallMongoHandler.java
│       ├── VideoCallRoomHandler.java
│       ├── VideoCallService.java
│       └── VideoCallSignalingHandler.java
├── tests/                                  # Zero-dependency Java test suites (13 suites)
│   ├── SuiteTestesServidor.java
│   ├── auth/
│   │   ├── HandlerLifecycleTeste.java
│   │   ├── JwtAuthValidatorTeste.java
│   │   ├── LimitadorTentativasTeste.java
│   │   ├── OtpServiceTeste.java
│   │   ├── RecoveryHandlerTeste.java
│   │   ├── RevogacaoTokensTeste.java
│   │   └── SenhaHasherTeste.java
│   ├── utils/
│   │   ├── ConfigEnvTeste.java
│   │   └── JsonTeste.java
│   ├── videocall/hub/
│   │   ├── HubTeste.java
│   │   └── RegistradorChatTeste.java
│   ├── websocket/
│   │   ├── HandshakeTeste.java
│   │   └── QuadroTeste.java
│   └── testeServidor.txt
├── README.md                               # Server technical manual (this file)
└── lib/                                    # MongoDB Java Driver dependencies (JAR files)
```

---

## 🧩 Package Responsibilities

### **`Main.java` (`server/src/Main.java`)**
- Unified application entry point reading `SERVER_PORT` (default `8080`) via `ConfigEnv`.
- Registers `/health`, all `/api/auth/*`, `/api/admin/users*`, `POST /api/admin/teachers`, `/api/video-call/rooms*`, legacy `/api/videocall/*`, `/api/admin/system/email-diagnostic`, academic calculation endpoints, and `/ws/video-call/{roomCode}`.

### **`core` (`server/src/core/`)**
- Low-level network abstractions built over native TCP `ServerSocket` and `Socket`.
- Supports both `application/json` and `application/x-www-form-urlencoded` bodies via `HttpUtils.extrairParametros`.
- Implements HTTP/1.1 protocol parsing, response formatting, and CORS headers.

### **`auth` (`server/src/auth/`)** — **Complete Authentication System**
- **`SenhaHasher.java`**: PBKDF2WithHmacSHA256 password hashing (600k iterations) with constant-time comparison via `MessageDigest.isEqual`.
- **`JwtGerador.java`**: Generates HS256 JWT access tokens (15min) and refresh tokens (7 days) with JTI for revocation.
- **`JwtAuthValidator.java`**: Validates JWT signatures, expiration, and checks blacklist using native `javax.crypto.Mac`.
- **`LoginHandler.java`**: Login endpoint with rate limiting, dummy hash protection against user enumeration, and 2FA support.
- **`LogoutHandler.java`**: Revokes tokens by adding them to an in-memory blacklist.
- **`RefreshTokenHandler.java`**: Rotates refresh tokens and issues new access/refresh token pairs.
- **`TwoFactorHandler.java`**: Verifies 2FA OTP codes sent via email.
- **`RecoveryHandler.java`**: OTP-based password recovery workflow (send, verify, reset).
- **`ChangePasswordHandler.java`**: Authenticated password change endpoint.
- **`AuthSessionHandler.java`**: Validates active sessions and returns user profile data.
- **`LimitadorTentativas.java`**: Rate limiting with progressive lockout (30s → 5min → 30min).
- **`RevogacaoTokens.java`**: In-memory token blacklist with automatic expiration cleanup.
- **`OtpService.java`**: Generates 6-digit OTP codes with HMAC-SHA256 storage and expiration.
- **`SmtpCliente.java`**: Raw SMTP client for sending OTP emails via socket-level implementation.
- **`RepositorioUsuarios.java`**: MongoDB integration for user CRUD and session management.
- **`UsuarioAutenticado.java`**: Authenticated user model with profile, permissions, and metadata.

### **`videocall` (`server/src/videocall/`)** — **Video Conferencing System**
- **`VideoCallRoomHandler.java`**: Room lifecycle (open/close) restricted to Teacher or Admin profiles.
- **`VideoCallSignalingHandler.java`**: WebRTC signaling (SDP offer/answer, ICE candidates) for P2P connections.
- **`VideoCallInteractionHandler.java`**: Hand-raising (FIFO queue) and real-time chat endpoints.
- **`VideoCallAttendanceHandler.java`**: Presence homologation based on connected duration.
- **`VideoCallService.java`**: In-memory room state, participant tracking, and telemetry.
- **`TicketWebSocketValidator.java`**: Validates single-use, 60-second WebSocket connection tickets.
- **`hub/SalaVideoHub.java`**: WebSocket hub relaying P2P envelopes (join, leave, chat, signal) with room isolation.
- **`hub/RegistradorChat.java`**: Records bounded chat history (up to 2000 chars) and synchronizes with `VideoCallService`.
- **`hub/RegistradorEnvelope.java`**: Envelope structure for WebSocket message routing.

### **`websocket` (`server/src/websocket/`)** — **RFC 6455 WebSocket Implementation**
- **`HandshakeWebSocket.java`**: HTTP upgrade handshake with Sec-WebSocket-Accept validation.
- **`QuadroWebSocket.java`**: Frame parsing (text, binary, ping, pong, close) with masking support.
- **`ConexaoWebSocket.java`**: Connection lifecycle and state management.
- **`AtendenteWebSocket.java`**: WebSocket handler interface for protocol events.
- **`OuvinteWebSocket.java`**: Event listener interface for application-level callbacks.

### **`utils` (`server/src/utils/`)** — **Utilities**
- **`ConfigEnv.java`**: Loads environment variables from `.env` file with type conversion and validation.
- **`Json.java`**: Full JSON parser and serializer with validation (rejects trailing commas, duplicate keys, excessive nesting).
- **`JsonSimples.java`**: Lightweight JSON parser for simple use cases.

---

## 🚀 Transparent Startup (`cd frontend` & `flutter run`)

The server **does not require manual startup** during standard desktop development:

1. Open your terminal in the frontend directory and run:
   ```bash
   cd frontend
   flutter run
   ```
2. Flutter triggers `BackendProcessLauncher`:
   - Checks if port `8080` is already active (`GET /health`).
   - Ensures `.java` sources are compiled into `server/bin/` targeting Java 8 (`--release 8`).
   - Starts `java -cp bin:lib/* Main` (`bin;lib/*` on Windows) as an independent background process (*detached*).

*(Optional / Manual Execution)*:
```bash
cd server
javac --release 8 -encoding UTF-8 -cp "lib/*" -d bin $(find src -name "*.java")
java -cp "bin:lib/*" Main
```

---

## 📡 Registered API Endpoints Catalog

The server listens on `http://localhost:8080` with the following active endpoints:

### Health, Authentication & Account Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Native Java server healthcheck |
| `POST` | `/api/auth/login` | Login with PBKDF2/BCrypt verification, rate limiting, and optional 2FA |
| `POST` | `/api/auth/logout` | Revokes MongoDB session and blacklists JWT |
| `GET` | `/api/auth/session` / `/api/auth/me` | Validates Bearer HS256 JWT + MongoDB session and returns user profile |
| `PATCH` | `/api/auth/profile` | Updates profile fields and triggers internal sync on `backend/` |
| `GET` / `DELETE` | `/api/auth/sessions` & `/api/auth/sessions/:id` | Lists or revokes persisted user sessions in `auth_sessions` |
| `POST` | `/api/auth/logout-others` | Revokes all user sessions except the current one |
| `POST` | `/api/auth/refresh` | Rotates refresh token and issues new access/refresh token pair |
| `POST` | `/api/auth/verify-two-factor` | Verifies 2FA OTP or single-use backup code |
| `POST` | `/api/auth/two-factor` & `/api/auth/backup-codes` | Toggles 2FA or regenerates backup codes |
| `POST` | `/api/auth/send-recovery-otp` / `/verify-recovery-otp` / `/reset-password` | Sends OTP, issues single-use reset grant, and resets password without replay |
| `POST` | `/api/auth/change-password` | Changes password for authenticated user (supports pending forced change) |
| `GET` | `/api/auth/security-logs` & `/api/auth/lgpd-export` | Lists security audit events and exports identity + academic LGPD data via internal bridge |

### Admin Identity Management Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` / `POST` / `PATCH` | `/api/admin/users`, `/:id`, `/:id/status` | Manages institutional user accounts (`adminOnly`) |
| `GET` / `POST` | `/api/admin/users/:id/sessions`, `/revoke-sessions`, `/reset-password` | Inspects sessions, revokes tokens, and resets temporary password (`adminOnly`) |
| `GET` | `/api/admin/users/:id/dossier` | Returns user dossier combining identity logs and academic summary from `backend/` |
| `POST` | `/api/admin/teachers` | Creates a new teacher account (`adminOnly`) |

### Video Call Endpoints (Persisted `/api/video-call/rooms*` + Legacy `/api/videocall/*`)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/video-call/rooms` | Lists authorized classrooms & live status for the logged-in user |
| `POST` | `/api/video-call/rooms/enter` | Opens/joins room in MongoDB and issues single-use 60s WebSocket ticket |
| `POST` | `/api/video-call/rooms/close` | Closes live classroom in `academic_live_sessions` |
| `POST` | `/api/video-call/rooms/attendance` | Persists video-call attendance telemetry in MongoDB |
| `GET` / `POST` | `/api/videocall/rooms`, `/open`, `/close`, `/join`, `/leave`, `/signal`, `/hand-raise`, `/chat`, `/attendance` | Legacy in-memory video-call & signaling endpoints |

### WebSocket Signaling

The Flutter client connects to `ws://127.0.0.1:8080/ws/video-call/{roomCode}?ticket=...`. The single-use ticket comes directly from `POST /api/video-call/rooms/enter` (stored in MongoDB `video_call_ws_tickets`) and is consumed atomically by `TicketWebSocketValidator` before completing the RFC 6455 handshake.

---

## 🧪 Automated Native Test Suite

Run all 13 zero-dependency Java test suites:

```bash
cd server
find src tests -name "*.java" > /tmp/sources.txt
javac --release 8 -encoding UTF-8 -cp "lib/*" -d bin @/tmp/sources.txt
java -cp "bin:lib/*" SuiteTestesServidor
```

**Test Suites**:
1. **ConfigEnv Master .env** — Environment variable loading and validation
2. **Json & JsonSimples** — JSON parsing, serialization, and validation
3. **WebSocket Handshake (RFC 6455)** — Sec-WebSocket-Accept calculation
4. **WebSocket Quadros (RFC 6455)** — Frame parsing, masking, and protocol compliance
5. **VideoCall RegistradorChat** — Chat message recording and synchronization
6. **VideoCall SalaVideoHub Integracao** — WebSocket hub message routing and room isolation
7. **Autenticacao JWT HS256 Nativa** — JWT validation, session revocation, password-change guard, admin RBAC
8. **SenhaHasher PBKDF2** — Password hashing, verification, complexity validation, and dummy hash protection
9. **RevogacaoTokens (blacklist)** — Token revocation and automatic expiration cleanup
10. **LimitadorTentativas (rate limiting)** — Progressive lockout and attempt tracking
11. **OtpService (2FA e recuperacao)** — OTP generation, HMAC storage, and validation
12. **RecoveryHandler** — Single-use recovery reset grant & anti-replay verification
13. **HandlerLifecycle** — Shared MongoDB repository preservation across `TwoFactorHandler` and `RefreshTokenHandler`

For manual HTTP endpoint validation via `curl`, see `server/tests/testeServidor.txt`.

---

## 🔒 Security Features

- **Password Hashing**: PBKDF2WithHmacSHA256 with 600,000 iterations (OWASP 2023 recommendation)
- **Token Security**: HS256 JWT with constant-time signature validation via `MessageDigest.isEqual`
- **Rate Limiting**: Progressive lockout (5 attempts → 30s, 15 attempts → 5min, 30+ attempts → 30min)
- **User Enumeration Protection**: Dummy hash verification ensures constant-time responses for invalid users
- **Token Revocation**: In-memory blacklist with automatic expiration cleanup
- **2FA Support**: OTP-based two-factor authentication via email
- **Password Complexity**: Configurable minimum length, uppercase, lowercase, numbers, and special characters
- **Session Management**: MongoDB-persisted sessions with remote validation support
- **WebSocket Security**: Single-use, 60-second connection tickets validated before RFC 6455 handshake

---

## 📦 Dependencies

**Zero external dependencies** — All functionality uses the Java SE standard library:
- `javax.crypto` — PBKDF2, HMAC-SHA256, constant-time comparison
- `java.net` — TCP sockets, HTTP server
- `java.security` — SecureRandom, MessageDigest
- `java.util` — Collections, Base64, UUID

**MongoDB Driver** (in `lib/`):
- `mongodb-driver-sync.jar` — MongoDB synchronous driver
- `mongodb-driver-core.jar` — Core MongoDB driver components
- `bson.jar` — BSON serialization/deserialization
- `netty-buffer.jar` — Buffer management (transitive dependency)
- `netty-common.jar` — Common utilities (transitive dependency)

---

## 🔄 Architecture Philosophy

The server follows a **minimalist, high-performance design**:
- **Zero Dependencies**: No Spring, Quarkus, Maven, JUnit, or heavy frameworks
- **Native HTTP**: Custom TCP socket-based HTTP/1.1 implementation
- **Native WebSocket**: RFC 6455 compliant WebSocket implementation from scratch
- **In-Memory State**: Token blacklist, rate limiting, and room state stored in memory for speed
- **Modular Design**: Clear separation of concerns (auth, videocall, websocket, core, utils)
- **Test-Driven**: 109 automated tests with zero external test frameworks
- **Security-First**: Defense in depth with multiple layers of protection

This architecture ensures **predictable performance**, **minimal attack surface**, and **complete control** over the authentication and video conferencing workflows.
