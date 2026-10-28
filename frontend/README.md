# Frontend — Portal Acadêmico Integrado AGMRM

O módulo `frontend` abriga a aplicação multiplataforma cliente da **Plataforma Educacional Integrada AGMRM** (*PI-IV Time 3*), desenvolvida em **Flutter 3** e Dart. Fornece interface institucional completa, acessível e responsiva para os três perfis de usuários: **Discente (*Aluno*)**, **Docente (*Professor*)** e **Administrador (*Admin*)**.

---

## 🏛️ Arquitetura (Feature-First Clean Architecture)

O código é estritamente estruturado em torno da Clean Architecture orientada a funcionalidades (*Feature-First*), desacoplando a camada de domínio das tecnologias de apresentação e fontes externas de dados:

$$\text{Presentation Layer (Widgets & Controllers)} \longleftrightarrow \text{Domain Layer (UseCases & Entities)} \longleftrightarrow \text{Data Layer (Repositories & DataSources)}$$

### Módulos Funcionais Principais:
1. **`auth`**: Fluxos completos de autenticação segura e recuperação de credenciais:
   - Login multiperfil (Aluno, Docente, Admin).
   - Esqueci a Senha com mitigação de canal lateral (*timing attacks*).
   - Validação de OTP com contagem regressiva de token efêmero.
   - Redefinição de senha com indicador de entropia de 4 fatores.
2. **`student`**: Portal do Aluno com notas semestrais, diário de frequência, quadro de horários, calendário acadêmico e visualização de pendências regimentais.
3. **`teacher`**: Portal do Docente com lançamento de avaliações, diário de classe com chamada digital, homologação de presença e gestão de materiais pedagógicos.
4. **`admin`**: Portal de Administração Acadêmica com cadastro de usuários, cockpit de supervisão, secretaria institucional e trava regimental CONSEPE de lacre de pautas.
5. **`video_call`**: Módulo institucional de Videochamada P2P / WebRTC com:
   - Sala de espera (*Lobby*) com verificação de hardware (câmera/microfone).
   - Grid de vídeo dinâmico e detecção de orador ativo com histerese (*Active Speaker*).
   - Fila ordenada de dúvidas (Mãos Levantadas) e chat em tempo real.
   - Compartilhamento de tela e gravação de sessão com ledger institucional.
   - Abertura regimental de salas restrita a Docente ou Admin.
6. **`multiperfil`**: Ponte de interoperabilidade acadêmica (*Academic Bridge*) conectando em tempo real as ações entre Aluno, Docente e Admin.

---

## 📂 Estrutura de Diretórios

```
.../PI-IV-Time3/frontend/
├── lib/
│   ├── core/
│   │   ├── backend/
│   │   │   └── backend_process_launcher.dart  # Launcher transparente dos serviços das pastas mães
│   │   ├── errors/
│   │   ├── router/
│   │   ├── theme/
│   │   └── utils/
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── multiperfil/
│   │   ├── student/
│   │   ├── teacher/
│   │   └── video_call/
│   └── main.dart                             # Ponto de entrada da aplicação Flutter
├── test/                                     # 396 testes automatizados de unidade, widget e integração
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── multiperfil/
│   │   ├── student/
│   │   ├── teacher/
│   │   └── video_call/
│   └── widget_test.dart
├── pubspec.yaml                              # Dependências do app (incluindo agmrm_security)
└── README.md                                 # Documentação técnica do frontend (este arquivo)
```

---

## 🚀 Como Executar o Projeto

Graças ao mecanismo de automação integrado, **não é necessário executar scripts adicionais nem abrir múltiplos terminais**:

```bash
# 1. Navegue até a pasta do frontend
cd .../PI-IV-Time3/frontend

# 2. Inicie a aplicação
flutter run
```

Ao executar `flutter run`:
- O Flutter compila e inicializa a aplicação desktop/web.
- Os serviços das pastas mães (`server/` com os 13 endpoints e `backend/` com a persistência) são **iniciados automaticamente em segundo plano**.
- A biblioteca de segurança corporativa (`security/`) é resolvida e vinculada via `pubspec.yaml`.

---

## 🧪 Qualidade de Código e Testes

A base de código mantém padrão corporativo rigoroso:

```bash
# Análise estática do código (0 alertas / 0 problemas)
flutter analyze

# Execução da suíte completa de testes (396 testes aprovados)
flutter test
```
