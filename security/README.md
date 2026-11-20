# Security — Arquitetura Corporativa de Defesa e Governança (AGMRM)

> **Módulo Central de Segurança**: `.../PI-IV-Time3/security/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  
> **Padrões de Engenharia**: Defesa em Profundidade (*Defense-in-Depth*), Arquitetura Limpa, Zero Dependências Externas Desnecessárias  

---

## 1. Visão Geral Arquitetural e Propósito

O módulo `security` centraliza a arquitetura corporativa de **Defesa em Profundidade** e as políticas de governança cibernética da plataforma AGMRM. Ele protege fluxos de autenticação, mecanismos de recuperação de credenciais e comunicações via sockets HTTP contra vulnerabilidades críticas (OWASP Top 10), incluindo:

- Ataques de força bruta e *credential stuffing*.
- Injeção de SQL (SQLi) e Cross-Site Scripting (XSS).
- Ataques de temporização por canal lateral (*side-channel timing attacks*) na validação de credenciais e tokens.
- Coleta de identidades de usuários e enumeração de contas entre os perfis de aluno, docente e administrador.
- Sequestro de sessão e adulteração de tokens efêmeros.
- Amplificação de memória e Negação de Serviço (DoS) via payloads HTTP inflados.

---

## 2. Estrutura de Diretórios

A estrutura do módulo segue rigorosamente os padrões de pacotes Dart/Flutter e as convenções corporativas de backend Java:

```
.../PI-IV-Time3/security/
├── lib/                          # Defesas no lado do cliente (Dart / Flutter)
│   ├── auth/                     # Controladores de autenticação e guardas defensivos de estado
│   │   ├── lockout_state.dart
│   │   ├── rate_limiter.dart
│   │   ├── timing_attack_mitigation.dart
│   │   └── token_lifecycle_manager.dart
│   ├── policies/                 # Invariantes e políticas de respostas opacas
│   │   ├── generic_feedback_policy.dart
│   │   └── security_constants.dart
│   ├── student/                  # Submódulo de proteção e integridade do portal discente
│   │   ├── integrity/            # student_sha256_engine.dart, student_submission_integrity_verifier.dart
│   │   ├── policies/             # student_security_limits.dart, student_security_policy.dart
│   │   ├── rate_limiting/        # student_action_rate_limiter.dart, student_action_type.dart
│   │   ├── sanitizers/           # student_forum_content_sanitizer.dart, student_text_input_sanitizer.dart
│   │   ├── validators/           # student_file_upload_validator.dart, student_git_repository_validator.dart, student_magic_bytes_inspector.dart
│   │   ├── widgets/              # student_integrity_badge.dart, student_password_entropy_meter.dart, student_rate_limit_cooldown_banner.dart
│   │   └── student_security.dart # Exportação unificada das defesas discentes
│   ├── validators/               # Sanitizadores de entrada e avaliadores de entropia de senha
│   │   ├── input_sanitizer.dart
│   │   └── password_entropy_validator.dart
│   ├── widgets/                  # Componentes visuais defensivos institucionais
│   │   ├── lockout_countdown_banner.dart
│   │   └── token_timer_widget.dart
│   └── security.dart             # Exportação unificada (barrel) do pacote
├── test/                         # 125 testes automatizados em Dart (21 arquivos de teste)
│   ├── student/                  # 10 suítes dedicadas à integridade, uploads, sanitização e rate-limit discente
│   ├── cross_feature_security_test.dart
│   ├── e2e_test_runner.dart
│   ├── generic_feedback_test.dart
│   ├── input_sanitizer_test.dart
│   ├── m1_adversarial_challenge_test.dart
│   ├── password_entropy_test.dart
│   ├── rate_limiter_test.dart
│   ├── real_world_attack_workload_test.dart
│   ├── security_constants_test.dart
│   ├── timing_attack_test.dart
│   └── token_lifecycle_test.dart
├── server/                       # Filtros de segurança no lado do servidor (Java SE)
│   ├── src/security/
│   │   ├── auth/                 # AccountLockoutManager, ConstantTimeComparator, EphemeralRecoveryTokenManager
│   │   ├── middleware/           # SecurityHeadersFilter, BoundedBodyReader, ServerErrorSanitizer
│   │   ├── policies/             # GenericFeedbackPolicy, SecurityConstants
│   │   └── validators/           # ServerInputSanitizer, ServerPasswordEntropyValidator
│   └── test/                     # Testes adversariais e de estresse para o servidor Java (20 cenários)
│       ├── M1AdversarialChallengeTest.java
│       └── SecurityServerTestSuite.java
├── analysis_options.yaml         # Regras estritas de linter
├── pubspec.yaml                  # Manifesto do pacote agmrm_security
└── README.md                     # Manual técnico de segurança (este arquivo)
```

---

## 3. Quatro Camadas de Proteção Defensiva

```
┌────────────────────────────────────────────────────────────────────────┐
│                       CAMADA 1: DEFESA NO CLIENTE                      │
│                    (Cliente Flutter / security/lib/)                   │
│  • Banner interativo com contagem regressiva de bloqueio de 30s        │
│  • Validação de entropia de senha em 4 fatores (Pontuação >= 3)        │
│  • Temporizador de token efêmero de recuperação (TTL de 300s)          │
│  • Sanitização prévia de ID, e-mail e strings (XSS/SQLi)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ TLS 1.3 / HTTPS
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     CAMADA 2: MIDDLEWARE DEFENSIVO                     │
│                   (security/server/src/security/middleware/)           │
│  • Cabeçalhos defensivos HTTP (nosniff, DENY, CSP, HSTS)               │
│  • Limite estrito de payload de 64 KB (65.536 bytes -> HTTP 413)       │
│  • Sanitizador de erros suprimindo stack traces internos e logs de BD  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    CAMADA 3: POLÍTICAS INSTITUCIONAIS                  │
│                     (security/server/src/security/policies/)           │
│  • Respostas opacas anti-enumeração idênticas para IDs válidos/falsos  │
│  • Invariantes numéricos centralizados e limites regimentais           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  CAMADA 4: RESILIÊNCIA E ENDURECIMENTO                 │
│                      (security/server/src/security/auth/)              │
│  • Comparador de strings em tempo constante (mitigação de canal lateral)│
│  • Limitador de taxa com bloqueio de 30s após 5 falhas consecutivas    │
│  • Invalidação de token OTP e revogação de sessão após 3 erros         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Executando os Testes de Segurança

Graças ao layout padronizado do diretório `test/`, todos os testes automatizados são executados usando as ferramentas padrão do Flutter:

```bash
# Executar a suíte de testes de segurança em Dart (125 testes automatizados)
cd .../PI-IV-Time3/security
flutter test

# Executar análise estática (0 problemas)
flutter analyze
```

---

## 5. Integração com o Frontend

O pacote `agmrm_security` é vinculado como dependência de caminho local em `.../PI-IV-Time3/frontend/pubspec.yaml`:

```yaml
dependencies:
  agmrm_security:
    path: ../security
```

Qualquer atualização nas políticas de segurança, limites de taxa ou widgets defensivos é refletida imediatamente na aplicação Flutter durante `flutter run`.
