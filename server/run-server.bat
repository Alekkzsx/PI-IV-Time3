@echo off
REM Desenvolvido por Guilherme Henrique Moreira
setlocal
cd /d "%~dp0"

if not exist "src\main\Main.java" (
  echo ERRO: execute este script dentro da pasta server do projeto.
  pause
  exit /b 1
)

if not exist "bin" mkdir "bin"
set "LISTA=%TEMP%\agmr_fontes_%RANDOM%.txt"
dir /s /b "src\*.java" > "%LISTA%"
javac -encoding UTF-8 -d "bin" @"%LISTA%"
set "ERRO=%ERRORLEVEL%"
del "%LISTA%" >nul 2>nul

if not "%ERRO%"=="0" (
  echo ERRO: falha na compilacao do servidor.
  pause
  exit /b %ERRO%
)

echo Iniciando servidor nativo AGMRM (Modulos Academicos e Videochamada)...
java -cp "bin" main.Main
pause
