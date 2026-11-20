# Governança, Automação de CI/CD e Configurações de IDE — `.github`

> **Módulo Institucional**: `.../PI-IV-Time3/.github/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  
> **Padrões de Engenharia**: Gitflow Estrito, Defesa em Profundidade, Automação Transparente, Revisões por Pares Obrigatórias  

O diretório `.github` centraliza a governança do repositório, as regras de propriedade de código (*Code Ownership*), as barreiras de proteção de branches de CI/CD e os perfis compartilhados de IDE para a **Plataforma Educacional Integrada AGMRM**.

---

## 🏛️ Estrutura do Diretório de Governança

```
.../PI-IV-Time3/.github/
├── .vscode/                      # Modelos compartilhados de configuração de IDE (VS Code)
│   ├── launch.json               # Configurações de depuração e inicialização (Flutter Desktop/Web + Java)
│   └── tasks.json                # Tarefas de build em segundo plano e execução não bloqueante do servidor
├── workflows/
│   └── restrict-main.yml         # Fluxo automatizado do GitHub Actions protegendo a branch main
├── CODEOWNERS                    # Atribuições formais de revisão de código da equipe de engenharia
└── GOVERNANCE.md                 # Manual consolidado de governança, CI/CD e ciclo de vida (este arquivo)
```

---

## 🛠️ Configurações Compartilhadas de IDE (`.github/.vscode/`)

Para garantir uniformidade de ambiente entre todos os membros da equipe de engenharia sem depender de configurações locais manuais, as configurações institucionais do VS Code são versionadas em `.../PI-IV-Time3/.github/.vscode/`:

1. **`launch.json`**:
   - `Portal AVA (Flutter + Backend Java)`: Executa o cliente Flutter com inicialização simultânea dos serviços Java nativos (`server/`).
   - `Portal AVA - Web Chrome`: Execução direcionada no Google Chrome para verificação na web.
   - `Portal AVA - Windows Desktop`: Execução nativa para desktop Windows.
2. **`tasks.json`**:
   - Define a tarefa `start-backend-server`, garantindo que o servidor Java nativo em `server/` seja iniciado silenciosamente em segundo plano sem bloquear o ambiente de desenvolvimento.

---

## 🛡️ Fluxo de Proteção da Branch Main (`restrict-main.yml`)

O fluxo automatizado do GitHub Actions em `.../PI-IV-Time3/.github/workflows/restrict-main.yml` impõe integridade estrita ao Gitflow:

- A branch `main` representa versões estáveis de produção e implantação.
- **Pull Requests direcionados à `main` são aceitos estrita e exclusivamente a partir da branch `develop`**.
- Tentativas de merge direto a partir de branches de funcionalidade disparam uma falha automática, bloqueando o merge do PR.

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

### Mecânica Técnica do Fluxo:
1. **Condição de Disparo (`on.pull_request`)**:
   - Dispara automaticamente sempre que um Pull Request é aberto, sincronizado ou direcionado contra a `main`.
2. **Runner Isolado (`runs-on: ubuntu-latest`)**:
   - Executa em um contêiner Linux limpo e determinístico na infraestrutura do GitHub Actions.
3. **Avaliação da Origem da Branch (`github.head_ref`)**:
   - Se a branch de origem não for `develop`, encerra com status `1`, bloqueando ações de merge no pull request.
   - Se originado de `develop`, encerra com status `0`, permitindo que a revisão por pares e as verificações de status continuem.

---

## 🌿 Estratégia de Ramificação Gitflow e Ciclo de Vida

O repositório segue as convenções padrão do **Gitflow**:

```
[Desenvolvedor / Tarefa]
       │
       ▼
feature/new-feature ────────► PR para develop ────────► Revisão Técnica por Pares
                                    │                         │
                                    ▼                         ▼
                            Merge para develop ◄─────── Aprovado e Testado
                                    │
                                    ▼
                           develop ───► PR para main
                                             │
                                             ▼
                                 restrict-main.yml (Aprovado)
                                             │
                                             ▼
                                Aprovação Final de Engenharia
                                             │
                                             ▼
                                  Merge para main (Release)
```

### Hierarquia de Branches e Permissões

| Branch | Propósito e Ciclo de Vida | Política de Proteção | Origens de PR Permitidas |
|---|---|---|---|
| **`main`** | Base de código estável pronta para produção. | **Estritamente Protegida**: Pushes diretos desabilitados; fluxo controlador imposto. | **Exclusivamente `develop`** |
| **`develop`** | Branch de integração onde funcionalidades verificadas convergem. | **Protegida**: Requer PR e aprovação nas suítes de testes automatizados. | `feature/*`, `fix/*`, `refactor/*` |
| **`feature/*`** | Desenvolvimento isolado de novas funcionalidades ou telas de interface. | Branch de funcionalidade de curta duração. | Ramificada a partir de `develop` |
| **`fix/*`** | Correções de defeitos identificados em QA ou testes automatizados. | Branch de correção de curta duração. | Ramificada a partir de `develop` |
| **`hotfix/*`** | Correções emergenciais em produção. | Branch de correção emergencial. | Ramificada a partir de `main`; mergeada para `main` e `develop` |

---

## 👥 Propriedade de Código e Revisões (`CODEOWNERS`)

As revisões de código e autorizações de merge são coordenadas formalmente pelos membros da equipe técnica registrados em `.../PI-IV-Time3/.github/CODEOWNERS`:

```text
* @Alekkzsx @GuilhermeMoreira07
```

- **Escopo Universal (`*`)**: O seletor curinga atribui responsabilidade compartilhada em todos os diretórios do repositório (`frontend/`, `server/`, `backend/`, `security/` e `.github/`).
- **Portão de Qualidade Obrigatório**: Nenhum pull request pode ser mergeado em branches protegidas sem aprovação formal de revisão por pares dos mantenedores designados da equipe.

---

## 📝 Padrões de Contribuição e Conventional Commits

### 1. Formato de Mensagem de Commit (Conventional Commits)
Todas as mensagens de commit devem seguir as convenções padrão:
- `feat:` Introduz uma nova funcionalidade (ex.: `feat(server): add real smtp email dispatch for otp recovery`).
- `fix:` Corrige um defeito ou bug (ex.: `fix(security): resolve test suite path references`).
- `docs:` Alterações na documentação (ex.: `docs(root): align readme with project presentation standards`).
- `refactor:` Modificações de código que não corrigem bugs nem adicionam novas funcionalidades.
- `test:` Adição ou atualização de suítes de testes automatizados.
- `ci:` Ajustes de pipeline e fluxos de automação do repositório.

### 2. Checklist Pré-Submissão de Pull Request
Antes de abrir um Pull Request para revisão:
- [ ] O código segue estritamente as fronteiras arquiteturais (Clean Architecture Feature-First em `frontend/`, POJO nativo em `server/`).
- [ ] A branch de origem está com rebase realizado ou atualizada com `develop`.
- [ ] Todos os testes automatizados passam localmente (`cd frontend && flutter test`, `cd security && flutter test`).
- [ ] A análise estática é concluída com 0 avisos (`flutter analyze`).
- [ ] Nenhuma credencial local ou arquivo `.env` ativo está versionado (apenas `.env-example` como modelo).

---

## 🔒 Alinhamento com Governança de Segurança

- Todos os fluxos de CI/CD, gerenciamento de segredos e políticas de rede por sockets seguem os padrões corporativos documentados em [`.../PI-IV-Time3/security/`](../security/README.md).
- Quaisquer vulnerabilidades de segurança ou falhas em casos extremos devem ser divulgadas de forma responsável à equipe de engenharia do projeto.
