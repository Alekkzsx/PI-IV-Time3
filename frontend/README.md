# Frontend — AGMRM Academic Portal Client

The `frontend` module houses the cross-platform client application for the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3). Built with **Flutter 3** and Dart, this application provides a responsive, institutional user interface for Students (*Aluno*), Faculty (*Docente*), and Administrators (*Admin*).

The codebase strictly adheres to **Feature-First Clean Architecture**, enforcing clear separation of concerns, modularity, framework independence in domain layers, and comprehensive automated testability across both authentication workflows (`auth_view`) and the student academic portal (`student_view`).

---

## 🏛️ Architectural Overview (Feature-First Clean Architecture)

The application organizes features by functional domain (`auth_view` and `student_view`), isolating business rules and entities from presentation widgets and external data sources:

$$\text{Presentation Layer} \longleftrightarrow \text{Domain Layer} \longleftrightarrow \text{Data Layer} \longleftrightarrow \text{External Layer}$$

```text
frontend/
├── lib/
│   ├── core/                                    # Shared design tokens, failures, and validators
│   │   ├── errors/
│   │   │   └── failures.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       └── input_validators.dart
│   ├── features/
│   │   ├── auth_view/                           # Authentication & Password Recovery Flows
│   │   │   ├── login/
│   │   │   │   ├── domain/usecases/
│   │   │   │   │   └── login_usecase.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/
│   │   │   │       │   └── login_controller.dart
│   │   │   │       ├── pages/
│   │   │   │       │   └── login_page.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── brand_panel.dart
│   │   │   │           └── login_profile_tabs.dart
│   │   │   ├── forgot_password/
│   │   │   │   ├── domain/usecases/
│   │   │   │   │   └── recover_password_usecase.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/
│   │   │   │       │   └── recover_password_controller.dart
│   │   │   │       ├── pages/
│   │   │   │       │   └── recover_password_page.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── primary_action_button.dart
│   │   │   │           ├── profile_selector_tabs.dart
│   │   │   │           ├── recovery_input_field.dart
│   │   │   │           └── security_alert_banner.dart
│   │   │   ├── verify_code/
│   │   │   │   └── presentation/pages/
│   │   │   │       └── verify_code_page.dart
│   │   │   └── reset_password/
│   │   │       └── presentation/
│   │   │           ├── pages/
│   │   │           │   └── reset_password_page.dart
│   │   │           └── widgets/
│   │   │               ├── academic_identity_card.dart
│   │   │               ├── password_reset_field.dart
│   │   │               └── password_strength_indicator.dart
│   │   └── student_view/                        # Student Portal (Visão do Aluno - Portal AVA)
│   │       ├── student_messages/
│   │       │   ├── domain/entities/
│   │       │   │   └── academic_message.dart
│   │       │   └── presentation/
│   │       │       ├── controllers/
│   │       │       │   └── student_messages_controller.dart
│   │       │       ├── pages/
│   │       │       │   └── student_messages_page.dart
│   │       │       └── widgets/
│   │       │           ├── academic_message_card.dart
│   │       │           └── message_filter_bar.dart
│   │       └── student_secretariat/
│   │           ├── domain/entities/
│   │           │   ├── academic_record_summary.dart
│   │           │   └── protocol_request.dart
│   │           └── presentation/
│   │               ├── controllers/
│   │               │   └── student_secretariat_controller.dart
│   │               ├── pages/
│   │               │   └── student_secretariat_page.dart
│   │               └── widgets/
│   │                   ├── academic_record_card.dart
│   │                   └── protocol_requests_table.dart
│   ├── shared/                                  # Shared cross-feature repositories, layouts & widgets
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   └── auth_repository.dart
│   │   │   └── external/
│   │   │       └── auth_remote_datasource_impl.dart
│   │   ├── student_layout/
│   │   │   ├── student_portal_shell.dart
│   │   │   └── student_sidebar.dart
│   │   └── widgets/
│   │       ├── recovery_footer_links.dart
│   │       └── top_header_bar.dart
│   └── main.dart                                # Application entry point, DI & route registry
└── test/                                        # Unit and Widget test suites
    ├── features/
    │   ├── auth_view/
    │   │   ├── forgot_password/
    │   │   │   ├── domain/usecases/
    │   │   │   │   └── recover_password_usecase_test.dart
    │   │   │   └── presentation/controllers/
    │   │   │       └── recover_password_controller_test.dart
    │   │   └── login/
    │   │       ├── domain/usecases/
    │   │       │   └── login_usecase_test.dart
    │   │       └── presentation/controllers/
    │   │           └── login_controller_test.dart
    │   └── student_view/
    │       └── student_portal_test.dart
    └── widget_test.dart
```

---

## 🧩 Module & Layer Breakdown

### 1. Core Layer (`lib/core/`)
Provides shared domain-agnostic utilities, error abstractions, and design tokens:
- **`errors/failures.dart`**: Implements an immutable failure hierarchy (`Failure`, `ValidationFailure`, `ServerFailure`) for structured error propagation.
- **`theme/app_theme.dart`**: Centralizes the AGMRM institutional design tokens (`AppColors`) and typography powered by Google Fonts.
- **`utils/input_validators.dart`**: Provides static input validation utilities for academic registration numbers (RA/Matrícula) and institutional emails.

### 2. Shared Layer (`lib/shared/`)
Encapsulates infrastructure, layouts, and UI components reused across multiple features:
- **`shared/auth/`**:
  - `domain/auth_repository.dart`: Abstract contract defining authentication and password recovery operations.
  - `data/auth_remote_datasource.dart` & `data/auth_repository_impl.dart`: Repository implementation and remote data source contract.
  - `external/auth_remote_datasource_impl.dart`: Concrete network adapter simulating transport latency and error conditions.
- **`shared/student_layout/`**:
  - `student_sidebar.dart`: Collapsible vertical navigation sidebar (`StudentSidebar`, `StudentNavItem`) with 8 student portal sections (*Início*, *Disciplinas*, *Agenda*, *Desempenho*, *Mensagens*, *Secretaria*, *Perfil*, *Sair*).
  - `student_portal_shell.dart`: Responsive portal wrapper combining the sidebar (or mobile drawer), top institutional header bar with history and notification indicators, scrollable content container, and institutional footer.
- **`shared/widgets/`**:
  - `top_header_bar.dart` & `recovery_footer_links.dart`: Shared header and footer components for the authentication and recovery flows.

### 3. Authentication & Password Recovery (`lib/features/auth_view/`)
Groups all screens, controllers, use cases, and widgets dedicated to user authentication and credential recovery:
- **`login/`**:
  - `LoginUseCase`, `LoginController`, `LoginPage`, `BrandPanel`, and `LoginProfileTabs`.
  - Supports role selection (Student, Faculty, Admin), responsive split-panel desktop layout, and credential validation.
- **`forgot_password/`**:
  - `RecoverPasswordUseCase`, `RecoverPasswordController`, `RecoverPasswordPage`, `ProfileSelectorTabs`, `RecoveryInputField`, `SecurityAlertBanner`, and `PrimaryActionButton`.
  - Validates academic identity and initiates the 5-minute TTL recovery flow.
- **`verify_code/`**:
  - `VerifyCodePage`: 6-digit OTP verification step with countdown timer, code resending, and paste support.
- **`reset_password/`**:
  - `ResetPasswordPage`, `AcademicIdentityCard`, `PasswordResetField`, and `PasswordStrengthIndicator` (4-level reactive password entropy scoring).

### 4. Student Portal View (`lib/features/student_view/`)
Implements the authenticated student workspace (*Visão do Aluno* — Portal AVA AGMRM):
- **`student_messages/`** (Route: `/student/messages`):
  - `AcademicMessage` entity (`MessageCategory.institutional` and `MessageCategory.discipline`).
  - `StudentMessagesController`: Reactive filtering by category (*Todos Os Comunicados*, *Secretaria & Reitoria*, *Disciplinas*) and real-time search by keyword or faculty name.
  - `StudentMessagesPage`, `MessageFilterBar`, and `AcademicMessageCard`: Displays official university announcements with `INSTITUCIONAL` / `DISCIPLINA` badges and `Novo` indicators.
- **`student_secretariat/`** (Route: `/student/secretaria`):
  - `AcademicRecordSummary` and `ProtocolRequest` (`ProtocolStatus`) entities.
  - `StudentSecretariatController`: Manages the student's academic summary and registered protocol requests.
  - `StudentSecretariatPage`, `AcademicRecordCard`, and `ProtocolRequestsTable`: Displays the *Prontuário Acadêmico Regular* (R.A., course, CR, curriculum completion percentage, active enrollment badge), interactive modals for issuing digital enrollment declarations and submitting new requests, and the registered protocols table with official opinion viewer (*Ver Parecer*).

---

## 🧭 Application Routes (`lib/main.dart`)

| Route | Page Widget | Feature Group | Description |
|---|---|---|---|
| `/` | `LoginPage` | `auth_view` | Main institutional login screen |
| `/recover-password` | `RecoverPasswordPage` | `auth_view` | Password recovery identity request |
| `/verify-code` | `VerifyCodePage` | `auth_view` | 6-digit verification code (OTP) entry |
| `/reset-password` | `ResetPasswordPage` | `auth_view` | New password creation with strength meter |
| `/student/messages` | `StudentMessagesPage` | `student_view` | Student Messages & Official Announcements Center |
| `/student/secretaria` | `StudentSecretariatPage` | `student_view` | Virtual Secretariat, Academic Record & Protocols |

---

## 🚀 Execution & Build Guide

### Prerequisites
- **Flutter SDK**: `^3.9.2` (or compatible Flutter 3.x release)
- **Dart SDK**: `^3.9.2`

### 1. Dependency Installation
```bash
cd frontend
flutter pub get
```

### 2. Running the Client
- **Web Browser (Chrome)**:
  ```bash
  flutter run -d chrome
  ```
- **Linux / Windows / macOS Desktop**:
  ```bash
  flutter run -d linux
  # or: flutter run -d windows / flutter run -d macos
  ```
- **Android / iOS**:
  ```bash
  flutter run -d android
  # or: flutter run -d ios
  ```

---

## 🧪 Automated Testing Suite

The test directory (`frontend/test/`) mirrors the feature organization of `lib/`:
- **`test/features/auth_view/`**:
  - `login/domain/usecases/login_usecase_test.dart`: Unit tests for `LoginUseCase`.
  - `login/presentation/controllers/login_controller_test.dart`: State transition tests for `LoginController`.
  - `forgot_password/domain/usecases/recover_password_usecase_test.dart`: Unit tests for `RecoverPasswordUseCase`.
  - `forgot_password/presentation/controllers/recover_password_controller_test.dart`: Validation and state tests for `RecoverPasswordController`.
- **`test/features/student_view/`**:
  - `student_portal_test.dart`: Unit and widget tests for `StudentMessagesController`, `StudentMessagesPage`, `StudentSecretariatController`, and `StudentSecretariatPage`.
- **`test/widget_test.dart`**:
  - End-to-end widget navigation tests covering the full authentication and password recovery lifecycle across desktop and mobile viewports.

### Running Tests & Static Analysis
```bash
cd frontend

# Run static analyzer
flutter analyze

# Run all unit and widget tests
flutter test

# Run tests with coverage report
flutter test --coverage
```

---

## 🔒 Security Alignment

Client-side security controls in `frontend/` align with the platform-wide defense-in-depth policies defined in the [`security/`](../security/README.md) module:
- **Short-Lived Recovery Tokens**: Visual enforcement of the 5-minute (300s) token TTL via `SecurityAlertBanner` and `VerifyCodePage` countdown timers.
- **Input Validation & Sanitization**: Pre-flight validation via `InputValidators` and format restrictions on OTP inputs.
- **Credential Hygiene**: Multi-factor password strength validation via `PasswordStrengthIndicator` before allowing password reset submission.
