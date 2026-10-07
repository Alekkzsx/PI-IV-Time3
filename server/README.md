# Server — Zero-Dependency Native Java HTTP Server

The `server` module contains an autonomous, **100% native Java HTTP server** developed from scratch for the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3). 

Designed and implemented by **Guilherme Henrique Moreira** (`@GuilhermeMoreira07`), this server operates entirely on the standard **Java SE 17+** runtime library without depending on external frameworks, application containers, or build automation tools (no Spring, Quarkus, Maven, Gradle, or Tomcat).

---

## 🏛️ Architectural Overview & Design Principles

```
┌────────────────────────────────────────────────────────────────────────┐
│               Client Request (Flutter Web/Desktop or cURL)             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTP / Port 8080
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        ServidorHttpNativo.java                         │
│             (HttpServer.create(new InetSocketAddress(8080), 0))        │
│                       server.setExecutor(null)                         │
└───────┬───────────────────┬───────────────────┬───────────────────┬────┘
        │                   │                   │                   │
        │ /api/teste-tipos  │ /api/presenca     │ /api/tarefas/...  │ /api/notas/boletim
        ▼                   ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│TesteTipos-    │   │Presenca-      │   │Tarefas-       │   │Boletim-       │
│Handler.java   │   │Handler.java   │   │Handler.java   │   │Handler.java   │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │                   │
        └───────────────────┼───────────────────┼───────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│                            HttpUtils.java                              │
│  - aplicarHeadersCors() (CORS Pre-flight OPTIONS & Headers)            │
│  - lerCorpoRequisicao() (UTF-8 InputStream Reader)                     │
│  - parseFormUrlEncoded() (x-www-form-urlencoded Map Parser)            │
│  - enviarResposta() (Status Code, Byte Counting & Response Stream)     │
└────────────────────────────────────────────────────────────────────────┘
```

### Key Technical Characteristics
- **Zero Third-Party Dependencies**: Compiles directly with standard `javac` and executes on standard `java` Virtual Machine (JVM).
- **Standard Socket Abstraction**: Built on `com.sun.net.httpserver.HttpServer` and `java.net.InetSocketAddress`.
- **Default Port & Address**: Listens on port `8080` bound to all interfaces (`0.0.0.0`), utilizing the operating system default TCP socket connection backlog (`0`).
- **Threading Model**: Operates with `server.setExecutor(null)`, utilizing the default single-threaded dispatcher of `com.sun.net.httpserver`.
- **Cross-Origin Resource Sharing (CORS)**: Out-of-the-box support for browser pre-flight requests (`OPTIONS` yielding `204 No Content`) and cross-origin header injection (`Access-Control-Allow-Origin: *`).

---

## 📂 Complete Directory Tree

```
server/
├── README.md                     # Native Java server documentation (this file)
├── src/                          # Java source code files (default package)
│   ├── BoletimHandler.java       # Weighted academic report card average & status
│   ├── HttpUtils.java            # Shared HTTP helper (CORS, body reader, form parser, responder)
│   ├── PresencaHandler.java      # Attendance rate calculation & manual teacher adjustment
│   ├── ServidorHttpNativo.java   # Main server bootstrap entry point & routing configuration
│   ├── TarefasHandler.java       # Late assignment submission penalty calculation
│   └── TesteTiposHandler.java    # Primitive data type extraction & parsing handler
└── tests/
    └── testeServidor.txt         # Compilation commands & automated cURL test suite
```

---

## 🧩 Source Code Breakdown (`server/src/`)

### 1. `ServidorHttpNativo.java` (Main Entry Point)
- **Role**: Entry point containing the `public static void main(String[] args)` method.
- **Port Constant**: `PORTA_PADRAO = 8080`.
- **Socket Initialization**:
  ```java
  HttpServer server = HttpServer.create(new InetSocketAddress(porta), 0);
  ```
- **Context Routing**:
  - `/api/teste-tipos` $\rightarrow$ `TesteTiposHandler`
  - `/api/presenca` $\rightarrow$ `PresencaHandler`
  - `/api/tarefas/calcular-nota` $\rightarrow$ `TarefasHandler`
  - `/api/notas/boletim` $\rightarrow$ `BoletimHandler`
- **Lifecycle**: Invokes `server.start()` and logs interactive startup banners and endpoint references to `System.out`.

### 2. `HttpUtils.java` (Shared HTTP Utility)
- **Role**: Static utility helper providing foundational protocol handling:
  - `aplicarHeadersCors(HttpExchange exchange)`: Sets `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`, and `Access-Control-Allow-Headers: Content-Type, Authorization`.
  - `lerCorpoRequisicao(HttpExchange exchange)`: Reads raw request payload stream into a `String` using `BufferedReader` and UTF-8 encoding.
  - `parseFormUrlEncoded(String body)`: Splits string parameters on delimiter `&` and key-value tokens on `=`, mapping them into a `Map<String, String>`.
  - `enviarResposta(HttpExchange exchange, int statusCode, String resposta)`: Converts output payload into UTF-8 byte stream, executes `sendResponseHeaders(statusCode, bytes.length)`, flushes payload, and terminates the response stream.

### 3. `TesteTiposHandler.java` (Data Type Extraction)
- **Endpoint**: `POST /api/teste-tipos`
- **Purpose**: Exercises and validates native type conversion from form parameters into Java primitive and wrapper types:
  - `texto`: String (default: `"vazio"`)
  - `inteiro`: `int` via `Integer.parseInt` (default: `0`)
  - `flutuante`: `float` via `Float.parseFloat` (default: `0.0f`)
  - `duplo`: `double` via `Double.parseDouble` (default: `0.0d`)
  - `caractere`: `char` from initial index of param (default: `'X'`)
- **Responses**: Returns `200 OK` with serialized type array, or `400 Bad Request` upon parse failure.

### 4. `PresencaHandler.java` (Class Attendance Computation)
- **Endpoint**: `POST /api/presenca`
- **Input Parameters**: `minutosAssistidos` (int), `duracaoTotal` (int, default `60`), optional `statusManual` (string).
- **Business Logic**:
  - If `statusManual` is supplied: overrides calculation, returning `<STATUS> (Ajuste Manual do Professor)`.
  - Otherwise, computes percentage:
    $$\text{percentual} = \left(\frac{\text{minutosAssistidos}}{\text{duracaoTotal}}\right) \times 100$$
    - $\ge 75.0\%$: `PRESENCA_INTEGRAL (X%)`
    - $\ge 50.0\%$: `MEIA_PRESENCA (X%)`
    - $< 50.0\%$: `FALTA_AUTOMATICA (X%)`
- **Responses**: `200 OK` with attendance status, or `400 Bad Request`.

### 5. `TarefasHandler.java` (Late Assignment Penalty)
- **Endpoint**: `POST /api/tarefas/calcular-nota`
- **Input Parameters**: `diasAtraso` (int), `notaBase` (double, default `10.0`).
- **Business Logic**:
  - `PENALIDADE_DIARIA = 0.20` (20% penalty per calendar day late).
  - Deduction formula:
    $$\text{notaMaximaPermitida} = \text{notaBase} \times (1.0 - (\text{diasAtraso} \times 0.20))$$
  - Bound to minimum score: $\max(0.0, \text{notaMaximaPermitida})$.
- **Responses**: `200 OK` with allowed ceiling score, or `400 Bad Request`.

### 6. `BoletimHandler.java` (Weighted Report Card Average)
- **Endpoint**: `POST /api/notas/boletim`
- **Input Parameters**:
  - Exam 1: `p1` (default `0.0`), `peso1` (default `0.4`)
  - Exam 2: `p2` (default `0.0`), `peso2` (default `0.4`)
  - Project: `trabalho` (default `0.0`), `pesoTrabalho` (default `0.2`)
- **Business Logic**:
  - Computes weighted average:
    $$\text{media} = \frac{(p1 \times peso1) + (p2 \times peso2) + (trabalho \times pesoTrabalho)}{peso1 + peso2 + pesoTrabalho}$$
  - Rounded to 2 decimal places.
  - Status evaluation:
    - $\text{media} \ge 7.0$: `APROVADO`
    - $\text{media} \ge 5.0$: `EM_RECUPERACAO`
    - $\text{media} < 5.0$: `REPROVADO_POR_NOTA`
- **Responses**: `200 OK` with `Media Final: X.X | Status: STATUS`, or `400 Bad Request`.

---

## 🛠️ Compilation and Execution Guide

### Prerequisites
- **Java SE Development Kit (JDK)**: Version 17, 21, or newer.
- Ensure `javac` and `java` are available in your system path (`PATH`).

### Option A: From Repository Root (Recommended)
1. **Compile all Java source files**:
   ```bash
   javac server/src/*.java
   ```
2. **Execute the server**:
   ```bash
   java -cp server/src ServidorHttpNativo
   ```

### Option B: From Inside `server/src/`
1. **Navigate to the source directory**:
   ```bash
   cd server/src
   ```
2. **Compile**:
   ```bash
   javac ServidorHttpNativo.java
   ```
   *(Java compiler automatically resolves dependencies: `HttpUtils`, `BoletimHandler`, etc.)*
3. **Execute**:
   ```bash
   java ServidorHttpNativo
   ```

### Script Wrappers (`run-server.bat` / `run-server.sh`)
While the core repository intentionally provides lightweight direct command execution, developers can optionally create standard shell or batch wrapper scripts to streamline local workflows:
- **Windows (`run-server.bat`)**:
  ```bat
  @echo off
  javac server\src\*.java
  java -cp server\src ServidorHttpNativo
  ```
- **macOS / Linux (`run-server.sh`)**:
  ```bash
  #!/usr/bin/env bash
  javac server/src/*.java
  java -cp server/src ServidorHttpNativo
  ```

---

## 🧪 Automated Testing Suite & cURL Verifications

Test procedures and sample payloads are cataloged in `server/tests/testeServidor.txt`. With the server running, execute the following commands in an independent terminal window:

### 1. Primitive Type Extraction Test
```bash
curl -X POST http://localhost:8080/api/teste-tipos \
  -d "texto=Calculo1&inteiro=42&flutuante=7.5&duplo=99.99&caractere=A"
```
**Expected Response (`200 OK`)**:
```text
OK - Tipos Processados: [Calculo1, 42, 7.5, 99.99, A]
```

### 2. Student Attendance Evaluation Test
```bash
curl -X POST http://localhost:8080/api/presenca \
  -d "minutosAssistidos=50&duracaoTotal=60"
```
**Expected Response (`200 OK`)**:
```text
Resultado Presenca: PRESENCA_INTEGRAL (83%)
```

*(Manual adjustment test)*:
```bash
curl -X POST http://localhost:8080/api/presenca \
  -d "statusManual=PRESENCA_ABONADA"
```
**Expected Response (`200 OK`)**:
```text
Resultado Presenca: PRESENCA_ABONADA (Ajuste Manual do Professor)
```

### 3. Late Assignment Deduction Test
```bash
curl -X POST http://localhost:8080/api/tarefas/calcular-nota \
  -d "diasAtraso=1&notaBase=10.0"
```
**Expected Response (`200 OK`)**:
```text
Nota Maxima Permitida: 8.0
```

### 4. Weighted Academic Report Card Test
```bash
curl -X POST http://localhost:8080/api/notas/boletim \
  -d "p1=8.0&peso1=0.4&p2=6.0&peso2=0.4&trabalho=10.0&pesoTrabalho=0.2"
```
**Calculation Check**:
$$\text{media} = \frac{(8.0 \times 0.4) + (6.0 \times 0.4) + (10.0 \times 0.2)}{0.4 + 0.4 + 0.2} = \frac{3.2 + 2.4 + 2.0}{1.0} = 7.6$$
**Expected Response (`200 OK`)**:
```text
Media Final: 7.6 | Status: APROVADO
```

---

## 🔒 Security & Robustness Considerations

- **Input Isolation**: All request parsing operations are wrapped in `try-catch` blocks, preventing malicious or malformed parameters from crashing the server thread.
- **CORS Hardening**: Permissive CORS headers are configured for local multi-origin prototyping; production environments should restrict `Access-Control-Allow-Origin` to authorized domain origins.
- For comprehensive security standards across all tiers, see the [`security/`](../security/README.md) module documentation.
