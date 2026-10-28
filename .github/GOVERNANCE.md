# Governance, CI/CD Automation & IDE Configurations — `.github`

> **Institutional Module**: `.../PI-IV-Time3/.github/`  
> **Ecosystem**: Integrated Educational Platform AGMRM (*PI-IV Team 3*)  
> **Engineering Standards**: Strict Gitflow, Defense-in-Depth, Transparent Automation, Mandatory Peer Reviews  

The `.github` directory centralizes repository governance, code ownership rules (*Code Ownership*), CI/CD branch protection guardrails, and shared IDE profiles for the **Integrated Educational Platform AGMRM**.

---

## 🏛️ Governance Directory Structure

```
.../PI-IV-Time3/.github/
├── .vscode/                      # Shared IDE configuration templates (VS Code)
│   ├── launch.json               # Debugging and launch configurations (Flutter Desktop/Web + Java)
│   └── tasks.json                # Background build tasks and non-blocking server execution
├── workflows/
│   └── restrict-main.yml         # Automated GitHub Actions workflow protecting main branch
├── CODEOWNERS                    # Formal engineering team code review assignments
└── GOVERNANCE.md                 # Consolidated governance, CI/CD, and lifecycle manual (this file)
```

---

## 🛠️ Shared IDE Configurations (`.github/.vscode/`)

To guarantee environment uniformity across all engineering team members without relying on manual local setups, institutional VS Code configurations are versioned in `.../PI-IV-Time3/.github/.vscode/`:

1. **`launch.json`**:
   - `Portal AVA (Flutter + Backend Java)`: Executes the Flutter client with simultaneous startup of native Java services (`server/`).
   - `Portal AVA - Web Chrome`: Targeted execution in Google Chrome for web verification.
   - `Portal AVA - Windows Desktop`: Native Windows desktop execution.
2. **`tasks.json`**:
   - Defines the `start-backend-server` task, ensuring the native Java server in `server/` starts quietly in the background without blocking the development environment.

---

## 🛡️ Main Branch Protection Workflow (`restrict-main.yml`)

The automated GitHub Actions workflow at `.../PI-IV-Time3/.github/workflows/restrict-main.yml` enforces strict Gitflow integrity:

- The `main` branch represents stable production and deployment releases.
- **Pull Requests targeting `main` are accepted strictly and exclusively from the `develop` branch**.
- Direct merge attempts from feature branches trigger an automated failure, blocking the PR merge.

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

### Technical Workflow Mechanics:
1. **Trigger Condition (`on.pull_request`)**:
   - Triggers automatically whenever a Pull Request is opened, synchronized, or targeted against `main`.
2. **Isolated Runner (`runs-on: ubuntu-latest`)**:
   - Runs in a clean, deterministic Linux container within the GitHub Actions infrastructure.
3. **Branch Origin Evaluation (`github.head_ref`)**:
   - If the head branch is not `develop`, exits with status `1`, blocking merge actions in the pull request.
   - If originating from `develop`, exits with status `0`, allowing peer review and status checks to continue.

---

## 🌿 Gitflow Branching Strategy & Lifecycle

The repository follows standard **Gitflow** branching conventions:

```
[Developer / Task]
       │
       ▼
feature/new-feature ────────► PR to develop ────────► Peer Technical Review
                                    │                         │
                                    ▼                         ▼
                            Merge to develop ◄─────── Approved & Tested
                                    │
                                    ▼
                           develop ───► PR to main
                                             │
                                             ▼
                                 restrict-main.yml (Pass)
                                             │
                                             ▼
                                Final Engineering Approval
                                             │
                                             ▼
                                  Merge to main (Release)
```

### Branch Hierarchy and Permissions

| Branch | Purpose & Lifecycle | Protection Policy | Permitted PR Sources |
|---|---|---|---|
| **`main`** | Production-ready stable release codebase. | **Strictly Protected**: Direct pushes disabled; gatekeeper workflow enforced. | **Exclusively `develop`** |
| **`develop`** | Integration branch where verified features converge. | **Protected**: Requires PR and passing automated test suites. | `feature/*`, `fix/*`, `refactor/*` |
| **`feature/*`** | Isolated development of new features or UI views. | Short-lived feature branch. | Branched from `develop` |
| **`fix/*`** | Bug fixes identified in QA or automated testing. | Short-lived bugfix branch. | Branched from `develop` |
| **`hotfix/*`** | Emergency production patches. | Emergency patch branch. | Branched from `main`; merged to `main` & `develop` |

---

## 👥 Code Ownership & Reviews (`CODEOWNERS`)

Code reviews and merge authorizations are coordinated formally by the technical team members registered in `.../PI-IV-Time3/.github/CODEOWNERS`:

```text
* @Alekkzsx @GuilhermeMoreira07
```

- **Universal Scope (`*`)**: The wildcard selector assigns shared stewardship across all repository directories (`frontend/`, `server/`, `backend/`, `security/`, and `.github/`).
- **Mandatory Quality Gate**: No pull request can be merged into protected branches without formal peer review approval from designated team maintainers.

---

## 📝 Contribution Standards & Conventional Commits

### 1. Commit Message Format (Conventional Commits)
All commit messages must follow standard conventions:
- `feat:` Introduces a new feature (e.g. `feat(server): add real smtp email dispatch for otp recovery`).
- `fix:` Fixes a defect or bug (e.g. `fix(security): resolve test suite path references`).
- `docs:` Documentation changes (e.g. `docs(root): align readme with project presentation standards`).
- `refactor:` Code modifications that neither fix bugs nor add new features.
- `test:` Addition or update of automated test suites.
- `ci:` Pipeline and repository automation workflow adjustments.

### 2. Pre-Submission Pull Request Checklist
Before opening a Pull Request for review:
- [ ] Code strictly follows architectural boundaries (Feature-First Clean Architecture in `frontend/`, native POJO in `server/`).
- [ ] Source branch is rebased or updated with `develop`.
- [ ] All automated tests pass locally (`cd frontend && flutter test`, `cd security && flutter test`).
- [ ] Static analysis completes with 0 warnings (`flutter analyze`).
- [ ] No local credentials or active `.env` files are tracked (only `.env-example` as a template).

---

## 🔒 Security Governance Alignment

- All CI/CD workflows, secrets management, and socket networking policies follow the enterprise standards documented in [`.../PI-IV-Time3/security/`](../security/README.md).
- Any security vulnerabilities or edge-case exploits must be disclosed responsibly to the project engineering team.
