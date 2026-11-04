# =============================================================================
# AGMRM - Console Interativo de Controle do Servidor Java SE (Porta 8080)
# =============================================================================
# Desenvolvido para o ecossistema AGMRM (PI-IV Time 3 - PUC-Campinas 2026)
# Suporta auto-recuperacao de porta, compilacao nativa e operacao multi-opcao
# =============================================================================

$Host.UI.RawUI.WindowTitle = "AGMRM - Painel de Controle Servidor Java (Porta 8080)"

# -----------------------------------------------------------------------------
# FUNCAO: Localizacao Dinamica e Resiliente da Raiz do Projeto
# -----------------------------------------------------------------------------
function Resolve-AGMRMProjectRoot {
    param ($StartPath = $PSScriptRoot)
    if (-not $StartPath) {
        $StartPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $curr = Resolve-Path $StartPath
    for ($i = 0; $i -lt 8; $i++) {
        $hasServer = Test-Path (Join-Path $curr "server")
        $hasBackend = Test-Path (Join-Path $curr "backend")
        $hasFrontend = Test-Path (Join-Path $curr "frontend")
        if ($hasServer -and $hasBackend -and $hasFrontend) {
            return $curr.Path
        }
        $parent = Split-Path -Parent $curr
        if (-not $parent -or $parent -eq $curr.Path) { break }
        $curr = Resolve-Path $parent
    }
    return (Resolve-Path "$StartPath\..\..").Path
}

$ProjectRoot = Resolve-AGMRMProjectRoot
$ServerDir = Join-Path $ProjectRoot "server"
$EnvFile = Join-Path $ProjectRoot ".env"
$BinDir = Join-Path $ServerDir "bin"
$LogFile = Join-Path $ServerDir "server.log"
$ErrorLogFile = Join-Path $ServerDir "server-error.log"

# Detecta compilador e runtime Java
function Get-JavaTools {
    $tools = @{ Javac = $null; Java = $null }
    
    # 1. Busca em caminhos conhecidos do Antigravity IDE, Code e JDKs locais
    $knownDirs = @(
        "$env:JAVA_HOME\bin",
        "$env:APPDATA\Antigravity IDE\User\globalStorage\pleiades.java-extension-pack-jdk\java\17\bin",
        "$env:APPDATA\Code\User\globalStorage\pleiades.java-extension-pack-jdk\java\17\bin",
        "C:\Program Files\Java\jdk-17*\bin",
        "C:\Program Files\Java\jdk-21*\bin",
        "C:\Program Files\Eclipse Adoptium\jdk-17*\bin",
        "C:\Program Files\Eclipse Adoptium\jdk-21*\bin",
        "C:\Program Files\Microsoft\jdk-17*\bin",
        "C:\Program Files\Microsoft\jdk-21*\bin"
    )
    foreach ($kd in $knownDirs) {
        $resolved = Resolve-Path $kd -ErrorAction SilentlyContinue
        if ($resolved) {
            $candJavac = Join-Path $resolved[0].Path "javac.exe"
            $candJava = Join-Path $resolved[0].Path "java.exe"
            if (-not $tools.Javac -and (Test-Path $candJavac)) { $tools.Javac = $candJavac }
            if (-not $tools.Java -and (Test-Path $candJava)) { $tools.Java = $candJava }
        }
    }
    
    # 2. Fallbacks no PATH
    if (-not $tools.Javac -and (Get-Command javac.exe -ErrorAction SilentlyContinue)) {
        $tools.Javac = (Get-Command javac.exe).Source
    }
    if (-not $tools.Java -and (Get-Command java.exe -ErrorAction SilentlyContinue)) {
        $tools.Java = (Get-Command java.exe).Source
    }
    
    # Se encontramos o javac, prioriza o java.exe no mesmo bin
    if ($tools.Javac) {
        $siblingJava = Join-Path (Split-Path -Parent $tools.Javac) "java.exe"
        if (Test-Path $siblingJava) {
            $tools.Java = $siblingJava
        }
    }
    
    if (-not $tools.Java) { $tools.Java = "java.exe" }
    if (-not $tools.Javac) { $tools.Javac = "javac.exe" }
    
    return $tools
}

$JavaTools = Get-JavaTools

# Mata processos que estejam escutando na porta 8080
function Stop-Port8080 {
    try {
        $conns = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            if ($c.OwningProcess -gt 0) {
                Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
    
    try {
        $lines = netstat -ano | Select-String ":8080\s+.*LISTENING\s+(\d+)"
        foreach ($line in $lines) {
            $pidToKill = [int]$line.Matches.Groups[1].Value
            if ($pidToKill -gt 0) {
                Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

# Compila as classes Java em server/src
function Invoke-JavaCompilation {
    Write-Host "[BUILD] Compilando fontes Java em '$ServerDir\src'..." -ForegroundColor Cyan
    if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }
    
    $srcFiles = Get-ChildItem -Path (Join-Path $ServerDir "src") -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
    if (-not $srcFiles) {
        Write-Host "[ERRO] Nenhum arquivo .java encontrado em $ServerDir\src" -ForegroundColor Red
        return $false
    }
    
    $tempList = Join-Path $env:TEMP ("agmrm_src_" + (Get-Random) + ".txt")
    [System.IO.File]::WriteAllLines($tempList, $srcFiles)
    
    $javacCmd = $JavaTools.Javac
    $process = Start-Process -FilePath $javacCmd -ArgumentList "--release", "8", "-encoding", "UTF-8", "-d", "`"$BinDir`"", "@`"$tempList`"" -NoNewWindow -Wait -PassThru
    Remove-Item $tempList -Force -ErrorAction SilentlyContinue
    
    if ($process.ExitCode -eq 0) {
        Write-Host "[BUILD] Compilacao concluida com sucesso em '$BinDir'." -ForegroundColor Green
        return $true
    } else {
        Write-Host "[BUILD] Tentando compilacao direta com codificacao UTF-8..." -ForegroundColor Yellow
        $tempList = Join-Path $env:TEMP ("agmrm_src_" + (Get-Random) + ".txt")
        [System.IO.File]::WriteAllLines($tempList, $srcFiles)
        $process2 = Start-Process -FilePath $javacCmd -ArgumentList "-encoding", "UTF-8", "-d", "`"$BinDir`"", "@`"$tempList`"" -NoNewWindow -Wait -PassThru
        Remove-Item $tempList -Force -ErrorAction SilentlyContinue
        return ($process2.ExitCode -eq 0)
    }
}

# Inicia o servidor em background
function Start-JavaServer {
    param ([bool]$Recompile = $true)
    
    Write-Host ""
    Write-Host ">>> Iniciando / Reiniciando Servidor Java AGMRM..." -ForegroundColor Yellow
    
    # Encerra qualquer processo ativo na porta 8080
    Stop-Port8080
    Start-Sleep -Milliseconds 600
    
    if ($Recompile) {
        $ok = Invoke-JavaCompilation
        if (-not $ok) {
            Write-Host "[FALHA] Nao foi possivel compilar os fontes. Abortando inicio." -ForegroundColor Red
            return
        }
    }
    
    # Inicia processo do servidor
    $javaCmd = $JavaTools.Java
    Write-Host "[EXEC] Executando Main na porta 8080 via $javaCmd..." -ForegroundColor Cyan
    
    # Limpa logs anteriores
    "" | Out-File -FilePath $LogFile -Force
    "" | Out-File -FilePath $ErrorLogFile -Force
    
    $global:ServerProc = Start-Process -FilePath $javaCmd `
        -ArgumentList "-Dfile.encoding=UTF-8", "-cp", "`"$BinDir`"", "Main" `
        -WorkingDirectory $ServerDir `
        -RedirectStandardOutput $LogFile `
        -RedirectStandardError $ErrorLogFile `
        -PassThru
    
    # Aguarda inicializacao
    $running = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 300
        try {
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/api/videocall/rooms" -TimeoutSec 1 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($resp -and $resp.StatusCode -eq 200) {
                $running = $true
                break
            }
        } catch {}
    }
    
    if ($running) {
        Write-Host "[SUCESSO] Servidor Java SE ATIVO e RESPONDENDO na porta 8080! (PID: $($global:ServerProc.Id))" -ForegroundColor Green
    } else {
        Write-Host "[AVISO] Servidor iniciado (PID: $($global:ServerProc.Id)), aguardando conclusao do handshake..." -ForegroundColor Yellow
    }
}

# Desliga o servidor
function Stop-JavaServer {
    Write-Host ""
    Write-Host ">>> Encerrando Servidor Java AGMRM..." -ForegroundColor Yellow
    Stop-Port8080
    if ($global:ServerProc -and -not $global:ServerProc.HasExited) {
        Stop-Process -Id $global:ServerProc.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Servidor Java finalizado. Porta 8080 liberada." -ForegroundColor Green
}

# Verifica status atual
function Get-ServerStatus {
    $status = @{ Online = $false; Pid = $null; LatencyMs = 0; Details = "Inativo" }
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/api/videocall/rooms" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        $sw.Stop()
        if ($resp.StatusCode -eq 200) {
            $status.Online = $true
            $status.LatencyMs = $sw.ElapsedMilliseconds
            $status.Details = "ONLINE (HTTP 200 OK)"
        }
    } catch {
        $status.Online = $false
        $status.Details = "OFFLINE"
    }
    
    try {
        $conns = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        if ($conns) {
            $status.Pid = $conns[0].OwningProcess
        }
    } catch {}
    
    return $status
}

# Executa testes nativos
function Run-NativeTests {
    Write-Host ""
    Write-Host ">>> Compilando e Executando Suite de Testes Nativos do Servidor..." -ForegroundColor Cyan
    
    $srcFiles = Get-ChildItem -Path (Join-Path $ServerDir "src") -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
    $testFiles = Get-ChildItem -Path (Join-Path $ServerDir "tests") -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
    $allFiles = $srcFiles + $testFiles
    
    $tempList = Join-Path $env:TEMP ("agmrm_tests_" + (Get-Random) + ".txt")
    [System.IO.File]::WriteAllLines($tempList, $allFiles)
    
    $javacCmd = $JavaTools.Javac
    $javaCmd = $JavaTools.Java
    
    $p = Start-Process -FilePath $javacCmd -ArgumentList "--release", "8", "-encoding", "UTF-8", "-d", "`"$BinDir`"", "@`"$tempList`"" -NoNewWindow -Wait -PassThru
    Remove-Item $tempList -Force -ErrorAction SilentlyContinue
    
    if ($p.ExitCode -ne 0) {
        Write-Host "[ERRO] Falha na compilacao dos testes." -ForegroundColor Red
        return
    }
    
    Write-Host "[EXEC] Executando SuiteTestesServidor..." -ForegroundColor Yellow
    & $javaCmd -Dfile.encoding=UTF-8 -cp $BinDir SuiteTestesServidor
}

# Exibe logs recentes
function Show-Logs {
    Write-Host ""
    Write-Host "=== ULTIMOS LOGS DO SERVIDOR ($LogFile) ===" -ForegroundColor Cyan
    if (Test-Path $LogFile) {
        $content = Get-Content $LogFile -Tail 30 -ErrorAction SilentlyContinue
        if ($content) {
            $content | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        } else {
            Write-Host "  (Arquivo de log vazio ou sem saida)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  (Nenhum log gerado ainda)" -ForegroundColor DarkGray
    }
    
    if (Test-Path $ErrorLogFile) {
        $errContent = Get-Content $ErrorLogFile -Tail 15 -ErrorAction SilentlyContinue
        if ($errContent -and $errContent.Trim()) {
            Write-Host "`n=== ERROS RECENTES ($ErrorLogFile) ===" -ForegroundColor Red
            $errContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
    }
}

# Exibe variaveis do .env mestre
function Show-MasterEnv {
    Write-Host ""
    Write-Host "=== VARIAVEIS DO .ENV MESTRE NA RAIZ ($EnvFile) ===" -ForegroundColor Cyan
    if (Test-Path $EnvFile) {
        Get-Content $EnvFile | Where-Object { $_ -and -not $_.StartsWith("#") } | ForEach-Object {
            $line = $_.Trim()
            if ($line.StartsWith("AUTH_JWT_SECRET") -or $line.StartsWith("JWT_SECRET") -or $line.StartsWith("SMTP_PASSWORD")) {
                $parts = $line -split "=", 2
                Write-Host "  $($parts[0]) = ******** (oculto por seguranca)" -ForegroundColor Yellow
            } else {
                Write-Host "  $line" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  [ERRO] Arquivo .env nao encontrado em $EnvFile" -ForegroundColor Red
    }
}

# Inicializacao automatica ao abrir o console
Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "         AGMRM - SERVIDOR HTTP & WEBSOCKET NATIVO JAVA SE (PORTA 8080)          " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Raiz do Projeto : $ProjectRoot" -ForegroundColor Gray
Write-Host " Compilador Java : $($JavaTools.Javac)" -ForegroundColor Gray
Write-Host " Runtime Java    : $($JavaTools.Java)" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

Start-JavaServer -Recompile $true

# Loop interativo do menu
while ($true) {
    $st = Get-ServerStatus
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    if ($st.Online) {
        Write-Host " STATUS: [ONLINE] | PID: $($st.Pid) | Porta: 8080 | Latencia: $($st.LatencyMs)ms" -ForegroundColor Green
    } else {
        Write-Host " STATUS: [OFFLINE] | Porta 8080 Livre | Servidor Java Parado" -ForegroundColor Red
    }
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [1] Iniciar / Reiniciar Servidor Java (Recompila e sobe na porta 8080)" -ForegroundColor White
    Write-Host " [2] Desligar / Parar Servidor Java (Libera a porta 8080)" -ForegroundColor White
    Write-Host " [3] Status e Diagnostico em Tempo Real (Testa endpoints)" -ForegroundColor White
    Write-Host " [4] Visualizar Logs do Servidor (server.log)" -ForegroundColor White
    Write-Host " [5] Recompilar Fontes Java (Sem reiniciar processo atual)" -ForegroundColor White
    Write-Host " [6] Executar Suite de Testes Nativos (7 suites sem JUnit)" -ForegroundColor White
    Write-Host " [7] Exibir Variaveis Carregadas do .env Mestre" -ForegroundColor White
    Write-Host " [8] Abrir Endpoint no Navegador (Healthcheck: /api/videocall/rooms)" -ForegroundColor White
    Write-Host " [9] Limpar Tela do Console" -ForegroundColor White
    Write-Host " [0] Encerrar Servidor e Fechar Console" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    
    $choice = Read-Host "Digite o numero da opcao desejada"
    
    switch ($choice.Trim()) {
        "1" { Start-JavaServer -Recompile $true }
        "2" { Stop-JavaServer }
        "3" {
            Write-Host "`n>>> Diagnostico de Endpoints:" -ForegroundColor Cyan
            $endpoints = @(
                "/api/videocall/rooms",
                "/api/teste-tipos",
                "/api/presenca",
                "/api/auth/session"
            )
            foreach ($ep in $endpoints) {
                try {
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8080$ep" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
                    $sw.Stop()
                    Write-Host "  [OK $($r.StatusCode)] http://127.0.0.1:8080$ep ($($sw.ElapsedMilliseconds)ms)" -ForegroundColor Green
                } catch {
                    $code = $_.Exception.Response.StatusCode.value__
                    if ($code) {
                        Write-Host "  [RES $code] http://127.0.0.1:8080$ep (Resposta controlada recebida)" -ForegroundColor Yellow
                    } else {
                        Write-Host "  [ERRO] http://127.0.0.1:8080$ep (Nao responde)" -ForegroundColor Red
                    }
                }
            }
        }
        "4" { Show-Logs }
        "5" { Invoke-JavaCompilation }
        "6" { Run-NativeTests }
        "7" { Show-MasterEnv }
        "8" {
            Start-Process "http://127.0.0.1:8080/api/videocall/rooms"
            Write-Host "[OK] Endpoint aberto no navegador padrao." -ForegroundColor Green
        }
        "9" { Clear-Host }
        "0" {
            Stop-JavaServer
            Write-Host "[SAIR] Console finalizado. Ate logo!" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            exit 0
        }
        default {
            Write-Host "[AVISO] Opcao invalida. Digite um numero de 0 a 9." -ForegroundColor Yellow
        }
    }
}
