# =============================================================================
# AGMRM Educational Platform - Setup e Orquestrador Automatizado Ultra-Robusto
# =============================================================================
# Desenvolvido para o ecossistema AGMRM (PI-IV Time 3 - PUC-Campinas 2026)
# Suporta auto-deteccao, auto-instalacao/reparo de dependencias e multi-terminal
# =============================================================================

[CmdletBinding()]
param (
    [switch]$SkipInstall,
    [switch]$NoLaunch,
    [string]$FlutterDevice
)

$Host.UI.RawUI.WindowTitle = "AGMRM - Setup e Orquestrador de Inicializacao"

# -----------------------------------------------------------------------------
# FUNCAO: Localizacao Dinamica e Resiliente da Raiz do Projeto
# -----------------------------------------------------------------------------
function Resolve-AGMRMProjectRoot {
    param ($StartPath = $PSScriptRoot)
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
$BackendDir = Join-Path $ProjectRoot "backend"
$FrontendDir = Join-Path $ProjectRoot "frontend"
$SecurityDir = Join-Path $ProjectRoot "security"
$ServerDir = Join-Path $ProjectRoot "server"
$EnvFile = Join-Path $ProjectRoot ".env"
$EnvExampleFile = Join-Path $ProjectRoot ".env-example"

# Localiza o script do console interativo Java em setup/ ou setup/modules/
$JavaConsoleScript = Join-Path $PSScriptRoot "java-server-console.ps1"
if (-not (Test-Path $JavaConsoleScript)) {
    $alt = Join-Path $PSScriptRoot "modules\java-server-console.ps1"
    if (Test-Path $alt) { $JavaConsoleScript = $alt }
}
if (-not (Test-Path $JavaConsoleScript)) {
    $alt2 = Join-Path $ProjectRoot ".github\setup\java-server-console.ps1"
    if (Test-Path $alt2) { $JavaConsoleScript = $alt2 }
}
if (-not (Test-Path $JavaConsoleScript)) {
    $alt3 = Join-Path $ProjectRoot ".github\setup\modules\java-server-console.ps1"
    if (Test-Path $alt3) { $JavaConsoleScript = $alt3 }
}

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "       AGMRM EDUCATIONAL PLATFORM - SETUP E ORQUESTRADOR AUTOMATIZADO           " -ForegroundColor Yellow
Write-Host "           Projeto Interdisciplinar IV - PI-IV Time 3 - PUC-Campinas            " -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Raiz do Projeto: $ProjectRoot" -ForegroundColor Gray
Write-Host " Data/Hora       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# FUNCAO: Atualiza variaveis de ambiente da sessao a partir do Registro
# -----------------------------------------------------------------------------
function Refresh-SessionEnvPath {
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$userPath;$machinePath;$env:Path"
    } catch {}
}

# -----------------------------------------------------------------------------
# 1. VERIFICACAO DE AMBIENTE E AUTO-REPARO DE DEPENDENCIAS
# -----------------------------------------------------------------------------
Write-Host "`n[ETAPA 1/4] Verificando dependencias essenciais do ambiente..." -ForegroundColor Cyan

$DependenciesOk = $true
$HasWinget = [bool](Get-Command winget.exe -ErrorAction SilentlyContinue)

# A. Git
$gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    # Busca em locais comuns do Windows
    $gitCommon = @(
        "C:\Program Files\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
        "C:\Git\cmd\git.exe",
        "C:\Program Files (x86)\Git\cmd\git.exe"
    )
    foreach ($gc in $gitCommon) {
        if (Test-Path $gc) {
            $gitDir = Split-Path -Parent $gc
            $env:Path = "$gitDir;$env:Path"
            $gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if ($gitCmd) {
    $gitVer = (git --version 2>$null)
    Write-Host "  [OK] Git instalado: $gitVer" -ForegroundColor Green
} else {
    Write-Host "  [FALHA] Git nao encontrado no PATH do sistema!" -ForegroundColor Red
    if ($HasWinget) {
        Write-Host "  [AUTO-REPARO] Deseja que o setup instale o Git automaticamente via winget? (S/N)" -ForegroundColor Yellow
        $resp = Read-Host
        if ($resp.Trim().ToUpper() -eq "S") {
            Write-Host "  Instalando Git via winget..." -ForegroundColor Cyan
            winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
            Refresh-SessionEnvPath
            if (Get-Command git.exe -ErrorAction SilentlyContinue) {
                Write-Host "  [OK] Git instalado e configurado na sessao!" -ForegroundColor Green
            } else {
                $DependenciesOk = $false
            }
        } else {
            $DependenciesOk = $false
        }
    } else {
        $DependenciesOk = $false
    }
}

# B. Node.js
$nodeCmd = Get-Command node.exe -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    $nodeCommon = @(
        "C:\Program Files\nodejs\node.exe",
        "C:\node*\node.exe",
        "$env:LOCALAPPDATA\Programs\node*\node.exe",
        "$env:ProgramFiles\nodejs\node.exe"
    )
    foreach ($nc in $nodeCommon) {
        $resolved = Resolve-Path $nc -ErrorAction SilentlyContinue
        if ($resolved) {
            $nodeDir = Split-Path -Parent $resolved.Path
            $env:Path = "$nodeDir;$env:Path"
            $nodeCmd = Get-Command node.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if ($nodeCmd) {
    $nodeVer = (node -v 2>$null)
    $nodeMajor = [int]($nodeVer -replace '^v(\d+)\..*$', '$1')
    if ($nodeMajor -ge 20) {
        Write-Host "  [OK] Node.js instalado: $nodeVer (Versao recomendada >= 20.x)" -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Node.js $nodeVer detectado. Recomenda-se versao 20.x ou superior." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [FALHA] Node.js nao encontrado no PATH!" -ForegroundColor Red
    if ($HasWinget) {
        Write-Host "  [AUTO-REPARO] Deseja instalar Node.js LTS automaticamente via winget? (S/N)" -ForegroundColor Yellow
        $resp = Read-Host
        if ($resp.Trim().ToUpper() -eq "S") {
            Write-Host "  Instalando Node.js LTS via winget..." -ForegroundColor Cyan
            winget install --id OpenJS.NodeJS.LTS -e --source winget --accept-source-agreements --accept-package-agreements
            Refresh-SessionEnvPath
            if (Get-Command node.exe -ErrorAction SilentlyContinue) {
                Write-Host "  [OK] Node.js instalado com sucesso!" -ForegroundColor Green
            } else {
                $DependenciesOk = $false
            }
        } else {
            $DependenciesOk = $false
        }
    } else {
        $DependenciesOk = $false
    }
}

# C. npm
if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
    $npmVer = (npm -v 2>$null)
    Write-Host "  [OK] npm instalado: v$npmVer" -ForegroundColor Green
} else {
    Write-Host "  [FALHA] npm nao encontrado!" -ForegroundColor Red
    $DependenciesOk = $false
}

# D. Java JDK e Javac
$JavacPath = $null
$JavaPath = $null

$knownJdkDirs = @(
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

foreach ($k in $knownJdkDirs) {
    $res = Resolve-Path $k -ErrorAction SilentlyContinue
    if ($res) {
        $candJavac = Join-Path $res[0].Path "javac.exe"
        $candJava = Join-Path $res[0].Path "java.exe"
        if (-not $JavacPath -and (Test-Path $candJavac)) { $JavacPath = $candJavac }
        if (-not $JavaPath -and (Test-Path $candJava)) { $JavaPath = $candJava }
    }
}

if (-not $JavacPath -and (Get-Command javac.exe -ErrorAction SilentlyContinue)) {
    $JavacPath = (Get-Command javac.exe).Source
}
if (-not $JavaPath -and (Get-Command java.exe -ErrorAction SilentlyContinue)) {
    $JavaPath = (Get-Command java.exe).Source
}

if ($JavacPath) {
    $siblingJava = Join-Path (Split-Path -Parent $JavacPath) "java.exe"
    if (Test-Path $siblingJava) {
        $JavaPath = $siblingJava
    }
    # Garante no PATH da sessao
    $jdkBin = Split-Path -Parent $JavacPath
    $env:Path = "$jdkBin;$env:Path"
    Write-Host "  [OK] Java JDK Compilador detectado: $JavacPath" -ForegroundColor Green
    Write-Host "  [OK] Java Runtime emparelhado: $JavaPath" -ForegroundColor Green
} else {
    Write-Host "  [FALHA] Compilador javac nao encontrado!" -ForegroundColor Red
    if ($HasWinget) {
        Write-Host "  [AUTO-REPARO] Deseja instalar OpenJDK 17 (Eclipse Temurin) via winget? (S/N)" -ForegroundColor Yellow
        $resp = Read-Host
        if ($resp.Trim().ToUpper() -eq "S") {
            Write-Host "  Instalando Eclipse Temurin 17 JDK via winget..." -ForegroundColor Cyan
            winget install --id EclipseAdoptium.Temurin.17.JDK -e --source winget --accept-source-agreements --accept-package-agreements
            Refresh-SessionEnvPath
            if (Get-Command javac.exe -ErrorAction SilentlyContinue) {
                $JavacPath = (Get-Command javac.exe).Source
                $JavaPath = (Get-Command java.exe).Source
                Write-Host "  [OK] JDK 17 instalado com sucesso!" -ForegroundColor Green
            } else {
                $DependenciesOk = $false
            }
        } else {
            $DependenciesOk = $false
        }
    } else {
        $DependenciesOk = $false
    }
}

# E. Flutter SDK
$FlutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
if (-not $FlutterCmd) {
    $FlutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
}

if (-not $FlutterCmd) {
    # Busca em locais padroes conhecidos onde usuarios costumam extrair o Flutter
    $flutterCandidates = @(
        "C:\src\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "D:\src\flutter\bin\flutter.bat",
        "D:\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:USERPROFILE\src\flutter\bin\flutter.bat",
        "C:\tools\flutter\bin\flutter.bat"
    )
    foreach ($fc in $flutterCandidates) {
        if (Test-Path $fc) {
            $flutterBinDir = Split-Path -Parent $fc
            $env:Path = "$flutterBinDir;$env:Path"
            $FlutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
            Write-Host "  [AUTO-CONFIG] Flutter localizado em '$fc' e adicionado ao PATH da sessao." -ForegroundColor Cyan
            break
        }
    }
}

if ($FlutterCmd) {
    $flutterVer = (flutter --version 2>$null | Select-Object -First 1)
    Write-Host "  [OK] Flutter SDK detectado: $flutterVer" -ForegroundColor Green
} else {
    Write-Host "  [FALHA] Flutter SDK nao encontrado no PATH nem nos diretorios usuais!" -ForegroundColor Red
    if ($gitCmd) {
        Write-Host "  [AUTO-INSTALACAO] Deseja clonar o Flutter SDK stable automaticamente via Git? (S/N)" -ForegroundColor Yellow
        $resp = Read-Host
        if ($resp.Trim().ToUpper() -eq "S") {
            New-Item -ItemType Directory -Path "C:\src" -Force -ErrorAction SilentlyContinue | Out-Null
            $cloneTarget = if (Test-Path "C:\src") { "C:\src\flutter" } else { "$env:LOCALAPPDATA\flutter" }
            Write-Host "  Clonando Flutter stable em '$cloneTarget'..." -ForegroundColor Cyan
            & git clone https://github.com/flutter/flutter.git -b stable $cloneTarget
            if (Test-Path "$cloneTarget\bin\flutter.bat") {
                $flutterBin = "$cloneTarget\bin"
                $env:Path = "$flutterBin;$env:Path"
                try {
                    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
                    if ($userPath -notmatch [regex]::Escape($flutterBin)) {
                        [System.Environment]::SetEnvironmentVariable("Path", "$flutterBin;$userPath", "User")
                    }
                } catch {}
                $FlutterCmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
                Write-Host "  [OK] Flutter SDK instalado e configurado no PATH com sucesso!" -ForegroundColor Green
            } else {
                $DependenciesOk = $false
            }
        } else {
            $DependenciesOk = $false
        }
    } else {
        $DependenciesOk = $false
    }
}

# F. Deteccao de Dispositivo Flutter (Windows Desktop vs Web Chrome)
$TargetDevice = "chrome"
$hasDevMode = $false
try {
    $regVal = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    if ($regVal -eq 1) { $hasDevMode = $true }
} catch {}

if ($FlutterDevice) {
    $TargetDevice = $FlutterDevice
} elseif ($FlutterCmd) {
    try {
        $devs = (flutter devices 2>$null | Out-String)
        # Windows desktop requer Developer Mode (symlinks) e Visual Studio C++
        if ($hasDevMode -and $devs -match "windows\s+•\s+windows") {
            $TargetDevice = "windows"
            Write-Host "  [OK] Dispositivo de execucao: Windows Desktop nativo habilitado." -ForegroundColor Green
        } elseif ($devs -match "chrome\s+•\s+chrome") {
            $TargetDevice = "chrome"
            Write-Host "  [OK] Dispositivo de execucao: Google Chrome (Web - Inicializacao rapida sem necessidade de compilador C++)." -ForegroundColor Green
        } elseif ($devs -match "edge\s+•\s+edge") {
            $TargetDevice = "edge"
            Write-Host "  [OK] Dispositivo de execucao: Microsoft Edge (Web)." -ForegroundColor Green
        } else {
            $TargetDevice = "chrome"
        }
    } catch {
        $TargetDevice = "chrome"
    }
}

# G. Arquivo de Configuracao Mestre .env
if (Test-Path $EnvFile) {
    Write-Host "  [OK] Arquivo mestre .env presente na raiz do projeto." -ForegroundColor Green
} else {
    if (Test-Path $EnvExampleFile) {
        Write-Host "  [CRIANDO] .env ausente. Copiando automaticamente de .env-example..." -ForegroundColor Yellow
        Copy-Item -Path $EnvExampleFile -Destination $EnvFile -Force
        Write-Host "  [OK] Arquivo .env criado a partir de .env-example na raiz." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Arquivo .env e .env-example nao foram encontrados na raiz!" -ForegroundColor Red
        $DependenciesOk = $false
    }
}

if (-not $DependenciesOk) {
    Write-Host "`n[AVISO CRITICO] Algumas dependencias necessitam de atencao antes da inicializacao." -ForegroundColor Red
    $ans = Read-Host "Deseja tentar prosseguir mesmo assim? (S/N)"
    if ($ans.Trim().ToUpper() -ne "S") {
        Write-Host "Setup cancelado pelo usuario." -ForegroundColor Gray
        exit 1
    }
}

# -----------------------------------------------------------------------------
# 2. ATUALIZACAO E INSTALACAO DE DEPENDENCIAS CONFORME O AMBIENTE
# -----------------------------------------------------------------------------
if (-not $SkipInstall) {
    Write-Host "`n[ETAPA 2/4] Atualizando e instalando dependencias de todos os modulos..." -ForegroundColor Cyan
    
    # A. Backend (Node / npm)
    Write-Host "`n  -> [backend/] Executando 'npm install'..." -ForegroundColor Yellow
    Push-Location $BackendDir
    try {
        & npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Dependencias do backend TypeScript atualizadas com sucesso." -ForegroundColor Green
        } else {
            Write-Host "  [AVISO] 'npm install' retornou codigo $LASTEXITCODE." -ForegroundColor Yellow
        }
    } finally {
        Pop-Location
    }
    
    # B. Security (Flutter pub get)
    if ($FlutterCmd) {
        Write-Host "`n  -> [security/] Executando 'flutter pub get' no modulo de ciberdefesa..." -ForegroundColor Yellow
        Push-Location $SecurityDir
        try {
            & flutter pub get
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Dependencias do modulo agmrm_security atualizadas com sucesso." -ForegroundColor Green
            } else {
                Write-Host "  [AVISO] 'flutter pub get' em security/ retornou codigo $LASTEXITCODE." -ForegroundColor Yellow
            }
        } finally {
            Pop-Location
        }
        
        # C. Frontend (Flutter pub get)
        Write-Host "`n  -> [frontend/] Executando 'flutter pub get' no aplicativo multiplataforma..." -ForegroundColor Yellow
        Push-Location $FrontendDir
        try {
            & flutter pub get
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Dependencias do frontend Flutter atualizadas com sucesso." -ForegroundColor Green
            } else {
                Write-Host "  [AVISO] 'flutter pub get' em frontend/ retornou codigo $LASTEXITCODE." -ForegroundColor Yellow
            }
        } finally {
            Pop-Location
        }
    }
    
    # D. Server Java (Compilacao das classes)
    Write-Host "`n  -> [server/] Compilando classes Java nativas para bin/..." -ForegroundColor Yellow
    $BinDir = Join-Path $ServerDir "bin"
    if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }
    
    $srcFiles = Get-ChildItem -Path (Join-Path $ServerDir "src") -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
    $tempList = Join-Path $env:TEMP ("agmrm_setup_src_" + (Get-Random) + ".txt")
    [System.IO.File]::WriteAllLines($tempList, $srcFiles)
    
    $javacToUse = if ($JavacPath) { $JavacPath } else { "javac.exe" }
    $p = Start-Process -FilePath $javacToUse -ArgumentList "--release", "8", "-encoding", "UTF-8", "-d", "`"$BinDir`"", "@`"$tempList`"" -NoNewWindow -Wait -PassThru
    Remove-Item $tempList -Force -ErrorAction SilentlyContinue
    
    if ($p.ExitCode -eq 0) {
        Write-Host "  [OK] Modulo server/ compilado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Tentando compilacao direta sem flag --release..." -ForegroundColor Yellow
        $tempList = Join-Path $env:TEMP ("agmrm_setup_src_" + (Get-Random) + ".txt")
        [System.IO.File]::WriteAllLines($tempList, $srcFiles)
        $p2 = Start-Process -FilePath $javacToUse -ArgumentList "-encoding", "UTF-8", "-d", "`"$BinDir`"", "@`"$tempList`"" -NoNewWindow -Wait -PassThru
        Remove-Item $tempList -Force -ErrorAction SilentlyContinue
        if ($p2.ExitCode -eq 0) {
            Write-Host "  [OK] Modulo server/ compilado com sucesso." -ForegroundColor Green
        } else {
            Write-Host "  [AVISO] Nao foi possivel compilar server/ nesta etapa. O console interativo tentara novamente." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`n[ETAPA 2/4] Instalacao de dependencias ignorada conforme parametro -SkipInstall." -ForegroundColor DarkGray
}

if ($NoLaunch) {
    Write-Host "`n[CONCLUIDO] Setup finalizado sem inicializacao de janelas (-NoLaunch ativo)." -ForegroundColor Green
    exit 0
}

# -----------------------------------------------------------------------------
# 3. LIBERACAO DE PORTAS ANTES DE ABRIR OS SERVICOS
# -----------------------------------------------------------------------------
function Stop-PortListener([int]$port) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            if ($c.OwningProcess -gt 0) {
                Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}
Stop-PortListener 8080
Stop-PortListener 3001

# -----------------------------------------------------------------------------
# 4. INICIALIZACAO DOS SERVICOS EM JANELAS DE TERMINAL SEPARADAS
# -----------------------------------------------------------------------------
Write-Host "`n[ETAPA 3/4] Inicializando os servicos em abas/janelas dedicadas de terminal..." -ForegroundColor Cyan

# 1. ABA/JANELA SEPARADA: Servidor Java SE Interativo (Porta 8080)
Write-Host "  -> Abrindo Janela 1: Servidor Java SE (Console Interativo com Menu: Reiniciar, Desligar, Status...)" -ForegroundColor Yellow
$javaArgs = @('/k', "title AGMRM - Servidor Java SE (Porta 8080) & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$JavaConsoleScript`"")
Start-Process "cmd.exe" -ArgumentList $javaArgs

Start-Sleep -Seconds 1

# 2. ABA/JANELA SEPARADA: Backend TypeScript API (Porta 3001)
Write-Host "  -> Abrindo Janela 2: Backend API TypeScript (Express + MongoDB na Porta 3001)" -ForegroundColor Yellow
$backendArgs = @('/k', "title AGMRM - Backend API TypeScript (Porta 3001) & cd /d `"$BackendDir`" & npm run dev")
Start-Process "cmd.exe" -ArgumentList $backendArgs

Start-Sleep -Seconds 1

# 3. ABA/JANELA SEPARADA: Frontend Flutter App
Write-Host "  -> Abrindo Janela 3: Frontend Flutter (Executando flutter run -d $TargetDevice)" -ForegroundColor Yellow
$frontendArgs = @('/k', "title AGMRM - Frontend Flutter ($TargetDevice) & cd /d `"$FrontendDir`" & flutter run -d $TargetDevice || flutter run -d chrome")
Start-Process "cmd.exe" -ArgumentList $frontendArgs

# -----------------------------------------------------------------------------
# 5. RESUMO DOS SERVICOS E CONCLUSAO
# -----------------------------------------------------------------------------
Write-Host "`n[ETAPA 4/4] Resumo do Ecossistema AGMRM em Execucao:" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " [JANELA 1] SERVIDOR JAVA SE (Porta 8080):" -ForegroundColor Green
Write-Host "            - Console interativo aberto em janela dedicada." -ForegroundColor Gray
Write-Host "            - Opcoes disponiveis: 1 = Reiniciar, 2 = Desligar, 3 = Status, 4 = Logs..." -ForegroundColor Gray
Write-Host "            - Healthcheck: http://127.0.0.1:8080/api/videocall/rooms" -ForegroundColor Gray
Write-Host ""
Write-Host " [JANELA 2] BACKEND API TYPESCRIPT (Porta 3001):" -ForegroundColor Green
Write-Host "            - Executando 'npm run dev' em janela separada." -ForegroundColor Gray
Write-Host "            - Healthcheck: http://127.0.0.1:3001/health" -ForegroundColor Gray
Write-Host ""
Write-Host " [JANELA 3] FRONTEND FLUTTER ($TargetDevice):" -ForegroundColor Green
Write-Host "            - Executando 'flutter run -d $TargetDevice' em janela separada." -ForegroundColor Gray
Write-Host "            - Atalhos no terminal do Flutter: 'r' = Hot Reload, 'R' = Hot Restart." -ForegroundColor Gray
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "`n[SUCESSO] Todo o ambiente do projeto AGMRM foi verificado, atualizado e iniciado!" -ForegroundColor Green
Write-Host "Este terminal pode ser mantido ou fechado sem interromper os servicos ativos.`n" -ForegroundColor Gray
