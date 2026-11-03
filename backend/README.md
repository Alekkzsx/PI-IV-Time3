<!-- Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 -->

# Backend Institucional (TypeScript + Express + MongoDB)

Serviço modular em TypeScript para autenticação institucional (login, 2FA/TOTP, sessões persistentes e recuperação de senha por OTP), gestão administrativa (`admin`), portal do aluno (`student`) e autorização/emissão de tickets de salas de videochamada (`video-call`).

Roda na porta `3001` por padrão e opera em conjunto com o servidor Java SE nativo em `../server` (porta `8080`), que atende os cálculos acadêmicos, sinalização WebRTC via WebSocket e validação nativa de tokens JWT HS256. O arquivo `.env.example` lista as variáveis esperadas; o serviço também carrega `.env.local`.

## Organização

```text
backend/
├── src/
│   ├── app.ts                        # Composição da aplicação Express e middlewares globais
│   ├── server.ts                     # Bootstrap HTTP e conexão com MongoDB
│   ├── config/                       # Carregamento e validação estrita de variáveis de ambiente
│   ├── shared/                       # Erros HTTP, cliente MongoDB, rate limit e utilitários
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── application/          # Casos de uso de login, 2FA, sessões e recuperação OTP
│   │   │   ├── domain/               # Entidades, perfis institucionais e portas de repositório
│   │   │   ├── infrastructure/       # Repositórios MongoDB, bcrypt, JWT HS256, TOTP e SMTP
│   │   │   └── presentation/         # Contratos de validação e rotas HTTP (/api/auth/*)
│   │   ├── admin/
│   │   │   ├── infrastructure/       # Middleware adminOnly, auditoria e sanitização de registros
│   │   │   └── presentation/         # Controllers de usuários, acadêmico e operações (/api/admin/*)
│   │   ├── student/
│   │   │   ├── application/          # Agregação de turmas, notas, frequência e avisos do discente
│   │   │   └── presentation/         # Controller do painel do aluno (/api/student/*)
│   │   └── video-call/
│   │       ├── application/          # Autorização de salas ao vivo e tickets efêmeros SHA-256
│   │       └── presentation/         # Controller de salas e consumo de ticket (/api/video-call/*)
│   ├── scripts/
│   │   ├── create-auth-user.ts       # Provisionamento seguro de contas via CLI
│   │   ├── admin-demo.seed.ts        # Regra idempotente de seed demonstrativo ADMIN
│   │   ├── seed-admin.ts             # Entrypoint CLI do seed ADMIN
│   │   ├── student-demo.seed.ts      # Regra de seed demonstrativo do discente
│   │   └── seed-student.ts           # Entrypoint CLI do seed do discente
│   └── tests/
│       ├── unit/                     # Testes unitários isolados (env, auth service, seed)
│       └── integration/              # Testes de integração HTTP ponta a ponta
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

Para provisionar uma conta autorizada localmente, com o backend configurado em `.env`, execute `npm run create-user` na pasta `backend`.

## Configuração, execução e testes

Requer Node.js 20 ou superior e MongoDB acessível. Na pasta `backend`:

```powershell
Copy-Item .env.example .env
npm install
npm run dev
```

Preencha `.env` com URI e nome do banco, `AUTH_JWT_SECRET` aleatório de pelo menos 32 caracteres (compartilhado com `server/` caso deseje validação JWT local no servidor Java), `AUTH_OTP_SECRET` diferente com pelo menos 32 caracteres e as credenciais SMTP para recuperação por e-mail.

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
| `GET` | `/health` | Health check do serviço |
| `POST` | `/api/auth/login` | Valida identidade, senha e perfil; retorna JWT curto (ou desafio 2FA) |
| `POST` | `/api/auth/2fa/verify-login` | Conclui login com código TOTP ou código reserva |
| `GET` | `/api/auth/me` | Retorna dados e validade da sessão autenticada atual |
| `POST` | `/api/auth/logout` / `/logout-all` | Revoga a sessão atual ou todas as sessões do usuário |
| `POST` | `/api/auth/send-recovery-otp` | Solicita OTP sem revelar se a identidade existe |
| `POST` | `/api/auth/verify-recovery-otp` | Valida OTP e retorna grant temporário de redefinição |
| `POST` | `/api/auth/reset-password` | Consome o grant de uso único e redefine a senha |
| `GET` | `/api/student/dashboard` | Painel consolidado do discente autenticado |
| `GET` / `POST` | `/api/admin/users` e `/api/admin/teachers` | Gestão administrativa de identidades e docentes (`adminOnly`) |
| `GET` / `POST` | `/api/admin/courses` e `/api/admin/classes` | Gestão de cursos, turmas, matrículas, sessões e calendário (`adminOnly`) |
| `POST` | `/api/video-call/rooms/enter` | Docente atribuído abre a sala; aluno matriculado entra e recebe ticket WS |
| `POST` | `/api/video-call/rooms/close` | Docente responsável encerra a sala ao vivo |
| `POST` | `/api/video-call/rooms/consume-ticket` | Consome uma única vez o ticket de 60s durante o handshake WebSocket Java |

## Seed demonstrativo do ADMIN

Execute somente quando quiser inserir dados de demonstração em desenvolvimento (bloqueado em produção):

```powershell
npm run seed:admin
```

Defina `SEED_DEMO_PASSWORD` localmente (entre 8 caracteres e 72 bytes UTF-8) em `.env.local` ou variável de terminal. Se o resolvedor local apresentar `querySrv ECONNREFUSED`, configure opcionalmente `$env:SEED_DNS_SERVERS = "1.1.1.1,8.8.8.8"` antes de rodar o comando.
