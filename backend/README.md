# Backend — Enterprise Academic Services & Persistence

The `backend` module defines the target architecture for the enterprise business logic, persistence layer, identity management, and orchestration services of the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3).

---

## Docente, video chamada e WebSocket (implementado)

Tudo escrito apenas com o JDK (sockets, threads, `MessageDigest`); a unica dependencia externa e o driver `mongodb-driver-sync`.

**Como rodar** (sem Maven; jars do driver em `backend/lib`):

```
backend
un-server.bat
```

Configuracao em `MONGODB_URI` e `MONGODB_DATABASE` (variavel de ambiente ou arquivo `env` na raiz, nunca versionado). Sem `MONGODB_URI` o servidor usa banco em memoria. Porta: `SERVER_PORT` (padrao 8080).

**REST** (JSON; `GET` lista com filtros `?campo=valor`, `POST` cria, `GET/PUT/PATCH/DELETE /{id}`):

| Rota | Colecao no banco `agmrm` |
|---|---|
| `/api/docente/profiles` | `docente_profiles` |
| `/api/docente/class-plans` | `docente_class_plans` (ementa e materiais de uma turma) |
| `/api/docente/attendance-sessions` | `docente_attendance_sessions` |
| `/api/docente/assignments` | `docente_assignments` |
| `/api/docente/grades` | `docente_grades` |
| `/api/docente/notices` | `docente_notices` |
| `/api/docente/events` | `docente_events` |
| `/api/video-call/rooms` | `video_rooms` |
| `/api/video-call/sessions` | `video_call_sessions` |
| `/api/video-call/chat-messages` | `video_chat_messages` |

Os campos usam os mesmos nomes dos modelos do frontend (`features/teacher/shared/domain/models` e `video_call`), entao o app consome o JSON sem traducao. `teacherIdentity` e `professorIdentity` referenciam o login do professor e `classCode` pode apontar para uma turma de `academic_classes`, sem duplicar o que o admin ja cadastra. Os campos aceitos de cada colecao estao em `docente/DocenteEsquemas.java` e `videocall/VideoCallEsquemas.java`; campos desconhecidos, tipos errados e valores fora das opcoes (ex.: `classification`, `type`) retornam 400. As notas em `/api/docente/grades` voltam com `n1Total`, `n2Total`, `finalAverage` e `status` calculados pelo servidor.

**Acoes do docente com regra de negocio** (`POST /api/docente/actions/{acao}`, o cliente nao envia valores calculados):

| Acao | Corpo | Regra aplicada no servidor |
|---|---|---|
| `attendance` | `sessionId`, `studentId`, `status` (`presente`, `ausente`, `justificada`) | soma ou desconta falta (0 a 40), recalcula `attendanceRate` sobre 38 aulas e `riskLevel` (abaixo de 80% atencao, abaixo de 75% critico); a aula deixa de estar homologada |
| `homologate` | `sessionId` | marca a aula como homologada |
| `rubric-evaluation` | `assignmentId`, `submissionId`, `feedback`, `scores` (criterio -> nota) | nota de 0 a 10 proporcional aos pontos dos criterios; rejeita nota acima do maximo do criterio; entrega vira `corrigido` |
| `syllabus-advance` | `courseId`, `unitId` | avanca 2 aulas na unidade (volta 2 se completa), entre 0 e o total |
| `publish-material` | `courseId`, `title` (`type` e `size` opcionais) | cria o material com id e data do servidor |
| `grade` | `courseId`, `studentId`, `assignmentsScore`, `p1Score`, `projectsScore`, `p2Score` | notas de 0 a 10; devolve medias e situacao (`aprovado` com media 7 ou mais, `exame` de 4 a 7, `reprovadoPorNota`, e `reprovadoPorFalta` com frequencia abaixo de 75%) |
| `toggle-two-factor` | `profileId` | alterna `twoFactorEnabled` |
| `disconnect-session` | `profileId`, `sessionId` | remove a sessao ativa do perfil |

Registro inexistente retorna 404 e dados invalidos, 400. Ainda nao ha autenticacao nas rotas.

**WebSocket**: `ws://localhost:8080/ws/video-call/{sala}` (handshake RFC 6455 manual). O hub repassa os envelopes `p2p_videocall_v1` a todos da sala menos o remetente, impede troca de `senderId`, avisa a saida com `leave` e grava as mensagens de chat em `video_chat_messages`.

**Seed do docente**: `java -cp "out;lib\*" docente.SeedDocente` faz um ensaio em memoria; com `--confirmar` grava no MongoDB (substitui por id, pode repetir).

**Testes** (sem JUnit; cada um e um `main` em `backend/tests`): compilar `src` e `tests` juntos com `javac -cp "lib\*"` e executar a classe, por exemplo `api.CrudHandlerTeste`, `websocket.QuadroTeste`, `videocall.hub.HubTeste`.

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

- **Frontend Integration**: The Flutter client ([`frontend/`](../frontend/README.md)) connects its feature modules (`features/auth_view/` and `features/student_view/`) and shared data layer (`shared/auth/external/auth_remote_datasource_impl.dart`) to these REST endpoints.
- **Server Integration**: The native Java HTTP server ([`server/`](../server/README.md)) continues to operate as a high-speed computational service for primitive parsing and mathematical evaluation or can be embedded as an internal microservice.
- **Security Policy**: All backend operations comply with the defense-in-depth guards, threat models, and governance policies implemented in [`security/`](../security/README.md).
