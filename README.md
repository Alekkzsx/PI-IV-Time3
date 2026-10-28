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
- **Institutional Video Call (`video_call`)**: P2P WebRTC video conference integrated into the native Java server (`server/`). Active speaker detection, FIFO doubt queue (raised hands), real-time chat, and presence tracking by connected time.
- **Native Java SE HTTP Server (`server/`)**: Zero-dependency native server on port 8080. 15 endpoints for academic logic, WebRTC signaling, and real OTP email recovery via SMTP SSL/TLS.
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
| **Backend Core (Server)** | Java SE — Pure Native HTTP Server (No external libraries) |
| **Security & Defenses** | agmrm_security (Dart) + Java Security Middleware (Defense-in-Depth) |
| **Persistence Layer** | Relational (PostgreSQL) / Document (MongoDB) |
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
├── server/           # Native autonomous Java HTTP server (zero external frameworks)
│   ├── src/
│   │   ├── main/     # Main.java — Central orchestrator on port 8080
│   │   ├── core/     # Low-level TCP sockets, HTTP handlers, and CORS
│   │   ├── academic/ # Grades, Attendance, Tasks, and Data Types
│   │   ├── auth/     # Real email OTP recovery via SMTP SSL/TLS (port 465)
│   │   └── videocall/# Virtual rooms, WebRTC signaling, Chat, Raised hands, Attendance
│   └── tests/        # Documented cURL validation commands (testeServidor.txt)
├── security/         # Enterprise cyber defense module (37 tests)
│   ├── lib/          # Client-side defenses (lockout, rate limiter, timing, entropy)
│   ├── test/         # Security test suite (37 tests)
│   └── server/       # Server-side security filters (rate limiter, headers, sanitizers)
├── backend/          # Enterprise persistence and orchestration configuration
│   ├── backend-config.json # Declarative configuration for parent modules
│   └── target/classes/     # Compiled entity models and repositories
└── .env-example      # Unified master environment template for all modules
```

---

## Running Locally (Dev Environment)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Java JDK](https://www.oracle.com/java/technologies/downloads/) (JDK 8 or higher / JDK 17 or 21 recommended)
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

| Variable | Description | Default Value |
|---|---|---|
| `SERVER_PORT` | HTTP Server port | `8080` |
| `REQUEST_TIMEOUT_SECONDS` | Request timeout for socket connection | `30` |
| `MAX_FAILED_LOGIN_ATTEMPTS` | Maximum failed logins before lockout | `5` |
| `LOCKOUT_DURATION_SECONDS` | Lockout duration in seconds | `30` |
| `STANDARDIZED_AUTH_LATENCY_MS` | Constant-time execution baseline | `1000` |
| `RECOVERY_TOKEN_TTL_SECONDS` | Ephemeral OTP recovery token lifespan | `300` |
| `MAX_VERIFICATION_ATTEMPTS` | Maximum invalid OTP attempts allowed | `3` |
| `SMTP_HOST` | Outgoing SMTP email host | `smtp.gmail.com` |
| `SMTP_PORT` | Outgoing SMTP SSL port | `465` |
| `SMTP_USER` | Dedicated email sender account | `staff.notadez@gmail.com` |

---

### 3. Install Project Dependencies

Install dependencies for both Flutter and Dart packages:

```bash
cd frontend
flutter pub get
cd ../security
flutter pub get
cd ..
```

---

### 4. Start the Backend Server

The Java server is automatically launched when running `flutter run`, or can be executed manually:

#### On Windows:
```bash
cd server
javac --release 8 -encoding UTF-8 -d bin src/core/*.java src/academic/*.java src/auth/*.java src/videocall/*.java src/main/*.java
java -cp bin main.Main
```

#### On Linux / macOS:
```bash
cd server
javac --release 8 -encoding UTF-8 -d bin src/core/*.java src/academic/*.java src/auth/*.java src/videocall/*.java src/main/*.java
java -cp bin main.Main
```

*The server will start on port 8080.*

#### Automated Full Build and Verification:
To build and run tests across all parent modules:

##### On Windows / PowerShell:
```powershell
cd frontend
flutter test
cd ../security
flutter test
```

##### On Linux / macOS:
```bash
cd frontend
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

The native Java server provides 15 endpoints on port 8080:

| Method | Endpoint | Description |
|---|---|---|
| `GET` / `POST` | `/api/teste-tipos` | Diagnostic and echo of primitive types (text, numeric, boolean) |
| `POST` | `/api/presenca` | Calculates presence percentage and excused absence allowance |
| `POST` | `/api/tarefas/calcular-nota` | Computes final task grade deducting penalty for late submissions |
| `POST` | `/api/notas/boletim` | Calculates semester weighted average and passing status |
| `GET` | `/api/videocall/rooms` | Lists active virtual classrooms and room health status |
| `POST` | `/api/videocall/open` | Opens virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/close` | Closes virtual classroom (**Teacher or Admin only**) |
| `POST` | `/api/videocall/join` | Joins session and records attendance telemetry |
| `POST` | `/api/videocall/leave` | Leaves session and logs connected duration |
| `POST` | `/api/videocall/signal` | P2P WebRTC signaling (SDP offer/answer, ICE candidates) |
| `POST` | `/api/videocall/hand-raise` | Manages FIFO queue of raised hands and doubts |
| `POST` | `/api/videocall/chat` | Real-time chat messages with room timestamps |
| `POST` | `/api/videocall/attendance` | Homologates presence based on connected duration |
| `POST` | `/api/auth/send-recovery-otp` | Generates 6-digit OTP and dispatches real SMTP email (5-min TTL) |
| `POST` | `/api/auth/verify-recovery-otp` | Validates OTP with 300s TTL and 3-attempt brute-force limit |

---

*Software Engineering • Systems Architecture & Security • PUC-Campinas • 2026*
