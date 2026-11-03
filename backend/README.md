<!-- Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 -->

# Backend de autenticação

Consulte [autenticação e ADMIN](IMPLEMENTATION.md) para os contratos completos,
sessões persistentes, execução local e testes de integração. O arquivo
`.env.example` lista as variáveis esperadas; o serviço também carrega `.env.local`.

Serviço independente em TypeScript para login institucional e recuperação de
senha. Ele roda na porta `3001` por padrão e não substitui o servidor Java da
porta `8080`, que continua atendendo às funcionalidades acadêmicas e de
videochamada.

## Organização

```text
backend/
├── src/
│   ├── app.ts
│   ├── server.ts
│   ├── config/
│   ├── shared/
│   └── modules/auth/
│       ├── application/       # Casos de uso e testes unitários
│       ├── domain/            # Entidades, perfis e portas
│       ├── infrastructure/   # MongoDB, bcrypt, JWT e SMTP
│       └── presentation/      # Contratos e rotas HTTP
├── .env.example
├── package.json
└── tsconfig.json
```

As dependências de persistência e serviços externos são injetadas no caso de
uso. Assim, regras de autenticação podem ser testadas sem conexão com MongoDB,
SMTP ou servidor HTTP.

## Perfis e contas

Os únicos perfis aceitos são `aluno`, `docente` e `admin`. Contas são lidas da
coleção `auth_users` no banco MongoDB escolhido. O serviço não cria contas
fictícias nem aceita credenciais de demonstração.

Cada documento precisa conter:

```json
{
  "identity": "identificador institucional",
  "normalizedIdentity": "identificador institucional em minúsculas",
  "email": "endereço institucional",
  "displayName": "nome para mensagens de recuperação",
  "profile": "aluno",
  "passwordHash": "hash produzido por bcrypt",
  "active": true
}
```

`normalizedIdentity` deve ser único. A inicialização cria esse índice e o
índice TTL da coleção `auth_recovery`. Senhas devem ser provisionadas como
hashes bcrypt, nunca em texto claro.

Para provisionar uma conta autorizada localmente, com o backend configurado em
`.env`, execute `npm run create-user` na pasta `backend`. O comando solicita os
dados no terminal, oculta a senha digitada e grava somente o hash bcrypt em
`auth_users`. Não existe cadastro público na API.

## Configuração e execução

Requer Node.js 20 ou superior e MongoDB acessível. Na pasta `backend`:

```powershell
Copy-Item .env.example .env
npm install
npm run dev
```

Preencha `.env` com URI e nome do banco, um segredo JWT aleatório de pelo menos
32 caracteres, um segredo OTP diferente também com pelo menos 32 caracteres e
as credenciais SMTP para habilitar recuperação por e-mail.
Não versione `.env`. Sem SMTP configurado, o serviço inicia normalmente, mas
pedidos de recuperação para contas existentes retornam erro explícito.

```powershell
npm test
npm run build
npm start
```

O serviço valida a configuração antes de iniciar e falha explicitamente se
MongoDB ou variáveis obrigatórias estiverem indisponíveis. O frontend usa esta API para login e recuperação e o datasource Flutter aponta
por padrão para `http://127.0.0.1:3001`. O serviço TypeScript não é iniciado por
`flutter run`; durante desenvolvimento, inicie-o separadamente. Para outros
ambientes, informe `--dart-define=AUTH_API_BASE_URL=https://...` no build Flutter
e configure a origem do portal em `AUTH_CORS_ORIGINS`. A API não depende nem lê
credenciais SMTP do cliente.

## Endpoints

Base local: `http://127.0.0.1:3001`

| Método | Caminho | Descrição |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/api/auth/login` | Valida identidade, senha e perfil; retorna JWT curto |
| `POST` | `/api/auth/send-recovery-otp` | Solicita OTP sem revelar se a identidade existe |
| `POST` | `/api/auth/verify-recovery-otp` | Valida OTP e retorna grant temporário de redefinição |
| `POST` | `/api/auth/reset-password` | Consome o grant e troca a senha |
| `GET` | `/api/admin/teachers` | Lista docentes persistidos; exige JWT de admin |
| `POST` | `/api/admin/teachers` | Cria uma conta de docente; exige JWT de admin |
| `GET` / `POST` | `/api/admin/courses` | Lista e cadastra cursos; exige JWT de admin |
| `GET` / `POST` | `/api/admin/classes` | Lista e abre turmas; exige JWT de admin |
| `PATCH` | `/api/admin/classes/:classCode/professor` | Atribui um docente ativo à turma |
| `GET` / `POST` | `/api/admin/classes/:classCode/enrollments` | Consulta e registra matrículas de alunos ativos |
| `GET` / `POST` | `/api/admin/classes/:classCode/sessions` | Consulta e agenda aulas da turma |
| `POST` | `/api/video-call/rooms/enter` | Docente atribuído abre a sala; aluno matriculado entra |
| `POST` | `/api/video-call/rooms/close` | Docente responsável encerra a sala |

As rotas administrativas usam o token Bearer emitido pelo login e validam o
perfil no servidor. Os dados ficam nas coleções `academic_courses`,
`academic_classes`, `academic_enrollments` e `academic_class_sessions`; elas e
seus índices são criados pela inicialização do backend. No frontend, as telas de
cursos e turmas usam essas rotas e exibem estado vazio quando não há dados reais.
O cadastro administrativo cria uma identidade `DOC-...` em `auth_users` com
senha aleatória armazenada somente como hash. O docente define a própria senha
pela opção “Esqueci minha senha”. Uma chamada só pode ser aberta pelo docente
atribuído à turma; alunos precisam de matrícula ativa. As salas ativas ficam na
coleção `academic_live_sessions` e expiram após oito horas.

Na versão Web, a sinalização da chamada usa `BroadcastChannel`: os participantes
precisam usar o mesmo navegador, origem e código de turma. A autorização e o
estado de abertura da sala são validados pelo backend.

O OTP é gerado criptograficamente, armazenado como HMAC, expira conforme
`AUTH_OTP_TTL_SECONDS` e é revogado após `AUTH_OTP_MAX_ATTEMPTS`. O token de
redefinição é aleatório, tem validade curta e só pode ser consumido uma vez.
Não existe código universal de teste.

As rotas HTTP validam e limitam o tamanho dos dados recebidos, aplicam rate
limit e respostas de erro sem detalhes internos. CORS aceita apenas as origens
configuradas em `AUTH_CORS_ORIGINS`.

## Seed demonstrativo do ADMIN

Execute somente quando quiser inserir dados de demonstração. O comando não faz
parte da inicialização do servidor e fica bloqueado em produção.

Na pasta `backend`, configure `.env.local` com a conexão do Atlas,
`MONGODB_DATABASE` explícito e os segredos exigidos pela configuração existente.
O seed carrega `.env.local` e depois `.env`, sem substituir variáveis do terminal.
Esses arquivos devem continuar fora do Git.

Defina `SEED_DEMO_PASSWORD` localmente, sem compartilhá-la no chat ou versioná-la.
Ela deve ter pelo menos 8 caracteres e no máximo 72 bytes UTF-8, limite do bcrypt.
Pode ser definida no terminal ou no arquivo local ignorado.

```powershell
npm run seed:admin
```

Se o resolvedor local apresentar `querySrv ECONNREFUSED`, configure opcionalmente:

```powershell
$env:SEED_DNS_SERVERS = "1.1.1.1,8.8.8.8"
npm run seed:admin
Remove-Item Env:SEED_DNS_SERVERS
```

Essa opção altera apenas o DNS usado pelo processo do seed, sem mudar o Windows,
a URI ou o processo do servidor. Não resolve credenciais inválidas nem substitui
a configuração de acesso ao cluster no Atlas.

O seed prepara os seguintes registros:

| Coleção | Dados |
|---|---|
| `auth_users` | `admin.demo`, `prof.demo`, `aluno.demo1`, `aluno.demo2` |
| `academic_courses` | Curso `ES-DEMO` |
| `academic_classes` | Turma `ES-DEMO-4N`, vinculada ao professor e ao curso |
| `academic_enrollments` | Duas matrículas vinculadas aos alunos |
| `academic_class_sessions` | Aula em 09/11/2026, das 19h às 20h30 de Brasília |

As quatro contas usam a senha fornecida, armazenada somente como hash bcrypt.
Os e-mails são fictícios em `example.com`; não permitem testar entrega real de OTP.

Antes das inserções, são verificados conflitos de identidades, e-mails, perfis,
status, senhas e relacionamentos. Registros compatíveis são reutilizados sem
alteração; dados incompatíveis interrompem o seed. A execução não apaga registros
e não troca senhas existentes. Em falhas durante a gravação podem restar inserções
parciais; execute novamente após corrigir a causa. Rode uma execução por vez.

O resumo mostra quantos registros foram criados e reutilizados por coleção.
Ao repetir o comando, o resultado esperado é zero criados e nove reutilizados.
Os testes locais do seed fazem parte de `npm test` e não acessam o Atlas.
