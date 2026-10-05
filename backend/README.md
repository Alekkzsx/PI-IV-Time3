# Backend Module — AGMRM Academic Portal

## 1. Overview & Architecture

The `backend` module encapsulates the core academic business logic and HTTP service endpoints of the **AGMRM - Portal Acadêmico**. Designed for simplicity, maximum portability, and zero external dependency footprint, the backend is implemented in pure Java Standard Edition (Java SE 17+) utilizing the built-in HTTP server framework `com.sun.net.httpserver`.

### Architectural Separation
In accordance with clean monorepo architecture:
- **`backend/` (Domain & Application Logic)**: Houses the Java source code (`backend/src/ServidorHttpNativo.java`), API schemas, business calculation algorithms, and contract documentation.
- **`server/` (Runtime & Infrastructure)**: Manages socket lifecycle, runtime configuration (`server.properties`), compilation targets (`server/bin/`), cross-platform startup scripts (`run-server.bat`, `run-server.sh`), and automated curl test suites (`test-server.bat`, `test-server.sh`).

```
c:\Users\24802449\Documents\Github\PI-IV-Time3/
├── backend/
│   ├── README.md               # API contracts, business rules & architecture (this file)
│   ├── SECURITY.md             # Input validation, exception handling & RBAC guidelines
│   └── src/
│       ├── ServidorHttpNativo.java  # 100% intact native Java HTTP service
│       └── testeServidor.txt        # Reference testing commands
└── server/
    ├── server.properties       # Port 8080, host & CORS configuration
    ├── run-server.bat / .sh    # Compilation & server execution scripts
    ├── test-server.bat / .sh   # Automated endpoint verification suites
    ├── README.md               # Socket lifecycle & operational docs
    └── SECURITY.md             # Network hardening & DoS mitigation
```

---

## 2. Technology Stack & Runtime Requirements

- **Language**: Java SE 17 (or higher)
- **Framework**: Native JDK HTTP Server (`com.sun.net.httpserver`)
- **Dependencies**: None (pure standard library: `java.io`, `java.net`, `java.nio.charset`, `java.util`)
- **Default Port**: `8080` (TCP)
- **Data Exchange Format**: `application/x-www-form-urlencoded` payloads, plain UTF-8 text responses
- **CORS Support**: Cross-Origin Resource Sharing enabled for web client integration

---

## 3. Endpoints Specification & API Contracts

All endpoints are hosted on base URL `http://localhost:8080` and require `POST` requests. Pre-flight `OPTIONS` requests receive HTTP `204 No Content` with appropriate CORS headers.

### 3.1 Primitive Types Extraction — `/api/teste-tipos`

Tests server-side parsing and primitive type conversion from form-encoded string parameters.

- **URL**: `/api/teste-tipos`
- **Method**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`
- **Request Parameters**:
  | Parameter | Type | Required | Default | Description |
  |---|---|---|---|---|
  | `texto` | String | No | `"vazio"` | Arbitrary textual input |
  | `inteiro` | int | No | `0` | 32-bit signed integer |
  | `flutuante` | float | No | `0.0` | 32-bit IEEE 754 floating point |
  | `duplo` | double | No | `0.0` | 64-bit IEEE 754 floating point |
  | `caractere` | char | No | `'X'` | Single character (first character extracted) |

- **Response Codes**:
  - `200 OK`: Successful conversion and display of parsed primitives.
  - `400 Bad Request`: Conversion failure (e.g., passing non-numeric characters to `inteiro`).
  - `405 Method Not Allowed`: HTTP method is not `POST`.

- **Example Request**:
  ```bash
  curl -X POST http://localhost:8080/api/teste-tipos \
    -d "texto=Calculo1&inteiro=42&flutuante=7.5&duplo=99.99&caractere=A"
  ```

- **Example Response (HTTP 200)**:
  ```text
  OK - Tipos Processados: [Calculo1, 42, 7.5, 99.99, A]
  ```

---

### 3.2 Online Class Attendance Calculation — `/api/presenca`

Calculates student attendance status based on minutes attended relative to total class duration, supporting manual instructor overrides.

- **URL**: `/api/presenca`
- **Method**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`
- **Request Parameters**:
  | Parameter | Type | Required | Default | Description |
  |---|---|---|---|---|
  | `minutosAssistidos` | int | No | `0` | Number of minutes the student attended |
  | `duracaoTotal` | int | No | `60` | Total duration of the class in minutes |
  | `statusManual` | String | No | `null` | Instructor manual override (e.g., `"JUSTIFICADO"`, `"DISPENSA"`) |

- **Business Calculation Rules**:
  1. **Manual Override Priority**: If `statusManual` is provided and non-empty, the algorithm bypasses percentage calculation and outputs:
     $$\text{status} = \text{UPPERCASE}(statusManual) + \text{" (Ajuste Manual do Professor)"}$$
  2. **Automated Percentage Calculation**:
     $$\text{percentual} = \left(\frac{minutosAssistidos}{duracaoTotal}\right) \times 100$$
  3. **Classification Thresholds**:
     - $\text{percentual} \ge 75.0\%$: `PRESENCA_INTEGRAL (X%)`
     - $50.0\% \le \text{percentual} < 75.0\%$: `MEIA_PRESENCA (X%)`
     - $\text{percentual} < 50.0\%$: `FALTA_AUTOMATICA (X%)`

- **Response Codes**:
  - `200 OK`: Attendance evaluated.
  - `400 Bad Request`: Numeric parsing error on minutes.
  - `405 Method Not Allowed`: HTTP method is not `POST`.

- **Example Request**:
  ```bash
  curl -X POST http://localhost:8080/api/presenca \
    -d "minutosAssistidos=50&duracaoTotal=60"
  ```

- **Example Response (HTTP 200)**:
  ```text
  Resultado Presenca: PRESENCA_INTEGRAL (83%)
  ```

---

### 3.3 Task Late Penalty Calculation — `/api/tarefas/calcular-nota`

Computes the maximum permissible grade for an assignment submission based on the number of days delayed.

- **URL**: `/api/tarefas/calcular-nota`
- **Method**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`
- **Request Parameters**:
  | Parameter | Type | Required | Default | Description |
  |---|---|---|---|---|
  | `diasAtraso` | int | No | `0` | Number of days submitted after deadline |
  | `notaBase` | double | No | `10.0` | Maximum grade of the assignment |

- **Business Calculation Rules**:
  1. If `diasAtraso <= 0`:
     $$\text{notaMaximaPermitida} = notaBase$$
  2. If `diasAtraso > 0`:
     $$\text{desconto} = diasAtraso \times 0.20 \quad (20\% \text{ per day})$$
     $$\text{notaMaximaPermitida} = notaBase \times (1.0 - \text{desconto})$$
  3. Floor Boundary: If $\text{notaMaximaPermitida} < 0.0$, the result is clamped to $0.0$.
     *(Note: Submissions delayed by 5 or more days result in a maximum allowed grade of 0.0).*

- **Response Codes**:
  - `200 OK`: Calculated allowed maximum grade.
  - `400 Bad Request`: Invalid numeric input.
  - `405 Method Not Allowed`: HTTP method is not `POST`.

- **Example Request**:
  ```bash
  curl -X POST http://localhost:8080/api/tarefas/calcular-nota \
    -d "diasAtraso=1&notaBase=10.0"
  ```

- **Example Response (HTTP 200)**:
  ```text
  Nota Maxima Permitida: 8.0
  ```

---

### 3.4 Report Card Weighted Average — `/api/notas/boletim`

Calculates a student's final academic grade using weighted evaluation components (Exams P1 and P2, plus Project/Trabalho) and determines academic status.

- **URL**: `/api/notas/boletim`
- **Method**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`
- **Request Parameters**:
  | Parameter | Type | Required | Default | Description |
  |---|---|---|---|---|
  | `p1` | double | No | `0.0` | First exam grade (0.0 to 10.0) |
  | `peso1` | double | No | `0.4` | Weight of first exam (40%) |
  | `p2` | double | No | `0.0` | Second exam grade (0.0 to 10.0) |
  | `peso2` | double | No | `0.4` | Weight of second exam (40%) |
  | `trabalho` | double | No | `0.0` | Project/assignment grade (0.0 to 10.0) |
  | `pesoTrabalho` | double | No | `0.2` | Weight of project (20%) |

- **Business Calculation Rules**:
  1. **Weighted Sum**:
     $$\text{somaNotasPesos} = (p1 \times peso1) + (p2 \times peso2) + (trabalho \times pesoTrabalho)$$
     $$\text{somaPesos} = peso1 + peso2 + pesoTrabalho$$
  2. **Weighted Average**:
     $$\text{media} = \begin{cases} \frac{\text{somaNotasPesos}}{\text{somaPesos}} & \text{se } \text{somaPesos} > 0 \\ 0.0 & \text{caso contrário} \end{cases}$$
  3. **Decimal Rounding**:
     $$\text{mediaFinal} = \frac{\text{round}(\text{media} \times 100)}{100.0} \quad (\text{rounded to 2 decimal places})$$
  4. **Academic Standing Rules**:
     - $\text{mediaFinal} \ge 7.0$: `APROVADO`
     - $5.0 \le \text{mediaFinal} < 7.0$: `EM_RECUPERACAO`
     - $\text{mediaFinal} < 5.0$: `REPROVADO_POR_NOTA`

- **Response Codes**:
  - `200 OK`: Final average and status delivered.
  - `400 Bad Request`: Invalid numeric input.
  - `405 Method Not Allowed`: HTTP method is not `POST`.

- **Example Request**:
  ```bash
  curl -X POST http://localhost:8080/api/notas/boletim \
    -d "p1=8.0&peso1=0.4&p2=6.0&peso2=0.4&trabalho=10.0&pesoTrabalho=0.2"
  ```

- **Example Response (HTTP 200)**:
  ```text
  Media Final: 7.6 | Status: APROVADO
  ```

---

## 4. Compilation & Execution

While source files are preserved under `backend/src/`, all compilation and execution automation is maintained in the `server/` directory:

1. **Windows**: Run `server/run-server.bat`
2. **Linux / macOS**: Run `server/run-server.sh`
3. **Automated Verification**: Run `server/test-server.bat` or `server/test-server.sh`
