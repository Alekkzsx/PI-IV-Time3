# Módulo de Segurança Cibernética (Security Domain Module)

## 1. Visão Geral e Arquitetura do Módulo

O módulo **`security/`** consolida o domínio de governança de segurança cibernética, conformidade regulatória, modelagem de ameaças e políticas de proteção de dados para o repositório monorepo **Portal Acadêmico AGMRM** (`PI-IV-Time3`).

Este módulo atua como a espinha dorsal de conformidade do projeto, definindo as regras, contratos e requisitos que devem ser observados e implementados pelos demais módulos:
- **`frontend/`**: Aplicação Flutter Web (interface do aluno, professor e gestor).
- **`backend/`**: Serviços de lógica acadêmica em Java (cálculo de notas, presença, conversão de tipos).
- **`server/`**: Infraestrutura e runtime de execução do servidor nativo na porta `8080`.
- **`.github/`**: Governança de integração contínua e controle de acesso a ramificações de código.

---

## 2. Mapa Estrutural do Módulo `security/`

```
security/
├── .env.example                        # Modelo oficial de variáveis de ambiente e segredos
├── README.md                           # Documentação central do domínio de segurança
├── SECURITY.md                         # Política de reporte de vulnerabilidades, SLA e contatos
├── cors/
│   ├── CORS_GUIDELINES.md              # Diretrizes operacionais de CORS para dev, staging e prod
│   └── cors_config.json                # Especificação formal em JSON para proxies e gateways
├── headers/
│   └── security_headers_guidelines.md  # Especificação técnica de CSP, HSTS, X-Frame-Options, etc.
├── policies/
│   ├── access_control_policy.md        # Política RBAC (Aluno, Professor, Instituição/Admin)
│   ├── password_and_token_policy.md    # Requisitos de senha e regra institucional de token (5 min)
│   └── data_protection_policy.md       # Conformidade com a LGPD e privacidade de dados acadêmicos
└── threat_modeling/
    └── threat_model.md                 # Modelagem formal de ameaças STRIDE + DREAD
```

---

## 3. Navegação e Índice de Ativos

| Ativo / Subdiretório | Função Primária | Público / Módulos Impactados |
|---|---|---|
| [`.env.example`](./.env.example) | Template de configuração com valores padrão seguros, limites de DoS (64KB) e segredos institucionais. | Todos os desenvolvedores, `backend/`, `server/`. |
| [`cors/`](./cors/) | Especificações de Cross-Origin Resource Sharing, restringindo origens para prevenir exploração indevida da API Java a partir de páginas web de terceiros. | `frontend/`, `server/`, gateways de borda. |
| [`headers/`](./headers/) | Definições de cabeçalhos de segurança HTTP, incluindo CSP compatível com Flutter Web Wasm/CanvasKit e Google Fonts. | `server/`, proxies reversos (Nginx/Traefik). |
| [`policies/`](./policies/) | Diretrizes formais de autorização (RBAC), governança de credenciais (regra de 5 minutos para recuperação de senha) e adequação à LGPD. | Equipes de produto, compliance e desenvolvedores. |
| [`threat_modeling/`](./threat_modeling/) | Mapeamento detalhado de vulnerabilidades da aplicação (ex: fraude de presença, manipulação de notas por atraso, esgotamento de memória heap). | Engenheiros de software, auditores e QA. |
| [`SECURITY.md`](./SECURITY.md) | Procedimentos de divulgação responsável (*Responsible Disclosure*), matriz de SLA para correção e canais de contato de segurança. | Comunidade, pesquisadores de segurança e usuários. |

---

## 4. Linha de Base de Segurança e Regras Críticas do Domínio

### 4.1 Validade Temporal de Tokens de Redefinição (Regra dos 5 Minutos)
Conforme informado no componente de interface `SecurityAlertBanner` (`lib/app/presentation/widgets/security_alert_banner.dart`), todo token de redefinição emitido pelo portal possui **validade estrita e improrrogável de 5 minutos (300 segundos)**. Qualquer submissão posterior é terminantemente rejeitada pelo sistema.

### 4.2 Restrição de CORS em Ambientes Produtivos
O uso de coringa `Access-Control-Allow-Origin: *` presente no protótipo nativo (`ServidorHttpNativo.java:58`) é **proibido em produção**. O tráfego deve ser restrito exclusivamente a origens autorizadas da instituição (`https://portal.agmrm.edu.br`).

### 4.3 Sanitização e Validação de Limites de Entrada
Os manipuladores de rotas devem aplicar validação estrita:
- `/api/presenca`: Impedir divisão por zero (`duracaoTotal > 0`) e bloquear injeção não autenticada de `statusManual`.
- `/api/tarefas/calcular-nota`: Bloquear valores negativos para `diasAtraso` (mitigando inflação fraudulenta de notas).
- `/api/notas/boletim`: Bloquear notas negativas e garantir soma de pesos consistente.

### 4.4 Defesa contra DoS no Servidor Java Nativo
O método de leitura de requisições deve impor um teto máximo de processamento em memória de **64 KB (65.536 bytes)**, prevenindo o esgotamento da memória heap da JVM.

---

## 5. Checklist de Conformidade Regulatória e Institucional

- [x] **LGPD (Lei nº 13.709/2018)**: Mapeamento de bases legais para dados escolares e prazo de retenção definido em política.
- [x] **Marco Civil da Internet (Lei nº 12.965/2014)**: Guarda obrigatória de registros de conexão por no mínimo 6 meses.
- [x] **Diretrizes do MEC / LDB**: Integridade dos cálculos de frequência mínima (75%) e fórmulas de boletim escolar.
- [x] **OWASP Top 10**: Mitigações formais documentadas para Broken Access Control, Cryptographic Failures e Injection.
- [x] **Mascaramento de Segredos**: Arquivos `.env` protegidos no `.gitignore`, preservando apenas o template auditável `.env.example`.
