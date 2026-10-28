# Governança, Automação CI/CD e Configurações de IDE — `.github`

O diretório `.github` centraliza a governança corporativa do repositório, regras de ownership de código, guardrails de CI/CD para proteção de branches e perfis de configuração compartilhada de IDE para a **Plataforma Educacional Integrada AGMRM** (*PI-IV Time 3*).

---

## 🏛️ Estrutura do Diretório

```
.../PI-IV-Time3/.github/
├── .vscode/                      # Modelos compartilhados de configuração de IDE (VS Code)
│   ├── launch.json               # Configurações de depuração e execução (Flutter Desktop/Web)
│   └── tasks.json                # Tarefas de automação de compilação e servidores em background
├── workflows/
│   └── restrict-main.yml         # Workflow de proteção da branch main (apenas via develop)
├── CODEOWNERS                    # Atribuição formal de code ownership da equipe
├── GOVERNANCE.md                 # Manual detalhado de governança e ciclo de vida do repositório
└── README.md                     # Visão geral deste diretório (este arquivo)
```

---

## 🛠️ Configurações de IDE Compartilhadas (`.github/.vscode/`)

Para garantir uniformidade entre todos os membros da equipe sem depender de configurações manuais locais, as configurações institucionais do VS Code estão versionadas em `.../PI-IV-Time3/.github/.vscode/`:

1. **`launch.json`**:
   - `Portal AVA (Flutter + Backend Java)`: Executa a aplicação Flutter com disparo do backend Java nativo.
   - `Portal AVA - Web Chrome`: Execução direcionada ao Google Chrome.
   - `Portal AVA - Windows Desktop`: Execução direcionada ao Windows Desktop nativo.
2. **`tasks.json`**:
   - Define a task `start-backend-server`, garantindo que o servidor Java nativo em `server/` possa ser inspecionado ou inicializado de forma silenciosa e em segundo plano.

---

## 🛡️ Proteção de Branches e Guardrails (`restrict-main.yml`)

O pipeline automatizado do GitHub Actions em `.../PI-IV-Time3/.github/workflows/restrict-main.yml` implementa o modelo Gitflow estrito:

- A branch `main` representa o código estável de entrega e homologação.
- **Pull Requests para a branch `main` são aceitos estritamente e exclusivamente a partir da branch `develop`**.
- Tentativas de merge direto a partir de branches de feature geram erro automático no pipeline, bloqueando o merge.

---

## 👥 Code Owners (`CODEOWNERS`)

As revisões e aprovações de código são coordenadas formalmente pelos proprietários e mantenedores do projeto registrados em `.../PI-IV-Time3/.github/CODEOWNERS`.
