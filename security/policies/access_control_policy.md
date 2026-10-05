# Política de Controle de Acesso Baseada em Funções (RBAC Policy)

## 1. Objetivo e Escopo

A presente **Política de Controle de Acesso** rege a concessão, validação e revogação de privilégios de acesso aos módulos e serviços do **Portal Acadêmico AGMRM** (`PI-IV-Time3`). Esta política abrange todos os usuários do sistema — alunos, corpo docente e administradores da instituição — e todas as interfaces, incluindo o frontend em Flutter Web, o runtime de servidor HTTP e os endpoints da API Java.

O princípio orientador desta política é o **Princípio do Menor Privilégio (Principle of Least Privilege - PoLP)** e o modelo de **Segurança Zero-Trust**: nenhum usuário ou componente deve possuir permissões além das estritamente necessárias para a execução de suas atribuições acadêmicas ou administrativas.

---

## 2. Definição dos Perfis de Usuário (Roles)

O sistema opera com três papéis institucionais mutuamente exclusivos em cada contexto de sessão:

| Papel (*Role*) | Identificador do Token | Descrição e Atribuições Institucionais |
|---|---|---|
| **Aluno** | `ROLE_ALUNO` | Estudante regularmente matriculado em disciplinas da instituição. Tem permissão para consultar suas próprias notas, submeter tarefas e verificar registros de frequência. Não tem permissão para alterar critérios de avaliação nem abonar faltas. |
| **Professor** | `ROLE_PROFESSOR` | Docente responsável pela ministração de aulas, lançamento de avaliações, aplicação de penalidades por atraso em tarefas e validação manual de frequência de seus alunos. |
| **Instituição / Admin** | `ROLE_ADMIN` | Administrador acadêmico e de infraestrutura. Possui privilégios de gestão cadastral, auditoria de logs acadêmicos, configuração de parâmetros do sistema e gerenciamento de permissões. |

---

## 3. Matriz de Controle de Acesso a Recursos e Endpoints (RBAC Matrix)

A tabela a seguir especifica as permissões para cada rota da API e funcionalidade da aplicação:

| Recurso / Endpoint | Operação | Aluno (`ROLE_ALUNO`) | Professor (`ROLE_PROFESSOR`) | Administrador (`ROLE_ADMIN`) | Regra de Negócio e Validação de Segurança |
|---|---|:---:|:---:|:---:|---|
| **`/api/presenca`** *(Automática)* | Submeter minutos assistidos em aula ao vivo | **PERMITIDO** | **PERMITIDO** | **PERMITIDO** | Aluno pode registrar apenas a própria presença via token de sessão. |
| **`/api/presenca`** *(Manual)* | Submeter parâmetro `statusManual` | **NEGADO** | **PERMITIDO** | **PERMITIDO** | Apenas professores e admins podem aplicar overrides manuais de frequência (`PRESENCA_INTEGRAL`, `MEIA_PRESENCA`, `FALTA_AUTOMATICA`). |
| **`/api/tarefas/calcular-nota`** | Calcular nota com desconto de atraso | **LEITURA** *(Simulação)* | **EXECUÇÃO** *(Lançamento Oficial)* | **EXECUÇÃO** | Aluno pode visualizar a simulação de desconto; apenas o professor confirma a nota no diário de classe. |
| **`/api/notas/boletim`** | Calcular médias ponderadas e emitir status | **LEITURA** *(Próprio)* | **GESTÃO** *(Turma)* | **GESTÃO** *(Geral)* | Alunos não podem visualizar dados de outros estudantes (isolamento estrito por `student_id`). |
| **`/api/teste-tipos`** | Teste de conversão de tipos primitivos | **NEGADO** | **NEGADO** | **PERMITIDO** | Endpoint de diagnóstico e teste de infraestrutura. Bloqueado em produção para usuários finais. |
| **Recuperação de Senha** | Solicitar redefinição de credenciais | **PERMITIDO** | **PERMITIDO** | **PERMITIDO** | Sujeito à regra institucional de validade de 5 minutos e rate limiting. |
| **Logs de Auditoria** | Visualizar trilha de auditoria acadêmica | **NEGADO** | **NEGADO** | **PERMITIDO** | Acesso restrito a auditores e equipe de segurança para conformidade legal. |

---

## 4. Mecanismo de Autenticação e Validação de Tokens

### 4.1 Estrutura do Token de Acesso (JWT Bearer)
O controle de acesso é aplicado de forma desacoplada através de tokens criptográficos assinados no formato **JSON Web Token (JWT)**, transportados no cabeçalho HTTP:
```http
Authorization: Bearer <token_jwt>
```

#### Claims Obrigatórias no Payload:
- `sub`: Identificador único do usuário no banco de dados (UUID / ObjectId).
- `ra_matricula`: Registro Acadêmico ou número de matrícula funcional do usuário.
- `role`: Papel atribuído (`ROLE_ALUNO`, `ROLE_PROFESSOR` ou `ROLE_ADMIN`).
- `iss`: Emissor oficial (`agmrm-auth-service`).
- `aud`: Audiência (`agmrm-portal`).
- `iat`: Timestamp Unix de emissão.
- `exp`: Timestamp Unix de expiração (máximo de 3600 segundos para sessões normais).

### 4.2 Fluxo de Autorização no Servidor
1. **Extração do Cabeçalho**: O servidor intercepta a requisição e extrai o token do cabeçalho `Authorization`.
2. **Verificação Criptográfica**: Validação da assinatura HMAC-SHA256 (`HS256`) contra `JWT_SECRET`.
3. **Checagem de Validade Temporal**: Rejeição imediata se `current_time > exp`.
4. **Verificação de Permissão RBAC**: Verificação se a `role` contida no payload possui autorização para o endpoint e para a operação pretendida.
5. **Aplicação do Isolamento de Tenant/Contexto**: Caso um aluno solicite o boletim via `/api/notas/boletim`, o servidor assegura que o registro solicitado pertença estritamente ao identificador `sub` contido no token verificado.

---

## 5. Tratamento de Violações de Acesso

Qualquer tentativa de acesso a recursos não autorizados deve disparar a seguinte sequência de ações pelo servidor:
1. **Rejeição com Código HTTP Adequado**:
   - `HTTP 401 Unauthorized`: Token ausente, inválido, malformado ou expirado.
   - `HTTP 403 Forbidden`: Token válido, porém o usuário não possui o papel ou escopo necessário para executar a ação solicitada (ex: Aluno tentando enviar `statusManual` em `/api/presenca`).
2. **Mascaramento da Resposta**: O corpo da resposta deve conter apenas uma mensagem de erro genérica em português (*"Acesso negado: privilégios insuficientes"*), sem vazar detalhes da arquitetura interna.
3. **Auditoria de Eventos Suspeitos**: Gravação imediata do evento no arquivo de log de segurança (`logs/audit_academic.log`), contendo:
   - Data/Hora UTC
   - IP de origem
   - Rota requisitada
   - Identificador do usuário (se autenticado)
   - Motivo da recusa
