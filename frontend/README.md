# Frontend — AGMRM Portal Acadêmico

Este módulo consolida a aplicação cliente do projeto **AGMRM Portal Acadêmico**, desenvolvida em Flutter com suporte multiplataforma (Web, Android, iOS, Windows, Linux, macOS).

---

## 🏛️ Arquitetura (Clean Architecture)

A aplicação segue rigorosamente os princípios de **Clean Architecture**, desacoplando as regras de negócio de frameworks, bibliotecas e detalhes de infraestrutura.

A estrutura em `lib/` está organizada nas seguintes camadas:

```
lib/
├── app/
│   ├── data/             # Implementação de Repositórios e Contratos de DataSources
│   │   ├── datasources/  # auth_remote_datasource.dart
│   │   └── repositories/ # auth_repository_impl.dart
│   ├── domain/           # Entidades e Casos de Uso (Regras de Negócio Puras)
│   │   ├── repositories/ # auth_repository.dart
│   │   └── usecases/     # recover_password_usecase.dart
│   ├── external/         # Implementações de I/O, APIs remotas e clientes HTTP
│   │   └── datasources/  # auth_remote_datasource_impl.dart
│   └── presentation/     # Camada de Apresentação (UI, Controllers e Widgets)
│       ├── controllers/  # recover_password_controller.dart
│       ├── pages/        # recover_password_page.dart
│       └── widgets/      # Componentes reutilizáveis (botões, banners, inputs)
├── core/                 # Elementos transversais compartilhados
│   ├── errors/           # failures.dart (Tratamento estruturado de falhas)
│   ├── theme/            # app_theme.dart (Design System com Google Fonts Plus Jakarta Sans)
│   └── utils/            # input_validators.dart (Validação de e-mail e matrícula)
└── main.dart             # Ponto de entrada e Injeção de Dependência
```

### Fluxo de Dependência
As dependências apontam sempre para o centro:
`Presentation` / `External` ➔ `Data` ➔ `Domain`
A camada de **Domain** é pura e não depende de nenhuma camada externa nem do SDK do Flutter para suas regras centrais.

---

## 📱 Suporte Multiplataforma (Cross-Platform Runners)

O módulo conta com suporte nativo completo para 6 plataformas:
- **Web**: `web/` com metadados AGMRM, PWA manifest e ícones configurados.
- **Android**: `android/` com Gradle Wrapper, Kotlin `MainActivity`, e permissões mínimas.
- **iOS**: `ios/` com Xcode project e workspace de execução.
- **Windows**: `windows/` com CMake runner nativo C++.
- **Linux**: `linux/` com CMake runner nativo GTK.
- **macOS**: `macos/` com Xcode project Cocoa nativo.

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK `^3.9.2` (ou versão 3.x compatível com Dart `^3.9.2`)
- Google Chrome instalado (para execução Web)

### Comandos de Inicialização

1. **Navegar até o módulo frontend**:
   ```bash
   cd frontend
   ```

2. **Obter as dependências**:
   ```bash
   flutter pub get
   ```

3. **Executar no navegador (Web)**:
   ```bash
   flutter run -d chrome
   ```

4. **Executar em outras plataformas**:
   ```bash
   flutter run -d windows
   flutter run -d linux
   flutter run -d macos
   flutter run -d android
   ```

---

## 🧪 Testes Automatizados

O projeto contém testes unitários e de widgets em `test/`:

- **Executar todos os testes**:
   ```bash
   flutter test
   ```

- **Executar testes com relatório de cobertura**:
   ```bash
   flutter test --coverage
   ```

- **Verificação estática / Linting**:
   ```bash
   flutter analyze
   ```

---

## 🔒 Padrões de Segurança

Para detalhes completos dos padrões de segurança implementados no frontend (como validação de entradas e validade do token de recuperação de senha de 5 minutos), consulte [SECURITY.md](SECURITY.md).
