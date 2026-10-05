# Diretório de Governança e CI/CD — `.github`

Bem-vindo à documentação central de governança, automação e integração contínua do repositório **Plataforma Educacional Integrada (AGMRM — PI-IV Time 3)**.

Este diretório estabelece os padrões institucionais de qualidade de código, controle de acesso a ramificações (branches), fluxos de trabalho do GitHub Actions e governança de propriedade intelectual e revisões.

---

## 1. Visão Geral da Governança

O repositório é gerenciado por uma política rigorosa de integração contínua e revisão por pares (*peer review*), garantindo que nenhum código seja mesclado à ramificação de produção sem validação automatizada e aprovação explícita dos mantenedores designados.

```
.github/
├── CODEOWNERS                      # Política de propriedade e revisores obrigatórios
├── README.md                       # Documentação de governança, CI/CD e PRs (este arquivo)
├── SECURITY.md                     # Diretrizes de segurança do pipeline GitHub Actions
└── workflows/
    └── restrict-main.yml           # Bloqueio de PRs diretos para a branch main
```

---

## 2. Política de Branching e Fluxo de Pull Requests

Adotamos uma variação padronizada do modelo **Gitflow**, separando estritamente desenvolvimento ativo, integração contínua e lançamentos de produção.

### 2.1 Estrutura de Ramificações (Branches)

| Branch | Propósito | Proteção / Acesso | Origem Permitida para PR |
|---|---|---|---|
| `main` | Código de produção estável, auditado e liberado para implantação. | **Rigorosamente Restrita** | **Exclusivamente `develop`** |
| `develop` | Branch de integração de novas funcionalidades e correções aprovadas. | Protegida contra push direto | `feature/*`, `fix/*`, `refactor/*` |
| `feature/*` | Desenvolvimento de novas funcionalidades ou módulos. | Branch de trabalho | Ramificada a partir de `develop` |
| `fix/*` | Correção de defeitos identificados em desenvolvimento ou QA. | Branch de trabalho | Ramificada a partir de `develop` |
| `hotfix/*` | Correção urgente de incidentes críticos em produção. | Branch de emergência | Ramificada a partir de `main` |

---

## 3. Workflow de Restrição da Branch `main` (`restrict-main.yml`)

O workflow `.github/workflows/restrict-main.yml` atua como uma barreira automatizada de proteção (*gatekeeper*) para garantir que a ramificação `main` receba alterações **unicamente** provenientes da branch `develop`.

### 3.1 Comportamento da Automação

1. **Gatilho de Execução (`on.pull_request`):** O workflow é acionado automaticamente em qualquer solicitação de Pull Request cujo alvo (*target branch*) seja a `main`.
2. **Validação da Origem (`github.head_ref`):**
   - Se `github.head_ref == 'develop'`: A validação é bem-sucedida (`exit 0`), permitindo que as verificações subsequentes e revisões de código prossigam.
   - Se `github.head_ref != 'develop'`: A execução falha imediatamente com o erro:
     ```text
     ERROR: A branch main so aceita Pull Requests vindo da branch develop!
     ```
     O Pull Request é bloqueado pelo GitHub Actions, impedindo a mesclagem (*merge*).

### 3.2 Diagrama do Ciclo de Vida de um Pull Request

```
[Desenvolvedor]
      │
      ▼
feature/nova-tela ───────► PR para develop ───────► Revisão CODEOWNERS
                                │                          │
                                ▼                          ▼
                        Merge em develop ◄──────── Aprovado & Testado
                                │
                                ▼
                       develop ───► PR para main
                                         │
                                         ▼
                             restrict-main.yml (Pass)
                                         │
                                         ▼
                            Revisão Final CODEOWNERS
                                         │
                                         ▼
                                  Merge em main (Release)
```

---

## 4. Política de Propriedade de Código (`CODEOWNERS`)

O arquivo `.github/CODEOWNERS` define a responsabilidade técnica formal sobre todas as áreas do repositório:

```text
* @Alekkzsx @GuilhermeMoreira07
```

### 4.1 Responsabilidades dos Code Owners

- **@Alekkzsx (Alex Gabriel):** Arquitetura geral, consolidação do Frontend Flutter, integração e governança do repositório.
- **@GuilhermeMoreira07 (Guilherme Moreira):** Arquitetura e implementação do Backend Java Nativo, infraestrutura de execução e cálculo de regras de negócio.

### 4.2 Regras de Aprovação

- **Revisão Obrigatória:** Qualquer Pull Request aberto no repositório solicitará automaticamente a revisão de ambos os mantenedores.
- **Merge Bloqueado:** O merge só pode ser concluído após pelo menos uma aprovação formal sem pedidos de alteração pendentes.
- **Preservação de Integridade:** Modificações em arquivos sensíveis de segurança, configurações de rede ou regras de negócio exigem auditoria detalhada.

---

## 5. Diretrizes para Envio de Contribuições (PR Guidelines)

Para garantir rastreabilidade e consistência histórica, todos os contribuidores devem seguir as diretrizes abaixo:

### 5.1 Padrão de Mensagens de Commit (Conventional Commits)

Utilize prefixos semânticos padronizados:

- `feat:` Nova funcionalidade (ex: `feat(frontend): adiciona validacao de email no login`).
- `fix:` Correção de bug (ex: `fix(backend): corrige arredondamento no calculo de presenca`).
- `docs:` Alterações em documentação (ex: `docs(security): adiciona matriz de headers HTTP`).
- `refactor:` Refatoração de código sem alteração comportamental externa.
- `test:` Adição ou aprimoramento de suítes de testes unitários ou de integração.
- `ci:` Modificações em workflows do GitHub Actions ou configurações de automação.

### 5.2 Checklist Pré-Submissão de PR

Antes de abrir um Pull Request, certifique-se de que:

- [ ] O código segue as convenções de estilo e padrões de arquitetura (Clean Architecture no Frontend, POJO no Backend).
- [ ] A branch de origem está atualizada em relação à `develop` (`git merge develop` ou `git rebase develop`).
- [ ] O código compila localmente sem erros (`server/run-server.bat` ou `flutter run`).
- [ ] Os testes automatizados foram executados com sucesso (`flutter test` e `server/test-server.bat`).
- [ ] Nenhuma credencial, token ou arquivo confidencial (`.env`, certificados) foi incluído no commit.
- [ ] O título do Pull Request descreve claramente o objetivo da alteração e faz referência à respectiva issue.

---

## 6. Políticas de Segurança e Gestão de Segredos

Para diretrizes detalhadas sobre a segurança do pipeline de integração contínua, permissões de tokens do GitHub e gestão de vulnerabilidades em actions, consulte [.github/SECURITY.md](SECURITY.md).
