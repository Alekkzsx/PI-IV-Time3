# Plataforma Educacional Integrada (AGMRM) — PI-IV (Time 3)

[![CI/CD Restrict Main](https://img.shields.io/badge/CI%2FCD-Restrict--Main-blue.svg)](.github/workflows/restrict-main.yml)
[![Arquitetura Monorepo](https://img.shields.io/badge/Arquitetura-5%20M%C3%B3dulos%20M%C3%A3e-success.svg)](#2-arquitetura-do-monorepo-5-módulos-mãe)
[![Licença MIT](https://img.shields.io/badge/Licen%C3%A7a-MIT-green.svg)](LICENSE)
[![Segurança Institucional](https://img.shields.io/badge/Seguran%C3%A7a-Pol%C3%ADticas%20Ativas-orange.svg)](SECURITY.md)

---

## 1. Sobre o Projeto

A **Plataforma Educacional Integrada AGMRM** é um ambiente acadêmico unificado e moderno desenvolvido no contexto do Projeto Integrador IV (Time 3). O sistema resolve a fragmentação de ferramentas educacionais ao consolidar controle de presenças, cálculo de médias acadêmicas com ponderação flexível, submissão de tarefas com descontos por atraso, autenticação segura com expiração estrita de tokens e suporte multiplataforma.

### 1.1 Equipe de Desenvolvimento (Equipe AGMRM)

| Integrante | GitHub / Identificador | Área de Atuação Principal |
|---|---|---|
| **Alex Gabriel** | [@Alekkzsx](https://github.com/Alekkzsx) | Arquitetura Geral, Frontend Flutter & Governança Monorepo |
| **Guilherme Moreira** | [@GuilhermeMoreira07](https://github.com/GuilhermeMoreira07) | Backend Java Nativo, Infraestrutura Server & Regras de Negócio |
| **Marcelo Zarpelon** | — | Análise de Requisitos e Modelagem Acadêmica |
| **Murilo Caravita** | — | Qualidade, Testes de Integração e Validação |
| **Rafael Henrique Inácio** | — | Segurança da Informação, Políticas e Conformidade |

---

## 2. Arquitetura do Monorepo: Os 5 Módulos-Mãe

O projeto adota uma arquitetura em **Monorepo** estritamente segregada em **5 módulos-mãe**, garantindo limites limpos (*clean boundaries*), separação de responsabilidades e independência operacional entre as camadas:

```
c:\Users\24802449\Documents\Github\PI-IV-Time3/
├── .github/                        # Governança, CI/CD e Políticas de Código
│   ├── CODEOWNERS                  # Responsáveis e revisores obrigatórios (* @Alekkzsx @GuilhermeMoreira07)
│   ├── README.md                   # Documentação de governança, Gitflow e PRs
│   ├── SECURITY.md                 # Segurança de pipelines GitHub Actions e segredos
│   └── workflows/
│       └── restrict-main.yml       # Bloqueio de PRs diretos para main (origem restrita a develop)
│
├── frontend/                       # Aplicação Multiplataforma Flutter (Clean Architecture)
│   ├── .gitignore                  # Regras de exclusão locais do ecossistema Flutter
│   ├── .metadata                   # Metadados de configuração de plataformas Flutter
│   ├── ARCHITECTURE.md             # Especificação da Clean Architecture no Frontend
│   ├── README.md                   # Guia de execução, dependências e testes do Frontend
│   ├── SECURITY.md                 # Diretrizes de segurança na camada de apresentação e TTL
│   ├── analysis_options.yaml       # Regras estáticas de linter Dart/Flutter
│   ├── android/                    # Runner nativo Android (Gradle/Kotlin)
│   ├── ios/                        # Runner nativo iOS (Xcode/Swift)
│   ├── lib/                        # Código-fonte Clean Architecture (Presentation, Domain, Data)
│   ├── linux/                      # Runner nativo Linux (CMake/C++)
│   ├── macos/                      # Runner nativo macOS (Xcode/Swift)
│   ├── pi_iv_time3.iml             # Configuração do projeto IntelliJ / Android Studio
│   ├── pubspec.yaml                # Manifesto de dependências e assets do Flutter
│   ├── pubspec.lock                # Travamento estrito de versões das dependências Dart
│   ├── test/                       # Testes de unidade e testes de widgets
│   ├── web/                        # Assets de build Web (index.html, manifest.json, favicons)
│   └── windows/                    # Runner nativo Windows Desktop (CMake/C++)
│
├── backend/                        # Serviços de Domínio e Lógica de Negócio (Java SE)
│   ├── README.md                   # Contratos formais da API, equações e tabelas de status
│   ├── SECURITY.md                 # Validação de limites numéricos, RBAC e prevenção a DoS
│   └── src/
│       ├── ServidorHttpNativo.java # Implementação das regras de negócio e handlers HTTP
│       └── testeServidor.txt       # Casos de teste de referência para requisições cURL
│
├── server/                         # Infraestrutura e Runtime Operacional do Servidor
│   ├── README.md                   # Operação de sockets, ciclo de vida e proxy reverso
│   ├── SECURITY.md                 # Hardening de rede, timeouts e mitigação de Slowloris
│   ├── run-server.bat              # Script de compilação e inicialização para Windows
│   ├── run-server.sh               # Script de compilação e inicialização para Linux / macOS
│   ├── server.properties           # Arquivo de propriedades de rede (porta 8080, threads, limits)
│   ├── test-server.bat             # Suite automatizada de testes cURL para Windows
│   └── test-server.sh              # Suite automatizada de testes cURL para Linux / macOS
│
├── security/                       # Governança de Cibersegurança Institucional
│   ├── .env.example                # Template canônico de variáveis de ambiente do monorepo
│   ├── README.md                   # Sumário do domínio de segurança e checklists de conformidade
│   ├── SECURITY.md                 # SLA institucional, reporte ético e contatos de segurança
│   ├── cors/
│   │   ├── CORS_GUIDELINES.md      # Guia de configuração segura de origens e preflight
│   │   └── cors_config.json        # Matriz formal de origens permitidas (Dev, Staging, Prod)
│   ├── headers/
│   │   └── security_headers_guidelines.md # Cabeçalhos HTTP (CSP, HSTS, X-Frame-Options, no-store)
│   ├── policies/
│   │   ├── access_control_policy.md       # Política de controle de acesso e matriz RBAC
│   │   ├── data_protection_policy.md      # Política de privacidade e conformidade com LGPD
│   │   └── password_and_token_policy.md   # Política de senhas e expiração de token (TTL 5 min)
│   └── threat_modeling/
│       └── threat_model.md         # Modelagem formal de ameaças STRIDE e análise de risco DREAD
│
├── .gitignore                      # Regras canônicas de exclusão de artefatos temporários e segredos
├── LICENSE                         # Licença MIT do software
└── README.md                       # Documentação central do monorepo (este arquivo)
```

---

## 3. Perfis de Acesso de Usuários (RBAC)

O ecossistema é modelado com base no princípio do menor privilégio, distribuindo permissões de acordo com o papel institucional do usuário:

```
                  ┌──────────────────────────────────────────────┐
                  │          PERFIS DE ACESSO (RBAC)             │
                  └──────────────────────┬───────────────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
  ┌──────────────┐               ┌──────────────┐                ┌──────────────┐
  │    ALUNO     │               │  PROFESSOR   │                │    ADMIN     │
  └──────┬───────┘               └──────┬───────┘                └──────┬───────┘
         │                              │                               │
         ├─ Consultar boletim           ├─ Lançar notas e pesos         ├─ Gerenciar usuários
         ├─ Verificar presenças         ├─ Ajustar presença manual      ├─ Configurar servidor
         ├─ Submeter tarefas            ├─ Consultar métricas           ├─ Auditar segurança
         └─ Recuperar senha (5 min)     └─ Gerenciar prazos de entrega  └─ Governar repositório
```

### 3.1 Aluno
- **Visão Acadêmica:** Consulta em tempo real do boletim consolidado via `/api/notas/boletim` com detalhamento das avaliações P1, P2 e Trabalho.
- **Controle de Frequência:** Verificação do status de presença via `/api/presenca` (integral, parcial ou ausência).
- **Entregas Acadêmicas:** Submissão de trabalhos com cálculo automático de notas considerando tolerâncias e descontos por atraso via `/api/tarefas/calcular-nota`.
- **Autenticação Segura:** Fluxo de recuperação de senha com validade estrita do token limitada a **5 minutos**, conforme alerta exibido na interface e ratificado na política institucional.

### 3.2 Professor
- **Lançamento de Avaliações:** Definição das notas e configuração de pesos personalizados (`peso1`, `peso2`, `pesoTrabalho`) por disciplina no fechamento do período letivo.
- **Gestão de Presença:** Condução de aulas e autorização de **ajuste manual justificado** (`statusManual`), possuindo precedência absoluta sobre o cálculo automatizado de minutos assistidos.
- **Regras de Entrega:** Configuração de notas-base e aplicação de regras de tolerância a prazos de entrega de tarefas.

### 3.3 Instituição / Administrador
- **Governança Global:** Manutenção de cadastros institucionais de alunos e docentes.
- **Infraestrutura e Runtime:** Parametrização da porta de rede (8080), limites de requisição e threads operacionais em `server/server.properties` e variáveis de ambiente em `security/.env.example`.
- **Cibersegurança e Conformidade:** Aplicação de políticas de privacidade em conformidade com a LGPD (Lei 13.709/2018), auditoria de logs conforme o Marco Civil da Internet (Lei 12.965/2014) e garantia de cabeçalhos de proteção (HSTS, CSP, X-Frame-Options).
- **Governança de Código:** Homologação e aprovação de Pull Requests via política `restrict-main.yml` e `CODEOWNERS`.

---

## 4. Matriz Completa de Interação Inter-Módulos

A tabela abaixo descreve as fronteiras de comunicação técnica, protocolos, portas, formatos de payload e responsabilidades entre os módulos do repositório:

| Módulo de Origem | Módulo de Destino | Protocolo / Canal | Porta / Canal | Formato do Payload | Responsabilidades & Regras Técnicas |
|---|---|---|---|---|---|
| **`frontend`** | **`server`** | HTTP / HTTPS (REST) | TCP `8080` | `application/x-www-form-urlencoded` | O Frontend consome os 4 endpoints do backend através do socket TCP aberto pelo módulo `server`: <br>• `POST /api/teste-tipos`<br>• `POST /api/presenca`<br>• `POST /api/tarefas/calcular-nota`<br>• `POST /api/notas/boletim`<br>Em caso de parâmetros inválidos ou métodos não suportados, recebe respostas HTTP 400 ou 405. |
| **`server`** | **`backend`** | Invocação em Processo JVM | Memória (JVM Interno) | Objetos Java (`HttpExchange`, `URI`) | O módulo `server` orquestra a compilação do código `backend/src/ServidorHttpNativo.java` para o diretório `server/bin/` e inicia a execução da classe `ServidorHttpNativo`. Os handlers HTTP do backend são instanciados e vinculados ao `HttpServer` da biblioteca padrão Java. |
| **`security`** | **`frontend`** | Políticas & Diretrizes | Design-time / Runtime | Configuração Dart / HTTP Headers | Define as regras aplicadas pelo cliente Flutter: <br>• TTL de 5 minutos para tokens de recuperação de senha.<br>• Validação local estrita de email e identidade (`input_validators.dart`).<br>• Conformidade com políticas de Content Security Policy (CSP) para carregamento de fontes do Google Fonts (`fonts.googleapis.com`) e execução WebAssembly/CanvasKit. |
| **`security`** | **`server`** | Políticas & Configurações | Arquivo / Variáveis de Ambiente | `.env`, `cors_config.json`, `properties` | Estabelece os limites de operação da infraestrutura: <br>• Restrição da origem CORS (`cors.allow_origin`).<br>• Limite máximo de corpo de requisição em 64 KB para mitigar exaustão de heap (DoS).<br>• Timeout de requisição de 30 segundos para prevenção de ataques Slowloris.<br>• Definição da porta padrão 8080 em `server.properties` e no `.env.example`. |
| **`security`** | **`backend`** | Diretrizes de Validação | Código & Contratos de API | Validação de Entrada & Exceções | Guia o tratamento de regras defensivas: <br>• Validação de limites numéricos (notas entre 0.0 e 10.0, dias de atraso não negativos).<br>• Ocultação de stack traces internas nas mensagens de erro retornadas ao cliente.<br>• Tratamento de divisão por zero na validação de soma de pesos. |
| **`backend`** | **`server`** | Código-fonte | Arquivo Java UTF-8 | Bytecode `.class` compilado | O arquivo `backend/src/ServidorHttpNativo.java` é a fonte canônica do serviço, preservado 100% intacto, lido pelos scripts `server/run-server.bat` e `server/run-server.sh`. |
| **`.github`** | **Todos os Módulos** | CI/CD & Governança | GitHub Actions / Git Hooks | YAML (`workflows`), Texto (`CODEOWNERS`) | Assegura que nenhuma alteração em qualquer módulo seja integrada à branch `main` sem passar pela branch `develop` (`restrict-main.yml`) e sem aprovação formal dos mantenedores designados (`CODEOWNERS`). |

---

## 5. Endpoints e Contratos de API do Backend

O servidor HTTP nativo disponibiliza 4 endpoints operacionais na porta **8080**:

### 5.1 `POST /api/teste-tipos`
Demonstra a recepção e conversão de múltiplos tipos primitivos a partir de formulário:
- **Parâmetros:** `texto` (String), `inteiro` (int), `flutuante` (float), `duplo` (double), `caractere` (char).
- **Resposta Sucesso (HTTP 200):** `OK - Tipos Processados: [<texto>, <inteiro>, <flutuante>, <duplo>, <caractere>]`.

### 5.2 `POST /api/presenca`
Calcula o percentual de frequência e define a situação acadêmica do aluno:
- **Parâmetros:** `minutosAssistidos` (long/int), `duracaoTotal` (long/int), `statusManual` (opcional: String).
- **Regra de Negócio:**
  - Se `statusManual` estiver presente e preenchido: Prevalece como `JUSTIFICADO (Ajuste Manual do Professor)`.
  - Se `(minutos / total) >= 0.75`: `PRESENCA_INTEGRAL` com percentual calculado.
  - Se `(minutos / total) >= 0.50`: `MEIA_PRESENCA` com percentual calculado.
  - Caso contrário: `AUSENCIA` com percentual calculado.
- **Resposta Sucesso (HTTP 200):** `Resultado Presenca: <STATUS> (<PERCENTUAL>%)`.

### 5.3 `POST /api/tarefas/calcular-nota`
Aplica deduções graduais na nota máxima permitida em função de dias de atraso na entrega:
- **Parâmetros:** `diasAtraso` (int), `notaBase` (double, opcional, padrão: 10.0).
- **Regra de Negócio:** Dedução de 20% da nota-base por dia corrido de atraso (`notaFinal = notaBase - (diasAtraso * (notaBase * 0.20))`), com piso em 0.0.
- **Resposta Sucesso (HTTP 200):** `Nota Maxima Permitida: <NOTA_FINAL>`.

### 5.4 `POST /api/notas/boletim`
Calcula a média ponderada final e define a situação acadêmica para o fechamento do período:
- **Parâmetros:** `p1` (double), `peso1` (double, opcional: 0.4), `p2` (double), `peso2` (double, opcional: 0.4), `trabalho` (double), `pesoTrabalho` (double, opcional: 0.2).
- **Regra de Negócio:** Média ponderada calculada por:
  $$\text{Média} = \frac{P_1 \cdot W_1 + P_2 \cdot W_2 + T \cdot W_T}{W_1 + W_2 + W_T}$$
  - $\text{Média} \ge 7.0$: `APROVADO`.
  - $5.0 \le \text{Média} < 7.0$: `EM_RECUPERACAO`.
  - $\text{Média} < 5.0$: `REPROVADO`.
- **Resposta Sucesso (HTTP 200):** `Media Final: <MEDIA> | Status: <STATUS>`.

---

## 6. Guia Rápido de Execução

### 6.1 Executando o Servidor de Backend

O servidor requer apenas o **Java Development Kit (JDK 17 ou superior)** instalado, sem frameworks externos ou dependências Maven/Gradle:

- **No Windows:**
  ```cmd
  server\run-server.bat
  ```
- **No Linux / macOS:**
  ```bash
  chmod +x server/run-server.sh
  ./server/run-server.sh
  ```

O terminal exibirá:
```text
==================================================
   SERVIDOR HTTP NATIVO INICIADO COM SUCESSO!     
   Escutando na porta: 8080
==================================================
```

### 6.2 Executando os Testes Automatizados da API

Com o servidor em execução, abra um novo terminal e execute a suíte de testes cURL:

- **No Windows:**
  ```cmd
  server\test-server.bat
  ```
- **No Linux / macOS:**
  ```bash
  chmod +x server/test-server.sh
  ./server/test-server.sh
  ```

Todos os 6 testes (incluindo preflight CORS `OPTIONS`) serão validados automaticamente.

### 6.3 Executando o Frontend Flutter

Navegue até o diretório `frontend/`:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Para rodar a suíte de testes unitários e de widgets:
```bash
flutter test
```

---

## 7. Navegação e Documentações dos Módulos

Para aprofundar-se em cada componente do ecossistema, consulte as documentações especializadas em cada módulo-mãe:

| Módulo | Documentação Geral | Política de Segurança |
|---|---|---|
| **Raiz do Projeto** | [README.md](README.md) | [SECURITY.md](SECURITY.md) |
| **.github** | [.github/README.md](.github/README.md) | [.github/SECURITY.md](.github/SECURITY.md) |
| **frontend** | [frontend/README.md](frontend/README.md) | [frontend/SECURITY.md](frontend/SECURITY.md) |
| **backend** | [backend/README.md](backend/README.md) | [backend/SECURITY.md](backend/SECURITY.md) |
| **server** | [server/README.md](server/README.md) | [server/SECURITY.md](server/SECURITY.md) |
| **security** | [security/README.md](security/README.md) | [security/SECURITY.md](security/SECURITY.md) |

---

## 8. Licença

Este projeto é distribuído sob os termos da licença **MIT**. Para maiores detalhes, consulte o arquivo [LICENSE](LICENSE).