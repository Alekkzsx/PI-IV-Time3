@echo off
setlocal
cd /d "%~dp0"
title AGMRM - Setup e Orquestrador de Inicializacao (Windows)

echo ================================================================================
echo    AGMRM EDUCATIONAL PLATFORM -- SETUP E ORQUESTRADOR DE INICIALIZACAO
echo    Projeto Interdisciplinar IV - PI-IV Time 3 - PUC-Campinas 2026
echo ================================================================================
echo Iniciando orquestrador Windows via PowerShell...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0modules\setup.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo O setup encontrou um problema ou foi interrompido [Codigo: %ERRORLEVEL%].
    pause
)
