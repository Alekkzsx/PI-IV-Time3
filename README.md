# Plataforma Educacional Integrada (AGMRM)

> Repositório integrado da Plataforma Educacional Integrada (*Projeto Interdisciplinar IV - PI-IV Time 3 - PUC-Campinas 2026*)

---

## Sobre

A **Plataforma Educacional Integrada (AGMRM)** é uma plataforma educacional acadêmica integrada desenvolvida para a disciplina Projeto Interdisciplinar IV.

A plataforma resolve a fragmentação de ferramentas educacionais ao integrar controle de presença, diário de classe digital, cálculo de notas, entrega de atividades com penalidades automáticas por atraso, videoconferência com WebRTC e arquitetura de ciberdefesa em profundidade.

### Principais Funcionalidades

- **Portais Multi-Perfil (Discente, Docente, Administrador)**: Interfaces dedicadas com níveis de permissão distintos.
- **Portal do Discente**: Histórico acadêmico com médias ponderadas, faltas, grade de horários, avisos e secretaria virtual.
- **Portal do Docente**: Lançamento de notas, diário de presença digital, homologação de frequência e gestão de sala de aula virtual.
- **Portal Administrativo**: Gestão de identidade de usuários, cockpit de auditoria, secretaria acadêmica e trava regimental do CONSEPE.
- **Videochamada Institucional (`video_call`)**: Videoconferência P2P WebRTC hospedada no servidor Java nativo (`server/` na porta `8080`) com lobby pré-chamada em tema monocromático de alto contraste (`VideoCallColors`), salas e presenças persistidas (`academic_live_sessions`, `video_call_attendance_logs`), tíquetes WS de uso único (`video_call_ws_tickets`), detecção de orador ativo, fila FIFO de dúvidas (mãos levantadas) e chat em tempo real sincronizado com o hub WebSocket.
- **Servidor Java SE Nativo (`server/` na porta `8080`)**: Fronteira autoritativa de Identidade e Comunicação em Tempo Real (Login com validação estrita de compatibilidade de perfil `aluno`/`docente`/`admin`, 2FA, recuperação via OTP de uso único, Perfil/Sessões/exportação LGPD, Gestão Administrativa de Usuários, `/api/video-call/rooms*` persistido + `/ws/video-call/{roomCode}`, `/health` e monitor proativo `MonitorBackendAcademico`). Comunica-se com `backend/` via `/api/internal/academic/*` (`X-Internal-Service-Secret`).
- **API do Núcleo Acadêmico (`backend/` na porta `3001`)**: Serviço acadêmico modular em TypeScript + Express + MongoDB responsável pelos portais Discente/Docente, operações acadêmicas administrativas, downloads de arquivos (`/api/files/*`), validação passiva de JWT HS256 + `auth_sessions` e ponte interna `/api/internal/academic/*`.
- **Guarda Fail-Closed de Disponibilidade (`ServerUnavailableGuard`)**: Monitoramento contínuo dos serviços Java (`:8080/health`) e TypeScript (`:3001/health`) no cliente Flutter, bloqueando operações órfãs quando qualquer servidor estiver indisponível (com opção de desativação para desenvolvimento via `--dart-define=ENABLE_SERVER_GUARD=false` ou `.github/setup` `--no-guard` / `-NoGuard`).
- **Ciberdefesa em Profundidade (`security/`)**: Bloqueio contra força bruta (5 tentativas $\rightarrow$ bloqueio de 30s), mitigação de ataques de temporização (side-channel timing), respostas opacas anti-enumeração, sanitização contra XSS/SQLi, ciclo de vida de tokens OTP e submódulo de proteção discente (verificação SHA-256 de entregas, inspeção de *magic bytes* de uploads, validador de repositórios Git e limitador de ações).

---

## Equipe

| Nome Completo | RA |
|---|---|
| Alex Gabriel Soares Sousa | 24802449 |
| Guilherme Henrique Moreira | 25006702 |
| Marcelo Zarpelon | 25015323 |
| Murillo Caravita | 25014012 |
| Rafael Henrique Inácio | 25009719 |

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| **Aplicação (Cliente)** | Flutter (Desktop: Windows / Mobile / Web) |
| **Servidor de Identidade, Usuários e WS de Videochamada** | Java SE (`server/` na porta `8080`) — HTTP Nativo Puro + WebSocket RFC 6455 + MongoDB Sync Driver |
| **Núcleo Acadêmico e API de Ponte Interna** | TypeScript + Express + MongoDB (`backend/` na porta `3001`) |
| **Segurança e Defesas** | agmrm_security (Dart) + Defesa em Profundidade Nativa com JWT/Rate-Limit |
| **Camada de Persistência** | Orientada a Documentos (MongoDB) |
| **Controle de Versão** | Git & GitHub |

---

## Estrutura do Repositório

```
.../PI-IV-Time3/
├── .github/          # Fluxos de CI/CD, CODEOWNERS, GOVERNANCE.md, perfis .vscode e orquestrador multiplataforma (setup/)
├── frontend/         # Aplicativo Flutter multiplataforma (Clean Architecture Feature-First, 57 arquivos de teste)
│   ├── lib/
│   │   ├── core/     # Tema, tokens de design, rotas, guarda Fail-Closed (ServerHealthMonitor) e launcher de backend
│   │   ├── features/ # auth, student, teacher, admin, video_call, multiperfil
│   │   └── main.dart # Ponto de entrada do app com inicialização automatizada e guarda de disponibilidade
│   └── test/         # Suíte abrangente de testes de unidade, widget e integração
├── server/           # Servidor Java SE na porta 8080 (104 arquivos Java: Identidade, Admin, Videochamada REST + WS)
│   ├── src/
│   │   ├── Main.java # Orquestrador central na porta 8080
│   │   ├── core/     # Sockets TCP HTTP/1.1, CORS, failover MongoDB/DoH e MonitorBackendAcademico
│   │   ├── auth/     # Autenticação, 2FA, Recuperação OTP, Perfil, Sessões, Usuários Admin, E-mail e validação JWT
│   │   ├── bridge/   # Cliente HTTP autenticado para /api/internal/academic/* do backend
│   │   ├── utils/    # BsonUtils, ConfigEnv, Json, JsonSimples e RedeUtils
│   │   ├── websocket/# Handshake WebSocket RFC 6455, enquadramento (framing) e ciclo de vida
│   │   └── videocall/# Salas persistidas (/api/video-call/rooms*), hub WebRTC e Frequência
│   └── tests/        # Suíte nativa de testes Java sem dependências externas (SuiteTestesServidor - 17 suítes)
├── security/         # Módulo corporativo de ciberdefesa (agmrm_security: 125 testes Dart + 20 cenários Java)
│   ├── lib/          # Defesas de autenticação e proteção discente (SHA-256, magic bytes, rate-limit, entropia)
│   ├── test/         # 21 suítes de testes automatizados em Dart/Flutter
│   └── server/       # Filtros de segurança do lado do servidor Java (limitador de taxa, cabeçalhos, sanitizadores)
├── backend/          # Núcleo Acadêmico em TypeScript + Express + MongoDB na porta 3001 (61 testes automatizados)
│   ├── src/
│   │   ├── config/   # Carregamento de ambiente e validação estrita
│   │   ├── shared/   # Cliente MongoDB, middleware passivo JWT+sessão, índices e erros
│   │   ├── modules/  # Módulos acadêmicos: admin/, student/, teacher/, notifications/, internal/
│   │   ├── scripts/  # Provisionamento de usuários via CLI e 6 seeds modulares idempotentes
│   │   └── tests/    # Suítes centralizadas de testes unitários (unit/) e de integração (integration/)
│   └── backend-config.json # Configuração declarativa para os módulos principais
└── .env-example      # Modelo mestre unificado de variáveis de ambiente para todos os módulos
```

---

## Executando Localmente (Ambiente de Desenvolvimento)

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x ou superior)
- [Java JDK](https://www.oracle.com/java/technologies/downloads/) (JDK 8 ou superior / JDK 17 ou 21 recomendado)
- [Node.js](https://nodejs.org/) (20.x ou superior, para `backend/`)
- Git

---

### 1. Clonar o Repositório

```bash
git clone https://github.com/Alekkzsx/PI-IV-Time3.git
cd .../PI-IV-Time3
```

---

### 2. Configurar Credenciais de Ambiente

Crie seu arquivo de configuração de ambiente a partir do modelo na raiz do projeto:

```bash
cp .env-example .env
```

Todos os módulos do projeto (`backend/`, `server/`, `frontend/`, `security/`) carregam a configuração **exclusivamente** deste único arquivo `.env` mestre na raiz.

| Variável | Descrição | Valor Padrão |
|---|---|---|
| `SERVER_PORT` | Porta do servidor HTTP/WS em Java | `8080` |
| `AUTH_JWT_SECRET` | Segredo compartilhado JWT HS256 (mín. 32 caracteres) | *(configurado no `.env`)* |
| `REQUEST_TIMEOUT_SECONDS` | Tempo limite de requisição para conexão de socket | `30` |
| `MAX_FAILED_LOGIN_ATTEMPTS` | Máximo de tentativas de login malsucedidas antes do bloqueio | `5` |
| `LOCKOUT_DURATION_SECONDS` | Duração do bloqueio em segundos | `30` |
| `STANDARDIZED_AUTH_LATENCY_MS` | Linha de base de execução em tempo constante | `1000` |
| `RECOVERY_TOKEN_TTL_SECONDS` | Tempo de vida efêmero do token de recuperação OTP | `300` |
| `MAX_VERIFICATION_ATTEMPTS` | Máximo de tentativas inválidas de OTP permitidas | `3` |

---

### 3. Instalar Dependências do Projeto

Instale as dependências dos pacotes Flutter, de segurança em Dart e do backend em TypeScript:

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

### 4. Iniciar os Serviços (Automático via `.github/setup` ou Manual)

#### Opção A: Orquestrador Multiplataforma Automatizado (Recomendado)
Inicia automaticamente o Servidor Java (`:8080`), o Backend TypeScript (`:3001`) e o Frontend Flutter em 3 terminais dedicados:

```bash
# Linux / macOS / WSL2:
./.github/setup/setup.sh

# Para iniciar com a trava Fail-Closed desativada:
./.github/setup/setup.sh --no-guard
```

```powershell
# Windows (CMD ou PowerShell):
.\.github\setup\setup.bat

# Para iniciar com a trava Fail-Closed desativada:
.\.github\setup\setup.bat -NoGuard
```

#### Opção B: Inicialização Manual dos Serviços
Inicie o Núcleo Acadêmico em TypeScript e a API de Ponte Interna na porta `3001`:

```bash
cd backend
npm run dev
```

Compile e inicie o servidor Java nativo na porta `8080`:

```bash
cd server
mkdir -p bin
javac --release 8 -encoding UTF-8 -cp "lib/*" -d bin $(find src -name "*.java")
java -Dfile.encoding=UTF-8 -cp "bin:lib/*" Main
```

#### Build e Verificação Completa Automatizada:
Para compilar e executar as suítes de testes em todos os módulos:

```bash
# 1. Backend Acadêmico (61 testes)
cd backend && npm test

# 2. Servidor Java Nativo (17 suítes nativas)
cd ../server && mkdir -p /tmp/server_test_bin && javac --release 8 -encoding UTF-8 -cp "lib/*" -d /tmp/server_test_bin $(find src tests -name "*.java") && java -Dfile.encoding=UTF-8 -cp "/tmp/server_test_bin:lib/*" SuiteTestesServidor

# 3. Módulo de Ciberdefesa (125 testes Dart)
cd ../security && flutter test

# 4. Frontend Flutter
cd ../frontend && flutter test
```

---

### 5. Executar o Aplicativo

No diretório `frontend`:

```bash
cd frontend
```

#### Windows Desktop (Recomendado):
```bash
flutter run -d windows
```

#### Google Chrome (Web):
```bash
flutter run -d chrome
```

#### Lista de Dispositivos Disponíveis:
```bash
flutter devices
```

---

## Endpoints da API

Os serviços seguem uma separação estrita de contextos delimitados entre Identidade/Videochamada (`server/` na `8080`) e Núcleo Acadêmico (`backend/` na `3001`):

| Método | Endpoint | Serviço | Descrição |
|---|---|---|---|
| `GET` | `/health` | Java (`8080`) | Verificação de integridade do servidor de Identidade e Videochamada |
| `POST` | `/api/auth/login` | Java (`8080`) | Login institucional com emissão de JWT HS256 (com 2FA e `requirePasswordChange`) |
| `POST` | `/api/auth/verify-two-factor` | Java (`8080`) | Verifica código OTP 2FA ou código de backup e persiste a sessão |
| `GET` / `PATCH` | `/api/auth/me` / `/profile` / `/lgpd-export` | Java (`8080`) | Inspeção de sessão, atualização de perfil e exportação de dados LGPD |
| `GET` / `DELETE` | `/api/auth/sessions` / `/logout-others` | Java (`8080`) | Inspeção e revogação de sessões ativas |
| `GET` / `POST` / `PATCH` | `/api/admin/users*` & `POST /api/admin/teachers` | Java (`8080`) | Gestão administrativa do ciclo de vida de usuários, dossiê e provisionamento de docentes |
| `GET` / `POST` | `/api/video-call/rooms*` | Java (`8080`) | Consulta de sala ao vivo persistida, emissão de tíquete WS de uso único, encerramento e frequência |
| `GET` / `POST` | `/api/videocall/*` | Java (`8080`) | Endpoints legados de compatibilidade para sala ao vivo, sinalização e telemetria de chat |
| `GET` | `/health` | TS (`3001`) | Verificação de integridade da API Acadêmica (`agmrm-academic-api`) |
| `GET` / `POST` / `PATCH` | `/api/student/*`, `/api/teacher/*`, `/api/files/*` | TS (`3001`) | Portal AVA do Discente, cockpit do Docente e downloads de arquivos acadêmicos |
| `GET` / `POST` / `PATCH` | `/api/admin/courses*`, `/classes*`, `GET /teachers`, `/protocols*`, `/settings`, `/announcements*`, `/calendar*`, `/audit-logs`, `/system/*` | TS (`3001`) | Gestão acadêmica administrativa e operações institucionais |
| `GET` / `POST` | `/api/internal/academic/*` | TS (`3001`) | Ponte HTTP serviço-a-serviço protegida por `X-Internal-Service-Secret` |

As rotas públicas `/api/auth/*`, `/api/admin/users*`, `POST /api/admin/teachers` e `/api/video-call/*` não são mais servidas na porta `3001` (`404`). O cliente Flutter utiliza `AUTH_API_BASE_URL` (`http://127.0.0.1:8080`), `ACADEMIC_API_BASE_URL` (`http://127.0.0.1:3001`) e `VIDEO_CALL_WS_BASE_URL` (`ws://127.0.0.1:8080/ws/video-call/{roomCode}?ticket=...`).

---

*Engenharia de Software • PUC-Campinas • 2026*
