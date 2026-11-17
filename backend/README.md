<!-- Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 -->

# Backend Acadêmico (TypeScript + Express + MongoDB)

Serviço modular em TypeScript dedicado ao núcleo acadêmico (`student`, `teacher`, operações acadêmicas de `admin`, download de arquivos `/api/files/*`) e à ponte HTTP interna (`/api/internal/academic/*`).

Roda na porta `3001` por padrão e opera em conjunto com o servidor Java SE em `../server` (porta `8080`), que detém a autoridade exclusiva sobre autenticação, sessão, gestão de usuários (`/api/admin/users*`, `POST /api/admin/teachers`) e sinalização/persistência de videochamada (`/api/video-call/*`, `/ws/video-call/*`). Este serviço realiza apenas validação passiva de JWT HS256 contra `auth_users` e `auth_sessions` no MongoDB e carrega a configuração exclusivamente do `.env` na raiz (`../.env`).

## Organização

```text
backend/
├── src/
│   ├── app.ts                        # Composição das rotas acadêmicas, ponte interna e 404 explícitos
│   ├── server.ts                     # Bootstrap HTTP e conexão com MongoDB
│   ├── config/                       # Carregamento e validação estrita de variáveis de ambiente
│   ├── shared/
│   │   ├── auth/                     # Middleware passivo JWT + auth_users / auth_sessions
│   │   ├── formatting/               # Formatação reutilizável de datas e sanitizeRoomCode
│   │   ├── mongo/                    # MongoAcademicDatabase e criação de índices por domínio
│   │   └── ...                       # Erros HTTP, transações e validação compartilhada
│   ├── modules/
│   │   ├── internal/                 # Ponte HTTP interna (/api/internal/academic/*)
│   │   ├── notifications/            # ResilientEmailSender (SMTP / outbox local / banco)
│   │   ├── admin/
│   │   │   ├── infrastructure/       # Middleware adminOnly, auditoria e sanitização de registros
│   │   │   └── presentation/
│   │   │       ├── academic/         # Rotas de cursos, turmas, matrículas e GET /teachers
│   │   │       └── operations/
│   │   │           ├── calendar/     # Calendário institucional
│   │   │           ├── protocols/    # Requerimentos e decisões da secretaria
│   │   │           ├── announcements/ # Comunicados institucionais
│   │   │           ├── settings/     # Configurações institucionais
│   │   │           └── system/       # Diagnóstico de e-mail / sistema
│   │   ├── student/
│   │   │   ├── application/          # Casos de uso discentes (painel, entregas, notas, fórum, protocolos)
│   │   │   └── presentation/
│   │   │       ├── dashboard/        # Rotas /api/student/*
│   │   │       └── files/            # Downloads (/api/files/*)
│   │   └── teacher/
│   │       ├── application/          # Casos de uso docentes (diário, materiais, notas, homologação)
│   │       └── presentation/         # Rotas docentes (/api/teacher/*)
│   ├── scripts/
│   │   ├── index.ts                  # Orquestrador mestre das seeds do ecossistema
│   │   ├── modules/                  # Seeds 01-users .. 06-institutional
│   │   ├── shared/                   # Runner e tipagens compartilhadas de seeds
│   │   ├── create-auth-user.ts       # Provisionamento seguro de contas via CLI
│   │   └── test-email-resilience.ts  # Teste de envio e resiliência de e-mail (outbox)
│   └── tests/
│       ├── unit/                     # Testes unitários isolados
│       └── integration/              # Testes de integração HTTP (incluindo ponte interna e fronteira)
├── .env.example
├── backend-config.json
├── package.json
└── tsconfig.json
```

As dependências de persistência e serviços externos são injetadas nos casos de uso, permitindo testar regras de negócio sem conexão externa com MongoDB ou SMTP.

## Perfis e contas

Os únicos perfis aceitos são `aluno`, `docente` e `admin`. Contas são lidas da coleção `auth_users` no banco MongoDB escolhido. O serviço não cria contas fictícias automaticamente nem aceita credenciais hardcoded.

Cada documento contém:

```json
{
  "identity": "identificador institucional",
  "normalizedIdentity": "identificador institucional em minúsculas",
  "email": "endereço institucional",
  "displayName": "nome de exibição",
  "profile": "aluno",
  "passwordHash": "hash produzido por bcrypt",
  "active": true
}
```

`normalizedIdentity` é único. A inicialização cria esse índice e os índices TTL das coleções `auth_recovery`, `auth_sessions`, `academic_live_sessions` e `video_call_ws_tickets`. Senhas são armazenadas exclusivamente como hashes bcrypt.

Para provisionar uma conta autorizada localmente, com o ambiente configurado no `.env` da raiz, execute `npm run create-user` na pasta `backend`.

## Configuração, execução e testes

Requer Node.js 20 ou superior e MongoDB acessível. A configuração é unificada no `.env` da raiz do projeto (`../.env`):

```powershell
# Na pasta backend:
npm install
npm run dev
```

O arquivo mestre `.env` na raiz já contém as variáveis compartilhadas (`MONGODB_URI`, `AUTH_JWT_SECRET`, `AUTH_OTP_SECRET`, `SMTP_*`, etc.), lidas automaticamente por todos os serviços.

Comandos de verificação e build:

```powershell
npm test                  # Compila TypeScript e executa toda a suíte (unit + integration)
npm run test:unit         # Executa apenas src/tests/unit
npm run test:integration  # Executa apenas src/tests/integration
npm run build             # Gera build de produção em dist/
npm start                 # Inicia build compilado
```

## Endpoints principais

Base local: `http://127.0.0.1:3001`

| Método | Caminho | Descrição |
|---|---|---|
| `GET` | `/health` | Health check do serviço acadêmico (`agmrm-academic-api`) |
| `GET` / `POST` | `/api/student/*` | Painel, boletim, entregas, fórum, anotações e protocolos do discente |
| `GET` | `/api/files/*` | Downloads autenticados de materiais, entregas e protocolos |
| `GET` / `POST` / `PATCH` | `/api/teacher/*` | Diário de aula, materiais, tarefas, avaliação, notas e homologação |
| `GET` | `/api/admin/teachers` | Listagem somente leitura de docentes para alocação de turmas (`adminOnly`) |
| `GET` / `POST` / `PATCH` | `/api/admin/courses`, `/classes`, `/protocols`, `/announcements`, `/calendar`, `/settings`, `/audit-logs`, `/system/*` | Operações acadêmicas e institucionais administrativas (`adminOnly`) |
| `GET` / `POST` / `PATCH` | `/api/internal/academic/*` | Ponte interna autenticada via `X-Internal-Service-Secret` para o servidor Java |

Rotas públicas de `/api/auth/*`, `/api/admin/users*`, `POST /api/admin/teachers` e `/api/video-call/*` pertencem exclusivamente ao servidor Java (`:8080`) e retornam `404` nesta API.

## Seeds do Ecossistema Acadêmico

Execute para popular o banco de dados de desenvolvimento com o ecossistema acadêmico completo (bloqueado em produção):

```powershell
npm run seed
```

Você também pode executar módulos específicos através das opções:

```powershell
npm run seed:users          # Apenas contas de usuários (Admin, Docentes e Alunos)
npm run seed:courses        # Apenas cursos e matriz curricular
npm run seed:classes        # Apenas turmas e matrículas
npm run seed:teacher        # Apenas domínio do docente (aulas, materiais, tarefas)
npm run seed:student        # Apenas domínio do aluno (entregas, notas, protocolos)
npm run seed:institutional  # Apenas domínio institucional (calendário, comunicados, configurações)
```

Defina opcionalmente `SEED_DEMO_PASSWORD` localmente (entre 8 caracteres e 72 bytes UTF-8) em `.env.local` ou variável de terminal (caso não definida, o valor padrão de desenvolvimento `Agmrm@2026` será utilizado de forma segura). Se o resolvedor local apresentar `querySrv ECONNREFUSED`, configure opcionalmente `$env:SEED_DNS_SERVERS = "1.1.1.1,8.8.8.8"` antes de rodar o comando.
