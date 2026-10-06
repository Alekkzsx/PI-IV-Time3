#!/usr/bin/env bash
# ==============================================================================
# AGMRM - Academic Portal: Native Java HTTP Server (Port 8080)
# Linux / macOS Compilation & Startup Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"
SRC_DIR="${SCRIPT_DIR}/../backend/src"

echo "=============================================================================="
echo "       AGMRM - Academic Portal: Native Java HTTP Server (Port 8080)"
echo "=============================================================================="

echo "[1/3] Validating Java Development Kit (JDK 17+) environment..."
if ! command -v javac >/dev/null 2>&1; then
    echo "[ERROR] 'javac' compiler was not found in your PATH." >&2
    echo "Please install JDK 17 or higher and ensure JAVA_HOME is configured." >&2
    exit 1
fi

if ! command -v java >/dev/null 2>&1; then
    echo "[ERROR] 'java' runtime was not found in your PATH." >&2
    echo "Please ensure Java 17+ is installed." >&2
    exit 1
fi

if [[ ! -f "${SRC_DIR}/ServidorHttpNativo.java" ]]; then
    echo "[ERROR] Main source file not found at: ${SRC_DIR}/ServidorHttpNativo.java" >&2
    exit 1
fi

echo "[2/3] Preparing output directory: ${BIN_DIR}..."
mkdir -p "${BIN_DIR}"

echo "[3/3] Compiling Java backend sources with UTF-8 encoding..."
javac -encoding UTF-8 -d "${BIN_DIR}" "${SRC_DIR}/"*.java

echo ""
echo "=============================================================================="
echo "Compilation successful. Starting HTTP Server on port 8080..."
echo "Press Ctrl+C to terminate the server."
echo "=============================================================================="
echo ""

exec java -cp "${BIN_DIR}" ServidorHttpNativo
