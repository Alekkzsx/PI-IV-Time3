@echo off
setlocal enabledelayedexpansion

echo ==============================================================================
echo        AGMRM - Academic Portal: Native Java HTTP Server (Port 8080)
echo ==============================================================================

set "SERVER_DIR=%~dp0"
set "BIN_DIR=%SERVER_DIR%bin"
set "SRC_FILE=%SERVER_DIR%..\backend\src\ServidorHttpNativo.java"

echo [1/3] Validating Java Development Kit (JDK 17+) environment...
where javac >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'javac' compiler was not found in your PATH.
    echo Please install JDK 17 or higher and ensure JAVA_HOME is added to PATH.
    echo Example: set PATH=%%JAVA_HOME%%\bin;%%PATH%%
    exit /b 1
)

where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 'java' runtime was not found in your PATH.
    echo Please ensure Java 17+ is installed and configured in PATH.
    exit /b 1
)

if not exist "%BIN_DIR%" (
    echo [2/3] Initializing output directory: "%BIN_DIR%"
    mkdir "%BIN_DIR%"
) else (
    echo [2/3] Using output directory: "%BIN_DIR%"
)

if not exist "%SRC_FILE%" (
    echo [ERROR] Source file not found at: "%SRC_FILE%"
    exit /b 1
)

echo [3/3] Compiling ServidorHttpNativo.java with UTF-8 encoding...
javac -encoding UTF-8 -d "%BIN_DIR%" "%SRC_FILE%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Compilation failed with error code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

echo.
echo ==============================================================================
echo Compilation successful. Starting HTTP Server on port 8080...
echo Press Ctrl+C to terminate the server.
echo ==============================================================================
echo.

java -cp "%BIN_DIR%" ServidorHttpNativo

endlocal
