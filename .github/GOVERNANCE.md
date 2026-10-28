# Governança, Automação CI/CD e Configurações de IDE — `.github`

> **Módulo Institucional**: `.../PI-IV-Time3/.github/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  
> **Padrões de Engenharia**: Gitflow Estrito, Defesa em Profundidade, Automação Transparente e Revisão por Pares  

O diretório `.github` centraliza a governança corporativa do repositório, regras de propriedade de código (*Code Ownership*), guardrails de CI/CD para proteção de branches e perfis de configuração compartilhada de IDE para a **Plataforma Educacional Integrada AGMRM**.

---

## 🏛️ Estrutura de Diretórios de Governança

```
.../PI-IV-Time3/.github/
├── .vscode/                      # Modelos compartilhados de configuração de IDE (VS Code)
│   ├── launch.json               # Configurações de depuração e execução (Flutter Desktop/Web + Java)
│   └── tasks.json                # Tarefas de automação de compilação e servidores em background
├── workflows/
│   └── restrict-main.yml         # Pipeline automatizado de proteção da branch main (apenas via develop)
├── CODEOWNERS                    # Atribuição formal de revisão e responsabilidade da equipe técnica
└── GOVERNANCE.md                 # Manual consolidado de governança, CI/CD e ciclo de vida (este arquivo)
```

---

## 🛠️ Configurações Compartilhadas de IDE (`.github/.vscode/`)

Para garantir uniformidade entre todos os membros da equipe de engenharia sem depender de configurações manuais locais, as configurações institucionais do VS Code estão versionadas em `.../PI-IV-Time3/.github/.vscode/`:

1. **`launch.json`**:
   - `Portal AVA (Flutter + Backend Java)`: Executa a aplicação Flutter com disparo simultâneo dos serviços nativos em Java (`server/`).
   - `Portal AVA - Web Chrome`: Execução direcionada ao Google Chrome para homologação web.
   - `Portal AVA - Windows Desktop`: Execução nativa para Windows Desktop.
2. **`tasks.json`**:
   - Define a automação `start-backend-server`, garantindo que o servidor Java nativo em `server/` seja inicializado de forma silenciosa e em segundo plano sem bloquear a IDE.

---

## 🛡️ Proteção de Branches e Guardrails (`restrict-main.yml`)

O pipeline automatizado do GitHub Actions em `.../PI-IV-Time3/.github/workflows/restrict-main.yml` implementa o modelo Gitflow estrito:

- A branch `main` representa o código estável de entrega e homologação da plataforma.
- **Pull Requests para a branch `main` são aceitos estritamente e exclusivamente a partir da branch `develop`**.
- Tentativas de merge direto a partir de branches de feature geram erro automático no pipeline, bloqueando o merge.

```yaml
name: Restrict PRs to main

on:
  pull_request:
    branches:
      - main

jobs:
  check-source-branch:
    runs-on: ubuntu-latest
    steps:
      - name: Check if source is develop
        if: github.head_ref != 'develop'
        run: |
          echo "ERROR: A branch main so aceita Pull Requests vindo da branch develop!"
          exit 1
      - name: Success
        if: github.head_ref == 'develop'
        run: echo "Branch origem é develop. Permitido!"
```

### Mecânica Técnica do Workflow:
1. **Gatilho de Execução (`on.pull_request`)**:
   - Ativa automaticamente sempre que um Pull Request é aberto, sincronizado ou direcionado contra a branch `main`.
2. **Ambiente Isolado (`runs-on: ubuntu-latest`)**:
   - Executa em runner Linux conteinerizado e determinístico no GitHub Actions.
3. **Avaliação da Origem (`github.head_ref`)**:
   - Se a branch de origem não for `develop`, emite código de saída `1` (*exit code 1*), bloqueando preventivamente a mesclagem.
   - Se originário de `develop`, avança com código `0`, liberando as verificações de status e revisão por pares.

---

## 🌿 Ciclo de Vida e Estratégia de Branches (Gitflow)

O repositório adota o modelo **Gitflow** para fluxo contínuo e integrado de desenvolvimento:

```
[Desenvolvedor / Tarefa]
       │
       ▼
feature/nova-funcionalidade ────► PR para develop ────► Revisão Técnica por Pares
                                        │                           │
                                        ▼                           ▼
                                Merge em develop ◄─────── Aprovado e Testado
                                        │
                                        ▼
                               develop ───► PR para main
                                                 │
                                                 ▼
                                     restrict-main.yml (Aprovado)
                                                 │
                                                 ▼
                                    Aprovação Final da Equipe
                                                 │
                                                 ▼
                                      Merge em main (Release)
```

### Hierarquia e Permissões de Branches

| Branch | Propósito e Ciclo de Vida | Política de Proteção | Fontes Permitidas de PR |
|---|---|---|---|
| **`main`** | Código estável de entrega e produção. | **Estritamente Protegida**: Pushes diretos desabilitados. | **Exclusivamente `develop`** |
| **`develop`** | Linha de integração onde funcionalidades e correções convergem. | **Protegida**: Exige PR e testes automatizados 100% verdes. | `feature/*`, `fix/*`, `refactor/*` |
| **`feature/*`** | Desenvolvimento isolado de novas funcionalidades ou telas. | Ramificação de trabalho de curta duração. | Originada a partir de `develop` |
| **`fix/*`** | Correção de defeitos identificados em testes ou integração. | Ramificação de trabalho de curta duração. | Originada a partir de `develop` |
| **`hotfix/*`** | Correção emergencial de falhas críticas. | Ramificação emergencial. | Originada de `main`; mesclada em `main` e `develop` |

---

## 👥 Propriedade de Código e Revisões (`CODEOWNERS`)

As revisões e aprovações de código são coordenadas formalmente pelos mantenedores e membros da equipe técnica registrados em `.../PI-IV-Time3/.github/CODEOWNERS`:

```text
* @Alekkzsx @GuilhermeMoreira07
```

- **Escopo Universal (`*`)**: O seletor atribui responsabilidade compartilhada por todo o repositório (`frontend/`, `server/`, `backend/`, `security/` e `.github/`).
- **Portão Obrigatório de Qualidade**: Nenhum Pull Request é mesclado em branches protegidas sem a aprovação formal da equipe técnica.

---

## 📝 Padrões de Contribuição e Commits Convencionais

### 1. Mensagens de Commit (Conventional Commits)
As mensagens de commit devem seguir o padrão:
- `feat:` Introduz nova funcionalidade (ex: `feat(server): adicionar suporte a disparo real de emails via smtp`).
- `fix:` Corrige um erro ou bug identificado (ex: `fix(security): ajustar path de testes de sanitizacao`).
- `docs:` Atualizações de documentação (ex: `docs(github): consolidar governanca em GOVERNANCE.md`).
- `refactor:` Alterações de código sem impacto comportamental externo.
- `test:` Adição ou refatoração de testes automatizados.
- `ci:` Modificações em pipelines ou automações de governança.

### 2. Checklist Pré-Submissão de Pull Request
Antes de abrir um PR para revisão:
- [ ] O código segue estritamente as fronteiras arquiteturais estabelecidas no ecossistema.
- [ ] A branch de origem está atualizada com a branch `develop`.
- [ ] Todos os testes automatizados executam e passam localmente (`cd frontend && flutter test`, `cd security && flutter test`).
- [ ] A análise estática de código está livre de avisos (`flutter analyze` com 0 apontamentos).
- [ ] Nenhum arquivo `.env` com senhas ou credenciais ativas foi incluído no commit (apenas `.env-example` como referência).

---

## 🔒 Alinhamento com as Políticas de Segurança

- As diretrizes de CI/CD, variáveis de ambiente e restrições de rede seguem a governança detalhada no módulo de segurança em [`.../PI-IV-Time3/security/`](../security/README.md).
- Vulnerabilidades identificadas devem ser tratadas de forma coordenada e responsável pela equipe do projeto.
