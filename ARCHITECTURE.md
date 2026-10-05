# Arquitetura do Projeto Frontend (Flutter Web)

Este documento detalha a estrutura de diretórios e a arquitetura adotada na aplicação Flutter do **Portal Acadêmico AGMRM**.

---

## 🏛️ Clean Architecture (Arquitetura Limpa)

A aplicação foi organizada seguindo os princípios de **Clean Architecture**, promovendo a separação clara de responsabilidades, independência de frameworks e alta testabilidade.

```
lib/
├── app/
│   ├── data/
│   │   ├── datasources/
│   │   │   └── auth_remote_datasource.dart       # Contrato da fonte de dados remota
│   │   └── repositories/
│   │       └── auth_repository_impl.dart         # Implementação concreta do repositório
│   ├── domain/
│   │   ├── repositories/
│   │   │   └── auth_repository.dart              # Interface do repositório no domínio
│   │   └── usecases/
│   │       └── recover_password_usecase.dart     # Regra de negócio (Recuperação de Senha)
│   ├── external/
│   │   └── datasources/
│   │       └── auth_remote_datasource_impl.dart  # Integração com API/HTTP remota
│   └── presentation/
│       ├── controllers/
│       │   └── recover_password_controller.dart  # Gerenciamento de estado (ChangeNotifier)
│       ├── pages/
│       │   └── recover_password_page.dart        # Página principal responsiva
│       └── widgets/
│           ├── top_header_bar.dart               # Barra superior com branding AGMRM
│           ├── recovery_input_field.dart         # Campo de entrada com ícone e rótulo duplo
│           ├── security_alert_banner.dart        # Alerta de segurança de 5 minutos
│           ├── primary_action_button.dart        # Botão escuro de ação com spinner
│           └── recovery_footer_links.dart        # Links inferiores de suporte
└── core/
    ├── errors/
    │   └── failures.dart                         # Tratamento de exceções e falhas
    ├── theme/
    │   └── app_theme.dart                        # Design System (Plus Jakarta Sans, Cores)
    └── utils/
        └── input_validators.dart                 # Validações sintáticas de campos
```

---

## 📦 Camadas do Sistema

### 1. **Domain Layer (`lib/app/domain`)**
Contém a lógica de negócio pura do sistema. Não depende de nenhuma biblioteca externa ou do Flutter SDK.
- **UseCases**: Encapsulam fluxos de negócio específicos (ex: `RecoverPasswordUseCase`).
- **Repositories (Interfaces)**: Contratos abstratos implementados pela camada de Data.

### 2. **Data Layer (`lib/app/data`)**
Orquestra o fluxo de dados entre a camada de domínio e as fontes de dados externas.
- **Datasources (Interfaces)**: Abstração das chamadas de API ou banco local.
- **Repository Implementations**: Implementações concretas dos contratos do domínio.

### 3. **External Layer (`lib/app/external`)**
Contém a integração real com serviços externos, APIs HTTP ou SDKs terceiros (`AuthRemoteDataSourceImpl`).

### 4. **Presentation Layer (`lib/app/presentation`)**
Responsável pela interface do usuário (UI) e gerenciamento de estado.
- **Controllers**: Gerenciam os estados reativos da tela (`RecoverPasswordController`).
- **Pages & Widgets**: Componentes modulares e reutilizáveis construídos em Flutter.

### 5. **Core Layer (`lib/core`)**
Recursos compartilhados por todo o aplicativo, incluindo tema visual (**Plus Jakarta Sans**), validadores e tratamento de erros.

---

## 🧪 Testes

A estrutura de testes espelha as camadas do domínio e apresentação:
```
test/
├── domain/
│   └── usecases/
│       └── recover_password_usecase_test.dart
├── presentation/
│   └── controllers/
│       └── recover_password_controller_test.dart
└── widget_test.dart
```
