#!/usr/bin/env bash
# ==============================================================================
# AGMRM - Academic Portal: Automated API Verification Suite (Linux/macOS)
# Target: http://localhost:8080
# ==============================================================================
set -euo pipefail

BASE_URL="http://localhost:8080"

echo "=============================================================================="
echo "       AGMRM - Academic Portal: Automated API Verification Suite"
echo "                 Target: ${BASE_URL}"
echo "=============================================================================="

if ! command -v curl >/dev/null 2>&1; then
    echo "[ERROR] 'curl' command-line tool not found. Please install curl." >&2
    exit 1
fi

echo ""
echo "=============================================================================="
echo "[TEST 1/6] POST /api/teste-tipos (Primitive Types Parsing)"
echo "Payload: texto=Calculo1&inteiro=42&flutuante=7.5&duplo=99.99&caractere=A"
echo "Expected: OK - Tipos Processados: [Calculo1, 42, 7.5, 99.99, A]"
echo "------------------------------------------------------------------------------"
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X POST "${BASE_URL}/api/teste-tipos" \
  -d "texto=Calculo1&inteiro=42&flutuante=7.5&duplo=99.99&caractere=A"

echo ""
echo "=============================================================================="
echo "[TEST 2/6] POST /api/presenca (Attendance: 50 min / 60 min = 83.33%)"
echo "Expected: Resultado Presenca: PRESENCA_INTEGRAL (83%)"
echo "------------------------------------------------------------------------------"
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X POST "${BASE_URL}/api/presenca" \
  -d "minutosAssistidos=50&duracaoTotal=60"

echo ""
echo "=============================================================================="
echo "[TEST 3/6] POST /api/presenca (Teacher Manual Override)"
echo "Expected: Resultado Presenca: JUSTIFICADO (Ajuste Manual do Professor)"
echo "------------------------------------------------------------------------------"
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X POST "${BASE_URL}/api/presenca" \
  -d "statusManual=JUSTIFICADO"

echo ""
echo "=============================================================================="
echo "[TEST 4/6] POST /api/tarefas/calcular-nota (Late Penalty: 1 Day = 20% discount)"
echo "Expected: Nota Maxima Permitida: 8.0"
echo "------------------------------------------------------------------------------"
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X POST "${BASE_URL}/api/tarefas/calcular-nota" \
  -d "diasAtraso=1&notaBase=10.0"

echo ""
echo "=============================================================================="
echo "[TEST 5/6] POST /api/notas/boletim (Weighted Average: 8.0*0.4 + 6.0*0.4 + 10*0.2)"
echo "Expected: Media Final: 7.6 | Status: APROVADO"
echo "------------------------------------------------------------------------------"
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X POST "${BASE_URL}/api/notas/boletim" \
  -d "p1=8.0&peso1=0.4&p2=6.0&peso2=0.4&trabalho=10.0&pesoTrabalho=0.2"

echo ""
echo "=============================================================================="
echo "[TEST 6/6] OPTIONS /api/presenca (CORS Preflight Check)"
echo "Expected HTTP Status: 204 No Content"
echo "------------------------------------------------------------------------------"
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X OPTIONS "${BASE_URL}/api/presenca"

echo ""
echo "=============================================================================="
echo "               All Automated Endpoint Tests Completed!"
echo "=============================================================================="
