# Diretrizes de Segurança CORS (Cross-Origin Resource Sharing)

## 1. Visão Geral e Contexto Arquitetural

No ecossistema do **Portal Acadêmico AGMRM**, a aplicação cliente frontend desenvolvida em **Flutter Web** opera tipicamente sob um contexto de origem isolada no navegador (por exemplo, `http://localhost:3000` em ambiente de desenvolvimento ou `https://portal.agmrm.edu.br` em ambiente produtivo), enquanto o backend de serviços Java responde no endereço de rede `http://localhost:8080` (ou sob terminação segura em gateway de aplicação).

Devido à política de mesma origem do navegador (*Same-Origin Policy - SOP*), qualquer comunicação assíncrona iniciada via `fetch` ou `XMLHttpRequest` entre origens distintas dispara verificações automáticas de **CORS**. O servidor HTTP é responsável por emitir os cabeçalhos de resposta apropriados para permitir que o navegador entregue as respostas acadêmicas de forma segura e controlada.

---

## 2. Auditoria da Implementação Atual do Servidor Nativo

No arquivo de referência do servidor Java nativo (`backend/src/ServidorHttpNativo.java`, linhas 57–61 e manipuladores das linhas 126, 191, 257, 326), observa-se o seguinte comportamento:

```java
private static void aplicarHeadersCors(HttpExchange exchange) {
    exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
    exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type, Authorization");
}
```

### Pontos de Vulnerabilidade Identificados:
1. **Origem Coringa (`Access-Control-Allow-Origin: *`)**:
   - Em produção, o uso de `*` permite que qualquer página web arbitrária na internet induza o navegador de um aluno ou professor logado a realizar chamadas para as rotas da API acadêmica.
   - Embora `*` impeça o compartilhamento explícito de cookies HTTP com `credentials: 'include'`, requisições contendo cabeçalhos customizados como `Authorization: Bearer <token>` podem ser enviadas e exploradas caso não haja validação restritiva de origem.
2. **Métodos Desnecessariamente Expostos**:
   - O cabeçalho expõe `PUT` e `DELETE`, porém o servidor nativo implementa exclusivamente manipulação para requisições `POST` e preflight `OPTIONS`. A exposição de métodos não implementados amplia a superfície de ataque e confunde varreduras de conformidade.
3. **Ausência de Cache de Preflight (`Access-Control-Max-Age`)**:
   - Sem o cabeçalho `Access-Control-Max-Age`, o navegador emite uma requisição `OPTIONS` prévia para cada chamada subsequente de `POST`, dobrando a latência de rede e sobrecarregando o loop de requisições do servidor Java.

---

## 3. Matriz de Políticas por Ambiente

| Parâmetro | Desenvolvimento (`development`) | Homologação (`staging`) | Produção (`production`) |
|---|---|---|---|
| **Origens Permitidas** | `http://localhost:3000`<br>`http://127.0.0.1:3000`<br>`http://localhost:8080` | `https://staging-portal.agmrm.edu.br`<br>`https://staging-api.agmrm.edu.br` | `https://portal.agmrm.edu.br` *(estrito)* |
| **Métodos Autorizados** | `GET, POST, OPTIONS` | `GET, POST, OPTIONS` | `GET, POST, OPTIONS` |
| **Cabeçalhos Permitidos** | `Content-Type, Authorization, X-Requested-With, Accept, Origin` | `Content-Type, Authorization, X-Requested-With, Accept` | `Content-Type, Authorization, X-Requested-With, Accept` |
| **Cabeçalhos Expostos** | `Content-Length, Date, X-Request-Id` | `Content-Length, X-Request-Id` | `Content-Length, X-Request-Id` |
| **Credenciais** | `true` | `true` | `true` |
| **Cache Preflight (Max-Age)** | `3600` (1 hora) | `43200` (12 horas) | `86400` (24 horas) |

---

## 4. Regras Operacionais para Produção

### 4.1 Proibição de Wildcard Dinâmico / Origem Refletida Cega
É terminantemente proibido refletir cegamente o valor do cabeçalho `Origin` recebido da requisição para o cabeçalho `Access-Control-Allow-Origin` sem validação contra uma lista branca (*whitelist*). 

A reflexão cega (`Allow-Origin: $http_origin`) combinada com `Allow-Credentials: true` anula completamente as defesas do SOP, permitindo que atacantes leiam dados de notas (`/api/notas/boletim`) e presenças (`/api/presenca`).

### 4.2 Cache de Preflight
Para otimizar o desempenho do aplicativo Flutter Web sem comprometer a segurança, as respostas aos métodos `OPTIONS` devem incluir:
```http
Access-Control-Max-Age: 86400
```
Isso garante que o navegador cacheie o resultado da validação preflight pelo período de 24 horas para aquela tupla (origem, rota, método).

### 4.3 Isolamento de Endpoints Críticos
- `/api/tarefas/calcular-nota`: Deve ser acessível apenas por origens autorizadas da instituição e com token de professor.
- `/api/notas/boletim`: Contém dados acadêmicos sensíveis (LGPD) e nunca deve ser acessível por origens não homologadas.

---

## 5. Implementação de Referência no Gateway / Proxy Reverso (Nginx)

Em arquitetura de implantação empresarial, a terminação de CORS e de TLS deve ocorrer no proxy reverso que protege a instância do servidor Java (`8080`):

```nginx
# Bloco Nginx para terminação de CORS segura
map $http_origin $cors_allowed_origin {
    default "";
    "https://portal.agmrm.edu.br" "https://portal.agmrm.edu.br";
}

server {
    listen 443 ssl http2;
    server_name api.agmrm.edu.br;

    ssl_certificate /etc/letsencrypt/live/api.agmrm.edu.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.agmrm.edu.br/privkey.pem;

    location /api/ {
        # Verificação da Origem Permitida
        if ($cors_allowed_origin != "") {
            add_header "Access-Control-Allow-Origin" $cors_allowed_origin always;
            add_header "Access-Control-Allow-Methods" "GET, POST, OPTIONS" always;
            add_header "Access-Control-Allow-Headers" "Content-Type, Authorization, X-Requested-With, Accept" always;
            add_header "Access-Control-Allow-Credentials" "true" always;
            add_header "Access-Control-Max-Age" 86400 always;
        }

        # Tratamento de Preflight OPTIONS
        if ($request_method = 'OPTIONS') {
            add_header "Content-Type" "text/plain; charset=UTF-8";
            add_header "Content-Length" 0;
            return 204;
        }

        # Encaminhamento para o backend Java nativo na porta 8080
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 6. Procedimento de Teste e Validação

Para validar de forma independente a conformidade da política de CORS, execute os seguintes testes via terminal `curl`:

### Teste 1: Requisição Preflight com Origem Válida
```bash
curl -i -X OPTIONS http://localhost:8080/api/presenca \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type, Authorization"
```
**Resultado Esperado**:
- Status HTTP `204 No Content`
- Cabeçalhos de CORS presentes e coerentes com a lista autorizada.

### Teste 2: Requisição com Origem Não Autorizada (Simulação de Ataque)
```bash
curl -i -X OPTIONS http://localhost:8080/api/notas/boletim \
  -H "Origin: https://malicious-academic-phishing.com" \
  -H "Access-Control-Request-Method: POST"
```
**Resultado Esperado em Produção**:
- Cabeçalho `Access-Control-Allow-Origin` ausente ou rejeitado pelo proxy reverso.
