# Server Infrastructure Module — AGMRM Academic Portal

## 1. Overview & Architecture

The `server` module provides the operational runtime infrastructure, startup automation, port management, and automated verification suites for the **AGMRM - Portal Acadêmico** HTTP backend.

### Architectural Separation
- **`backend/` (Domain Logic & Contracts)**: Houses the Java application source code (`ServidorHttpNativo.java`), API schemas, and mathematical calculations.
- **`server/` (Runtime & Operations)**: Manages socket bindings, compilation output (`server/bin/`), cross-platform lifecycle scripts (`run-server.bat`, `run-server.sh`), runtime configuration (`server.properties`), and automated test runners (`test-server.bat`, `test-server.sh`).

```
c:\Users\24802449\Documents\Github\PI-IV-Time3/
├── backend/
│   ├── README.md               # API contracts & business logic
│   ├── SECURITY.md             # Input bounds & RBAC specifications
│   └── src/
│       ├── ServidorHttpNativo.java  # Native Java HTTP service
│       └── testeServidor.txt        # Reference testing commands
└── server/
    ├── README.md               # Infrastructure documentation (this file)
    ├── SECURITY.md             # Network hardening & DoS mitigations
    ├── server.properties       # Port 8080, host & CORS configuration
    ├── run-server.bat          # Windows compilation and launch script
    ├── run-server.sh           # Linux/macOS compilation and launch script
    ├── test-server.bat         # Windows automated curl test suite
    ├── test-server.sh          # Linux/macOS automated curl test suite
    └── bin/                    # Compiled Java bytecode (.class files)
```

---

## 2. Server Runtime & Socket Lifecycle

### 2.1 Core Components
The native HTTP server relies on the Java Standard Edition library `com.sun.net.httpserver.HttpServer`:
- **Socket Binding**:
  ```java
  int porta = 8080;
  HttpServer server = HttpServer.create(new InetSocketAddress(porta), 0);
  ```
  The server opens a listening TCP socket on port `8080`. The second argument `0` delegates the TCP backlog queue length to the system default (typically 50 connections).
- **Executor & Threading Model**:
  ```java
  server.setExecutor(null);
  ```
  Passing `null` directs `HttpServer` to use the default executor, which processes requests synchronously on the dispatcher thread. For multi-threaded production scaling, a bounded thread pool can be provided:
  ```java
  server.setExecutor(Executors.newFixedThreadPool(16));
  ```
- **Context Routing**:
  The server routes incoming requests to dedicated `HttpHandler` implementations:
  - `/api/teste-tipos` -> `TesteTiposHandler`
  - `/api/presenca` -> `PresencaHandler`
  - `/api/tarefas/calcular-nota` -> `TarefasHandler`
  - `/api/notas/boletim` -> `BoletimHandler`

---

## 3. Compilation & Execution Guide

### 3.1 Prerequisites
- **JDK 17+** (Java Development Kit) installed.
- `javac` and `java` binaries accessible in system `PATH`.
- Verified via:
  ```bash
  javac -version
  java -version
  ```

### 3.2 Running on Windows
Execute the automated batch launcher:
```cmd
server\run-server.bat
```
What the script does:
1. Validates that `javac` and `java` are available in `PATH`.
2. Creates the `server\bin\` output directory if missing.
3. Compiles `..\backend\src\ServidorHttpNativo.java` with UTF-8 encoding into `server\bin\`.
4. Boots the compiled class `ServidorHttpNativo` on port 8080.
5. Displays startup banner:
   ```text
   ==================================================
      SERVIDOR HTTP NATIVO INICIADO COM SUCESSO!     
      Escutando na porta: 8080
   ==================================================
   ```

### 3.3 Running on Linux / macOS
Grant execution permission and run the shell script:
```bash
chmod +x server/run-server.sh server/test-server.sh
./server/run-server.sh
```

---

## 4. Port 8080 Management & Troubleshooting

### 4.1 Port Conflicts (EADDRINUSE)
If another process is occupying port 8080, `HttpServer.create` throws `java.net.BindException: Address already in use`.

**Identifying the conflicting process**:
- **Windows**:
  ```cmd
  netstat -ano | findstr :8080
  taskkill /PID <PID> /F
  ```
- **Linux / macOS**:
  ```bash
  lsof -i :8080
  kill -9 <PID>
  ```

---

## 5. Automated Verification Suite

Once the server is running on port 8080, run the automated test suite in a separate terminal:

### On Windows:
```cmd
server\test-server.bat
```

### On Linux / macOS:
```bash
./server/test-server.sh
```

### Expected Output Summary:
| Test | Endpoint | Expected Status | Expected Body Substring |
|---|---|---|---|
| 1 | `POST /api/teste-tipos` | 200 OK | `OK - Tipos Processados: [Calculo1, 42, 7.5, 99.99, A]` |
| 2 | `POST /api/presenca` | 200 OK | `Resultado Presenca: PRESENCA_INTEGRAL (83%)` |
| 3 | `POST /api/presenca` (Manual) | 200 OK | `Resultado Presenca: JUSTIFICADO (Ajuste Manual do Professor)` |
| 4 | `POST /api/tarefas/calcular-nota` | 200 OK | `Nota Maxima Permitida: 8.0` |
| 5 | `POST /api/notas/boletim` | 200 OK | `Media Final: 7.6 \| Status: APROVADO` |
| 6 | `OPTIONS /api/presenca` | 204 No Content | *(Empty body with CORS headers)* |

---

## 6. Production Reverse Proxying & Hardening

In production environments, `ServidorHttpNativo` should NOT be exposed directly to the public Internet. Instead, an edge reverse proxy (such as Nginx or Caddy) must terminate TLS and forward requests to `http://127.0.0.1:8080`.

### Example Nginx Configuration:
```nginx
server {
    listen 443 ssl http2;
    server_name portal.agmrm.edu.br;

    ssl_certificate     /etc/ssl/certs/portal.agmrm.edu.br.crt;
    ssl_certificate_key /etc/ssl/private/portal.agmrm.edu.br.key;

    # Security Headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self';" always;

    # Limit maximum request body to 64KB
    client_max_body_size 64k;

    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 15s;
        proxy_send_timeout 15s;
    }
}
```

### Systemd Service Unit (`/etc/systemd/system/agmrm-server.service`):
```ini
[Unit]
Description=AGMRM Academic Portal Native HTTP Server
After=network.target

[Service]
Type=simple
User=agmrm
WorkingDirectory=/opt/agmrm/server
ExecStart=/usr/bin/java -cp /opt/agmrm/server/bin ServidorHttpNativo
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```
