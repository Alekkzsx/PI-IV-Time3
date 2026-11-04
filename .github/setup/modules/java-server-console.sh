#!/usr/bin/env bash
# =============================================================================
# AGMRM - Console Interativo de Controle do Servidor Java SE (Porta 8080)
# =============================================================================
# Desenvolvido para o ecossistema AGMRM (PI-IV Time 3 - PUC-Campinas 2026)
# Suporta auto-recuperacao de porta, compilacao nativa e operacao multi-opcao
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

# Titulo do terminal
printf "\033]0;%s\007" "AGMRM - Painel de Controle Servidor Java (Porta 8080)" 2>/dev/null || true

# -----------------------------------------------------------------------------
# FUNCAO: Localizacao Dinamica da Raiz do Projeto
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

PROJECT_ROOT="$(resolve_project_root)"
SERVER_DIR="${PROJECT_ROOT}/server"
ENV_FILE="${PROJECT_ROOT}/.env"
BIN_DIR="${SERVER_DIR}/bin"
LOG_FILE="${SERVER_DIR}/server.log"
ERR_LOG_FILE="${SERVER_DIR}/server-error.log"
PID_FILE="${SERVER_DIR}/server.pid"

# -----------------------------------------------------------------------------
# Deteccao de Ferramentas Java (javac e java)
# -----------------------------------------------------------------------------
detect_java_tools() {
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
            "/usr/lib/jvm/java-17-openjdk*/bin/javac"
            "/usr/lib/jvm/java-21-openjdk*/bin/javac"
            "/usr/lib/jvm/default-java/bin/javac"
            "/usr/lib/jvm/*-openjdk*/bin/javac"
            "/opt/jdk-17*/bin/javac"
            "/opt/jdk-21*/bin/javac"
            "$HOME/.sdkman/candidates/java/current/bin/javac"
            "/c/Users/${USER:-24802449}/AppData/Roaming/Antigravity IDE/User/globalStorage/pleiades.java-extension-pack-jdk/java/17/bin/javac.exe"
            "/c/Program Files/Java/jdk-17*/bin/javac.exe"
            "/c/Program Files/Java/jdk-21*/bin/javac.exe"
            "/c/Program Files/Eclipse Adoptium/jdk-17*/bin/javac.exe"
        )
        for cand in "${JDK_CANDIDATES[@]}"; do
            for match in $cand; do
                if [[ -x "$match" ]]; then
                    JAVAC_CMD="$match"
                    cand_dir="$(dirname "$match")"
                    export PATH="${cand_dir}:$PATH"
                    if [[ -x "${cand_dir}/java" ]]; then
                        JAVA_CMD="${cand_dir}/java"
                    elif [[ -x "${cand_dir}/java.exe" ]]; then
                        JAVA_CMD="${cand_dir}/java.exe"
                    fi
                    break 2
                fi
            done
        done
    fi

    # Fallback
    if [[ -z "$JAVAC_CMD" ]]; then JAVAC_CMD="javac"; fi
    if [[ -z "$JAVA_CMD" ]]; then JAVA_CMD="java"; fi
}

detect_java_tools

# -----------------------------------------------------------------------------
# Mata processos escutando na porta 8080
# -----------------------------------------------------------------------------
stop_port_8080() {
    # 1. PID salvo
    if [[ -f "$PID_FILE" ]]; then
        local saved_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$saved_pid" && "$saved_pid" =~ ^[0-9]+$ ]]; then
            kill -9 "$saved_pid" >/dev/null 2>&1 || true
        fi
        rm -f "$PID_FILE" 2>/dev/null || true
    fi

    # 2. fuser
    if command -v fuser >/dev/null 2>&1; then
        fuser -k -9 8080/tcp >/dev/null 2>&1 || true
    fi

    # 3. lsof
    if command -v lsof >/dev/null 2>&1; then
        local pids="$(lsof -ti:8080 2>/dev/null || true)"
        if [[ -n "$pids" ]]; then
            echo "$pids" | xargs -r kill -9 >/dev/null 2>&1 || true
        fi
    fi

    # 4. ss / netstat
    if command -v ss >/dev/null 2>&1; then
        local ss_pids="$(ss -lptn 'sport = :8080' 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d= -f2 || true)"
        if [[ -n "$ss_pids" ]]; then
            echo "$ss_pids" | xargs -r kill -9 >/dev/null 2>&1 || true
        fi
    fi
}

# -----------------------------------------------------------------------------
# Compila fontes Java em server/src
# -----------------------------------------------------------------------------
invoke_compilation() {
    echo -e "${CLR_CYAN}[BUILD] Compilando fontes Java em '${SERVER_DIR}/src'...${CLR_RESET}"
    (
        cd "$SERVER_DIR"
        mkdir -p bin

        local tmp_list="$(mktemp /tmp/agmrm_src_XXXXXX.txt 2>/dev/null || echo "bin/src_list.txt")"
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

        if [[ ! -s "$tmp_list" ]]; then
            echo -e "${CLR_RED}[ERRO] Nenhum arquivo .java encontrado em ${SERVER_DIR}/src${CLR_RESET}"
            rm -f "$tmp_list"
            return 1
        fi

        local build_ok=0
        "$JAVAC_CMD" --release 8 -encoding UTF-8 -d bin @"$tmp_list" 2>/dev/null || build_ok=$?

        if [[ $build_ok -eq 0 ]]; then
            echo -e "${CLR_GREEN}[BUILD] Compilacao concluida com sucesso em '${BIN_DIR}'.${CLR_RESET}"
            rm -f "$tmp_list"
            return 0
        else
            echo -e "${CLR_YELLOW}[BUILD] Tentando compilacao direta com codificacao UTF-8...${CLR_RESET}"
            if "$JAVAC_CMD" -encoding UTF-8 -d bin @"$tmp_list"; then
                echo -e "${CLR_GREEN}[BUILD] Compilacao concluida com sucesso em '${BIN_DIR}'.${CLR_RESET}"
                rm -f "$tmp_list"
                return 0
            else
                echo -e "${CLR_RED}[ERRO] Falha ao compilar fontes Java.${CLR_RESET}"
                rm -f "$tmp_list"
                return 1
            fi
        fi
    )
}

# -----------------------------------------------------------------------------
# Inicia Servidor Java em Segundo Plano
# -----------------------------------------------------------------------------
start_server() {
    local recompile="${1:-true}"
    echo ""
    echo -e "${CLR_YELLOW}>>> Iniciando / Reiniciando Servidor Java AGMRM...${CLR_RESET}"

    stop_port_8080
    sleep 0.5

    if [[ "$recompile" == "true" ]]; then
        if ! invoke_compilation; then
            echo -e "${CLR_RED}[FALHA] Nao foi possivel compilar os fontes. Abortando inicio.${CLR_RESET}"
            return 1
        fi
    fi

    echo -e "${CLR_CYAN}[EXEC] Executando Main na porta 8080 via ${JAVA_CMD}...${CLR_RESET}"
    : > "$LOG_FILE"
    : > "$ERR_LOG_FILE"

    cd "$SERVER_DIR"
    nohup "$JAVA_CMD" -Dfile.encoding=UTF-8 -cp "$BIN_DIR" Main > "$LOG_FILE" 2> "$ERR_LOG_FILE" < /dev/null &
    local s_pid=$!
    echo "$s_pid" > "$PID_FILE"

    local running=false
    for _ in {1..15}; do
        sleep 0.3
        if command -v curl >/dev/null 2>&1; then
            if curl -s -f -o /dev/null "http://127.0.0.1:8080/api/videocall/rooms"; then
                running=true
                break
            fi
        fi
    done

    if [[ "$running" == "true" ]]; then
        echo -e "${CLR_GREEN}[SUCESSO] Servidor Java SE ATIVO e RESPONDENDO na porta 8080! (PID: ${s_pid})${CLR_RESET}"
    else
        echo -e "${CLR_YELLOW}[AVISO] Servidor iniciado (PID: ${s_pid}), aguardando conclusao do handshake...${CLR_RESET}"
    fi
}

# -----------------------------------------------------------------------------
# Para Servidor Java
# -----------------------------------------------------------------------------
stop_server() {
    echo ""
    echo -e "${CLR_YELLOW}>>> Encerrando Servidor Java AGMRM...${CLR_RESET}"
    stop_port_8080
    echo -e "${CLR_GREEN}[OK] Servidor Java finalizado. Porta 8080 liberada.${CLR_RESET}"
}

# -----------------------------------------------------------------------------
# Verifica Status do Servidor
# -----------------------------------------------------------------------------
get_server_status() {
    local online=false
    local pid=""
    local latency=0

    if command -v curl >/dev/null 2>&1; then
        local start_ts=$(date +%s%N 2>/dev/null || date +%s)
        if curl -s -f -o /dev/null --connect-timeout 2 "http://127.0.0.1:8080/api/videocall/rooms"; then
            local end_ts=$(date +%s%N 2>/dev/null || date +%s)
            online=true
            latency=$(( (end_ts - start_ts) / 1000000 )) 2>/dev/null || latency=1
        fi
    fi

    if [[ -f "$PID_FILE" ]]; then
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    fi

    if [[ "$online" == "true" ]]; then
        echo -e " STATUS: ${CLR_GREEN}[ONLINE]${CLR_RESET} | PID: ${pid:-N/A} | Porta: 8080 | Latencia: ${latency}ms"
    else
        echo -e " STATUS: ${CLR_RED}[OFFLINE]${CLR_RESET} | Porta 8080 Livre | Servidor Java Parado"
    fi
}

# -----------------------------------------------------------------------------
# Executa Testes Nativos
# -----------------------------------------------------------------------------
run_native_tests() {
    echo ""
    echo -e "${CLR_CYAN}>>> Compilando e Executando Suite de Testes Nativos do Servidor...${CLR_RESET}"
    (
        cd "$SERVER_DIR"
        mkdir -p bin
        local tmp_tests="$(mktemp /tmp/agmrm_tests_XXXXXX.txt 2>/dev/null || echo "bin/tests_list.txt")"
        : > "$tmp_tests"

        shopt -s globstar nullglob 2>/dev/null || true
        for jf in src/**/*.java tests/**/*.java; do
            if command -v cygpath >/dev/null 2>&1 && [[ "${JAVAC_CMD:-}" == *.exe ]]; then
                cygpath -w "$jf" >> "$tmp_tests"
            else
                echo "$jf" >> "$tmp_tests"
            fi
        done
        shopt -u globstar nullglob 2>/dev/null || true

        if "$JAVAC_CMD" --release 8 -encoding UTF-8 -d bin @"$tmp_tests" 2>/dev/null || \
           "$JAVAC_CMD" -encoding UTF-8 -d bin @"$tmp_tests"; then
            rm -f "$tmp_tests"
            echo -e "${CLR_YELLOW}[EXEC] Executando SuiteTestesServidor...${CLR_RESET}"
            "$JAVA_CMD" -Dfile.encoding=UTF-8 -cp bin SuiteTestesServidor
        else
            rm -f "$tmp_tests"
            echo -e "${CLR_RED}[ERRO] Falha na compilacao dos testes.${CLR_RESET}"
        fi
    )
}

# -----------------------------------------------------------------------------
# Exibe Logs Recentes
# -----------------------------------------------------------------------------
show_logs() {
    echo ""
    echo -e "${CLR_CYAN}=== ULTIMOS LOGS DO SERVIDOR (${LOG_FILE}) ===${CLR_RESET}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -n 30 "$LOG_FILE" || echo -e "${CLR_GRAY}  (Arquivo de log vazio)${CLR_RESET}"
    else
        echo -e "${CLR_GRAY}  (Nenhum log gerado ainda)${CLR_RESET}"
    fi

    if [[ -f "$ERR_LOG_FILE" && -s "$ERR_LOG_FILE" ]]; then
        echo ""
        echo -e "${CLR_RED}=== ERROS RECENTES (${ERR_LOG_FILE}) ===${CLR_RESET}"
        tail -n 15 "$ERR_LOG_FILE"
    fi
}

# -----------------------------------------------------------------------------
# Exibe Variaveis do .env Mestre
# -----------------------------------------------------------------------------
show_master_env() {
    echo ""
    echo -e "${CLR_CYAN}=== VARIAVEIS DO .ENV MESTRE NA RAIZ (${ENV_FILE}) ===${CLR_RESET}"
    if [[ -f "$ENV_FILE" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            if [[ "$line" =~ ^(AUTH_JWT_SECRET|JWT_SECRET|SMTP_PASSWORD) ]]; then
                local key="${line%%=*}"
                echo -e "  ${CLR_YELLOW}${key} = ******** (oculto por seguranca)${CLR_RESET}"
            else
                echo -e "  ${CLR_GRAY}${line}${CLR_RESET}"
            fi
        done < "$ENV_FILE"
    else
        echo -e "${CLR_RED}  [ERRO] Arquivo .env nao encontrado em ${ENV_FILE}${CLR_RESET}"
    fi
}

# -----------------------------------------------------------------------------
# Inicializacao
# -----------------------------------------------------------------------------
clear 2>/dev/null || true
echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
echo -e "${CLR_YELLOW}         AGMRM - SERVIDOR HTTP & WEBSOCKET NATIVO JAVA SE (PORTA 8080)          ${CLR_RESET}"
echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
echo -e "${CLR_GRAY} Raiz do Projeto : ${PROJECT_ROOT}${CLR_RESET}"
echo -e "${CLR_GRAY} Compilador Java : ${JAVAC_CMD}${CLR_RESET}"
echo -e "${CLR_GRAY} Runtime Java    : ${JAVA_CMD}${CLR_RESET}"
echo -e "${CLR_GRAY}--------------------------------------------------------------------------------${CLR_RESET}"

start_server "true"

# -----------------------------------------------------------------------------
# Loop Interativo
# -----------------------------------------------------------------------------
while true; do
    echo ""
    echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
    get_server_status
    echo -e "${CLR_GRAY}--------------------------------------------------------------------------------${CLR_RESET}"
    echo -e "${CLR_WHITE} [1] Iniciar / Reiniciar Servidor Java (Recompila e sobe na porta 8080)${CLR_RESET}"
    echo -e "${CLR_WHITE} [2] Desligar / Parar Servidor Java (Libera a porta 8080)${CLR_RESET}"
    echo -e "${CLR_WHITE} [3] Status e Diagnostico em Tempo Real (Testa endpoints)${CLR_RESET}"
    echo -e "${CLR_WHITE} [4] Visualizar Logs do Servidor (server.log)${CLR_RESET}"
    echo -e "${CLR_WHITE} [5] Recompilar Fontes Java (Sem reiniciar processo atual)${CLR_RESET}"
    echo -e "${CLR_WHITE} [6] Executar Suite de Testes Nativos (7 suites sem JUnit)${CLR_RESET}"
    echo -e "${CLR_WHITE} [7] Exibir Variaveis Carregadas do .env Mestre${CLR_RESET}"
    echo -e "${CLR_WHITE} [8] Abrir Endpoint no Navegador (Healthcheck: /api/videocall/rooms)${CLR_RESET}"
    echo -e "${CLR_WHITE} [9] Limpar Tela do Console${CLR_RESET}"
    echo -e "${CLR_YELLOW} [0] Encerrar Servidor e Fechar Console${CLR_RESET}"
    echo -e "${CLR_CYAN}================================================================================${CLR_RESET}"
    read -rp "Digite o numero da opcao desejada: " choice

    case "${choice// /}" in
        1) start_server "true" ;;
        2) stop_server ;;
        3)
            echo -e "\n${CLR_CYAN}>>> Diagnostico de Endpoints:${CLR_RESET}"
            for ep in "/api/videocall/rooms" "/api/teste-tipos" "/api/presenca" "/api/auth/session"; do
                if command -v curl >/dev/null 2>&1; then
                    code="$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://127.0.0.1:8080${ep}" 2>/dev/null || echo "000")"
                    if [[ "$code" == "200" ]]; then
                        echo -e "  ${CLR_GREEN}[OK 200] http://127.0.0.1:8080${ep}${CLR_RESET}"
                    elif [[ "$code" != "000" ]]; then
                        echo -e "  ${CLR_YELLOW}[RES ${code}] http://127.0.0.1:8080${ep} (Resposta controlada)${CLR_RESET}"
                    else
                        echo -e "  ${CLR_RED}[ERRO] http://127.0.0.1:8080${ep} (Nao responde)${CLR_RESET}"
                    fi
                fi
            done
            ;;
        4) show_logs ;;
        5) invoke_compilation ;;
        6) run_native_tests ;;
        7) show_master_env ;;
        8)
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "http://127.0.0.1:8080/api/videocall/rooms" >/dev/null 2>&1 &
                echo -e "${CLR_GREEN}[OK] Endpoint aberto no navegador padrao.${CLR_RESET}"
            elif command -v sensible-browser >/dev/null 2>&1; then
                sensible-browser "http://127.0.0.1:8080/api/videocall/rooms" >/dev/null 2>&1 &
            else
                echo -e "${CLR_YELLOW}[AVISO] xdg-open nao encontrado. Acesse: http://127.0.0.1:8080/api/videocall/rooms${CLR_RESET}"
            fi
            ;;
        9) clear 2>/dev/null || true ;;
        0)
            stop_server
            echo -e "${CLR_CYAN}[SAIR] Console finalizado. Ate logo!${CLR_RESET}"
            sleep 1
            exit 0
            ;;
        *)
            echo -e "${CLR_YELLOW}[AVISO] Opcao invalida. Digite um numero de 0 a 9.${CLR_RESET}"
            ;;
    esac
done
