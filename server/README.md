# Server — Zero-Dependency Native Java HTTP & WebSocket Server (AGMRM)

> **Core Server Module**: `.../PI-IV-Time3/server/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Pure Java SE standard library (Java 8+), Zero external dependencies, Deterministic TCP sockets & RFC 6455 WebSockets  

The `server` module contains the native, autonomous, and high-performance HTTP & WebSocket server developed for the **Integrated Educational Platform AGMRM** (*PI-IV Team 3*).

It operates 100% on the **Java SE standard library** (compatible with Java 8 through 21+) with zero third-party dependencies or heavy application containers (no Spring, Quarkus, Maven, JUnit, or Tomcat).

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
│   ├── academic/                           # Academic handlers (Attendance, Report Card, Tasks, Data Types)
│   │   ├── BoletimHandler.java
│   │   ├── PresencaHandler.java
│   │   ├── TarefasHandler.java
│   │   └── TesteTiposHandler.java
│   ├── auth/                               # Native JDK HS256 JWT validation & session endpoint
│   │   ├── AuthSessionHandler.java
│   │   ├── JwtAuthValidator.java
│   │   └── UsuarioAutenticado.java
│   ├── websocket/                          # RFC 6455 handshake, frames, and socket lifecycle
│   │   ├── AtendenteWebSocket.java
│   │   ├── ConexaoWebSocket.java
│   │   ├── HandshakeWebSocket.java
│   │   └── QuadroWebSocket.java
│   ├── utils/                              # Environment loader & JSON parsing/serialization
│   │   ├── ConfigEnv.java
│   │   ├── Json.java
│   │   └── JsonSimples.java
│   └── videocall/                          # Video Conference, WebRTC Signaling, Chat & Presence Telemetry
│       ├── hub/
│       │   ├── OuvinteWebSocket.java
│       │   ├── RegistradorChat.java
│       │   ├── RegistradorEnvelope.java
│       │   └── SalaVideoHub.java
│       ├── TicketWebSocketValidator.java
│       ├── VideoCallAttendanceHandler.java
│       ├── VideoCallInteractionHandler.java
│       ├── VideoCallRoomHandler.java
│       ├── VideoCallService.java
│       └── VideoCallSignalingHandler.java
├── tests/                                  # Zero-dependency Java test suites + cURL manual
│   ├── SuiteTestesServidor.java
│   ├── auth/JwtAuthValidatorTeste.java
│   ├── utils/JsonTeste.java
│   ├── videocall/hub/HubTeste.java
│   ├── videocall/hub/RegistradorChatTeste.java
│   ├── websocket/HandshakeTeste.java
│   ├── websocket/QuadroTeste.java
│   └── testeServidor.txt
├── README.md                               # Server technical manual (this file)
├── run-server.bat                          # Compilation & startup script (Windows)
└── run-tests.bat                           # Automated native test suite runner (Windows)
```

---

## 🧩 Package Responsibilities

- **`Main.java` (`server/src/Main.java`)**:
  - Unified application entry point reading `SERVER_PORT` (default `8080`) via `ConfigEnv`.
  - Registers 14 HTTP endpoints and the `/ws/video-call/{roomCode}` WebSocket path.
- **`core` (`server/src/core/`)**:
  - Low-level network abstractions built over native TCP `ServerSocket` and `Socket`.
  - Supports both `application/json` and `application/x-www-form-urlencoded` bodies via `HttpUtils.extrairParametros`.
- **`academic` (`server/src/academic/`)**:
  - Semester grade computation and regimental weighted average calculation.
  - Absence ledger, lecture hours, and attendance percentage computation with faculty allowance.
  - Automated grade deductions for late assignment submissions.
- **`auth` (`server/src/auth/`)**:
  - Credential login, 2FA, and OTP password recovery are served by the TypeScript API in `../backend` (port `3001`).
  - On port `8080`, `JwtAuthValidator` verifies Bearer HS256 JWT tokens natively using JDK `javax.crypto.Mac` (`HmacSHA256`) and constant-time `MessageDigest.isEqual` (using `AUTH_JWT_SECRET` loaded via `ConfigEnv`, with optional remote session verification against `GET /api/auth/me`).
  - `AuthSessionHandler` exposes `GET /api/auth/session` and all `VideoCall*Handler` endpoints enforce authenticated user profiles/identities when a Bearer token is supplied.
- **`videocall` (`server/src/videocall/`)**:
  - Virtual classroom lifecycle (room opening restricted to Teacher or Admin).
  - `videocall/hub/SalaVideoHub` relays P2P envelopes (`join`, `leave`, presence, chat, hand raise, and WebRTC SDP/ICE signaling) while `RegistradorChat` records bounded chat history (up to 2000 chars per message) and synchronizes room telemetry with `VideoCallService`.
  - WebSocket upgrades require a short-lived, single-use room ticket issued by `backend/` and consumed by `TicketWebSocketValidator`.

---

## 🚀 Transparent Startup (`cd frontend` & `flutter run`)

The server **does not require manual startup** during standard desktop development:

1. Open your terminal in the frontend directory and run:
   ```bash
   cd frontend
   flutter run
   ```
2. Flutter triggers `BackendProcessLauncher`:
   - Checks if port `8080` is already active.
   - Ensures `.java` sources are compiled into `server/bin/` targeting Java 8 (`--release 8`).
   - Starts `java -cp bin Main` as an independent background process (*detached*).

*(Optional / Manual Execution)*:
```powershell
cd server
.\run-server.bat
```

---

## 📡 Registered API Endpoints Catalog (14 Routes + WebSocket)

The server listens on `http://localhost:8080` with the following active endpoints:

| Method | Endpoint | Module | Description / Payload |
|---|---|---|---|
| `GET`/`POST` | `/api/teste-tipos` | Academic | Diagnostic and echo of primitive types (text, numeric, boolean) |
| `POST` | `/api/presenca` | Academic | Calculates presence percentage and excused absence allowance |
| `POST` | `/api/tarefas/calcular-nota` | Academic | Computes final task grade deducting penalty for late submissions |
| `POST` | `/api/notas/boletim` | Academic | Calculates semester weighted average and passing status |
| `GET` | `/api/auth/session` | Auth | Validates Bearer HS256 JWT / active session and returns user profile |
| `GET` | `/api/videocall/rooms` | Video Call | Lists active virtual classrooms and room health status |
| `POST` | `/api/videocall/open` | Video Call | Opens virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/close` | Video Call | Closes virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/join` | Video Call | Joins session and records attendance telemetry |
| `POST` | `/api/videocall/leave` | Video Call | Leaves session and logs connected duration |
| `POST` | `/api/videocall/signal` | Video Call | P2P WebRTC signaling (SDP offer/answer, ICE candidates) |
| `GET`/`POST` | `/api/videocall/hand-raise` | Video Call | Manages FIFO queue of raised hands and doubts |
| `GET`/`POST` | `/api/videocall/chat` | Video Call | Real-time chat messages synchronized with WebSocket hub |
| `GET`/`POST` | `/api/videocall/attendance` | Video Call | Homologates presence based on connected duration |

### WebSocket signaling

The Flutter client connects to `ws://127.0.0.1:8080/ws/video-call/{roomCode}?ticket=...`. The single-use ticket comes from `POST /api/video-call/rooms/enter` on `backend/` (port `3001`), expires after 60 seconds, and is consumed by `TicketWebSocketValidator` before completing the RFC 6455 handshake.

---

## 🧪 Automated Native Test Suite & cURL Validation

Run all 6 zero-dependency Java test suites (`JsonTeste`, `HandshakeTeste`, `QuadroTeste`, `RegistradorChatTeste`, `HubTeste`, and `JwtAuthValidatorTeste`):

```powershell
cd server
.\run-tests.bat
```

For manual HTTP endpoint validation via `curl`, see `server/tests/testeServidor.txt`.
