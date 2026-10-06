# Integrated Educational Platform (AGMRM)

Project developed for the **Integrator Project 4** course in Software Engineering at **PUC-Campinas** (2026).

---

## About

**Integrated Educational Platform (AGMRM)** is a unified academic mobile and web platform developed for Integrator Project IV (Team 3).

The platform addresses the fragmentation of educational tools by consolidating attendance tracking, flexible weighted grade calculation, assignment submissions with automated late penalties, secure authentication with strict token expiration, and multi-platform access.

### Key features

- **Academic Report & Grades** — real-time query of report cards (`/api/notas/boletim`) with exams (P1, P2), assignments, custom weights, and automatic pass/recovery status
- **Attendance Tracking** — automated attendance calculation (`/api/presenca`) with thresholds for full attendance ($\ge 75\%$), half attendance ($\ge 50\%$), absence, and instructor manual overrides
- **Assignment Submissions** — automated late penalty calculation (`/api/tarefas/calcular-nota`) deducting 20% of base grade per late day down to zero
- **Security & Authentication** — password recovery with strict 5-minute token TTL, role-based access control (Student, Professor, Admin), input validation, and STRIDE/DREAD threat modeling
- **Type Processing API** — endpoint (`/api/teste-tipos`) demonstrating multi-type data parsing and type validation over HTTP

---

## Team

| Full name | Student ID (RA) | Role / Focus Area |
|---|---|---|
| *Alex Gabriel Soares Sousa* | *24802449* | Architecture, Frontend Flutter & Monorepo Governance |
| *Guilherme Moreira* | *25006702* | Native Java Backend, Server Infrastructure & Business Logic |
| *Marcelo Zarpelon* | *25015323* | Requirements Analysis & Academic Domain Modeling |
| *Murillo Caravita* | *—* | Quality Assurance, Integration Testing & Validation |
| *Rafael Henrique Inácio* | *25009719* | Information Security, Policies & Compliance |

---

## Tech stack

| Layer | Technology |
|---|---|
| App (Frontend) | Flutter + Dart (Clean Architecture) |
| Backend | Java SE 17+ (Native HTTP Server) |
| Server Runtime | Native Sockets + Scripts (Batch / Shell) |
| Security & Governance | STRIDE / DREAD Threat Modeling, CORS, GitHub Actions |
| Version control | Git + GitHub |

---

## Repository structure

```
PI-IV-Time3/
├── .github/                  # CI/CD workflows, CODEOWNERS, and branch protection policies
├── frontend/                 # Multi-platform Flutter app (Clean Architecture: Presentation, Domain, Data)
├── backend/                  # Domain services and business logic (Java SE native HTTP server)
├── server/                   # Server runtime scripts, socket configuration (port 8080), and cURL test suite
└── security/                 # Institutional cybersecurity governance, CORS configuration, and threat modeling
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
| `CORS_ORIGIN` | Allowed CORS origin | `http://localhost` |
| `REQUEST_TIMEOUT_SECONDS` | Request timeout for DoS mitigation | `30` |
| `MAX_BODY_SIZE_KB` | Maximum request body size | `64` |

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