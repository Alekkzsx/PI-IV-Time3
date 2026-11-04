# AGMRM — Setup Automatizado & Orquestrador de Inicialização

> **Módulo de Infraestrutura & Automação**: `.github/setup/`  
> **Plataforma Educacional Integrada (AGMRM)** — *PI-IV Time 3 (PUC-Campinas 2026)*

Este diretório contém os scripts de setup automatizado completo e inicialização multi-janela para desenvolvedores e avaliadores do projeto.

---

## 📁 Estrutura do Módulo

```text
.github/setup/
├── setup.bat                # Inicializador universal Windows em lote (duplo clique)
├── setup.ps1                # Orquestrador mestre em PowerShell (verificação, dependências e abertura de janelas)
├── java-server-console.bat  # Inicializador em lote do console interativo Java
├── java-server-console.ps1  # Console interativo do Servidor Java SE (com menu: iniciar, reiniciar, desligar...)
└── README.md                # Este guia explicativo
```

---

## 🚀 Como Executar

### Opção 1: Via Duplo Clique (Windows Explorer)
Basta clicar duas vezes em **`setup.bat`**.

### Opção 2: Via Terminal (PowerShell ou CMD)
```powershell
# A partir da raiz do repositório:
.\.github\setup\setup.bat

# Ou diretamente via PowerShell:
powershell -ExecutionPolicy Bypass -File .\.github\setup\setup.ps1
```

---

## ⚙️ O que o Setup faz Automaticamente:

### 1. Verificação de Dependências do Ambiente
Testa e reporta o status de:
- **Git**
- **Node.js** ($\ge$ 20.x) e **npm**
- **Java JDK** (`javac` e `java` $\ge$ 8 / recomendado 17+) com auto-detecção em IDEs e diretórios padrão do sistema
- **Flutter SDK**
- **Arquivo Mestre `.env`**: Verifica se o arquivo `.env` existe na raiz do projeto; se não existir, cria-o automaticamente a partir do template `.env-example`.

### 2. Atualização e Instalação de Dependências
- `backend/`: Executa `npm install`.
- `security/`: Executa `flutter pub get`.
- `frontend/`: Executa `flutter pub get`.
- `server/`: Compila os fontes Java nativos para `server/bin/`.

### 3. Abertura de 3 Janelas / Abas Separadas de Terminal:

1. **Janela 1 — Servidor Java SE Nativo (Porta 8080)**:
   Abre o console interativo com menu em tempo real:
   - **`[1]`**: Iniciar / Reiniciar Servidor Java (recompila e sobe o processo)
   - **`[2]`**: Desligar / Parar Servidor Java (libera a porta 8080)
   - **`[3]`**: Status e Diagnóstico em Tempo Real (testa `/api/videocall/rooms`, `/api/teste-tipos`, `/api/presenca`, etc.)
   - **`[4]`**: Visualizar Logs Recentes do Servidor (`server.log`)
   - **`[5]`**: Recompilar Fontes Java
   - **`[6]`**: Executar as 7 Suítes de Testes Nativos do Servidor
   - **`[7]`**: Exibir Variáveis Carregadas do `.env` Mestre
   - **`[8]`**: Abrir Endpoint no Navegador
   - **`[0]`**: Encerrar Servidor e Fechar Console

2. **Janela 2 — Backend API TypeScript (Porta 3001)**:
   Abre um terminal dedicado executando `npm run dev` na pasta `backend/`, mantendo os logs da API Express e a conexão com o MongoDB Atlas visíveis.

3. **Janela 3 — Frontend Flutter (Windows Desktop)**:
   Abre um terminal dedicado executando `flutter run -d windows` na pasta `frontend/`, permitindo uso direto do Hot Reload (`r`) e Hot Restart (`R`).

---

## 🛠️ Parâmetros Opcionais (`setup.ps1`)

- **`-SkipInstall`**: Pula a etapa de instalação/atualização de dependências (`npm install` e `flutter pub get`) e vai direto para a abertura dos serviços:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\.github\setup\setup.ps1 -SkipInstall
  ```
- **`-NoLaunch`**: Apenas verifica o ambiente e instala/atualiza as dependências, sem abrir as janelas dos serviços:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\.github\setup\setup.ps1 -NoLaunch
  ```

