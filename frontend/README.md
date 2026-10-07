# Frontend — AGMRM Academic Portal Client

The `frontend` module houses the cross-platform client application for the **AGMRM Integrated Educational Platform** (*Plataforma Educacional Integrada* — PI-IV Time 3). Built with the **Flutter 3** framework and Dart, this application provides an enterprise-grade user interface designed for Students (*Aluno*), Faculty (*Docente*), and Administrators (*Admin*).

The codebase strictly adheres to the principles of **Clean Architecture**, enforcing separation of concerns, framework independence, and high testability across all layers.

---

## 🏛️ Architectural Overview (Clean Architecture)

The application architecture separates pure enterprise and application business logic from framework details, UI widgets, and network I/O. Data and dependencies flow inward toward the domain layer:

$$\text{Presentation Layer} \longleftrightarrow \text{Data Layer} \longleftrightarrow \text{Domain Layer} \longleftrightarrow \text{External Layer}$$

```
lib/
├── app/
│   ├── data/                   # Data Layer (Repository implementations & Datasource contracts)
│   │   ├── datasources/        # Abstract contracts for external I/O
│   │   │   └── auth_remote_datasource.dart
│   │   └── repositories/       # Concrete implementation of domain repository contracts
│   │       └── auth_repository_impl.dart
│   ├── domain/                 # Domain Layer (Pure business logic, zero UI dependencies)
│   │   ├── repositories/       # Abstract domain repository interfaces
│   │   │   └── auth_repository.dart
│   │   └── usecases/           # Callable business use cases
│   │       └── recover_password_usecase.dart
│   ├── external/               # External Layer (Network transports, simulated latency & APIs)
│   │   └── datasources/        # Concrete implementation of data contracts
│   │       └── auth_remote_datasource_impl.dart
│   └── presentation/           # Presentation Layer (UI, State Management, and Modular Widgets)
│       ├── controllers/        # Reactive state controllers extending ChangeNotifier
│       │   └── recover_password_controller.dart
│       ├── pages/              # Full-screen responsive page views
│       │   ├── login_page.dart
│       │   ├── recover_password_page.dart
│       │   └── reset_password_page.dart
│       └── widgets/            # 11 Atomic, modular UI components
│           ├── academic_identity_card.dart
│           ├── brand_panel.dart
│           ├── login_profile_tabs.dart
│           ├── password_reset_field.dart
│           ├── password_strength_indicator.dart
│           ├── primary_action_button.dart
│           ├── profile_selector_tabs.dart
│           ├── recovery_footer_links.dart
│           ├── recovery_input_field.dart
│           ├── security_alert_banner.dart
│           └── top_header_bar.dart
├── core/                       # Core Layer (Shared design system, error types, validators)
│   ├── errors/                 # Standardized failure value objects
│   │   └── failures.dart
│   ├── theme/                  # Design system token definitions & Google Fonts typography
│   │   └── app_theme.dart
│   └── utils/                  # Reusable regex and input format validators
│       └── input_validators.dart
└── main.dart                   # Application bootstrap & dependency injection composition root
```

---

## 🧩 Layer Breakdown & Responsibilities

### 1. Core Layer (`lib/core/`)
Provides shared domain-agnostic utilities, error abstractions, and design tokens:
- **`errors/failures.dart`**: Implements an immutable failure hierarchy (`Failure`, `ValidationFailure`, `ServerFailure`) supporting structured functional error propagation without throwing uncaught exceptions.
- **`theme/app_theme.dart`**: Centralizes the AGMRM design tokens via `AppColors` (institutional dark navy `#0B132B`, slate neutral background `#F8FAFC`, alert amber `#FFFBEB`, and accent borders `#CBD5E1`). Configures typography using Google Fonts **Plus Jakarta Sans**.
- **`utils/input_validators.dart`**: Provides static input validation utilities, including academic registration number (RA/Matrícula) minimum length checks ($\ge 3$ characters) and strict RFC-compliant email regex pattern matching (`^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`).

### 2. Domain Layer (`lib/app/domain/`)
The conceptual core of the application. Contains zero dependencies on Flutter UI packages or third-party libraries:
- **`repositories/auth_repository.dart`**: Defines the contract `Future<void> recoverPassword({required String identity})`.
- **`usecases/recover_password_usecase.dart`**: Encapsulates the execution workflow for triggering password recovery instructions. Injected with `AuthRepository`.

### 3. Data Layer (`lib/app/data/`)
Bridges the domain contracts with external infrastructure:
- **`datasources/auth_remote_datasource.dart`**: Abstract interface defining remote communications (`sendPasswordResetInstructions({required String identity})`).
- **`repositories/auth_repository_impl.dart`**: Implements `AuthRepository`, orchestrating the remote datasource call, mapping lower-level exceptions into domain-level `Failure` objects.

### 4. External Layer (`lib/app/external/`)
Contains concrete I/O implementations and network adapters:
- **`datasources/auth_remote_datasource_impl.dart`**: Concrete implementation of `AuthRemoteDataSource`. Simulates realistic network transport latency using `Future.delayed(Duration(milliseconds: 1500))`. Handles validation triggers (e.g., throwing a `ServerFailure` if an identity contains the term `"invalid"`).

### 5. Presentation Layer (`lib/app/presentation/`)
Responsible for rendering user interfaces and reacting to state changes:
- **State Management (`controllers/recover_password_controller.dart`)**:
  - Implements lightweight, framework-native reactive state using `ChangeNotifier`.
  - Exposes observable properties: `identity`, `isLoading`, `errorMessage`, `isSuccess`.
  - Executes client-side validation via `InputValidators` before dispatching use cases.

#### Page Views (`lib/app/presentation/pages/`)
1. **`login_page.dart`** *(Authored by Murillo Caravita)*:
   - Institutional entry point with a responsive dual-layout (desktop side-by-side split banner vs. mobile compact column layout).
   - Profile selection between Student, Faculty, and Admin.
   - Credentials input with real-time validation and routing to recovery flows.
2. **`recover_password_page.dart`** *(Authored by Marcelo Zarpelon)*:
   - Identity input step for password reset link requests.
   - Binds directly to `RecoverPasswordController`, displaying reactive loading states, validation error banners, and the 5-minute security alert.
   - On success, triggers animated navigation to `ResetPasswordPage`.
3. **`reset_password_page.dart`** *(Authored by Rafael Henrique Inácio)*:
   - Password update step.
   - Embeds student identity card confirmation (`Gabriel Martins • R.A. 2024.1.00892`).
   - Features password confirmation fields with visibility toggles and real-time security strength scoring.

#### Modular Widgets (`lib/app/presentation/widgets/`)
The interface is constructed from 11 atomic, reusable components:
| Widget File | Description & Technical Role |
|---|---|
| `academic_identity_card.dart` | Renders confirmed student credentials with photo placeholder and green verified badge. |
| `brand_panel.dart` | Institutional navy banner featuring radial gradients, dot grid accents, and typography. |
| `login_profile_tabs.dart` | Three-way segmented tab switcher for Student, Faculty, and Admin roles on Login. |
| `password_reset_field.dart` | Custom obscured text input field featuring eye-toggle visibility controls. |
| `password_strength_indicator.dart` | 4-level reactive score calculator evaluating length ($\ge 8$), uppercase, lowercase, numbers, and symbols with color-coded bar (Red, Amber, Blue, Green). |
| `primary_action_button.dart` | Slate navy primary button supporting asynchronous spinner loading states. |
| `profile_selector_tabs.dart` | Tab selection component tailored for the password recovery context. |
| `recovery_footer_links.dart` | Institutional footer providing contact links to Academic Office, Help Desk, and FAQ. |
| `recovery_input_field.dart` | Input field with contextual prefix icons and dynamic placeholder text per role. |
| `security_alert_banner.dart` | High-visibility warning banner reinforcing the 5-minute Time-To-Live (TTL) security token. |
| `top_header_bar.dart` | App navigation header providing back-step navigation and AGMRM logo. |

---

## 📱 Cross-Platform Support

The client is configured with production runners for six target platforms:
- **Web (`web/`)**: HTML5 canvas / canvaskit rendering, customized manifest, and AGMRM brand assets.
- **Windows (`windows/`)**: Native C++ Win32 runner configured via CMake.
- **Linux (`linux/`)**: GTK+ C++ runner configured via CMake.
- **macOS (`macos/`)**: Native Cocoa AppKit runner.
- **Android (`android/`)**: Kotlin `MainActivity` with Gradle wrapper and Android 14 compatibility.
- **iOS (`ios/`)**: Swift/Objective-C Xcode project and CocoaPods integration.

---

## 📂 Complete Directory Tree

```
frontend/
├── .flutter-plugins-dependencies
├── .gitignore
├── .metadata
├── README.md
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
├── android/
│   ├── app/
│   ├── gradle/
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
├── ios/
│   ├── Flutter/
│   ├── Runner/
│   └── Runner.xcodeproj
├── linux/
│   ├── flutter/
│   ├── runner/
│   └── CMakeLists.txt
├── macos/
│   ├── Flutter/
│   ├── Runner/
│   └── Runner.xcodeproj
├── web/
│   ├── favicon.png
│   ├── index.html
│   └── manifest.json
├── windows/
│   ├── flutter/
│   ├── runner/
│   └── CMakeLists.txt
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── errors/
│   │   │   └── failures.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       └── input_validators.dart
│   └── app/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       └── recover_password_usecase.dart
│       ├── external/
│       │   └── datasources/
│       │       └── auth_remote_datasource_impl.dart
│       └── presentation/
│           ├── controllers/
│           │   └── recover_password_controller.dart
│           ├── pages/
│           │   ├── login_page.dart
│           │   ├── recover_password_page.dart
│           │   └── reset_password_page.dart
│           └── widgets/
│               ├── academic_identity_card.dart
│               ├── brand_panel.dart
│               ├── login_profile_tabs.dart
│               ├── password_reset_field.dart
│               ├── password_strength_indicator.dart
│               ├── primary_action_button.dart
│               ├── profile_selector_tabs.dart
│               ├── recovery_footer_links.dart
│               ├── recovery_input_field.dart
│               ├── security_alert_banner.dart
│               └── top_header_bar.dart
└── test/
    ├── widget_test.dart
    ├── domain/
    │   └── usecases/
    │       └── recover_password_usecase_test.dart
    └── presentation/
        └── controllers/
            └── recover_password_controller_test.dart
```

---

## 🚀 Execution & Build Guide

### Prerequisites
- **Flutter SDK**: `^3.9.2` (or compatible Flutter 3.x release)
- **Dart SDK**: `^3.9.2`
- **Platform Toolchains**:
  - Chrome / Edge for Web development.
  - Visual Studio 2022 (C++ workload) for Windows Desktop.
  - Android Studio & Android SDK for Android.
  - Xcode & CocoaPods for iOS / macOS.

### 1. Dependency Installation
Navigate into the `frontend` directory and retrieve all project dependencies:
```bash
cd frontend
flutter pub get
```

### 2. Running the Client
To run the client application in development mode with Hot Reload enabled:

- **Web Browser (Chrome)**:
  ```bash
  flutter run -d chrome
  ```
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Linux Desktop**:
  ```bash
  flutter run -d linux
  ```
- **macOS Desktop**:
  ```bash
  flutter run -d macos
  ```
- **Mobile Device or Emulator**:
  ```bash
  flutter run -d android
  # or
  flutter run -d ios
  ```

---

## 🧪 Automated Testing Suite

The frontend includes automated unit and widget test suites located in `frontend/test/`:

### Test Coverage Targets
1. **`test/widget_test.dart`**:
   - Pumps the root `PortalAvaApp` widget tree.
   - Asserts the presence of critical login and recovery UI elements (e.g. `'Esqueceu sua senha?'` and `'Enviar Instruções de Recuperação'`).
2. **`test/domain/usecases/recover_password_usecase_test.dart`**:
   - Unit tests the `RecoverPasswordUseCase`.
   - Utilizes a mock repository implementation to verify that `recoverPassword` dispatches correctly with the expected identity payload.
3. **`test/presentation/controllers/recover_password_controller_test.dart`**:
   - Tests `RecoverPasswordController` lifecycle and reactive state transitions.
   - Asserts validation failure handling for empty and malformed inputs.
   - Verifies positive state mutation (`isLoading -> isSuccess`) upon successful use case resolution.

### Running Tests
Execute all test suites from the `frontend/` directory:
```bash
# Run all unit and widget tests
flutter test

# Run tests with code coverage analysis
flutter test --coverage

# Run static analysis and lint rule verification
flutter analyze
```

---

## 🔒 Security Alignment

Client-side security practices implemented in this module include:
- **Short-Lived Recovery Tokens**: Visual reinforcement of the 5-minute Time-To-Live (TTL) token expiration via `SecurityAlertBanner`.
- **Client-Side Sanitization**: Pre-flight validation against injection and formatting anomalies via `InputValidators`.
- **Credential Hygiene**: Password complexity rules enforced via `PasswordStrengthIndicator`.

For full cross-layer security architecture and backend policy details, see the [`security/`](../security/README.md) module documentation.
