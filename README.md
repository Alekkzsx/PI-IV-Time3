# Integrated Educational Platform (AGMRM)

Project developed for the **Integrator Project 4** course in Software Engineering at **PUC-Campinas** (2026).

---

## About

**Integrated Educational Platform (AGMRM)** is a unified academic mobile and web platform developed for Integrator Project IV (Team 3).

The platform addresses the fragmentation of educational tools by consolidating attendance tracking, flexible weighted grade calculation, assignment submissions with automated late penalties, secure authentication with strict token expiration, and multi-platform access.

### Key features

- **Student Academic Portal (`student_view`)** — dedicated student workspace with official **Messages & Announcements** (`student_messages`) and **Virtual Secretariat & Protocol Requests** (`student_secretariat`)
- **Academic Report & Grades** — real-time query of report cards (`/api/notas/boletim`) with exams (P1, P2), assignments, custom weights, and automatic pass/recovery status
- **Attendance Tracking** — automated attendance calculation (`/api/presenca`) with thresholds for full attendance ($\ge 75\%$), half attendance ($\ge 50\%$), absence, and instructor manual overrides
- **Assignment Submissions** — automated late penalty calculation (`/api/tarefas/calcular-nota`) deducting 20% of base grade per late day down to zero
- **Security & Authentication (`auth_view` & `security/`)** — multi-layer defense-in-depth architecture featuring brute-force rate limiting (5 attempts $\rightarrow$ 30s lockout), password recovery with strict 5-minute token TTL and 3-attempt OTP revocation, anti-enumeration generic responses, constant-time comparison, input sanitization, and HTTP security headers
- **Type Processing API** — endpoint (`/api/teste-tipos`) demonstrating multi-type data parsing and type validation over HTTP

---

## Team

| Full name | Student ID (RA) |
|---|---|
| *Alex Gabriel Soares Sousa* | *24802449* |
| *Guilherme Moreira* | *25006702* | 
| *Marcelo Zarpelon* | *25015323* | 
| *Murillo Caravita* | *25014012* |
| *Rafael Henrique Inácio* | *25009719* | 

---

## Tech stack

| Layer | Technology |
|---|---|
| App (Frontend) | Flutter + Dart (Feature-First Clean Architecture) |
| Native Server | Java SE 17+ (Native HTTP Server built from scratch) |
| Security Module | Dart/Flutter Client Guards + Native Java SE Server Guards |
| Server Runtime | Native Sockets + Scripts (Batch / Shell) |
| Version control | Git + GitHub |

---

## Repository structure

```
PI-IV-Time3/
├── .github/                  # CI/CD workflows, CODEOWNERS, and branch protection policies (see [.github/GOVERNANCE.md](.github/GOVERNANCE.md))
├── frontend/                 # Multi-platform Flutter app (Feature-First Clean Architecture)
│   ├── lib/
│   │   ├── core/             # Shared theme tokens, failure models, and input validators
│   │   ├── features/
│   │   │   ├── auth_view/    # Login, Forgot Password, Verify OTP Code, and Reset Password
│   │   │   └── student_view/ # Student Portal: Messages & Announcements, Virtual Secretariat
│   │   └── shared/           # Shared auth repository, student sidebar/shell layout, and widgets
│   └── test/                 # Unit and widget tests mirroring auth_view and student_view
├── server/                   # Autonomous native Java HTTP server (built from scratch, no frameworks)
│   ├── src/                  # Java sources: ServidorHttpNativo, handlers, and HttpUtils
│   └── tests/                # Compilation and automated cURL verification suite
├── security/                 # Enterprise defense-in-depth security module (Dart & Native Java SE)
│   ├── lib/                  # Client-side rate limiters, token lifecycle, sanitizers, and widgets
│   ├── auth/                 # Server-side lockout manager, constant-time comparator, and token TTL
│   ├── middleware/           # Security HTTP headers, 64 KB body ceiling, and error sanitizer
│   ├── validators/           # Server-side input sanitization and password entropy evaluation
│   ├── policies/             # Immutable security constants, generic feedback, and config loader
│   ├── tests/                # End-to-end Dart and Java security verification suites
│   └── .env.example          # Standardized security and server environment template
└── backend/                  # Target architecture for enterprise backend services & persistence
```

---

## Running locally (dev environment)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Java Development Kit (JDK 17+)](https://www.oracle.com/java/technologies/downloads/)
- Git
- Android Studio, VS Code with Flutter extension, or a browser (Chrome)

---

### 1. Clone the repository

```bash
git clone https://github.com/Alekkzsx/PI-IV-Time3.git
cd PI-IV-Time3
```

---

### 2. Configure environment variables (optional)

Review the example configuration file in the `security` directory:

```bash
cp security/.env.example security/.env
```

| Variable | Description | Default value |
|---|---|---|
| `SERVER_PORT` | HTTP server port | `8080` |
| `REQUEST_TIMEOUT_SECONDS` | Request timeout for DoS mitigation | `30` |
| `MAX_REQUEST_BODY_SIZE_BYTES` | Maximum request body size (64 KB) | `65536` |
| `MAX_FAILED_LOGIN_ATTEMPTS` | Failed logins before temporary lockout | `5` |
| `LOCKOUT_DURATION_SECONDS` | Account lockout cooldown duration | `30` |
| `RECOVERY_TOKEN_TTL_SECONDS` | Ephemeral recovery token expiration (5 min) | `300` |
| `MAX_VERIFICATION_ATTEMPTS` | Max OTP attempts before token revocation | `3` |
| `PASSWORD_MIN_ENTROPY_SCORE` | Minimum required password strength score | `3` |

---

### 3. Start the backend server

The server uses native Java SE with no external framework dependencies (no Maven or Gradle required):

**On Windows:**

```cmd
server\run-server.bat
```

**On Linux / macOS:**

```bash
chmod +x server/run-server.sh
./server/run-server.sh
```

The server will listen on port `8080`.

#### Automated API verification (test suite)

With the server running, open a second terminal and run:

**On Windows:**

```cmd
server\test-server.bat
```

**On Linux / macOS:**

```bash
chmod +x server/test-server.sh
./server/test-server.sh
```

---

### 4. Set up the frontend

Navigate to the `frontend` directory and install dependencies:

```bash
cd frontend
flutter pub get
```

---

### 5. Run the app

**In the browser (Chrome):**

```bash
cd frontend
flutter run -d chrome
```

**On a connected Android/iOS device or emulator:**

```bash
cd frontend
flutter run
```

**Run unit and widget tests:**

```bash
cd frontend
flutter test
```

**List available devices:**

```bash
flutter devices
```

---

## API Endpoints

The native HTTP server provides 4 REST endpoints on port **8080**:

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/teste-tipos` | Processes and validates primitive types (`texto`, `inteiro`, `flutuante`, `duplo`, `caractere`) |
| `POST` | `/api/presenca` | Calculates attendance rate (`minutosAssistidos`, `duracaoTotal`, optional `statusManual`) |
| `POST` | `/api/tarefas/calcular-nota` | Computes grade deduction based on late days (20% penalty per late day) |
| `POST` | `/api/notas/boletim` | Calculates weighted final grade (`p1`, `p2`, `trabalho`) and academic status |

---

*Integrator Project 4 — Software Engineering — PUC-Campinas — 2026*