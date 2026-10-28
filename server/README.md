# Server — Zero-Dependency Native Java HTTP Server (AGMRM)

> **Core Server Module**: `.../PI-IV-Time3/server/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Pure Java SE standard library, Zero external dependencies, Deterministic TCP sockets  

The `server` module contains the native, autonomous, and high-performance HTTP server developed for the **Integrated Educational Platform AGMRM** (*PI-IV Team 3*).

It operates 100% on the **Java SE standard library** (compatible with Java 8 through 21+) with zero third-party dependencies or heavy application containers (no Spring, Quarkus, Maven, or Tomcat).

---

## 🏛️ Modular Architecture and Organization

The server is structured into cohesive packages with strict separation of concerns:

```
.../PI-IV-Time3/server/
├── bin/                          # Compiled Java bytecode (.class)
├── src/                          # Modular Java source code
│   ├── main/
│   │   └── Main.java             # Central entry point and orchestrator on port 8080
│   ├── core/                     # Native HTTP socket abstractions, Request/Response, and CORS
│   │   ├── HttpUtils.java
│   │   ├── ManipuladorHttp.java
│   │   ├── RequisicaoHttp.java
│   │   ├── RespostaHttp.java
│   │   └── ServidorHttpNativo.java
│   ├── academic/                 # Academic handlers (Attendance, Report Card, Tasks, and Data Types)
│   │   ├── BoletimHandler.java
│   │   ├── PresencaHandler.java
│   │   ├── TarefasHandler.java
│   │   └── TesteTiposHandler.java
│   ├── auth/                     # Authentication & Real SMTP Email OTP Dispatch
│   │   ├── AuthRecoveryHandler.java
│   │   └── EmailService.java
│   └── videocall/                # Video Conference, WebRTC Signaling, and Presence Telemetry
│       ├── VideoCallAttendanceHandler.java
│       ├── VideoCallInteractionHandler.java
│       ├── VideoCallRoomHandler.java
│       ├── VideoCallService.java
│       └── VideoCallSignalingHandler.java
├── tests/
│   └── testeServidor.txt         # Documented test suite with cURL commands
├── README.md                     # Server technical manual (this file)
└── run-server.bat                # Optional legacy utility script
```

---

## 🧩 Package Responsibilities

- **`main` (`.../PI-IV-Time3/server/src/main/Main.java`)**:
  - Unified application entry point.
  - Registers and routes all 15 endpoints across the academic, video conference, and authentication modules on port 8080.
- **`core` (`.../PI-IV-Time3/server/src/core/`)**:
  - Low-level network abstractions built over native TCP `ServerSocket` and `Socket`.
  - HTTP lifecycle management (Request headers/body parsing, Response status codes, CORS headers, and payload boundaries).
- **`academic` (`.../PI-IV-Time3/server/src/academic/`)**:
  - Semester grade computation and regimental weighted average calculation.
  - Absence ledger, lecture hours, and attendance percentage computation with faculty allowance.
  - Automated grade deductions for late assignment submissions.
- **`auth` (`.../PI-IV-Time3/server/src/auth/`)**:
  - `EmailService.java`: Native Java SE SMTP client over SSL Socket (port 465) (RFC 5321). Dispatches real OTP emails with a responsive HTML template and cryptographic 6-digit codes.
  - `AuthRecoveryHandler.java`: Endpoints for OTP generation and verification with 300s TTL (5 minutes) and 3-attempt brute-force threshold.
- **`videocall` (`.../PI-IV-Time3/server/src/videocall/`)**:
  - Virtual classroom lifecycle (room opening regimental restricted to Teacher or Admin).
  - WebRTC signaling hub (SDP Offer/Answer and ICE Candidates exchange).
  - Ordered FIFO doubt queue ("Raised Hands") and real-time classroom chat.
  - Presence tracking and attendance computation based on active connected duration.

---

## 🚀 Transparent Startup (`cd frontend` & `flutter run`)

The server **does not require manual startup** during standard development:

1. Open your terminal in the frontend directory and run:
   ```bash
   cd frontend
   flutter run
   ```
2. Flutter triggers the automated pre-run orchestration via CMake and `BackendProcessLauncher`:
   - Checks if port `8080` is already active.
   - If inactive, compiles `.java` sources into `server/bin/` using `javac --release 8`.
   - Starts `java -cp bin main.Main` as an independent background process (*detached*), allowing the Flutter client to immediately communicate with all endpoints.

*(Optional / Manual Execution)*: To run the server independently in a dedicated terminal:
```bash
cd .../PI-IV-Time3/server
javac --release 8 -encoding UTF-8 -d bin src/core/*.java src/academic/*.java src/auth/*.java src/videocall/*.java src/main/*.java
java -cp bin main.Main
```

---

## 📡 Registered API Endpoints Catalog (15 Routes)

The server listens on `http://localhost:8080` with the following active endpoints:

| Method | Endpoint | Module | Description / Payload |
|---|---|---|---|
| `GET`/`POST` | `/api/teste-tipos` | Academic | Diagnostic and echo of primitive types (text, numeric, boolean) |
| `POST` | `/api/presenca` | Academic | Calculates presence percentage and excused absence allowance |
| `POST` | `/api/tarefas/calcular-nota` | Academic | Computes final task grade deducting penalty for late submissions |
| `POST` | `/api/notas/boletim` | Academic | Calculates semester weighted average and passing status |
| `GET` | `/api/videocall/rooms` | Video Call | Lists active virtual classrooms and room health status |
| `POST` | `/api/videocall/open` | Video Call | Opens virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/close` | Video Call | Closes virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/join` | Video Call | Joins session and records attendance telemetry |
| `POST` | `/api/videocall/leave` | Video Call | Leaves session and logs connected duration |
| `POST` | `/api/videocall/signal` | Video Call | P2P WebRTC signaling (SDP offer/answer, ICE candidates) |
| `POST` | `/api/videocall/hand-raise` | Video Call | Manages FIFO queue of raised hands and doubts |
| `POST` | `/api/videocall/chat` | Video Call | Real-time chat messages with room timestamps |
| `POST` | `/api/videocall/attendance`| Video Call | Homologates presence based on connected duration |
| `POST` | `/api/auth/send-recovery-otp` | Auth & Email | Generates 6-digit OTP and dispatches real SMTP email (5-min TTL) |
| `POST` | `/api/auth/verify-recovery-otp` | Auth & Email | Validates OTP with 300s TTL and 3-attempt brute-force limit |

---

## 🧪 Endpoint Validation & Testing

To validate all endpoints from the command line, refer to `.../PI-IV-Time3/server/tests/testeServidor.txt`, which contains documented `curl` commands covering successful executions and regimental edge cases.
