# Server Network Security & Hardening Policy

## 1. Overview

The `server` module manages the runtime execution environment of the **AGMRM - Portal Acadêmico** HTTP backend. Because `com.sun.net.httpserver` is an unhardened, embedded Java HTTP server intended primarily for lightweight or internal services, deploying it requires strict network-level and host-level security controls.

This document establishes the infrastructure security standards for hosting, binding, and protecting the server runtime on TCP port 8080.

---

## 2. Network Interface Binding & Hardening

### 2.1 Interface Exposure
- **Development**: The server binds to port 8080 without an explicit IP specification (`new InetSocketAddress(porta)`), which binds across all network interfaces (`0.0.0.0`).
- **Production Vulnerability**: Exposing port 8080 directly on `0.0.0.0` exposes the unencrypted, unauthenticated raw Java HTTP server to the public Internet or local area network.
- **Production Hardening Standard**:
  1. **Localhost Binding**: In production, bind the socket exclusively to loopback (`127.0.0.1` or `::1`):
     ```java
     HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", porta), 0);
     ```
  2. **Firewall Isolation**: If binding to external interfaces is required (e.g., inside container networks), enforce host firewall rules (Windows Defender Firewall or Linux `iptables`/`ufw`) restricting incoming traffic to port 8080 exclusively from the designated reverse proxy IP address:
     ```bash
     # Linux UFW example:
     ufw allow from 10.0.0.10 to any port 8080 proto tcp
     ufw deny 8080/tcp
     ```

---

## 3. Denial of Service (DoS) & Resource Exhaustion Mitigations

### 3.1 Request Body Size Ceiling (64 KB)
- **Threat**: The current implementation reads incoming request bodies into an in-memory `StringBuilder` line-by-line (`lerCorpoRequisicao`). An attacker transmitting gigabytes of payload data can cause an `OutOfMemoryError` (OOM), crashing the JVM.
- **Mitigation**:
  - Enforce a strict upstream body limit of **64 KB** (65,536 bytes) at the reverse proxy layer (`client_max_body_size 64k;` in Nginx).
  - In application logic, wrap the `InputStream` with a bounded stream counter that terminates reading and returns HTTP 413 (Payload Too Large) if bytes read exceed 64 KB.

### 3.2 Slowloris & Slow HTTP Attacks
- **Threat**: Attackers open numerous TCP connections and stream HTTP headers or body bytes extremely slowly, exhausting the server socket queue or thread pool.
- **Mitigation**:
  - Deploy an edge reverse proxy with aggressive socket timeouts:
    - Client header timeout: 5s
    - Client body timeout: 10s
    - Keepalive timeout: 30s
  - Configure OS TCP keepalive and SYN flood protection (`tcp_syncookies = 1`).

### 3.3 Thread Pool Starvation
- **Threat**: The default executor (`server.setExecutor(null)`) executes handler logic synchronously. A spike in concurrent requests can saturate socket worker threads.
- **Mitigation**:
  - Bound concurrent worker threads using a dedicated `ThreadPoolExecutor` with a bounded array blocking queue and caller-runs or discard rejection policies.

---

## 4. Reverse Proxy & TLS/HTTPS Enforcement

### 4.1 Plaintext HTTP Prohibition
- `ServidorHttpNativo` serves unencrypted HTTP over port 8080.
- Cleartext HTTP exposes academic grades, attendance records, and authentication tokens to network eavesdropping and man-in-the-middle (MITM) attacks.
- **Mandate**: All production traffic MUST use TLS 1.3 terminated at an edge reverse proxy (e.g., Nginx, Caddy, Cloudflare, AWS ALB). Cleartext port 8080 must only exist in private inter-process communication.

### 4.2 Security Headers Pipeline
The edge proxy fronting port 8080 must inject standard OWASP defense-in-depth headers on all API responses:
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'none'; frame-ancestors 'none';
```

---

## 5. Rate Limiting & Abuse Prevention

To prevent brute-force attacks against grading endpoints (`/api/notas/boletim`) and attendance calculation (`/api/presenca`):
- Enforce IP-based rate limiting at the reverse proxy:
  - Burst limit: 20 requests/second per IP.
  - Sustained limit: 60 requests/minute per IP.
- Return HTTP 429 Too Many Requests upon threshold violation.

---

## 6. Incident Reporting & Security Contacts

If you detect an infrastructure vulnerability or unauthorized access to the port 8080 service, immediately notify:
- Security Team: `security@agmrm.edu.br`
- Response SLA: Initial triage within 24 hours.
