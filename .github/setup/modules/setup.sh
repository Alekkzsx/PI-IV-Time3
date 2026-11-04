#!/usr/bin/env bash
# =============================================================================
# AGMRM Educational Platform - Setup e Orquestrador Automatizado Ultra-Robusto
# =============================================================================
# Desenvolvido para o ecossistema AGMRM (PI-IV Time 3 - PUC-Campinas 2026)
# Suporta auto-deteccao, auto-instalacao/reparo e orquestracao multi-terminal
# =============================================================================
set -u

# Configuracao de cores ANSI
CLR_RESET="\033[0m"
CLR_RED="\033[1;31m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_CYAN="\033[1;36m"
CLR_WHITE="\033[1;37m"
CLR_GRAY="\033[0;90m"

# Parametros de linha de comando
SKIP_INSTALL=false
NO_LAUNCH=false
AUTO_INSTALL=false
TARGET_DEVICE=""

for arg in "$@"; do
    case "$arg" in
        --skip-install|-s) SKIP_INSTALL=true ;;
        --no-launch|-n)    NO_LAUNCH=true ;;
        --auto-install|-y) AUTO_INSTALL=true ;;
        --device=*)        TARGET_DEVICE="${arg#*=}" ;;
        -d=*)              TARGET_DEVICE="${arg#*=}" ;;
        *)                 ;;
    esac
done

printf "\033]0;%s\007" "AGMRM - Setup e Orquestrador Linux" 2>/dev/null || true

# -----------------------------------------------------------------------------
# FUNCAO: Localizacao Dinamica e Resiliente da Raiz do Projeto
# -----------------------------------------------------------------------------
resolve_project_root() {
    local curr="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    for _ in {1..8}; do
        if [[ -d "${curr}/server" && -d "${curr}/backend" && -d "${curr}/frontend" ]]; then
            echo "$curr"
            return 0
        fi
        local parent="$(dirname "$curr")"
        if [[ "$parent" == "$curr" ]]; then break; fi
        curr="$parent"
    done
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
}

MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(resolve_project_root)"
BACKEND_DIR="${PROJECT_ROOT}/backend"
FRONTEND_DIR="${PROJECT_ROOT}/frontend"
SECURITY_DIR="${PROJECT_ROOT}/security"
SERVER_DIR="${PROJECT_ROOT}/server"
ENV_FILE="${PROJECT_ROOT}/.env"
ENV_EXAMPLE_FILE="${PROJECT_ROOT}/.env-example"
JAVA_CONSOLE_SCRIPT="${MODULES_DIR}/java-server-console.sh"

chmod +x "$JAVA_CONSOLE_SCRIPT" 2>/dev/null || true

clear 2>/dev/null || true
echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
echo -e "${CLR_YELLOW}       AGMRM EDUCATIONAL PLATFORM - SETUP E ORQUESTRADOR AUTOMATIZADO           ${CLR_RESET}"
echo -e "${CLR_WHITE}           Projeto Interdisciplinar IV - PI-IV Time 3 - PUC-Campinas            ${CLR_RESET}"
echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
echo -e "${CLR_GRAY} Raiz do Projeto: ${PROJECT_ROOT}${CLR_RESET}"
echo -e "${CLR_GRAY} Data/Hora       : $(date '+%Y-%m-%d %H:%M:%S')${CLR_RESET}"
echo -e "${CLR_GRAY}--------------------------------------------------------------------------------${CLR_RESET}"

# -----------------------------------------------------------------------------
# DETECCAO DE GERENCIADOR DE PACOTES LINUX
# -----------------------------------------------------------------------------
PKG_MANAGER=""
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
elif command -v apk >/dev/null 2>&1; then
    PKG_MANAGER="apk"
fi

ask_user() {
    local question="$1"
    if [[ "$AUTO_INSTALL" == "true" ]]; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        # Modo nao interativo (pipe ou sem tty disponivel)
        return 1
    fi
    read -rp "$question (s/n): " ans
    case "${ans,,}" in
        s|y|sim|yes) return 0 ;;
        *) return 1 ;;
    esac
}

install_package() {
    local deb_pkg="$1"
    local rpm_pkg="${2:-$1}"
    local arch_pkg="${3:-$1}"

    case "$PKG_MANAGER" in
        apt)
            echo -e "${CLR_CYAN}  Executando: sudo apt-get update && sudo apt-get install -y $deb_pkg${CLR_RESET}"
            sudo apt-get update -qq && sudo apt-get install -y "$deb_pkg"
            ;;
        dnf)
            echo -e "${CLR_CYAN}  Executando: sudo dnf install -y $rpm_pkg${CLR_RESET}"
            sudo dnf install -y "$rpm_pkg"
            ;;
        pacman)
            echo -e "${CLR_CYAN}  Executando: sudo pacman -S --noconfirm $arch_pkg${CLR_RESET}"
            sudo pacman -S --noconfirm "$arch_pkg"
            ;;
        *)
            echo -e "${CLR_RED}  Gerenciador de pacotes automatico nao suportado. Instale manualmente: $deb_pkg${CLR_RESET}"
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# 1. VERIFICACAO DE AMBIENTE E AUTO-REPARO DE DEPENDENCIAS
# -----------------------------------------------------------------------------
echo -e "\n${CLR_CYAN}[ETAPA 1/4] Verificando dependencias essenciais do ambiente...${CLR_RESET}"
DEPS_OK=true

# A. Git
if command -v git >/dev/null 2>&1; then
    echo -e "  ${CLR_GREEN}[OK] Git instalado: $(git --version)${CLR_RESET}"
else
    echo -e "  ${CLR_RED}[FALHA] Git nao encontrado!${CLR_RESET}"
    if [[ -n "$PKG_MANAGER" ]] && ask_user "  Deseja que o setup instale o Git automaticamente via $PKG_MANAGER?"; then
        install_package git git git
        if command -v git >/dev/null 2>&1; then
            echo -e "  ${CLR_GREEN}[OK] Git instalado com sucesso!${CLR_RESET}"
        else
            DEPS_OK=false
        fi
    else
        DEPS_OK=false
    fi
fi

# B. Node.js (>= 20)
NODE_OK=false
if command -v node >/dev/null 2>&1; then
    NODE_VER="$(node -v 2>/dev/null || true)"
    NODE_MAJOR="$(echo "$NODE_VER" | sed 's/^v//' | cut -d. -f1)"
    if [[ -n "$NODE_MAJOR" && "$NODE_MAJOR" -ge 20 ]]; then
        echo -e "  ${CLR_GREEN}[OK] Node.js instalado: ${NODE_VER} (Recomendado >= 20.x)${CLR_RESET}"
        NODE_OK=true
    else
        echo -e "  ${CLR_YELLOW}[AVISO] Node.js ${NODE_VER} detectado. Recomendado >= 20.x.${CLR_RESET}"
        NODE_OK=true
    fi
fi

if [[ "$NODE_OK" == "false" ]]; then
    echo -e "  ${CLR_RED}[FALHA] Node.js nao encontrado ou desatualizado!${CLR_RESET}"
    if [[ -n "$PKG_MANAGER" ]] && ask_user "  Deseja instalar Node.js 20.x LTS via instalador oficial?"; then
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif [[ "$PKG_MANAGER" == "dnf" ]]; then
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            sudo dnf install -y nodejs
        else
            install_package nodejs nodejs nodejs
        fi
        if command -v node >/dev/null 2>&1; then
            echo -e "  ${CLR_GREEN}[OK] Node.js instalado com sucesso: $(node -v)${CLR_RESET}"
        else
            DEPS_OK=false
        fi
    else
        DEPS_OK=false
    fi
fi

# C. npm
if command -v npm >/dev/null 2>&1; then
    echo -e "  ${CLR_GREEN}[OK] npm instalado: v$(npm -v)${CLR_RESET}"
else
    echo -e "  ${CLR_RED}[FALHA] npm nao encontrado!${CLR_RESET}"
    if [[ -n "$PKG_MANAGER" ]] && ask_user "  Deseja instalar npm via $PKG_MANAGER?"; then
        install_package npm npm npm
    else
        DEPS_OK=false
    fi
fi

# D. Java JDK e Javac
JAVAC_CMD=""
JAVA_CMD=""

if command -v javac >/dev/null 2>&1; then
    JAVAC_CMD="$(command -v javac)"
elif command -v javac.exe >/dev/null 2>&1; then
    JAVAC_CMD="$(command -v javac.exe)"
fi

if command -v java >/dev/null 2>&1; then
    JAVA_CMD="$(command -v java)"
elif command -v java.exe >/dev/null 2>&1; then
    JAVA_CMD="$(command -v java.exe)"
fi

if [[ -z "$JAVAC_CMD" ]]; then
    JDK_CANDIDATES=(
        "${JAVA_HOME:-}/bin/javac"
        "${JAVA_HOME:-}/bin/javac.exe"
        "/c/Users/${USER:-24802449}/AppData/Roaming/Antigravity IDE/User/globalStorage/pleiades.java-extension-pack-jdk/java/17/bin/javac.exe"
        "/c/Users/${USER:-24802449}/AppData/Roaming/Code/User/globalStorage/pleiades.java-extension-pack-jdk/java/17/bin/javac.exe"
        "/c/Program Files/Java/jdk-17*/bin/javac.exe"
        "/c/Program Files/Java/jdk-21*/bin/javac.exe"
        "/c/Program Files/Eclipse Adoptium/jdk-17*/bin/javac.exe"
        "/usr/lib/jvm/java-17-openjdk*/bin/javac"
        "/usr/lib/jvm/java-21-openjdk*/bin/javac"
        "/usr/lib/jvm/default-java/bin/javac"
        "/usr/lib/jvm/*-openjdk*/bin/javac"
        "/opt/jdk-17*/bin/javac"
        "/opt/jdk-21*/bin/javac"
        "$HOME/.sdkman/candidates/java/current/bin/javac"
    )
    for cand in "${JDK_CANDIDATES[@]}"; do
        if [[ -f "$cand" || -x "$cand" ]]; then
            JAVAC_CMD="$cand"
            cand_dir="$(dirname "$cand")"
            export PATH="${cand_dir}:$PATH"
            if [[ -f "${cand_dir}/java" || -x "${cand_dir}/java" ]]; then
                JAVA_CMD="${cand_dir}/java"
            elif [[ -f "${cand_dir}/java.exe" || -x "${cand_dir}/java.exe" ]]; then
                JAVA_CMD="${cand_dir}/java.exe"
            fi
            break
        fi
    done
fi

if [[ -n "$JAVAC_CMD" ]]; then
    echo -e "  ${CLR_GREEN}[OK] Java JDK Compilador detectado: ${JAVAC_CMD}${CLR_RESET}"
    echo -e "  ${CLR_GREEN}[OK] Java Runtime emparelhado: ${JAVA_CMD}${CLR_RESET}"
else
    echo -e "  ${CLR_RED}[FALHA] Compilador javac nao encontrado!${CLR_RESET}"
    if [[ -n "$PKG_MANAGER" ]] && ask_user "  Deseja instalar OpenJDK 17 JDK via $PKG_MANAGER?"; then
        install_package openjdk-17-jdk java-17-openjdk-devel jdk17-openjdk
        if command -v javac >/dev/null 2>&1; then
            JAVAC_CMD="$(command -v javac)"
            JAVA_CMD="$(command -v java)"
            echo -e "  ${CLR_GREEN}[OK] OpenJDK 17 instalado com sucesso!${CLR_RESET}"
        else
            DEPS_OK=false
        fi
    else
        DEPS_OK=false
    fi
fi

# E. Flutter SDK
FLUTTER_CMD=""
if command -v flutter >/dev/null 2>&1; then
    FLUTTER_CMD="$(command -v flutter)"
elif command -v flutter.bat >/dev/null 2>&1; then
    FLUTTER_CMD="$(command -v flutter.bat)"
else
    for cand in "$HOME/flutter/bin/flutter" "$HOME/src/flutter/bin/flutter" "$HOME/development/flutter/bin/flutter" "/opt/flutter/bin/flutter" "/snap/bin/flutter" "/c/src/flutter/bin/flutter.bat" "/c/flutter/bin/flutter.bat"; do
        if [[ -f "$cand" || -x "$cand" ]]; then
            export PATH="$(dirname "$cand"):$PATH"
            FLUTTER_CMD="$cand"
            echo -e "  ${CLR_CYAN}[AUTO-CONFIG] Flutter localizado em '${cand}' e adicionado ao PATH.${CLR_RESET}"
            break
        fi
    done
fi

if [[ -n "$FLUTTER_CMD" ]]; then
    flutter_ver="$(flutter --version 2>/dev/null | head -n 1 || echo "Flutter SDK")"
    echo -e "  ${CLR_GREEN}[OK] Flutter SDK detectado: ${flutter_ver}${CLR_RESET}"
else
    echo -e "  ${CLR_RED}[FALHA] Flutter SDK nao encontrado no PATH nem nos locais usuais!${CLR_RESET}"
    echo -e "  ${CLR_YELLOW}[AJUDA] Para instalar o Flutter: clone via Git no diretorio ~/flutter:${CLR_RESET}"
    echo -e "          git clone https://github.com/flutter/flutter.git -b stable ~/flutter"
    echo -e "          export PATH=\"\$HOME/flutter/bin:\$PATH\""
    if ask_user "  Deseja clonar automaticamente o Flutter stable em $HOME/flutter?"; then
        echo -e "${CLR_CYAN}  Clonando Flutter SDK...${CLR_RESET}"
        git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
        export PATH="$HOME/flutter/bin:$PATH"
        if command -v flutter >/dev/null 2>&1; then
            FLUTTER_CMD="$(command -v flutter)"
            echo -e "  ${CLR_GREEN}[OK] Flutter instalado com sucesso!${CLR_RESET}"
        else
            DEPS_OK=false
        fi
    else
        DEPS_OK=false
    fi
fi

# F. Deteccao de Dispositivo de Execucao Flutter
if [[ -z "$TARGET_DEVICE" ]]; then
    if [[ -n "$FLUTTER_CMD" ]]; then
        devs="$(flutter devices 2>/dev/null || true)"
        if echo "$devs" | grep -q "linux • linux"; then
            TARGET_DEVICE="linux"
            echo -e "  ${CLR_GREEN}[OK] Dispositivo de execucao: Linux Desktop nativo.${CLR_RESET}"
        elif echo "$devs" | grep -q "windows • windows"; then
            TARGET_DEVICE="windows"
            echo -e "  ${CLR_GREEN}[OK] Dispositivo de execucao: Windows Desktop nativo.${CLR_RESET}"
        elif echo "$devs" | grep -q "chrome • chrome"; then
            TARGET_DEVICE="chrome"
            echo -e "  ${CLR_YELLOW}[AVISO] Alternando para Google Chrome (Web).${CLR_RESET}"
        else
            TARGET_DEVICE="linux"
        fi
    else
        TARGET_DEVICE="linux"
    fi
fi

# G. Arquivo de Configuracao Mestre .env
if [[ -f "$ENV_FILE" ]]; then
    echo -e "  ${CLR_GREEN}[OK] Arquivo mestre .env presente na raiz do projeto.${CLR_RESET}"
else
    if [[ -f "$ENV_EXAMPLE_FILE" ]]; then
        echo -e "  ${CLR_YELLOW}[CRIANDO] .env ausente. Copiando automaticamente de .env-example...${CLR_RESET}"
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        chmod 600 "$ENV_FILE" 2>/dev/null || true
        echo -e "  ${CLR_GREEN}[OK] Arquivo .env criado a partir de .env-example na raiz.${CLR_RESET}"
    else
        echo -e "  ${CLR_RED}[FALHA] Arquivos .env e .env-example nao foram encontrados na raiz!${CLR_RESET}"
        DEPS_OK=false
    fi
fi

if [[ "$DEPS_OK" == "false" ]]; then
    echo -e "\n${CLR_RED}[AVISO CRITICO] Algumas dependencias necessitam de atencao antes da inicializacao.${CLR_RESET}"
    if ! ask_user "Deseja tentar prosseguir mesmo assim?"; then
        echo -e "${CLR_GRAY}Setup finalizado conforme configuracao.${CLR_RESET}"
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# 2. ATUALIZACAO E INSTALACAO DE DEPENDENCIAS CONFORME O AMBIENTE
# -----------------------------------------------------------------------------
if [[ "$SKIP_INSTALL" == "false" ]]; then
    echo -e "\n${CLR_CYAN}[ETAPA 2/4] Atualizando e instalando dependencias de todos os modulos...${CLR_RESET}"

    # A. Backend (Node / npm)
    echo -e "\n  ${CLR_YELLOW}-> [backend/] Executando 'npm install'...${CLR_RESET}"
    (
        cd "$BACKEND_DIR"
        npm install
    )
    echo -e "  ${CLR_GREEN}[OK] Dependencias do backend TypeScript atualizadas com sucesso.${CLR_RESET}"

    # B. Security & Frontend (Flutter pub get)
    if [[ -n "$FLUTTER_CMD" ]]; then
        echo -e "\n  ${CLR_YELLOW}-> [security/] Executando 'flutter pub get' no modulo de ciberdefesa...${CLR_RESET}"
        (
            cd "$SECURITY_DIR"
            flutter pub get
        )
        echo -e "  ${CLR_GREEN}[OK] Dependencias do modulo agmrm_security atualizadas com sucesso.${CLR_RESET}"

        echo -e "\n  ${CLR_YELLOW}-> [frontend/] Executando 'flutter pub get' no aplicativo multiplataforma...${CLR_RESET}"
        (
            cd "$FRONTEND_DIR"
            flutter pub get
        )
        echo -e "  ${CLR_GREEN}[OK] Dependencias do frontend Flutter atualizadas com sucesso.${CLR_RESET}"
    fi

    # C. Server Java (Compilacao)
    echo -e "\n  ${CLR_YELLOW}-> [server/] Compilando classes Java nativas para bin/...${CLR_RESET}"
    (
        cd "$SERVER_DIR"
        mkdir -p bin
        tmp_list="$(mktemp /tmp/agmrm_setup_src_XXXXXX.txt 2>/dev/null || echo "bin/src_list.txt")"
        : > "$tmp_list"

        shopt -s globstar nullglob 2>/dev/null || true
        for jf in src/**/*.java; do
            if command -v cygpath >/dev/null 2>&1 && [[ "${JAVAC_CMD:-}" == *.exe ]]; then
                cygpath -w "$jf" >> "$tmp_list"
            else
                echo "$jf" >> "$tmp_list"
            fi
        done
        shopt -u globstar nullglob 2>/dev/null || true

        javac_bin="${JAVAC_CMD:-javac}"
        if "$javac_bin" --release 8 -encoding UTF-8 -d bin @"$tmp_list" 2>/dev/null || \
           "$javac_bin" -encoding UTF-8 -d bin @"$tmp_list"; then
            echo -e "  ${CLR_GREEN}[OK] Modulo server/ compilado com sucesso.${CLR_RESET}"
        else
            echo -e "  ${CLR_YELLOW}[AVISO] Nao foi possivel compilar server/ nesta etapa. O console interativo tentara novamente.${CLR_RESET}"
        fi
        rm -f "$tmp_list"
    )
else
    echo -e "\n${CLR_GRAY}[ETAPA 2/4] Instalacao de dependencias ignorada conforme parametro --skip-install.${CLR_RESET}"
fi

if [[ "$NO_LAUNCH" == "true" ]]; then
    echo -e "\n${CLR_GREEN}[CONCLUIDO] Setup finalizado sem inicializacao de janelas (--no-launch ativo).${CLR_RESET}"
    exit 0
fi

# -----------------------------------------------------------------------------
# 3. LIBERACAO DE PORTAS ANTES DE ABRIR OS SERVICOS
# -----------------------------------------------------------------------------
if command -v fuser >/dev/null 2>&1; then
    fuser -k -9 8080/tcp >/dev/null 2>&1 || true
fi
if command -v lsof >/dev/null 2>&1; then
    lsof -ti:8080 2>/dev/null | xargs -r kill -9 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 4. INICIALIZACAO DOS SERVICOS EM JANELAS / ABAS DE TERMINAL SEPARADAS
# -----------------------------------------------------------------------------
echo -e "\n${CLR_CYAN}[ETAPA 3/4] Inicializando os servicos em abas/janelas dedicadas de terminal...${CLR_RESET}"

# Deteccao do emulador de terminal grafico
TERMINAL_EMU=""
if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    for emu in gnome-terminal ptyxis konsole xfce4-terminal tilix alacritty kitty xterm; do
        if command -v "$emu" >/dev/null 2>&1; then
            TERMINAL_EMU="$emu"
            break
        fi
    done
fi

launch_window() {
    local title="$1"
    local workdir="$2"
    local command="$3"

    case "$TERMINAL_EMU" in
        gnome-terminal)
            gnome-terminal --title="$title" --working-directory="$workdir" -- bash -c "$command; exec bash" 2>/dev/null &
            ;;
        ptyxis)
            ptyxis --working-directory="$workdir" -- bash -c "$command; exec bash" 2>/dev/null &
            ;;
        konsole)
            konsole --new-tab -p tabtitle="$title" --workdir "$workdir" -e bash -c "$command; exec bash" 2>/dev/null &
            ;;
        xfce4-terminal)
            xfce4-terminal --title="$title" --working-directory="$workdir" -e "bash -c '$command; exec bash'" 2>/dev/null &
            ;;
        tilix)
            tilix -t "$title" -w "$workdir" -e bash -c "$command; exec bash" 2>/dev/null &
            ;;
        alacritty)
            alacritty -t "$title" --working-directory "$workdir" -e bash -c "$command; exec bash" 2>/dev/null &
            ;;
        kitty)
            kitty --title "$title" --directory "$workdir" bash -c "$command; exec bash" 2>/dev/null &
            ;;
        xterm)
            xterm -title "$title" -e "cd '$workdir' && $command; exec bash" 2>/dev/null &
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# Se temos um emulador grafico detectado
if [[ -n "$TERMINAL_EMU" ]]; then
    echo -e "  Detectado emulador de terminal: ${CLR_GREEN}${TERMINAL_EMU}${CLR_RESET}"

    # 1. Servidor Java SE
    echo -e "  -> Abrindo Janela 1: Servidor Java SE (Console Interativo com Menu: Reiniciar, Desligar, Status...)"
    launch_window "AGMRM - Servidor Java SE (Porta 8080)" "$MODULES_DIR" "./java-server-console.sh"
    sleep 1

    # 2. Backend TypeScript API
    echo -e "  -> Abrindo Janela 2: Backend API TypeScript (Express + MongoDB na Porta 3001)"
    launch_window "AGMRM - Backend API TypeScript (Porta 3001)" "$BACKEND_DIR" "npm run dev"
    sleep 1

    # 3. Frontend Flutter
    echo -e "  -> Abrindo Janela 3: Frontend Flutter (Executando flutter run -d $TARGET_DEVICE)"
    launch_window "AGMRM - Frontend Flutter ($TARGET_DEVICE)" "$FRONTEND_DIR" "flutter run -d $TARGET_DEVICE"

# Fallback se estamos em modo headless / SSH / sem interface grafica direta
elif command -v tmux >/dev/null 2>&1; then
    echo -e "  ${CLR_YELLOW}[MODO TMUX] Ambiente headless/SSH detectado. Criando sessao tmux 'agmrm'...${CLR_RESET}"
    tmux kill-session -t agmrm 2>/dev/null || true
    tmux new-session -d -s agmrm -n "java-server" "cd '$MODULES_DIR' && ./java-server-console.sh"
    tmux new-window -t agmrm -n "backend" "cd '$BACKEND_DIR' && npm run dev"
    tmux new-window -t agmrm -n "frontend" "cd '$FRONTEND_DIR' && flutter run -d $TARGET_DEVICE"
    echo -e "  ${CLR_GREEN}[OK] Sessao tmux criada! Acesse com: tmux attach -t agmrm${CLR_RESET}"
else
    echo -e "  ${CLR_YELLOW}[MODO BACKGROUND] Nenhum emulador grafico ou tmux disponivel.${CLR_RESET}"
    echo -e "  Iniciando Backend e Frontend em background e abrindo Console Java neste terminal..."
    (cd "$BACKEND_DIR" && nohup npm run dev > "${BACKEND_DIR}/backend.log" 2>&1 &)
    (cd "$FRONTEND_DIR" && nohup flutter run -d "$TARGET_DEVICE" > "${FRONTEND_DIR}/frontend.log" 2>&1 &)
    sleep 1
    exec "$JAVA_CONSOLE_SCRIPT"
fi

# -----------------------------------------------------------------------------
# 5. RESUMO DOS SERVICOS E CONCLUSAO
# -----------------------------------------------------------------------------
echo -e "\n${CLR_CYAN}[ETAPA 4/4] Resumo do Ecossistema AGMRM em Execucao:${CLR_RESET}"
echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
echo -e " ${CLR_GREEN}[JANELA 1] SERVIDOR JAVA SE (Porta 8080):${CLR_RESET}"
echo -e "            - Console interativo aberto em janela dedicada."
echo -e "            - Opcoes disponiveis: 1 = Reiniciar, 2 = Desligar, 3 = Status, 4 = Logs..."
echo -e "            - Healthcheck: http://127.0.0.1:8080/api/videocall/rooms"
echo ""
echo -e " ${CLR_GREEN}[JANELA 2] BACKEND API TYPESCRIPT (Porta 3001):${CLR_RESET}"
echo -e "            - Executando 'npm run dev' em janela separada."
echo -e "            - Healthcheck: http://127.0.0.1:3001/health"
echo ""
echo -e " ${CLR_GREEN}[JANELA 3] FRONTEND FLUTTER ($TARGET_DEVICE):${CLR_RESET}"
echo -e "            - Executando 'flutter run -d $TARGET_DEVICE' em janela separada."
echo -e "            - Atalhos no terminal do Flutter: 'r' = Hot Reload, 'R' = Hot Restart."
echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
echo -e "\n${CLR_GREEN}[SUCESSO] Todo o ambiente do projeto AGMRM foi verificado, atualizado e iniciado!${CLR_RESET}"
echo -e "${CLR_GRAY}Este terminal pode ser mantido ou fechado sem interromper os servicos ativos.${CLR_RESET}\n"
