# Server — Servidor HTTP e WebSocket Nativo em Java sem Dependências (AGMRM)

> **Módulo Principal do Servidor**: `.../PI-IV-Time3/server/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  
> **Padrões de Engenharia**: Biblioteca padrão Java SE pura (Java 8+), zero dependências externas, sockets TCP determinísticos e WebSockets RFC 6455, Arquitetura OO Limpa (`abstratas/` + `modules/` + `utils/`)

O módulo `server` contém o servidor HTTP e WebSocket nativo, autônomo e de alto desempenho desenvolvido para a **Plataforma Educacional Integrada AGMRM** (*PI-IV Time 3*).

Ele opera 100% sobre a **biblioteca padrão do Java SE** (compilado com `--release 8`, compatível do Java 8 ao 25) sem frameworks pesados (sem Spring, Quarkus, Maven, JUnit ou Tomcat).

**Responsabilidades Principais (Contexto Delimitado na Porta `8080`)**:
- **Gestão Autoritativa de Identidade e Acesso**: Sistema completo de login com validação estrita de compatibilidade de perfil (`aluno`, `docente`, `admin` — rejeitando divergências com HTTP `403 invalid_user_type`), verificação PBKDF2/BCrypt, tokens JWT HS256 de acesso/atualização/recuperação, 2FA + códigos de backup, recuperação com OTP de uso único, troca de senha, exportação de perfil/preferências/sessões/LGPD e gerenciamento administrativo de usuários + provisionamento de docentes
- **Videoconferência e Sinalização em Tempo Real**: Salas persistidas e tickets WebSocket de uso único (`academic_live_sessions`, `video_call_ws_tickets`, `video_call_attendance_logs`) via `/api/video-call/rooms*`, `/ws/video-call/{roomCode}` em RFC 6455, sincronização de chat e telemetria legada em `/api/videocall/*`
- **Monitoramento Fail-Closed e Ponte Interna**: Monitora proativamente a disponibilidade do `backend/` (`:3001/health`) via `MonitorBackendAcademico` (bloqueando requisições dependentes com HTTP `503 backend_unavailable` caso o núcleo acadêmico caia, mantendo `/health` acessível para diagnóstico) e consome `/api/internal/academic/*` com `X-Internal-Service-Secret` (`ClientePonteAcademica`) para autorizar vínculo acadêmico em turmas, listar salas permitidas e buscar resumos acadêmicos para LGPD/dossiê

---

## 🏛️ Arquitetura OO Modular (`abstratas/` + `modules/` + `utils/`)

Cada domínio principal (`core`, `auth`, `videocall`) segue a mesma estrutura previsível e autodocumentada:
- **`abstratas/`** — Classes base abstratas implementando *Template Method*, *Strategy/Chain of Responsibility* e tratamento polimórfico de erros HTTP.
- **`modules/`** — Módulos concretos coesos agrupados por funcionalidade (cada arquivo focado em uma única responsabilidade).
- **`utils/`** — Funções auxiliares reutilizáveis e primitivas criptográficas compartilhadas entre módulos.

```text
.../PI-IV-Time3/server/
├── bin/                                              # Bytecode Java 8 compilado (.class)
├── lib/                                              # JARs do MongoDB Java Sync Driver
├── src/
│   ├── Main.java                                     # Índice central de rotas (Saude, Auth, Admin, VideoCall)
│   ├── utils/                                        # Utilitários globais reutilizáveis
│   │   ├── BsonUtils.java                            # Conversão recursiva Document <-> Map/List
│   │   ├── ConfigEnv.java                            # Leitor mestre do .env da raiz
│   │   ├── Json.java                                 # Parser/serializador JSON completo (RFC 8259)
│   │   ├── JsonSimples.java                          # Escape de strings e auxiliar JSON plano
│   │   └── RedeUtils.java                            # Stream UTF-8, codificação URL, extração de IP, loopback
│   ├── core/                                         # Motor de sockets HTTP nativo e infraestrutura MongoDB
│   │   ├── abstratas/
│   │   │   ├── ExcecaoHttpAbstrata.java              # Base polimórfica de exceções HTTP (statusHttp + codigo)
│   │   │   ├── HandlerHttpAbstrato.java              # Template Method HTTP (CORS, OPTIONS, 405, catch)
│   │   │   └── RepositorioMongoAbstrato.java         # Template Method MongoDB (índices, failover, erros)
│   │   ├── ConexaoMongo.java                         # MongoClient, failover SRV->Direct e cache de saúde
│   │   ├── DatabaseUnavailableException.java         # Exceção 503 para MongoDB bloqueado por DNS/rede
│   │   ├── HealthHandler.java                        # GET /health e /health/ready
│   │   ├── HttpUtils.java                            # CORS e cabeçalhos defensivos de segurança
│   │   ├── ManipuladorHttp.java                      # Interface de contrato do handler HTTP
│   │   ├── MonitorBackendAcademico.java              # Monitor proativo Fail-Closed do backend acadêmico (:3001)
│   │   ├── RequisicaoHttp.java                       # Parser de requisições HTTP/1.1 em socket TCP
│   │   ├── ResilientDnsClient.java                   # Resolvedor JNDI + DNS-over-HTTPS (DoH)
│   │   ├── RespostaHttp.java                         # Escritor nativo de respostas HTTP/1.1
│   │   └── ServidorHttpNativo.java                   # ServerSocket, ThreadPool, roteamento e upgrade WS
│   ├── auth/                                         # Identidade, sessões, conta, admin e e-mail resiliente
│   │   ├── abstratas/
│   │   │   ├── HandlerAutenticadoAbstrato.java       # Guarda obrigatória de JWT + sessão no MongoDB
│   │   │   ├── HandlerAuthPublicoAbstrato.java       # Emissão compartilhada de token/sessão para fluxos públicos
│   │   │   ├── AdminHandlerAbstrato.java             # RBAC admin obrigatório + ponte + guarda de escrita
│   │   │   ├── CanalEnvioEmailAbstrato.java          # Contrato resiliente de canal de e-mail (Camadas 1/2/3)
│   │   │   ├── CanalHttpsEmailAbstrato.java          # Transporte JSON HTTPS POST compartilhado (Camada 2)
│   │   │   └── TemplateEmailAbstrato.java            # Layout HTML institucional único + escape contra XSS
│   │   ├── model/
│   │   │   └── UsuarioAutenticado.java               # Modelo de identidade autenticada
│   │   ├── utils/
│   │   │   ├── AuthHttpUtils.java                    # Mascaramento de e-mail, latência constante, DTOs de usuário/perfil
│   │   │   ├── BCrypt.java                           # Implementação padrão Blowfish/BCrypt
│   │   │   ├── JwtAuthValidator.java                 # Validação JWT HS256 + verificação de sessão no MongoDB
│   │   │   ├── JwtGerador.java                       # Gerador unificado de tokens HS256 (acesso/atualização/recuperação)
│   │   │   ├── LimitadorTentativas.java              # Limitador progressivo contra força bruta
│   │   │   ├── OtpService.java                       # OTP de 6 dígitos SecureRandom + HMAC-SHA256 + SHA-256
│   │   │   ├── RevogacaoTokens.java                  # Lista de revogação JTI em memória
│   │   │   └── SenhaHasher.java                      # Verificação PBKDF2WithHmacSHA256 (600k) + BCrypt
│   │   └── modules/
│   │       ├── login/                                # LoginHandler, TwoFactorHandler, RefreshTokenHandler, LogoutHandler, AuthSessionHandler
│   │       ├── conta/                                # ProfileAccountHandler, ProfileHandler, AccountSecurityHandler, ChangePasswordHandler, RecoveryHandler
│   │       ├── admin/                                # AdminUsersHandler, AdminUserCrudHandler, AdminUserSecurityHandler, AdminUserDossierHandler, AdminTeacherHandler, EmailDiagnosticHandler
│   │       ├── persistencia/                         # RepositorioUsuarios (Facade), RepositorioContas, RepositorioSessoes, RepositorioOtps, RepositorioAuditoria
│   │       └── email/                                # SmtpCliente (Facade), MensagemEmail, CircuitBreakerSmtp, CanalSmtpNativo, CanalResendEmail, CanalBrevoEmail, CanalWebhookEmail, CanalOutboxLocal, TemplateEmail*
│   ├── videocall/                                    # REST de videoconferência, persistência e hub WebRTC
│   │   ├── abstratas/
│   │   │   └── HandlerVideoCallLegadoAbstrato.java   # Handler base com JWT opcional + VideoCallService
│   │   ├── utils/
│   │   │   └── VideoCallUtils.java                   # Sanitizador de código de sala, resolução de participante e cálculo de presença
│   │   └── modules/
│   │       ├── rooms/                                # VideoCallMongoHandler, RepositorioVideoCall, TicketWebSocketValidator
│   │       ├── legado/                               # VideoCallService, VideoCallRoomHandler, VideoCallSignalingHandler, VideoCallInteractionHandler, VideoCallAttendanceHandler
│   │       └── hub/                                  # SalaVideoHub, RegistradorChat, RegistradorEnvelope
│   ├── bridge/                                       # Cliente HTTP interno autenticado (:3001)
│   │   └── ClientePonteAcademica.java
│   └── websocket/                                    # Motor WebSocket RFC 6455 puro
│       ├── AtendenteWebSocket.java
│       ├── ConexaoWebSocket.java
│       ├── HandshakeWebSocket.java
│       ├── OuvinteWebSocket.java
│       └── QuadroWebSocket.java
└── tests/                                            # Suítes de testes Java sem dependências (17 suítes)
    ├── SuiteTestesServidor.java
    ├── auth/                                         # 9 suítes de auth/rede/e-mail
    ├── core/                                         # HttpUtilsCorsTeste + ArquiteturaAbstrataTeste
    ├── utils/                                        # ConfigEnvTeste + JsonTeste
    ├── videocall/hub/                                # HubTeste + RegistradorChatTeste
    └── websocket/                                    # HandshakeTeste + QuadroTeste
```

---

## 🧩 10 Classes Abstratas (Pilares de OO)

| Classe Abstrata | Pacote | Padrão | Responsabilidade |
|---|---|---|---|
| `ExcecaoHttpAbstrata` | `core.abstratas` | Polimorfismo | Unifica status HTTP + código de erro entre `DatabaseUnavailableException`, `HttpSecurityException` e `ExcecaoPonteAcademica` |
| `HandlerHttpAbstrato` | `core.abstratas` | Template Method | Padroniza CORS, cabeçalhos de segurança, `OPTIONS 204`, validação `405`, auxiliares JSON e tratamento polimórfico de erros |
| `RepositorioMongoAbstrato` | `core.abstratas` | Template Method | Centraliza acesso ao banco MongoDB, criação segura e assíncrona de índices (tratamento de conflitos `85`/`86`) e tradução de erros |
| `HandlerAutenticadoAbstrato` | `auth.abstratas` | Template Method | Impõe validação de Bearer JWT + sessão ativa no MongoDB antes de invocar subclasses |
| `HandlerAuthPublicoAbstrato` | `auth.abstratas` | Template Method | Centraliza emissão de par de tokens, persistência de sessão e montagem padrão do payload de autenticação |
| `AdminHandlerAbstrato` | `auth.abstratas` | Template Method | Impõe perfil `admin`, injeta `ClientePonteAcademica`, valida guarda de escrita e IDs de usuário |
| `CanalEnvioEmailAbstrato` | `auth.abstratas` | Strategy / Chain | Contrato comum de entrega para Camada 1 (SMTP), Camada 2 (HTTPS) e Camada 3 (Outbox) |
| `CanalHttpsEmailAbstrato` | `auth.abstratas` | Template Method | Transporte JSON HTTPS POST compartilhado com tratamento opcional de redirecionamento 302 para Resend, Brevo e Webhook |
| `TemplateEmailAbstrato` | `auth.abstratas` | Template Method | Layout HTML institucional único com escape embutido contra XSS compartilhado entre os 4 templates de e-mail |
| `HandlerVideoCallLegadoAbstrato` | `videocall.abstratas` | Template Method | Autenticação JWT opcional e auxiliares do `VideoCallService` para rotas legadas `/api/videocall/*` |

---

## 🚀 Compilação e Execução

### Execução Manual (Linux / macOS)
```bash
cd server
find src -name "*.java" > /tmp/server_src.txt
javac --release 8 -encoding UTF-8 -cp "lib/*" -d bin @/tmp/server_src.txt
java -Dfile.encoding=UTF-8 -cp "bin:lib/*" Main
```

### Suíte Automatizada de Testes Nativos (17 Suítes)
```bash
cd server
mkdir -p /tmp/server_test_bin
find src tests -name "*.java" > /tmp/server_all.txt
javac --release 8 -encoding UTF-8 -cp "lib/*" -d /tmp/server_test_bin @/tmp/server_all.txt
java -Dfile.encoding=UTF-8 -cp "/tmp/server_test_bin:lib/*" SuiteTestesServidor
```

**Suítes de Teste (17/17)**:
1. `ConfigEnvTeste` — Carregamento e validação do `.env` mestre
2. `JsonTeste` — Parsing/serialização completa de JSON e JsonSimples
3. `HandshakeTeste` — `Sec-WebSocket-Accept` conforme RFC 6455
4. `QuadroTeste` — Enquadramento e mascaramento conforme RFC 6455
5. `RegistradorChatTeste` — Registro e sincronização de chat via WebSocket
6. `HubTeste` — Roteamento do hub WebSocket ao vivo e isolamento de salas
7. `JwtAuthValidatorTeste` — Validação JWT HS256, revogação, guarda de troca de senha e RBAC
8. `SenhaHasherTeste` — Verificação PBKDF2WithHmacSHA256 e BCrypt + regras de complexidade
9. `RevogacaoTokensTeste` — Lista de revogação JTI em memória e limpeza por expiração
10. `LimitadorTentativasTeste` — Bloqueio progressivo contra força bruta
11. `OtpServiceTeste` — Geração de OTP de 6 dígitos, armazenamento HMAC e validação
12. `RecoveryHandlerTeste` — Concessão de redefinição de recuperação de uso único e proteção contra replay
13. `HandlerLifecycleTeste` — Preservação de pool de banco de dados compartilhado entre handlers
14. `HttpUtilsCorsTeste` — Resolução dinâmica de origem e Private Network Access
15. `ResilientNetworkTeste` — Parsing de DNS-over-HTTPS (DoH) e diagnósticos de rede HTTP 503
16. `SmtpClienteTeste` — CRLF/dot-stuffing conforme RFC 5321, AUTH LOGIN/PLAIN, validação de Webhook e Circuit Breaker
17. `ArquiteturaAbstrataTeste` — Classes abstratas (*Template Method*, exceções HTTP, canais/templates de e-mail) e utilitários compartilhados

---

## 📡 Catálogo de Endpoints de API Registrados

URL Base: `http://localhost:8080`

| Grupo | Método | Endpoint | Handler |
|---|---|---|---|
| **Saúde** | `GET` | `/health`, `/health/ready` | `HealthHandler` |
| **Login** | `POST` | `/api/auth/login`, `/logout`, `/refresh`, `/verify-two-factor` | `auth.modules.login.*` |
| **Sessão** | `GET` / `POST` | `/api/auth/session`, `/api/auth/me` | `AuthSessionHandler` |
| **Conta** | `PATCH` / `GET` / `POST` / `DELETE` | `/api/auth/profile`, `/lgpd-export`, `/sessions*`, `/logout-others`, `/two-factor`, `/backup-codes`, `/security-logs` | `ProfileAccountHandler` (`ProfileHandler` + `AccountSecurityHandler`) |
| **Senha** | `POST` | `/api/auth/send-recovery-otp`, `/verify-recovery-otp`, `/reset-password`, `/change-password` | `RecoveryHandler`, `ChangePasswordHandler` |
| **Admin** | `GET` / `POST` / `PATCH` | `/api/admin/users*`, `/api/admin/teachers`, `/api/auth/email-diagnostic` | `AdminUsersHandler` (4 sub-handlers), `EmailDiagnosticHandler` |
| **VideoCall (Mongo)** | `GET` / `POST` | `/api/video-call/rooms`, `/enter`, `/close`, `/attendance` | `VideoCallMongoHandler` |
| **VideoCall (Legado)** | `GET` / `POST` | `/api/videocall/rooms`, `/open`, `/close`, `/join`, `/leave`, `/signal`, `/hand-raise`, `/chat`, `/attendance` | `videocall.modules.legado.*` |
| **WebSocket** | `WS` | `/ws/video-call/{roomCode}?ticket=...` | `ServidorHttpNativo` + `SalaVideoHub` |
