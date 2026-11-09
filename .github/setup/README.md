# AGMRM — Setup Automatizado & Orquestrador de Inicialização Multiplataforma

> **Módulo de Infraestrutura & Automação**: `.github/setup/`  
> **Plataforma Educacional Integrada (AGMRM)** — *PI-IV Time 3 (PUC-Campinas 2026)*  
> Suporte Nativo Homologado: **Windows 11 / Windows 10**, **Linux (Ubuntu, Debian, Fedora, Arch, WSL2)** e **macOS (Apple Silicon M1–M4 & Intel x86_64)**

Este diretório foi projetado com máxima robustez para que qualquer desenvolvedor clone o repositório e inicie imediatamente todo o ecossistema com um único comando, garantindo verificação completa de dependências, auto-instalação/reparo, compilação de código, população de banco de dados e orquestração de 3 terminais dedicados.

---

## 📁 Estrutura de Arquivos

Para conveniência dos desenvolvedores, a pasta raiz de setup contém exclusivamente os disparadores de execução. Todos os scripts de processamento e console residem no subdiretório `modules/`:

```text
.github/setup/
├── setup.bat                        # DISPARADOR WINDOWS: 1-clique ou terminal (Windows 11 / 10)
├── setup.sh                         # DISPARADOR POSIX: 1-clique ou terminal (Linux / WSL2 / macOS)
├── README.md                        # Documentação completa de uso e arquitetura
└── modules/                         # Módulos executores de setup e consoles
    ├── setup.ps1                    # Motor de verificação e orquestrador Windows (PowerShell)
    ├── setup.sh                     # Motor de verificação e orquestrador Linux/macOS (Bash)
    ├── java-server-console.bat      # Launcher do console Java interativo (Windows CMD)
    ├── java-server-console.ps1      # Painel de controle interativo do Servidor Java SE (PowerShell)
    └── java-server-console.sh       # Painel de controle interativo do Servidor Java SE (Bash)
```

---

## 🚀 Como Executar

### 🪟 No Windows 11 / Windows 10

#### Modo 1: Duplo Clique (Recomendado)
Dê um duplo clique no arquivo **`setup.bat`** pelo Windows Explorer.

#### Modo 2: Via Terminal (CMD ou PowerShell)
```cmd
# A partir da raiz do projeto:
.\.github\setup\setup.bat

# Com população imediata das seeds do banco:
.\.github\setup\setup.bat -Seed

# Ou diretamente com PowerShell:
powershell -ExecutionPolicy Bypass -File .\.github\setup\modules\setup.ps1 -Seed
```

---

### 🐧 No Linux (Ubuntu / Debian / Fedora / Arch / WSL2)

#### Modo 1: Terminal
```bash
# A partir da raiz do projeto:
chmod +x .github/setup/setup.sh
./.github/setup/setup.sh

# Com população imediata das seeds do banco:
./.github/setup/setup.sh --seed
```

---

### 🍏 No macOS (Apple Silicon M1–M4 & Intel x86_64)

Compatível nativamente com o Bash 3.2 padrão do macOS e Zsh, sem necessidade de instalar bash atualizado. Suporta gerenciador de pacotes Homebrew (`brew`) e detecção automática de JDK via `/usr/libexec/java_home`.

#### Modo 1: Terminal
```bash
# A partir da raiz do projeto:
chmod +x .github/setup/setup.sh
./.github/setup/setup.sh

# Com população imediata das seeds do banco:
./.github/setup/setup.sh --seed
```

---

## ⚙️ O que o Setup Executa Automaticamente

### 1. Diagnóstico e Auto-Reparo de Dependências
Verifica se cada uma das seguintes ferramentas está instalada e configurada:
- **Git**: Detecta instalação e versão.
- **Node.js**: Verifica se a versão instalada é $\ge$ 20.x LTS.
- **npm**: Verifica integridade do gerenciador de pacotes Node.
- **Java JDK (`javac` e `java`)**: Suporta JDK 8, 17 e 21. Detecta automaticamente compilações locais em IDEs (Antigravity IDE, VS Code, Adoptium Eclipse Temurin, Corretto, Zulu, etc.). No macOS, consulta `/usr/libexec/java_home` e Homebrew (`openjdk@17`). No Linux, detecta instalações em `/usr/lib/jvm/` e distribuições padrão.
- **Flutter SDK**: Localiza o binário do Flutter mesmo que não esteja configurado no PATH global do sistema (buscando em `~/development/flutter`, `~/flutter`, `C:\src\flutter`, `C:\flutter`, etc.).
- **Arquivo Mestre `.env`**: Garante a presença do arquivo `.env` na raiz do projeto. Caso ausente, copia automaticamente o template `.env-example` e ajusta permissões (`chmod 600` em Unix).

> [!TIP]
> Caso alguma dependência esteja ausente, o script oferece auto-instalação assistida via `winget` (no Windows), `brew` (no macOS) ou gerenciador nativo da distribuição (`apt`, `dnf`, `pacman`, etc. no Linux).

---

### 2. Sincronização, Compilação e Seeds dos Módulos
- **Backend API TypeScript (`backend/`)**: Executa `npm install` para restaurar e auditar todas as dependências do servidor Express e drivers do MongoDB.
- **População de Banco de Dados (`npm run seed`)**: Oferece a execução das 6 seeds modulares (usuários, cursos, turmas, docentes, discentes e institucional — 30+ registros por entidade) para deixar o sistema 100% navegável no primeiro login.
- **Módulo de Ciberdefesa (`security/`)**: Executa `flutter pub get` no pacote `agmrm_security`.
- **Frontend App Multiplataforma (`frontend/`)**: Executa `flutter pub get` no aplicativo Flutter.
- **Servidor Java Nativo (`server/`)**: Compila todos os 41 fontes Java nativos de `server/src/` para bytecode em `server/bin/` com codificação UTF-8 e inclusão automática de dependências MongoDB em `server/lib/`.

---

### 3. Orquestração Multi-Terminal (3 Janelas ou Abas Separadas)

Ao concluir a verificação e compilação, o orquestrador libera preventivamente as portas 8080 e 3001 e abre **3 terminais independentes**:

```text
┌────────────────────────────────┐  ┌────────────────────────────────┐  ┌────────────────────────────────┐
│   JANELA 1: SERVIDOR JAVA SE   │  │    JANELA 2: BACKEND API       │  │      JANELA 3: FRONTEND        │
│          (Porta 8080)          │  │          (Porta 3001)          │  │       (Desktop ou Web)         │
│   Console com Menu Interativo  │  │   Express + MongoDB Atlas      │  │        Flutter App Run         │
│  [1] Reiniciar   [2] Parar...  │  │   Logs de Requisições / Auth   │  │   Hot Reload [r] / Restart [R] │
└────────────────────────────────┘  └────────────────────────────────┘  └────────────────────────────────┘
```

- **No Windows**: Utiliza **Windows Terminal (`wt.exe`)** criando abas unificadas caso disponível, ou 3 instâncias de console dedicadas.
- **No macOS**: Utiliza **AppleScript (`osascript`)** para abrir sessões dedicadas no `Terminal.app`.
- **No Linux**: Suporta 8 emuladores gráficos (`gnome-terminal`, `ptyxis`, `konsole`, `xfce4-terminal`, `tilix`, `alacritty`, `kitty`, `xterm`).
- **Modo Headless / SSH**: Cria automaticamente uma sessão **`tmux`** nomeada `agmrm` com 3 janelas, ou roda em background via `nohup` redirecionando logs para `server.log`, `backend.log` e `frontend.log`.

---

### 4. Painel de Controle do Servidor Java SE (Porta 8080)

O console da Janela 1 disponibiliza um menu de comandos em tempo real:
- **`[1]` Iniciar / Reiniciar Servidor Java**: Recompila os fontes e sobe o processo na porta 8080.
- **`[2]` Desligar / Parar Servidor Java**: Encerra o processo de forma limpa e libera a porta 8080.
- **`[3]` Status e Diagnóstico em Tempo Real**: Executa requisições de teste em múltiplos endpoints medindo a latência em ms.
- **`[4]` Visualizar Logs do Servidor**: Exibe as últimas 30 linhas de saída de `server.log` e erros recentes em `server-error.log`.
- **`[5]` Recompilar Fontes Java**: Recompila `server/src/` para `server/bin/` sem interromper o processo em execução.
- **`[6]` Executar Suíte de Testes Nativos**: Executa as 11 suítes de testes automatizados do servidor sem necessidade de JUnit (`SuiteTestesServidor`).
- **`[7]` Exibir Variáveis Carregadas do `.env` Mestre**: Mostra todas as variáveis carregadas da raiz (mascarando segredos por segurança).
- **`[8]` Abrir Endpoint no Navegador**: Abre o healthcheck no navegador padrão (`open` no macOS, `xdg-open` no Linux, `Start-Process` no Windows).
- **`[9]` Limpar Tela do Console**: Limpa a tela mantendo o status no topo.
- **`[0]` Encerrar Servidor e Fechar Console**: Finaliza o servidor Java e fecha o painel.

---

## 🛠️ Parâmetros Avançados

### No Windows (`setup.bat` ou `modules\setup.ps1`):
| Parâmetro | Descrição | Exemplo |
| :--- | :--- | :--- |
| `-Seed` | Executa automaticamente as seeds modulares do banco MongoDB sem prompt. | `setup.bat -Seed` |
| `-SkipInstall` | Pula a etapa de instalação de dependências e vai direto para a execução. | `setup.bat -SkipInstall` |
| `-NoLaunch` | Apenas valida dependências e compila os módulos, sem abrir as janelas. | `setup.bat -NoLaunch` |
| `-FlutterDevice <nome>` | Força o dispositivo Flutter (ex: `windows`, `chrome`, `edge`). | `setup.bat -FlutterDevice chrome` |

### No Linux & macOS (`setup.sh` ou `modules/setup.sh`):
| Parâmetro | Descrição | Exemplo |
| :--- | :--- | :--- |
| `--seed` | Executa automaticamente as seeds modulares do banco MongoDB sem prompt. | `./setup.sh --seed` |
| `--skip-install` / `-s` | Pula a instalação e atualização de dependências. | `./setup.sh --skip-install` |
| `--no-launch` / `-n` | Executa diagnóstico e compilação sem abrir janelas. | `./setup.sh --no-launch` |
| `--auto-install` / `-y` | Responde "sim" automaticamente a prompts de instalação. | `./setup.sh -y` |
| `--device=<nome>` | Força o dispositivo de execução Flutter (ex: `macos`, `linux`, `chrome`). | `./setup.sh --device=chrome` |
