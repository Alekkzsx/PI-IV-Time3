@echo off
REM Desenvolvido por Guilherme Henrique Moreira
setlocal
cd /d "%~dp0"

if not exist "src\Main.java" (
  echo ERRO: execute este script dentro da pasta server do projeto.
  pause
  exit /b 1
)

set "JAVAC_CMD=javac"
where javac >nul 2>nul
if not "%ERRORLEVEL%"=="0" (
  for /d %%D in ("%APPDATA%\Antigravity IDE\User\globalStorage\pleiades.java-extension-pack-jdk\java\17\bin" "%APPDATA%\Code\User\globalStorage\pleiades.java-extension-pack-jdk\java\17\bin") do (
    if exist "%%~D\javac.exe" set "JAVAC_CMD=%%~D\javac.exe"
  )
)

if not exist "bin" mkdir "bin"
set "LISTA=%TEMP%\agmr_fontes_%RANDOM%.txt"
dir /s /b "src\*.java" > "%LISTA%"
"%JAVAC_CMD%" --release 8 -encoding UTF-8 -d "bin" @"%LISTA%" 2>nul
if not "%ERRORLEVEL%"=="0" (
  "%JAVAC_CMD%" -encoding UTF-8 -d "bin" @"%LISTA%"
)
set "ERRO=%ERRORLEVEL%"
del "%LISTA%" >nul 2>nul

if not "%ERRO%"=="0" (
  echo ERRO: falha na compilacao do servidor.
  pause
  exit /b %ERRO%
)

echo Iniciando servidor nativo AGMRM (Modulos Academicos, Videochamada e Sessao JWT)...
java -Dfile.encoding=UTF-8 -cp "bin" Main
pause
