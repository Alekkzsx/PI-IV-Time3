# Backend — Enterprise Academic Services & Persistence

The `backend` module defines the target architecture for the enterprise business logic, persistence layer, identity management, and orchestration services of the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3).

---

## 🏛️ Architectural Purpose & Scope

The `backend` module serves as the long-term domain and persistence core of the AGMRM ecosystem. While the lightweight, zero-dependency native Java server in [`server/`](../server/README.md) provides specialized, high-performance execution of standalone academic calculation algorithms and raw HTTP socket handling, the `backend` module is scoped to accommodate:

1. **Persistent Data Storage**: Relational databases, migration pipelines, and Object-Relational Mapping (ORM) / Data Access Objects (DAO).
2. **Enterprise Business Microservices**: Complex student management workflows, enrollment validation, and curriculum lifecycle tracking.
3. **Identity & Access Management (IAM)**: Centralized OAuth2/OpenID Connect provider or JWT authentication engine.
4. **API Gateway & Orchestration**: Unified REST and GraphQL gateway mediating requests between the Flutter frontend client and core services.

---

## 📂 Current Repository State & Structural Reservation

On disk, the `backend` directory currently contains a versioned placeholder:

```
backend/
├── .gitkeep                      # Git placeholder maintaining directory structure
└── README.md                     # Architectural documentation (this file)
```

### Why is `.gitkeep` Present?
In the initial development milestone of the AGMRM project:
- Core calculation handlers (attendance percentage, assignment penalty deductions, and report card weighted grading) were developed inside [`server/src/`](../server/README.md) using native Java SE standard library APIs without third-party frameworks.
- The `backend/` directory is deliberately preserved in source control via `.gitkeep` to establish an explicit boundary between the protocol-level Java socket server (`server/`) and the full enterprise application backend tier.
- As the project advances through future sprints, enterprise backend frameworks, data schemas, and API definitions will be integrated directly into this module without disrupting the native socket server.

---

## 🗺️ Architectural Roadmap & Future Contracts

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter Client (frontend/)                     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                       HTTP / JSON (REST / GraphQL)
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       AGMRM Backend Services (backend/)                │
│                                                                        │
│   ┌───────────────────────────┐      ┌─────────────────────────────┐   │
│   │   Identity & Auth (IAM)   │      │    Academic Core Service    │   │
│   │  - OAuth2 / JWT Tokens    │      │  - Enrollments & Courses    │   │
│   │  - Argon2 Password Hashing│      │  - Gradebook Lifecycle      │   │
│   └─────────────┬─────────────┘      └──────────────┬──────────────┘   │
│                 │                                   │                  │
│   ┌─────────────▼─────────────┐      ┌──────────────▼──────────────┐   │
│   │   Attendance Sync Worker  │      │     Assignment Service      │   │
│   │  - Virtual Class Sessions │      │  - Submissions & Penalties  │   │
│   └─────────────┬─────────────┘      └──────────────┬──────────────┘   │
│                 │                                   │                  │
│                 └─────────────────┬─────────────────┘                  │
│                                   │                                    │
│                                   ▼                                    │
│                     Persistence Layer (ORM / DAO)                     │
│               PostgreSQL / SQLite + Flyway/Liquibase Migrations        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                     Calculations / Socket Dispatch
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Native Java Calculation Engine (server/src/)             │
│    (/api/teste-tipos, /api/presenca, /api/tarefas, /api/notas/boletim)  │
└────────────────────────────────────────────────────────────────────────┘
```

### Planned Subsystems & Target Contracts

| Subsystem | Planned Technology / Standard | Target Responsibilities |
|---|---|---|
| **Identity & Access Management (IAM)** | JWT (RFC 7519), OAuth2, Argon2id | Secure token issuance, token refresh rotation, role-based access control (Student, Faculty, Admin), and credential hashing. |
| **Academic Records Service** | REST / JSON Schema, gRPC | Course catalog, student registrations (RA), semester curriculum, and transcript archival. |
| **Gradebook & Calculation Orchestrator** | Spring Boot / Quarkus / Micronaut | Orchestrating grade submissions with the native calculation engine (`BoletimHandler` and `TarefasHandler`). |
| **Attendance Reconciliation Service** | Event-Driven / Webhooks | Real-time synchronization of virtual and in-person attendance logs, driving `PresencaHandler`. |
| **Persistence Engine** | PostgreSQL / SQLite with Flyway | ACID-compliant transactional persistence, audit logs, and automated schema migration scripts. |

---

## 🔌 API Contract Specifications (Preview)

When fully instantiated, the backend will expose standardized REST endpoints adhering to the following OpenAPI-style specifications:

### 1. Authentication Contract (`POST /api/v1/auth/token`)
- **Request Headers**: `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "identity": "24802449",
    "password": "SecurePassword#2026",
    "role": "aluno"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "refreshToken": "d8f3a9e2-1b4c-4e8a-...",
    "user": {
      "ra": "24802449",
      "name": "Alex Gabriel Soares Sousa",
      "role": "aluno"
    }
  }
  ```

### 2. Password Recovery Contract (`POST /api/v1/auth/recover-password`)
- **Request Body**:
  ```json
  {
    "identity": "24802449",
    "profile": "aluno"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "status": "INSTRUCTIONS_SENT",
    "expiresInSeconds": 300,
    "maskedDestination": "al***@puc-campinas.edu.br"
  }
  ```

---

## 🔗 Cross-Module Integration

- **Frontend Integration**: The Flutter client (`frontend/`) will replace its simulated network layer (`AuthRemoteDataSourceImpl`) with HTTP client implementations targeting these backend endpoints.
- **Server Integration**: The native Java HTTP server (`server/`) will continue to operate as a high-speed computational service for primitive parsing and mathematical evaluation or be embedded as an internal microservice.
- **Security Policy**: All backend operations will comply with the governance rules and threat models specified in [`security/`](../security/README.md).
