# Governance & CI/CD Automation — `.github`

The `.github` directory establishes repository governance, automated CI/CD guardrails, Gitflow branch management policies, and code review ownership rules for the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3).

---

## 🏛️ Governance & Automation Overview

To guarantee enterprise software quality and maintain production release integrity, all contributions across the repository are governed by automated GitHub Actions workflows and mandatory peer reviews. Direct pushes to production branches are prohibited, and pull requests are subject to automated origin-branch validation.

```
.github/
├── CODEOWNERS                      # Mandatory reviewers and code ownership policy
├── GOVERNANCE.md                   # Governance and CI/CD documentation (this file)
└── workflows/
    └── restrict-main.yml           # Automated gatekeeper workflow protecting main branch
```

---

## 🛡️ Main Branch Protection Workflow (`restrict-main.yml`)

The GitHub Actions workflow located at `.github/workflows/restrict-main.yml` acts as an automated pipeline gatekeeper, enforcing that the stable `main` branch accepts pull requests **strictly and exclusively** from the `develop` integration branch.

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

### Technical Workflow Mechanics
1. **Trigger Condition (`on.pull_request`)**:
   - The workflow activates automatically whenever a pull request is opened, reopened, synchronized, or targeted against the `main` branch.
2. **Execution Environment (`runs-on: ubuntu-latest`)**:
   - Runs in an isolated Linux container using the GitHub Actions runner infrastructure.
3. **Branch Origin Evaluation (`github.head_ref`)**:
   - **Unauthorized Source Branch (`github.head_ref != 'develop'`)**:
     If a developer attempts to open a PR into `main` from a personal branch, a `feature/*` branch, or a bug fix branch, the step executes, prints an error message, and exits with non-zero exit code `1`. This blocks the PR merge in the GitHub interface.
   - **Authorized Integration Branch (`github.head_ref == 'develop'`)**:
     If the pull request originates from `develop`, the success step executes with exit code `0`, allowing peer review and status checks to proceed.

---

## 🌿 Gitflow Branching Strategy

The repository follows a standardized **Gitflow** branching lifecycle:

```
[Developer Task]
       │
       ▼
feature/new-feature ────────► PR to develop ────────► CODEOWNERS Peer Review
                                    │                           │
                                    ▼                           ▼
                            Merge to develop ◄────────── Approved & Tested
                                    │
                                    ▼
                           develop ───► PR to main
                                             │
                                             ▼
                                 restrict-main.yml (Pass)
                                             │
                                             ▼
                                Final CODEOWNERS Approval
                                             │
                                             ▼
                                   Merge to main (Release)
```

### Branch Hierarchy & Permissions

| Branch | Purpose & Lifecycle | Protection Policy | Permitted PR Sources |
|---|---|---|---|
| **`main`** | Production-ready, stable, and release-tagged codebase. | **Strictly Protected**: Direct pushes disabled; status checks required. | **Exclusively `develop`** |
| **`develop`** | Integration branch where verified features, fixes, and refactors converge. | **Protected**: Direct pushes disabled; requires PR and passing tests. | `feature/*`, `fix/*`, `refactor/*` |
| **`feature/*`** | Isolated development of new capabilities or modules. | Working branch; short-lived. | Branched from `develop` |
| **`fix/*`** | Resolution of bugs identified in QA or integration. | Working branch; short-lived. | Branched from `develop` |
| **`hotfix/*`** | Emergency resolution of critical production defects. | Emergency branch. | Branched from `main`; merges to both `main` & `develop` |

---

## 👥 Repository Ownership (`CODEOWNERS`)

Code ownership and mandatory review assignments are declared in `.github/CODEOWNERS`:

```text
* @Alekkzsx @GuilhermeMoreira07
```

### Ownership Policy & Governance
- **Universal Scope (`*`)**: The wildcard selector assigns complete repository ownership across all directories (`frontend/`, `backend/`, `server/`, `security/`, and `.github/`) to the designated maintainers.
- **Designated Maintainers**:
  - **@Alekkzsx** (Alex Gabriel Soares Sousa — `RA: 24802449`): Overall system architecture, repository governance, and Flutter frontend consolidation.
  - **@GuilhermeMoreira07** (Guilherme Henrique Moreira — `RA: 25006702`): Native Java server architecture, calculation algorithms, and backend execution engine.
- **Mandatory Review Gate**: Every pull request requires mandatory review and formal approval from designated owners before it can be merged into protected branches.

---

## 📝 Contribution & Pull Request Guidelines

Contributors must follow standardized contribution practices to maintain high commit hygiene and traceability:

### 1. Conventional Commits Standard
Commit messages should follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat:` Introduces a new feature or functionality (e.g. `feat(frontend): implement password strength meter`).
- `fix:` Patches a defect or bug (e.g. `fix(server): correct weighted average rounding`).
- `docs:` Modifies documentation (e.g. `docs(security): update threat model matrix`).
- `refactor:` Code changes that neither fix a bug nor add a feature.
- `test:` Adds or refactors unit or integration tests (e.g. `test(frontend): add recover controller unit test`).
- `ci:` Changes to GitHub Actions workflows or pipeline configuration.

### 2. Pre-Submission Checklist
Prior to submitting a Pull Request for review:
- [ ] Code strictly follows architectural boundaries (Clean Architecture in `frontend/`, native POJO in `server/`).
- [ ] Source branch is up-to-date with `develop` (`git merge develop` or `git rebase develop`).
- [ ] Automated tests pass locally (`flutter test` in `frontend/` and cURL test suite in `server/tests/`).
- [ ] Code formatting and static analysis pass (`flutter analyze`).
- [ ] No credentials, API tokens, or private `.env` files are included in the commit.
- [ ] The PR description references the relevant issue or milestone.

---

## 🔒 Security Governance Alignment

- Workflow security configurations, runner token permissions, and secret management adhere to the organization standards documented in [`security/`](../security/README.md).
- To report sensitive vulnerabilities in CI/CD automation or project code, follow the responsible disclosure guidelines outlined in the security module.
