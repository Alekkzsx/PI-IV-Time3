@echo off
setlocal enabledelayedexpansion

echo ==============================================================================
echo        AGMRM - Academic Portal: Automated API Verification Suite
echo                  Target: http://localhost:8080
echo ==============================================================================

set "BASE_URL=http://localhost:8080"

where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'curl' command-line tool not found. Please install curl or use Windows 10/11 built-in curl.
    exit /b 1
)

echo.
echo ==============================================================================
echo [TEST 1/6] POST /api/teste-tipos (Primitive Types Parsing)
echo Payload: texto=Calculo1^&inteiro=42^&flutuante=7.5^&duplo=99.99^&caractere=A
echo Expected Response: OK - Tipos Processados: [Calculo1, 42, 7.5, 99.99, A]
echo ------------------------------------------------------------------------------
curl -s -w "\n[HTTP Status: %%{http_code}]\n" -X POST "%BASE_URL%/api/teste-tipos" -d "texto=Calculo1&inteiro=42&flutuante=7.5&duplo=99.99&caractere=A"

echo.
echo ==============================================================================
echo [TEST 2/6] POST /api/presenca (Attendance Calculation: 50 min / 60 min)
echo Payload: minutosAssistidos=50^&duracaoTotal=60 (83.33%% attendance)
echo Expected Response: Resultado Presenca: PRESENCA_INTEGRAL (83%%)
echo ------------------------------------------------------------------------------
curl -s -w "\n[HTTP Status: %%{http_code}]\n" -X POST "%BASE_URL%/api/presenca" -d "minutosAssistidos=50&duracaoTotal=60"

echo.
echo ==============================================================================
echo [TEST 3/6] POST /api/presenca (Teacher Manual Override)
echo Payload: statusManual=JUSTIFICADO
echo Expected Response: Resultado Presenca: JUSTIFICADO (Ajuste Manual do Professor)
echo ------------------------------------------------------------------------------
curl -s -w "\n[HTTP Status: %%{http_code}]\n" -X POST "%BASE_URL%/api/presenca" -d "statusManual=JUSTIFICADO"

echo.
echo ==============================================================================
echo [TEST 4/6] POST /api/tarefas/calcular-nota (Late Submission Penalty: 1 Day Overdue)
echo Payload: diasAtraso=1^&notaBase=10.0 (20%% penalty)
echo Expected Response: Nota Maxima Permitida: 8.0
echo ------------------------------------------------------------------------------
curl -s -w "\n[HTTP Status: %%{http_code}]\n" -X POST "%BASE_URL%/api/tarefas/calcular-nota" -d "diasAtraso=1&notaBase=10.0"

echo.
echo ==============================================================================
echo [TEST 5/6] POST /api/notas/boletim (Weighted Average Report Card)
echo Payload: p1=8.0 (w=0.4), p2=6.0 (w=0.4), trabalho=10.0 (w=0.2)
echo Calculation: (8.0*0.4 + 6.0*0.4 + 10.0*0.2) = 3.2 + 2.4 + 2.0 = 7.6
echo Expected Response: Media Final: 7.6 ^| Status: APROVADO
echo ------------------------------------------------------------------------------
curl -s -w "\n[HTTP Status: %%{http_code}]\n" -X POST "%BASE_URL%/api/notas/boletim" -d "p1=8.0&peso1=0.4&p2=6.0&peso2=0.4&trabalho=10.0&pesoTrabalho=0.2"

echo.
echo ==============================================================================
echo [TEST 6/6] OPTIONS /api/presenca (CORS Preflight Verification)
echo Expected HTTP Status: 204 No Content
echo ------------------------------------------------------------------------------
curl -s -w "\n[HTTP Status: %%{http_code}]\n" -X OPTIONS "%BASE_URL%/api/presenca"

echo.
echo ==============================================================================
echo               All Automated Endpoint Tests Dispatched!
echo ==============================================================================
endlocal
