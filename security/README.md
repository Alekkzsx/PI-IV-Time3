# Security — Enterprise Defense Architecture & Governance (AGMRM)

> **Módulo Central de Segurança**: `.../PI-IV-Time3/security/`  
> **Ecossistema**: Plataforma Educacional Integrada AGMRM (*PI-IV Time 3*)  
> **Padrões de Engenharia**: Defesa em Profundidade, Clean Architecture, Zero Dependências Externas Desnecessárias  

---

## 1. Visão Geral e Propósito Arquitetural

O módulo `security` centraliza a arquitetura corporativa de **Defesa em Profundidade** (*Defense-in-Depth*) e as políticas de governança cibernética da plataforma AGMRM. Protege os fluxos de autenticação, recuperação de credenciais e comunicação HTTP contra as principais vulnerabilidades (OWASP Top 10), incluindo:

- Ataques de força bruta e *credential stuffing*.
- Injeções SQL (SQLi) e Cross-Site Scripting (XSS).
- Ataques de canal lateral por análise de tempo (*timing attacks*).
- Enumeração de identidades discentes/docentes/administrativas.
- Sequestro de sessão e falsificação de tokens efêmeros de recuperação.
- Esgotamento de memória e negação de serviço (DoS) via payloads HTTP inflados.

---

## 2. Estrutura de Pastas Organizada e Limpa

A estrutura do módulo é padronizada conforme as melhores práticas de pacotes Dart/Flutter e módulos Java corporativos:

```
.../PI-IV-Time3/security/
├── lib/                          # Defesas do lado cliente (Dart / Flutter)
│   ├── auth/                     # Controladores de autenticação e estados
│   │   ├── lockout_state.dart
│   │   ├── rate_limiter.dart
│   │   ├── timing_attack_mitigation.dart
│   │   └── token_lifecycle_manager.dart
│   ├── policies/                 # Invariantes e políticas de resposta opaca
│   │   ├── generic_feedback_policy.dart
│   │   └── security_constants.dart
│   ├── validators/               # Sanitizadores de entrada e avaliador de entropia
│   │   ├── input_sanitizer.dart
│   │   └── password_entropy_validator.dart
│   ├── widgets/                  # Componentes visuais institucionais
│   │   ├── lockout_countdown_banner.dart
│   │   └── token_timer_widget.dart
│   └── security.dart             # Barril de exportação unificado do pacote
├── test/                         # 37 testes automatizados Flutter/Dart nativos
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
├── server/                       # Guardas defensivos do servidor (Java SE)
│   ├── src/security/
│   │   ├── auth/                 # AccountLockoutManager, ConstantTimeComparator, EphemeralRecoveryTokenManager
│   │   ├── middleware/           # SecurityHeadersFilter, BoundedBodyReader, ServerErrorSanitizer
│   │   ├── policies/             # GenericFeedbackPolicy, SecurityConstants
│   │   └── validators/           # ServerInputSanitizer, ServerPasswordEntropyValidator
│   └── test/                     # Testes de estresse e adversariais do servidor
│       ├── M1AdversarialChallengeTest.java
│       └── SecurityServerTestSuite.java
├── analysis_options.yaml         # Regras de linter estrito
├── pubspec.yaml                  # Manifesto do pacote agmrm_security
└── README.md                     # Manual técnico de segurança (este arquivo)
```

---

## 3. Os 4 Níveis de Proteção Defensiva

```
┌────────────────────────────────────────────────────────────────────────┐
│                        NÍVEL 1: CLIENT DEFENSE                         │
│                    (Flutter Client / security/lib/)                    │
│  • Banner interativo de contagem regressiva de lockout (30s)           │
│  • Validação de entropia de senha em 4 fatores (Score >= 3)            │
│  • Temporizador regressivo de token efêmero de recuperação (300s TTL)  │
│  • Sanitização pré-flight de RA, e-mail e strings (neutraliza XSS/SQLi)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ TLS 1.3 / HTTPS
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  NÍVEL 2: MIDDLEWARE DEFENSIVO                         │
│                   (security/server/src/security/middleware/)           │
│  • Cabeçalhos defensivos HTTP (nosniff, DENY, CSP, HSTS)               │
│  • Teto máximo de payload de 64 KB (65.536 bytes -> HTTP 413)          │
│  • Sanitizador de erros suprime stack traces internos e do banco       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     NÍVEL 3: POLÍTICAS INSTITUCIONAIS                  │
│                     (security/server/src/security/policies/)           │
│  • Respostas opacas anti-enumeração idênticas para contas válidas/falsas│
│  • Invariantes numéricas e limites regimentais centralizados           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  NÍVEL 4: RESILIÊNCIA E HARDENING                      │
│                      (security/server/src/security/auth/)              │
│  • Comparador de tempo constante (mitigação de side-channel)           │
│  • Rate Limiter com trava de 30s após 5 falhas de autenticação         │
│  • Invalidação de token OTP de recuperação após 3 tentativas erradas   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Como Executar os Testes de Segurança

Graças à organização padronizada da pasta `test/`, os testes rodam diretamente com os comandos padrão do ecossistema Flutter:

```bash
# Executa a suíte de testes de segurança (37 testes automatizados)
cd .../PI-IV-Time3/security
flutter test

# Executa a análise estática (0 issues)
flutter analyze
```

---

## 5. Integração com o Frontend

O pacote `agmrm_security` está vinculado como dependência local no arquivo `.../PI-IV-Time3/frontend/pubspec.yaml`:

```yaml
dependencies:
  agmrm_security:
    path: ../security
```

Dessa forma, qualquer atualização nas políticas ou widgets de segurança reflete instantaneamente em tempo real na interface Flutter durante `flutter run`.
