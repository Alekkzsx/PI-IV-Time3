# Política de Senhas, Credenciais e Ciclo de Vida de Tokens

## 1. Fundamento Institucional e Conformidade

No **Portal Acadêmico AGMRM**, a integridade dos dados acadêmicos e a privacidade dos estudantes dependem diretamente da robustez dos mecanismos de autenticação. 

Em consonância com as diretrizes de conformidade institucional apresentadas aos usuários através do componente frontend `SecurityAlertBanner` (`lib/app/presentation/widgets/security_alert_banner.dart`), esta política padroniza as regras mandatórias para:
1. Requisitos de complexidade e armazenamento de senhas de usuários.
2. **Ciclo de vida restrito de 5 minutos** para tokens temporários de redefinição de senha.
3. Proteções contra ataques de força bruta, dicionário e sequestro de sessão (*session hijacking*).

---

## 2. Requisitos de Complexidade de Senhas

Todas as senhas cadastradas ou alteradas no portal (por alunos, professores ou administradores) devem atender estritamente aos seguintes critérios mínimos:

| Critério | Especificação Mínima | Justificativa de Segurança |
|---|---|---|
| **Comprimento Mínimo** | 8 caracteres (recomendado 12+) | Dificulta ataques de busca exaustiva (força bruta). |
| **Letras Maiúsculas** | Pelo menos 1 caractere (`A-Z`) | Aumenta o espaço amostral de entropia. |
| **Letras Minúsculas** | Pelo menos 1 caractere (`a-z`) | Previne senhas compostas apenas por letras maiúsculas. |
| **Dígitos Numéricos** | Pelo menos 1 dígito (`0-9`) | Exige intercalação alfanumérica. |
| **Caracteres Especiais** | Pelo menos 1 símbolo (`!@#$%^&*()-_+=<>?`) | Impede o uso de palavras comuns puras. |
| **Negação de Informações Pessoais** | Não conter o R.A., Matrícula, primeiro ou último nome, nem data de nascimento do titular | Evita adivinhação trivial baseada em engenharia social. |
| **Histórico de Senhas** | Proibição de repetição das últimas 3 senhas utilizadas | Impede a alternância cíclica entre duas senhas conhecidas. |

---

## 3. Armazenamento e Criptografia de Senhas no Banco de Dados

É **terminantemente proibido** armazenar senhas em texto plano (*plaintext*) ou utilizar funções de resumo criptográfico obsoletas como MD5, SHA-1 ou SHA-256 simples.

### Algoritmos Homologados:
1. **Argon2id** (Padrão Primário Recomendado):
   - Tempo: 3 iterações
   - Memória: 64 MB (65536 KB)
   - Paralelismo: 2 threads
2. **BCrypt** (Padrão Secundário Compatível):
   - Fator de custo (*work factor / cost parameter*): Mínimo **12** (4.096 iterações).
   - Salt único gerado criptograficamente com 16 bytes de entropia para cada hash.

---

## 4. Política Institucional de Tokens de Redefinição de Senha (Regra dos 5 Minutos)

### 4.1 Validade Temporal Estrita (TTL de 300 Segundos)
Conforme informado aos usuários no banner de alerta institucional:
> *"O token de redefinição enviado tem validade de 5 minutos por conformidade de segurança da instituição."*

- **Tempo Máximo de Vida**: O token expira exatamente **300 segundos (5 minutos)** após sua geração no backend.
- Qualquer requisição de redefinição submetida após 5 minutos e 0 segundos deve ser recusada com a mensagem:
  `"Token de redefinição expirado. Por razões de segurança institucional, solicite um novo código."`

### 4.2 Geração e Entropia do Token
- O token deve ser gerado por um gerador de números pseudo-aleatórios criptograficamente seguro (CSPRNG, como `java.security.SecureRandom`).
- Tamanho mínimo do token: **32 bytes** (256 bits), codificado em Base64 URL-safe ou hexadecimal (64 caracteres).
- O token bruto é transmitido exclusivamente para o canal institucional do usuário (e-mail cadastrado ou SMS corporativo).

### 4.3 Armazenamento e Invalidação de Tokens
1. **Armazenamento com Hash**: O banco de dados **nunca** armazena o token em texto puro. O backend calcula o hash SHA-256 do token e persiste apenas o resumo (`token_hash`), o timestamp de expiração (`expires_at`) e o `user_id`.
2. **Uso Único (*Single-Use*)**: O token é invalidado imediatamente após o primeiro uso com sucesso.
3. **Invalidação por Novo Pedido**: A solicitação de um novo token para o mesmo R.A. ou e-mail invalida automaticamente qualquer token anterior pendente.
4. **Comparação em Tempo Constante**: A validação do token deve utilizar comparação segura contra ataques de temporização (*timing attacks*), como `MessageDigest.isEqual()`.

---

## 5. Limitação de Taxa (Rate Limiting) e Proteção contra Força Bruta

Para proteger a infraestrutura contra ataques automatizados de adivinhação de senhas e tokens:

| Operação | Limite Permitido | Janela de Tempo | Ação em Caso de Violação |
|---|---|---|---|
| **Tentativas de Login** | 5 falhas consecutivas | 15 minutos | Bloqueio temporário da conta por 15 minutos e envio de alerta por e-mail. |
| **Submissão de Token de Redefinição** | 3 tentativas inválidas | Durante a vigência do token (5 min) | Invalidação imediata do token emitido, exigindo reinício do processo. |
| **Solicitação de Novo Token** | 3 solicitações | 1 hora | Bloqueio de novas solicitações para o mesmo R.A./IP pelo período de 1 hora. |

---

## 6. Revogação de Sessões em Mudança de Credenciais

Após qualquer alteração bem-sucedida de senha:
1. Todos os tokens JWT de acesso ativos e tokens de renovação (*refresh tokens*) vinculados ao usuário devem ser **revogados imediatamente**.
2. A sessão atual é encerrada em todos os dispositivos, exigindo nova autenticação formal.
3. Um registro de auditoria é gravado com timestamp, IP do cliente e agente de usuário (User-Agent).
