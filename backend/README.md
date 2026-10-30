<!-- Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 -->

# Backend de autenticação

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

O OTP é gerado criptograficamente, armazenado como HMAC, expira conforme
`AUTH_OTP_TTL_SECONDS` e é revogado após `AUTH_OTP_MAX_ATTEMPTS`. O token de
redefinição é aleatório, tem validade curta e só pode ser consumido uma vez.
Não existe código universal de teste.

As rotas HTTP validam e limitam o tamanho dos dados recebidos, aplicam rate
limit e respostas de erro sem detalhes internos. CORS aceita apenas as origens
configuradas em `AUTH_CORS_ORIGINS`.
