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
- **Institutional Video Call (`video_call`)**: P2P WebRTC video conference hosted in the native Java server (`server/` on port `8080`) with persisted rooms/attendance (`academic_live_sessions`, `video_call_attendance_logs`), single-use WS tickets (`video_call_ws_tickets`), active speaker detection, FIFO doubt queue (raised hands), and real-time chat synchronized with the WebSocket hub.
- **Native Java SE Server (`server/` on port `8080`)**: Authoritative Identity & Real-Time Communication boundary (Login, 2FA, OTP recovery, Profile/Sessions/LGPD export, Admin User Management, persisted `/api/video-call/rooms*` + `/ws/video-call/{roomCode}`, `/health`, and academic calculation endpoints). Communicates with `backend/` via `/api/internal/academic/*` (`X-Internal-Service-Secret`).
- **Academic Core API (`backend/` on port `3001`)**: Modular TypeScript + Express + MongoDB academic service handling Student/Teacher portals, Academic Admin operations, File downloads (`/api/files/*`), passive HS256 JWT + `auth_sessions` validation, and the internal bridge `/api/internal/academic/*`.
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
| **Identity, Users & Video-Call WS Server** | Java SE (`server/` on port `8080`) — Pure Native HTTP + RFC 6455 WebSocket + MongoDB Sync Driver |
| **Academic Core & Internal Bridge API** | TypeScript + Express + MongoDB (`backend/` on port `3001`) |
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
├── server/           # Java SE server on port 8080 (Identity, Admin Users, Video-Call REST + WS)
│   ├── src/
│   │   ├── Main.java # Central orchestrator on port 8080
│   │   ├── core/     # Low-level TCP sockets, HTTP handlers, and CORS
│   │   ├── academic/ # Grades, Attendance, Tasks, and Data Types
│   │   ├── auth/     # Auth, 2FA, Recovery, Profile, Sessions, Admin Users & JWT validation
│   │   ├── bridge/   # Authenticated HTTP client to backend /api/internal/academic/*
│   │   ├── utils/    # ConfigEnv, Json, and JsonSimples
│   │   ├── websocket/# RFC 6455 WebSocket handshake, framing, and lifecycle
│   │   └── videocall/# Persisted rooms (/api/video-call/rooms*), WebRTC hub & Attendance
│   └── tests/        # Zero-dependency Java test suite (SuiteTestesServidor) & cURL guide
├── security/         # Enterprise cyber defense module (agmrm_security + Java tests)
│   ├── lib/          # Client-side defenses (lockout, rate limiter, timing, entropy)
│   ├── test/         # Security test suite
│   └── server/       # Server-side security filters (rate limiter, headers, sanitizers)
├── backend/          # TypeScript + Express + MongoDB Academic Core on port 3001
│   ├── src/
│   │   ├── config/   # Environment loading and strict validation
│   │   ├── shared/   # MongoDB client, passive JWT+session middleware, indexes, errors
│   │   ├── modules/  # Academic modules: admin/, student/, teacher/, notifications/, internal/
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

Create your environment configuration file from the template at the project root:

```bash
cp .env-example .env
```

All project modules (`backend/`, `server/`, `frontend/`, `security/`) pull configuration **exclusively** from this single master `.env` file at the root.

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

Start the TypeScript Academic Core & Internal Bridge API on port `3001`:

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
javac --release 8 -encoding UTF-8 -cp "lib/*" -d bin $(find src -name "*.java")
java -Dfile.encoding=UTF-8 -cp "bin:lib/*" Main
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

The services follow a strict bounded-context separation between Identity/Video-Call (`server/` on `8080`) and Academic Core (`backend/` on `3001`):

| Method | Endpoint | Service | Description |
|---|---|---|---|
| `GET` | `/health` | Java (`8080`) | Identity & Video-Call server healthcheck |
| `POST` | `/api/auth/login` | Java (`8080`) | Institutional login issuing HS256 JWT (with 2FA & `requirePasswordChange`) |
| `POST` | `/api/auth/verify-two-factor` | Java (`8080`) | Verifies 2FA OTP or backup code and persists session |
| `GET` / `PATCH` | `/api/auth/me` / `/profile` / `/lgpd-export` | Java (`8080`) | Session inspection, profile updates, and LGPD data export |
| `GET` / `DELETE` | `/api/auth/sessions` / `/logout-others` | Java (`8080`) | Active session inspection and revocation |
| `GET` / `POST` / `PATCH` | `/api/admin/users*` & `POST /api/admin/teachers` | Java (`8080`) | Admin user lifecycle management, dossier, and teacher provisioning |
| `GET` / `POST` | `/api/video-call/rooms*` | Java (`8080`) | Persisted live classroom lookup, single-use WS ticket issuance, closing, and attendance |
| `GET` / `POST` | `/api/videocall/*` | Java (`8080`) | Legacy live room/signaling/chat telemetry compatibility endpoints |
| `POST` | `/api/presenca`, `/api/notas/boletim`, `/api/tarefas/calcular-nota` | Java (`8080`) | Native academic calculation endpoints |
| `GET` | `/health` | TS (`3001`) | Academic API healthcheck (`agmrm-academic-api`) |
| `GET` / `POST` / `PATCH` | `/api/student/*`, `/api/teacher/*`, `/api/files/*` | TS (`3001`) | Student AVA portal, Teacher cockpit, and academic file downloads |
| `GET` / `POST` / `PATCH` | `/api/admin/courses*`, `/classes*`, `GET /teachers`, `/protocols*`, `/settings`, `/announcements*`, `/calendar*`, `/audit-logs`, `/system/*` | TS (`3001`) | Academic Admin management and institutional operations |
| `GET` / `POST` | `/api/internal/academic/*` | TS (`3001`) | Service-to-service HTTP bridge guarded by `X-Internal-Service-Secret` |

Public `/api/auth/*`, `/api/admin/users*`, `POST /api/admin/teachers`, and `/api/video-call/*` are no longer served on port `3001` (`404`). The Flutter client uses `AUTH_API_BASE_URL` (`http://127.0.0.1:8080`), `ACADEMIC_API_BASE_URL` (`http://127.0.0.1:3001`), and `VIDEO_CALL_WS_BASE_URL` (`ws://127.0.0.1:8080/ws/video-call/{roomCode}?ticket=...`).

---

*Software Engineering • Systems Architecture & Security • PUC-Campinas • 2026*
