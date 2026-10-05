# Modelagem de Ameaças Cibernéticas (STRIDE + DREAD)

## 1. Sumário Executivo e Escopo do Sistema

Este documento apresenta a **Modelagem de Ameaças** do **Portal Acadêmico AGMRM** (`PI-IV-Time3`), cobrindo todos os componentes da solução:
1. **Frontend**: Aplicação compilada em Flutter Web em execução no navegador do usuário.
2. **Runtime do Servidor HTTP Nativo**: Serviço Java `com.sun.net.httpserver` em execução na porta TCP `8080`.
3. **Lógica de Aplicação Backend**: Manipuladores de rotas e processamento de regras acadêmicas (`backend/src/ServidorHttpNativo.java`).
4. **Camada de Persistência**: Banco de dados MongoDB (porta TCP `27017`).

A análise emprega os modelos analíticos **STRIDE** (para categorização de vetores de ataque) e **DREAD** (para classificação quantitativa e priorização de risco).

---

## 2. Diagrama de Fluxo de Dados e Fronteiras de Confiança (DFD)

```
[ Usuário: Aluno / Professor / Admin ]
                 │
                 ▼  (Fronteira de Confiança 1: Ambiente de Execução do Cliente - NÃO CONFIÁVEL)
  [ Frontend Flutter Web (Browser) ]
                 │
                 ▼  (Fronteira de Confiança 2: Rede Pública / Internet)
  [ Proxy Reverso / Gateway TLS (Porta 443) ]
                 │
                 ▼  (Fronteira de Confiança 3: Perímetro de Aplicação Interno)
  [ Servidor HTTP Nativo Java (Porta 8080) ]
        ├── /api/teste-tipos
        ├── /api/presenca
        ├── /api/tarefas/calcular-nota
        └── /api/notas/boletim
                 │
                 ▼  (Fronteira de Confiança 4: Rede Privada de Dados)
  [ Banco de Dados NoSQL MongoDB (Porta 27017) ]
```

### Fronteiras de Confiança Identificadas:
- **TB-1 (Navegador do Cliente)**: Ambiente hostil. O código Dart/JS compilado pode ser inspecionado, modificado ou contornado por ferramentas de depuração do navegador (DevTools).
- **TB-2 (Tráfego de Rede)**: Sujeito a interceptação (*Man-in-the-Middle*), falsificação de DNS e ataques de repetição se desprovido de TLS estrito e HSTS.
- **TB-3 (Servidor HTTP Java)**: Ponto focal de validação. Nenhum dado vindo de TB-1 ou TB-2 pode ser aceito sem validação de tipos, limites e integridade.
- **TB-4 (Acesso ao Banco de Dados)**: Acesso estritamente autenticado e restrito à rede interna do cluster.

---

## 3. Matriz Geral de Ameaças STRIDE

| Categoria STRIDE | Descrição da Ameaça no Domínio Acadêmico | Componentes Afetados | Impacto no Negócio |
|---|---|---|---|
| **S - Spoofing** (Falsificação) | Aluno forjando requisições com `statusManual` de presença ou se passando por docente/outro aluno. | `/api/presenca`, Sessões JWT | Registro indevido de frequência para alunos ausentes. |
| **T - Tampering** (Adulteração) | Envio de `diasAtraso` negativo para inflar notas ou adulteração de notas no cálculo de boletim. | `/api/tarefas/calcular-nota`, `/api/notas/boletim` | Corrupção da integridade de notas e concessão indevida de aprovação. |
| **R - Repudiation** (Repúdio) | Professor negar lançamento de nota alterada ou aluno negar envio intempestivo de atividade. | Backend, Logs de Auditoria | Impossibilidade de resolução de litígios pedagógicos e auditoria institucional. |
| **I - Information Disclosure** (Vazamento) | Exposição de mensagens de erro internas nos retornos HTTP 400 ou consulta a boletins de outros alunos. | `lerCorpoRequisicao`, `/api/notas/boletim` | Violação da LGPD e vazamento de dados de desempenho estudantil. |
| **D - Denial of Service** (Negação de Serviço) | Envio de corpos HTTP infinitos esgotando a memória heap do servidor Java ou divisão por zero travando threads. | `HttpServer`, `lerCorpoRequisicao`, `/api/presenca` | Indisponibilidade total do portal durante períodos críticos de matrícula ou provas. |
| **E - Elevation of Privilege** (Elevação de Privilégio) | Aluno executando endpoints restritos a professores sem conferência de papel (*Role*). | Endpoints `/api/*` | Controle não autorizado sobre o sistema de notas. |

---

## 4. Classificação e Pontuação de Risco DREAD

O modelo DREAD avalia cinco dimensões em uma escala de 1 a 10:
- **D**amage Potential (Potencial de Dano)
- **R**eproducibility (Reprodutibilidade)
- **E**xploitability (Facilidade de Exploração)
- **A**ffected Users (Usuários Afetados)
- **D**iscoverability (Facilidade de Descoberta)

**Pontuação Total** = `(D + R + E + A + D) / 5`

| ID | Ameaça Identificada | D | R | E | A | D | Total DREAD | Severidade |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **THR-01** | Fraude de Frequência via Injeção de `statusManual` | 8 | 9 | 9 | 7 | 8 | **8.2** | **CRÍTICA** |
| **THR-02** | Adulteração de Nota via Dias de Atraso Negativos | 9 | 9 | 10 | 8 | 9 | **9.0** | **CRÍTICA** |
| **THR-03** | Esgotamento de Memória Heap por Payload Infinito (DoS) | 10 | 8 | 8 | 10 | 7 | **8.6** | **CRÍTICA** |
| **THR-04** | Divisão por Zero em Duração de Aula Nula | 7 | 10 | 9 | 6 | 8 | **8.0** | **ALTA** |
| **THR-05** | Vazamento de Stack Trace / Erros de Conversão em HTTP 400 | 5 | 9 | 9 | 7 | 8 | **7.6** | **ALTA** |
| **THR-06** | Ataque de Força Bruta contra Token de Redefinição de Senha | 8 | 7 | 6 | 5 | 7 | **6.6** | **MÉDIA** |
| **THR-07** | Replay de Token de Redefinição Expirado (> 5 minutos) | 8 | 6 | 5 | 5 | 6 | **6.0** | **MÉDIA** |
| **THR-08** | Abuso de CORS com Origem Aberta (`*`) para Roubo de Sessão | 7 | 6 | 6 | 6 | 7 | **6.4** | **MÉDIA** |

---

## 5. Análise Detalhada das Ameaças do Domínio

### 5.1 THR-01: Fraude de Frequência via `statusManual` em `/api/presenca`
- **Vetor de Ataque**: O endpoint aceita opcionalmente o parâmetro `statusManual`. Se um aluno interceptar a requisição e injetar `statusManual=PRESENCA_INTEGRAL`, a lógica atual no servidor nativo substitui o cálculo percentual e concede presença integral sem verificar a identidade ou papel do requisitante.
- **Código Vulnerável Observado**:
  ```java
  // backend/src/ServidorHttpNativo.java:214-221
  if (statusManual != null && !statusManual.trim().isEmpty()) {
      statusFinal = statusManual.trim();
  }
  ```
- **Mitigação Recomendada**:
  - Exigir token JWT no cabeçalho `Authorization`.
  - Rejeitar o processamento do campo `statusManual` se o token não contiver a permissão `ROLE_PROFESSOR` ou `ROLE_ADMIN`. Retornar `HTTP 403 Forbidden`.

---

### 5.2 THR-02: Adulteração de Nota via Dias de Atraso Negativos em `/api/tarefas/calcular-nota`
- **Vetor de Ataque**: A fórmula de cálculo de penalidade aplica `1.0 - (diasAtraso * 0.20)`. Se um atacante enviar `diasAtraso=-2`, a penalidade se torna negativa, resultando em um multiplicador de `1.40`, concedendo uma nota superior à nota base máxima permitida.
- **Código Vulnerável Observado**:
  ```java
  // backend/src/ServidorHttpNativo.java:274-279
  double penalidade = diasAtraso * 0.20;
  double notaMaximaPermitida = notaBase * (1.0 - penalidade);
  if (notaMaximaPermitida < 0) {
      notaMaximaPermitida = 0.0;
  }
  ```
- **Mitigação Recomendada**:
  - Validação estrita de limites numéricos (*Boundary Validation*):
    `if (diasAtraso < 0) throw new IllegalArgumentException("diasAtraso nao pode ser negativo");`
    `if (notaBase < 0.0 || notaBase > 10.0) throw new IllegalArgumentException("notaBase deve estar entre 0.0 e 10.0");`

---

### 5.3 THR-03: Esgotamento de Memória Heap por Payload Infinito (DoS)
- **Vetor de Ataque**: A função utilitária `lerCorpoRequisicao` lê o `InputStream` da requisição linha por linha sem qualquer contador de bytes acumulados. Um atacante abrindo uma conexão lenta e emitindo gigabytes de dados provoca `java.lang.OutOfMemoryError` na JVM, derrubando o servidor para todos os usuários.
- **Código Vulnerável Observado**:
  ```java
  // backend/src/ServidorHttpNativo.java:95-104
  BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
  String linha;
  while ((linha = reader.readLine()) != null) {
      sb.append(linha);
  }
  ```
- **Mitigação Recomendada**:
  - Limitar a leitura a no máximo **65.536 bytes (64 KB)**:
    Se a soma de bytes lidos exceder o limite, abortar imediatamente a leitura e fechar a conexão com `HTTP 413 Payload Too Large`.

---

### 5.4 THR-04: Divisão por Zero em Duração Nula em `/api/presenca`
- **Vetor de Ataque**: Se a requisição contiver `duracaoTotal=0`, a operação `((double) minutosAssistidos / duracaoTotal) * 100` em ponto flutuante produz `Double.POSITIVE_INFINITY`. Na verificação `porcentagem >= 75.0`, a condição é avaliada como verdadeira, concedendo `PRESENCA_INTEGRAL` fraudulenta para uma aula inexistente.
- **Mitigação Recomendada**:
  - Rejeitar com `HTTP 400 Bad Request` qualquer requisição com `duracaoTotal <= 0`.
  - Exigir `minutosAssistidos >= 0` e `minutosAssistidos <= duracaoTotal`.

---

### 5.5 THR-05: Replay e Força Bruta de Tokens de Redefinição de Senha
- **Vetor de Ataque**: Um atacante intercepta ou gera um token de recuperação de senha e tenta explorá-lo após o período de validade ou realizar milhares de tentativas automatizadas de adivinhação.
- **Mitigação Institucional Obrigatória**:
  - **Expiração em 5 Minutos (300 segundos)**: Ratificada na política institucional e informada no `SecurityAlertBanner`. Tokens com timestamp anterior a 5 minutos são imediatamente expurgados e recusados.
  - **Uso Único (Single-Use)**: Invalidação imediata do hash após o primeiro uso.
  - **Limitação de Tentativas**: Bloqueio de IP e usuário após 3 tentativas inválidas de validação do token na janela de 5 minutos.
  - **Comparação em Tempo Constante**: Uso de `MessageDigest.isEqual` para evitar ataques de temporização (*side-channel timing attacks*).

---

## 6. Plano de Ação de Engenharia e Defesa em Profundidade

| ID | Ação de Mitigação | Camada | Responsabilidade |
|---|---|---|---|
| **ACT-01** | Bloquear `statusManual` para perfis sem privilégios de docência. | Backend / RBAC | `security/policies/access_control_policy.md` |
| **ACT-02** | Impor teto de 64 KB de leitura de corpo de requisições. | Server Runtime | `server/` / `security/.env.example` |
| **ACT-03** | Validar limites: `diasAtraso >= 0`, `duracaoTotal > 0`, notas entre `0.0` e `10.0`. | Backend Logic | `security/threat_modeling/threat_model.md` |
| **ACT-04** | Restringir CORS de wildcard `*` para lista branca por ambiente. | Server / Proxy | `security/cors/` |
| **ACT-05** | Emissão de cabeçalhos de segurança (CSP, HSTS, X-Frame-Options, Cache-Control). | Web / Gateway | `security/headers/` |
| **ACT-06** | Garantir expiração de tokens em 5 minutos e descarte imediato. | Auth Service | `security/policies/password_and_token_policy.md` |
