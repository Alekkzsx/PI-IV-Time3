@echo off
setlocal
cd /d "%~dp0"
title AGMRM - Painel de Controle Servidor Java (Porta 8080)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0java-server-console.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Ocorreu um erro ao executar o console do servidor Java.
    pause
)

