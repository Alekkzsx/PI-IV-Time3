#!/usr/bin/env bash
# =============================================================================
# AGMRM Educational Platform - Launcher de Setup para Linux
# =============================================================================
# Desenvolvido para o ecossistema AGMRM (PI-IV Time 3 - PUC-Campinas 2026)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assegura permissao de execucao nos scripts do modulo
chmod +x "${SCRIPT_DIR}/modules"/*.sh 2>/dev/null || true

# Executa o orquestrador principal em modules/
exec "${SCRIPT_DIR}/modules/setup.sh" "$@"

