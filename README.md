# Integrated Educational Platform (AGMRM)

> Integrated repository of the Integrated Educational Platform (*Projeto Interdisciplinar IV - PI-IV Time 3 - PUC-Campinas 2026*)

---

## About

**Integrated Educational Platform (AGMRM)** is an integrated academic education platform developed for the Integrated Project IV course.

The platform solves the fragmentation of educational tools by integrating presence tracking, digital class diary, grade calculation, assignment submission with automated late penalties, video conference with WebRTC, and deep cyber defense architecture.

### Key Features

- **Multi-Role Portals (Student, Teacher, Admin)**: Dedicated interfaces with distinct permission levels.
- **Student Portal**: Academic history with weighted averages, absences, schedule, notices, and virtual desk.
- **Teacher Portal**: Grade entry, digital attendance log, attendance approval, and virtual classroom management.
- **Admin Portal**: User identity management, audit cockpit, academic registry, and CONSEPE official lock.
- **Institutional Video Call (`video_call`)**: P2P WebRTC video conference integrated into the native Java server (`server/`). Active speaker detection, FIFO doubt queue (raised hands), real-time chat synchronized with WebSocket hub, and presence tracking by connected time.
- **Native Java SE Server (`server/`)**: Zero-dependency HTTP and WebSocket server on port 8080. Handles academic calculations, relays WebRTC signaling, and validates HS256 JWT login sessions natively; user login, 2FA, OTP recovery, and room authorization run in the modular TypeScript API (`backend/`).
- **Cyber Defense in Depth (`security/`)**: Brute-force lockout (5 attempts $\rightarrow$ 30s lockout), side-channel timing attack mitigation, opaque anti-enumeration responses, input sanitization against XSS/SQLi, and OTP token lifecycle.

---

## Team

| Full Name | Academic ID (RA) |
|---|---|
| Alex Gabriel Soares Sousa | 24802449 |
| Guilherme Henrique Moreira | 25006702 |
| Marcelo Zarpelon | 25015323 |
| Murillo Caravita | 25014012 |
| Rafael Henrique Inácio | 25009719 |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Application (Client)** | Flutter (Desktop: Windows / Mobile / Web) |
| **Core Academic & WS Server** | Java SE — Pure Native HTTP & RFC 6455 WebSocket Server (Zero external libraries) |
| **Auth, Admin & Room Ticket API** | TypeScript + Express + MongoDB (`backend/` on port `3001`) |
| **Security & Defenses** | agmrm_security (Dart) + Native JWT/Rate-Limit Defense-in-Depth |
| **Persistence Layer** | Document (MongoDB) |
| **Version Control** | Git & GitHub |

---

## Repository Structure

```
.../PI-IV-Time3/
├── .github/          # CI/CD workflows, CODEOWNERS, GOVERNANCE.md, and shared IDE configs (.vscode)
├── frontend/         # Multi-platform Flutter app (Feature-First Clean Architecture, 396 tests)
│   ├── lib/
│   │   ├── core/     # Theme, design tokens, routes, and transparent backend launcher
│   │   ├── features/ # auth, student, teacher, admin, video_call, multiperfil
│   │   └── main.dart # App entry point with automated parent modules startup
│   └── test/         # Comprehensive test suite (396 tests)
├── server/           # Native autonomous Java SE HTTP & WebSocket server (zero external libraries)
│   ├── src/
│   │   ├── Main.java # Central orchestrator on port 8080
│   │   ├── core/     # Low-level TCP sockets, HTTP handlers, and CORS
│   │   ├── academic/ # Grades, Attendance, Tasks, and Data Types
│   │   ├── auth/     # Native JDK HS256 JWT validator & /api/auth/session handler
│   │   ├── utils/    # ConfigEnv, Json, and JsonSimples
│   │   ├── websocket/# RFC 6455 WebSocket handshake, framing, and lifecycle
│   │   └── videocall/# Virtual rooms, WebRTC signaling hub, RegistradorChat, Attendance
│   └── tests/        # Zero-dependency Java test suite (SuiteTestesServidor) & cURL guide
├── security/         # Enterprise cyber defense module (37 tests)
│   ├── lib/          # Client-side defenses (lockout, rate limiter, timing, entropy)
│   ├── test/         # Security test suite (37 tests)
│   └── server/       # Server-side security filters (rate limiter, headers, sanitizers)
├── backend/          # Modular TypeScript + MongoDB API on port 3001 (Auth, Admin, Student, VideoCall)
│   ├── src/
│   │   ├── config/   # Environment loading and strict validation
│   │   ├── shared/   # MongoDB client, HTTP errors, rate limiting
│   │   ├── modules/  # Layered modules: auth/, admin/, student/, video-call/
│   │   ├── scripts/  # CLI user provisioning & idempotent demo seed
│   │   └── tests/    # Centralized unit/ and integration/ test suites
│   └── backend-config.json # Declarative configuration for parent modules
└── .env-example      # Unified master environment template for all modules
```

---

## Running Locally (Dev Environment)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Java JDK](https://www.oracle.com/java/technologies/downloads/) (JDK 8 or higher / JDK 17 or 21 recommended)
- [Node.js](https://nodejs.org/) (20.x or higher, for `backend/`)
- Git

---

### 1. Clone the Repository

```bash
git clone https://github.com/Alekkzsx/PI-IV-Time3.git
cd .../PI-IV-Time3
```

---

### 2. Configure Environment Credentials

Create your environment configuration files from the templates:

```bash
cp .env-example .env
cp backend/.env.example backend/.env
```

| Variable | Description | Default Value |
|---|---|---|
| `SERVER_PORT` | Java HTTP/WS Server port | `8080` |
| `AUTH_JWT_SECRET` | Shared HS256 JWT secret (min 32 chars) | *(configured in `.env`)* |
| `REQUEST_TIMEOUT_SECONDS` | Request timeout for socket connection | `30` |
| `MAX_FAILED_LOGIN_ATTEMPTS` | Maximum failed logins before lockout | `5` |
| `LOCKOUT_DURATION_SECONDS` | Lockout duration in seconds | `30` |
| `STANDARDIZED_AUTH_LATENCY_MS` | Constant-time execution baseline | `1000` |
| `RECOVERY_TOKEN_TTL_SECONDS` | Ephemeral OTP recovery token lifespan | `300` |
| `MAX_VERIFICATION_ATTEMPTS` | Maximum invalid OTP attempts allowed | `3` |

---

### 3. Install Project Dependencies

Install dependencies for Flutter, Dart security, and TypeScript backend packages:

```bash
cd frontend
flutter pub get
cd ../security
flutter pub get
cd ../backend
npm install
cd ..
```

---

### 4. Start the Backend Services

Start the TypeScript Authentication & Academic API on port `3001`:

```bash
cd backend
npm run dev
```

The native Java server on port `8080` is automatically launched when running `flutter run` on desktop, or can be executed manually:

#### On Windows:
```powershell
cd server
.\run-server.bat
```

#### On Linux / macOS:
```bash
cd server
javac --release 8 -encoding UTF-8 -d bin $(find src -name "*.java")
java -Dfile.encoding=UTF-8 -cp bin Main
```

#### Automated Full Build and Verification:
To build and run tests across all modules:

##### On Windows / PowerShell:
```powershell
cd backend
npm test
cd ../server
.\run-tests.bat
cd ../frontend
flutter test
cd ../security
flutter test
```

---

### 5. Run the App

In the `frontend` directory:

```bash
cd frontend
```

#### Windows Desktop (Recommended):
```bash
flutter run -d windows
```

#### Google Chrome (Web):
```bash
flutter run -d chrome
```

#### Available Devices List:
```bash
flutter devices
```

---

## API Endpoints

The native Java server provides 14 HTTP endpoints on port `8080` (plus `/ws/video-call/{roomCode}`), working alongside the TypeScript API on port `3001`:

| Method | Endpoint | Service | Description |
|---|---|---|---|
| `GET` / `POST` | `/api/teste-tipos` | Java (`8080`) | Diagnostic and echo of primitive types (text, numeric, boolean) |
| `POST` | `/api/presenca` | Java (`8080`) | Calculates presence percentage and excused absence allowance |
| `POST` | `/api/tarefas/calcular-nota` | Java (`8080`) | Computes final task grade deducting penalty for late submissions |
| `POST` | `/api/notas/boletim` | Java (`8080`) | Calculates semester weighted average and passing status |
| `GET` | `/api/auth/session` | Java (`8080`) | Native JDK HS256 JWT & active session inspection |
| `GET` | `/api/videocall/rooms` | Java (`8080`) | Lists active virtual classrooms and room health status |
| `POST` | `/api/videocall/open` | Java (`8080`) | Opens virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/close` | Java (`8080`) | Closes virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/join` | Java (`8080`) | Joins session and records attendance telemetry |
| `POST` | `/api/videocall/leave` | Java (`8080`) | Leaves session and logs connected duration |
| `POST` | `/api/videocall/signal` | Java (`8080`) | P2P WebRTC signaling (SDP offer/answer, ICE candidates) |
| `GET` / `POST` | `/api/videocall/hand-raise` | Java (`8080`) | Manages FIFO queue of raised hands and doubts |
| `GET` / `POST` | `/api/videocall/chat` | Java (`8080`) | Real-time chat messages synchronized with WebSocket hub |
| `GET` / `POST` | `/api/videocall/attendance` | Java (`8080`) | Homologates presence based on connected duration |
| `POST` | `/api/auth/login` | TS (`3001`) | Institutional login issuing HS256 JWT (with 2FA support) |
| `POST` | `/api/video-call/rooms/enter` | TS (`3001`) | Authorizes the room and issues a single-use WebSocket ticket |
| `POST` | `/api/video-call/rooms/consume-ticket` | TS (`3001`) | Consumes the short-lived ticket during the Java WebSocket handshake |

Authentication, 2FA, OTP recovery, Admin management, Student dashboard, and room authorization run in `backend/` on port `3001`. The Flutter client connects to `ws://localhost:8080/ws/video-call/{roomCode}?ticket=...`; the Java server relays signaling envelopes while camera and microphone media remain peer-to-peer through WebRTC.

---

*Software Engineering • Systems Architecture & Security • PUC-Campinas • 2026*
