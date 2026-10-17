@echo off
REM Desenvolvido por Guilherme Henrique Moreira
setlocal
cd /d "%~dp0.."
if not exist "backend\src\server\ServidorHttpNativo.java" (
  echo ERRO: execute este script dentro da pasta server do projeto.
  pause
  exit /b 1
)
if not exist "backend\bin" mkdir "backend\bin"
set "LISTA=%TEMP%\agmr_fontes_%RANDOM%.txt"
dir /s /b "backend\src\*.java" > "%LISTA%"
javac -encoding UTF-8 -d "backend\bin" @"%LISTA%"
set "ERRO=%ERRORLEVEL%"
del "%LISTA%" >nul 2>nul
if not "%ERRO%"=="0" (
  echo ERRO: falha na compilacao.
  pause
  exit /b %ERRO%
)
echo Iniciando servidor AGMRM...
java -cp "backend\bin" server.ServidorHttpNativo
pause
