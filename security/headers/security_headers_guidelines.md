# Diretrizes de Cabeçalhos de Segurança HTTP (Security Headers)

## 1. Introdução e Propósito

Esta diretriz estabelece a especificação técnica obrigatória de cabeçalhos de segurança HTTP (*HTTP Response Security Headers*) para o **Portal Acadêmico AGMRM**. O objetivo primordial é fornecer defesa em profundidade no navegador do usuário, protegendo a aplicação **Flutter Web** e as APIs do servidor Java contra as classes mais prevalentes de ataques web, incluindo:
- Cross-Site Scripting (XSS)
- Clickjacking (UI Redressing)
- MIME-type sniffing e injeção de arquivos maliciosos
- Ataques de downgrade SSL/TLS (Man-in-the-Middle)
- Vazamento de histórico de navegação e tokens sensíveis via cabeçalho `Referer`
- Cache indevido de boletins acadêmicos e dados cadastrais de alunos

---

## 2. Especificação Detalhada dos Cabeçalhos

### 2.1 Content-Security-Policy (CSP)
O cabeçalho **Content-Security-Policy** define as fontes confiáveis de scripts, fontes, estilos e conexões que o navegador pode carregar e executar. 

Como a aplicação frontend utiliza **Flutter Web** (compilação WebAssembly / CanvasKit) e consome fontes externas da biblioteca `google_fonts: ^8.1.0` (declarada no `pubspec.yaml`), a política é ajustada para atender aos requisitos operacionais sem relaxar a segurança fundamental.

#### Política Recomendada para Produção:
```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: blob:; connect-src 'self' http://localhost:8080 https://portal.agmrm.edu.br; frame-ancestors 'none'; base-uri 'self'; form-action 'self';
```

#### Justificativa Diretiva a Diretiva:
- `default-src 'self'`: Bloqueia qualquer recurso cujo tipo não foi explicitamente declarado, permitindo apenas a própria origem.
- `script-src 'self' 'wasm-unsafe-eval'`: Necessário para que o runtime Flutter Web compile e execute o bytecode WebAssembly (Wasm) e CanvasKit de renderização gráfica.
- `style-src 'self' 'unsafe-inline' https://fonts.googleapis.com`: Autoriza as folhas de estilo dos componentes de design do Flutter e o carregamento do CSS da biblioteca Google Fonts.
- `font-src 'self' https://fonts.gstatic.com`: Permite que os arquivos de fonte binários (.woff2, .ttf) sejam baixados da infraestrutura oficial da Google Fonts.
- `img-src 'self' data: blob:`: Permite fotos de perfil dos alunos, logotipos e geração de gráficos de notas em memória via Blob.
- `connect-src 'self' http://localhost:8080 https://portal.agmrm.edu.br`: Restringe as chamadas HTTP/REST feitas pelo Flutter (`/api/presenca`, `/api/notas/boletim`, etc.) aos servidores oficiais da instituição.
- `frame-ancestors 'none'`: Impede que o portal seja incorporado em `<frame>`, `<iframe>`, `<object>` ou `<embed>` por qualquer site externo.
- `base-uri 'self'` e `form-action 'self'`: Restringe injeções de tags `<base>` e submissões diretas de formulários HTML nativos.

---

### 2.2 Strict-Transport-Security (HSTS)
O cabeçalho **HSTS** instrui os navegadores a se comunicarem com o domínio do Portal Acadêmico **exclusivamente via HTTPS**, forçando a conversão de qualquer link `http://` para `https://` antes de enviar o primeiro pacote na rede.

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

- `max-age=31536000`: Validade de 1 ano (31.536.000 segundos).
- `includeSubDomains`: Aplica a regra a todos os subdomínios (ex: `api.agmrm.edu.br`, `aluno.agmrm.edu.br`).
- `preload`: Autoriza a inclusão do domínio na lista HSTS Preload mantida pelos navegadores modernos.

---

### 2.3 X-Frame-Options
Protege contra ataques de **Clickjacking**, garantindo que um atacante não sobreponha a interface do portal em um iframe transparente para roubar cliques de aprovação de notas ou frequência.

```http
X-Frame-Options: DENY
```
*(Nota: Complementa o `frame-ancestors 'none'` do CSP para navegadores legados).*

---

### 2.4 X-Content-Type-Options
Impede o navegador de ignorar o tipo MIME declarado pelo servidor (*MIME sniffing*), prevenindo que uploads de imagens ou arquivos de texto sejam interpretados como código JavaScript ou executável.

```http
X-Content-Type-Options: nosniff
```

---

### 2.5 Referrer-Policy
Controla a quantidade de informações de referência repassadas no cabeçalho `Referer` quando o usuário clica em links externos ou quando recursos de terceiros são carregados.

```http
Referrer-Policy: strict-origin-when-cross-origin
```
- Em requisições de mesma origem: Envia a URL completa.
- Em requisições HTTPS para origens externas confiáveis: Envia apenas a origem (sem caminho ou query parameters que possam conter IDs ou dados sensíveis).
- Em downgrades HTTPS -> HTTP: Nenhum cabeçalho `Referer` é enviado.

---

### 2.6 Permissions-Policy (Feature-Policy)
Desativa explicitamente APIs de hardware do navegador que o portal acadêmico não tem necessidade de utilizar, mitigando riscos caso uma biblioteca de terceiros seja comprometida.

```http
Permissions-Policy: camera=(self), microphone=(self), geolocation=(), payment=(), usb=(), display-capture=(self)
```
- `camera=(self)` e `microphone=(self)`: Autoriza o uso exclusivo do domínio para aulas ao vivo e teleconferências interativas.
- `geolocation=()`, `payment=()`, `usb=()`: Desativadas universalmente.
- `display-capture=(self)`: Permite compartilhamento de tela para professores durante apresentações.

---

### 2.7 Políticas de Controle de Cache para Endpoints de API
Como as rotas `/api/presenca`, `/api/tarefas/calcular-nota` e `/api/notas/boletim` transitam informações pessoais identificáveis (PII) e dados acadêmicos protegidos pela LGPD, o servidor deve instruir proxies intermediários e navegadores a não armazenarem essas respostas em cache de disco compartilhado.

```http
Cache-Control: no-store, no-cache, must-revalidate, private, max-age=0
Pragma: no-cache
Expires: 0
```

---

### 2.8 Isolamento de Origem Cruzada (Cross-Origin Isolation)
Para proteger o ambiente de execução WebAssembly do Flutter contra ataques de canal lateral como Spectre e Meltdown:

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-site
```

---

## 3. Matriz de Aplicação por Tipo de Recurso

| Cabeçalho de Segurança | Frontend (Flutter Web) | Backend API (`/api/*`) |
|---|---|---|
| `Content-Security-Policy` | **OBRIGATÓRIO** (Restritivo) | **RECOMENDADO** (`default-src 'none'`) |
| `Strict-Transport-Security` | **OBRIGATÓRIO** (1 ano) | **OBRIGATÓRIO** (1 ano) |
| `X-Frame-Options` | **DENY** | **DENY** |
| `X-Content-Type-Options` | **nosniff** | **nosniff** |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | `no-referrer` |
| `Permissions-Policy` | Aplicado (Aulas ao vivo) | `geolocation=(), camera=(), microphone=()` |
| `Cache-Control` | Cache estático com hash para bundles Flutter | `no-store, no-cache, must-revalidate, private` |

---

## 4. Configuração em Servidores Web de Produção

### 4.1 Nginx (Proxy Reverso)
```nginx
# Adição centralizada de Security Headers no bloco Nginx
server {
    listen 443 ssl http2;
    server_name portal.agmrm.edu.br;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Defesa contra Sniffing e Framing
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(self), microphone=(self), geolocation=(), payment=(), usb=()" always;

    # Isolamento de Processo
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Resource-Policy "same-site" always;

    # CSP para aplicação Web
    location / {
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: blob:; connect-src 'self' http://localhost:8080 https://portal.agmrm.edu.br; frame-ancestors 'none'; base-uri 'self'; form-action 'self';" always;
        try_files $uri $uri/ /index.html;
    }

    # Cabeçalhos específicos para rotas de API
    location /api/ {
        add_header Cache-Control "no-store, no-cache, must-revalidate, private" always;
        add_header Pragma "no-cache" always;
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## 5. Script de Verificação Automatizada (Runbook)

Para validar a correta emissão dos cabeçalhos nos endpoints do sistema, utilize a seguinte rotina de inspeção:

```bash
# Inspecionar cabeçalhos de resposta de um endpoint do servidor nativo
curl -I -s http://localhost:8080/api/notas/boletim | grep -E -i \
  "(content-security-policy|strict-transport|x-frame|x-content-type|referrer-policy|cache-control|access-control)"
```

**Critérios de Aprovação**:
- `X-Content-Type-Options: nosniff` deve estar presente.
- `Cache-Control` deve proibir armazenamento de dados acadêmicos sensíveis (`no-store`).
- Nenhuma informação de versão de software interna (`Server: Sun-Java-System...`) deve vazar.
