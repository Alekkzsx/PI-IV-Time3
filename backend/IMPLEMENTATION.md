# Autenticação e backend ADMIN

O serviço existente em TypeScript/Express continua na porta 3001. O servidor
Java de cálculos acadêmicos e videochamadas permanece separado na porta 8080.
Não foram adicionadas bibliotecas nem alterado o servidor HTTP Java.

## Execução local

Na pasta `backend`:

```powershell
npm run build
npm start
```

Para desenvolvimento, use `npm run dev`. O servidor carrega `.env.local` e
depois `.env`; variáveis do terminal têm prioridade. O arquivo `.env.example`
lista os campos. Segredos JWT e OTP devem ser diferentes e ter pelo menos
32 caracteres. O banco configurado e as contas existentes são preservados.

Se necessário, `MONGODB_DNS_SERVERS=1.1.1.1,8.8.8.8` ajusta somente o resolvedor
do processo. Nenhuma configuração de rede do Windows é modificada.
Para Flutter Web, use uma origem presente em `AUTH_CORS_ORIGINS`:

```powershell
flutter run -d chrome --web-port=5000
```

## Contratos de autenticação

| Método | Caminho | Comportamento |
|---|---|---|
| POST | /api/auth/login | Identidade ou e-mail, senha e perfil; JWT ou desafio 2FA |
| POST | /api/auth/verify-two-factor | Confirma desafio e código de seis dígitos |
| POST | /api/auth/send-recovery-otp | Solicita código de recuperação |
| POST | /api/auth/verify-recovery-otp | Troca OTP por grant de redefinição |
| POST | /api/auth/reset-password | Consome grant, troca senha e revoga sessões |
| GET | /api/auth/me | Conta autenticada, sem hash |
| GET | /api/auth/sessions | Sessões vigentes do próprio usuário |
| POST | /api/auth/logout | Encerra somente a sessão atual |
| POST | /api/auth/change-password | Exige senha atual; encerra sessões anteriores |
| POST | /api/auth/two-factor | Exige senha atual para ativar/desativar 2FA por e-mail |

O login normal conserva `{success, accessToken, tokenType}`. Quando há 2FA,
retorna HTTP 202 com `{success, requiresTwoFactor, challengeToken}`, sem JWT.
Somente a confirmação do código cria uma sessão utilizável.

JWTs são verificados por assinatura, algoritmo, expiração, identificador da
sessão, conta ativa, perfil atual e versão de segurança. Tokens anteriores à
implementação das sessões persistentes exigem novo login. Suspender, rebaixar,
alterar dados de segurança, redefinir senha ou revogar sessões invalida acessos
anteriores. A reativação da conta não restaura tokens revogados.

Cinco falhas de login bloqueiam a conta por 30 segundos. O limite é compartilhado
entre login por identidade e e-mail da mesma conta e persiste no MongoDB.
Também há limite por IP e limite de 16 KB no JSON recebido.

Senhas novas usam bcrypt com custo 12, mínimo de oito caracteres e máximo de
72 bytes UTF-8. Não são retornadas pelas APIs nem registradas em auditoria.

OTP e desafios de login têm duração limitada e três tentativas; seus códigos são
armazenados como HMAC. A verificação do OTP condiciona a gravação ao digest
efetivamente lido, evitando consumir um código novo por causa de um pedido
antigo. O grant é consumido na mesma transação que altera a senha e revoga sessões.

## Contratos do ADMIN

Todas as rotas abaixo exigem uma conta ADMIN ativa e sessão vigente.

| Método | Caminho (prefixo /api/admin) | Recurso |
|---|---|---|
| GET, POST | /users | Listagem e cadastro |
| GET, PATCH | /users/:id | Consulta e edição |
| PATCH | /users/:id/status | Suspensão/ativação e motivo |
| GET | /users/:id/sessions | Sessões reais da conta |
| POST | /users/:id/revoke-sessions | Revogação de todos os acessos |
| POST | /users/:id/reset-password | Recuperação por e-mail |
| GET | /users/:id/dossier | Conta, vínculos e auditoria |
| GET, POST | /courses | Cursos e componentes curriculares |
| GET, PATCH | /courses/:code | Consulta e edição do curso |
| GET, POST | /classes | Turmas |
| GET, PATCH | /classes/:classCode | Dados, docente, regime, capacidade e estado da pauta |
| GET, POST | /classes/:classCode/enrollments | Matrículas |
| PATCH | /classes/:classCode/enrollments/:id | Cancelamento de matrícula |
| GET, POST | /classes/:classCode/sessions | Aulas |
| PATCH | /classes/:classCode/sessions/:id | Reagendamento/cancelamento de aula |
| GET | /dashboard | Contagens dos dados persistentes |
| GET | /audit-logs | Eventos reais da administração |
| GET, POST | /protocols | Protocolos de secretaria |
| PATCH | /protocols/:id/decision | Parecer único de deferimento/indeferimento |
| GET, POST | /announcements | Comunicados institucionais |
| GET, POST | /calendar | Eventos do calendário |
| GET, PATCH | /settings | Diretrizes e trava regimental |

`GET /users` preserva a resposta como array e suporta `profile`, `active`,
`search`, `limit` (até 500) e `offset`. O total vem em `X-Total-Count`.
Professores e alunos são usuários filtrados por perfil; não foram criadas
coleções duplicadas. Disciplinas continuam nos componentes do curso.

E-mails têm unicidade sem diferenciar maiúsculas de minúsculas. Identidades são
normalizadas. Campos desconhecidos são rejeitados. Alterar o perfil de uma conta
com vínculos acadêmicos ativos exige resolver esses vínculos primeiro.
Não há exclusão física de usuários ou dados acadêmicos.

As gravações administrativas usam transações e um registro compartilhado de
serialização para impedir exceder vagas ou perder o último administrador em
mudanças simultâneas. As operações que modificam dados gravam auditoria na mesma
transação. O histórico não contém senhas, JWTs, códigos OTP ou URI de conexão.

A consulta de dossiê é um recurso administrativo de leitura e gera auditoria.
O modo de suporte visual não emite tokens em nome de outra pessoa e não concede
permissões adicionais.

## Flutter

O portal carrega usuários, turmas, cursos, protocolos, auditoria, diretrizes e
indicadores reais. Cadastro, edição, suspensão, revogação, recuperação, atribuição
docente, regime, estado da pauta, protocolos, comunicados e trava regimental
confirmam a gravação antes de informar sucesso. Erros da API são apresentados.

A sessão local expira conforme o JWT; respostas de revogação levam ao login.
Uma resposta atrasada de uma sessão anterior não encerra um login novo.
O login trata o desafio de 2FA; a área de segurança permite alterar senha e
segundo fator com confirmação da senha atual. A recuperação não inventa nome,
e-mail ou vínculo institucional para a identidade informada.

Os métodos locais de demonstração e a ponte entre os portais da equipe foram
preservados. Páginas de supervisão e abas auxiliares que já apresentam conteúdos
de demonstração não substituem os registros acadêmicos do servidor Java.
A trava de pauta é um estado administrativo persistente; esta entrega não
reescreve os lançamentos de notas do módulo docente.

## Testes

```powershell
npm test
$env:RUN_DB_TESTS = "1"
npm run test:integration
Remove-Item Env:RUN_DB_TESTS
```

O primeiro comando compila e executa os testes locais. A integração é explícita,
usa um banco `agmrm_test_<identificador aleatório>` no Atlas e remove somente
esse banco ao terminar. Não modifica as contas do `agmrm`. É necessário um
usuário Mongo com permissão para criar e remover esse banco temporário.

Há verificações de concorrência de matrículas, OTP, redefinição e alteração de
administradores, além de testes de sessão, autorização e operações institucionais.
Os testes de e-mail usam um emissor simulado; não enviam mensagens reais.

Na pasta `frontend`, execute `flutter analyze` e `flutter test`.
Os testes visuais de recuperação usam HTTP simulado e não dependem de um OTP
universal na aplicação.

## Configuração externa pendente

O ambiente local atual não possui os campos SMTP completos. Login por senha e
ADMIN funcionam; recuperação e 2FA por e-mail exigem configurar SMTP para enviar
mensagens reais. Sem configuração, a API retorna 503, inclusive para identidades
inexistentes na recuperação. Ela não confirma envio nem habilita 2FA por conta
sem um emissor disponível. Os endereços `example.com` do seed são fictícios.

Nenhum commit ou push foi executado.

## Validação executada

| Verificação | Resultado |
|---|---|
| Build TypeScript | Aprovado |
| Testes locais do backend e seed | 18 aprovados |
| Integração com Atlas em banco temporário | 13 aprovados |
| Flutter analyze | Nenhum problema |
| Testes Flutter | 426 aprovados |
| Testes do pacote security | 37 aprovados |
| Build Flutter Web | Aprovado, saída em frontend/build/web |
| Inicialização do servidor compilado com .env.local | Validada |
| Quatro logins, logout e restrição administrativa no agmrm | Validados |
| Reexecução do comando padrão do seed | Zero criados, nove reutilizados |

Não foi enviado e-mail real: o ambiente permanece sem SMTP completo.

## Arquivos para revisão

A lista inclui o seed concluído na etapa anterior. Lockfiles e arquivos gerados
que já estavam alterados foram preservados. O .env.local continua ignorado; nesta
etapa foi acrescentada somente a configuração de DNS do Mongo para execução local.

### Arquivos novos

- [backend/.env.example](../backend/.env.example)
- [backend/IMPLEMENTATION.md](../backend/IMPLEMENTATION.md)
- [backend/src/config/local-environment.ts](../backend/src/config/local-environment.ts)
- [backend/src/modules/admin/admin-operations.controller.ts](../backend/src/modules/admin/admin-operations.controller.ts)
- [backend/src/modules/admin/admin-support.ts](../backend/src/modules/admin/admin-support.ts)
- [backend/src/modules/admin/admin-users.controller.ts](../backend/src/modules/admin/admin-users.controller.ts)
- [backend/src/modules/auth/infrastructure/mongo-auth-security.repository.ts](../backend/src/modules/auth/infrastructure/mongo-auth-security.repository.ts)
- [backend/src/modules/auth/infrastructure/session.middleware.ts](../backend/src/modules/auth/infrastructure/session.middleware.ts)
- [backend/src/modules/auth/presentation/session.controller.ts](../backend/src/modules/auth/presentation/session.controller.ts)
- [backend/src/scripts/admin-demo.seed.test.ts](../backend/src/scripts/admin-demo.seed.test.ts)
- [backend/src/scripts/admin-demo.seed.ts](../backend/src/scripts/admin-demo.seed.ts)
- [backend/src/scripts/seed-admin.ts](../backend/src/scripts/seed-admin.ts)
- [backend/src/shared/transaction.ts](../backend/src/shared/transaction.ts)
- [backend/src/shared/validation.ts](../backend/src/shared/validation.ts)
- [backend/src/tests/backend.integration.test.ts](../backend/src/tests/backend.integration.test.ts)
- [frontend/lib/core/network/authenticated_api_client.dart](../frontend/lib/core/network/authenticated_api_client.dart)
- [frontend/lib/features/admin/shared/data/admin_remote_data_source.dart](../frontend/lib/features/admin/shared/data/admin_remote_data_source.dart)
- [frontend/lib/features/admin/users/presentation/widgets/user_edit_dialog.dart](../frontend/lib/features/admin/users/presentation/widgets/user_edit_dialog.dart)
- [frontend/lib/features/auth/shared/presentation/change_password_dialog.dart](../frontend/lib/features/auth/shared/presentation/change_password_dialog.dart)
- [frontend/test/core/network/authenticated_api_client_test.dart](../frontend/test/core/network/authenticated_api_client_test.dart)

### Arquivos modificados

- [backend/README.md](../backend/README.md)
- [backend/package.json](../backend/package.json)
- [backend/src/app.ts](../backend/src/app.ts)
- [backend/src/config/environment.ts](../backend/src/config/environment.ts)
- [backend/src/modules/admin/admin-academic.controller.ts](../backend/src/modules/admin/admin-academic.controller.ts)
- [backend/src/modules/auth/application/auth.service.test.ts](../backend/src/modules/auth/application/auth.service.test.ts)
- [backend/src/modules/auth/application/auth.service.ts](../backend/src/modules/auth/application/auth.service.ts)
- [backend/src/modules/auth/domain/auth.types.ts](../backend/src/modules/auth/domain/auth.types.ts)
- [backend/src/modules/auth/infrastructure/mongo-auth.repository.ts](../backend/src/modules/auth/infrastructure/mongo-auth.repository.ts)
- [backend/src/modules/auth/infrastructure/security.providers.ts](../backend/src/modules/auth/infrastructure/security.providers.ts)
- [backend/src/modules/auth/infrastructure/smtp-recovery-email.sender.ts](../backend/src/modules/auth/infrastructure/smtp-recovery-email.sender.ts)
- [backend/src/modules/auth/presentation/auth.controller.test.ts](../backend/src/modules/auth/presentation/auth.controller.test.ts)
- [backend/src/modules/auth/presentation/auth.controller.ts](../backend/src/modules/auth/presentation/auth.controller.ts)
- [backend/src/scripts/create-auth-user.ts](../backend/src/scripts/create-auth-user.ts)
- [backend/src/server.ts](../backend/src/server.ts)
- [frontend/lib/core/state/app_user_session.dart](../frontend/lib/core/state/app_user_session.dart)
- [frontend/lib/features/admin/calendar/presentation/pages/calendar_page.dart](../frontend/lib/features/admin/calendar/presentation/pages/calendar_page.dart)
- [frontend/lib/features/admin/classes/presentation/pages/classes_page.dart](../frontend/lib/features/admin/classes/presentation/pages/classes_page.dart)
- [frontend/lib/features/admin/classes/presentation/pages/supervision_cockpit_page.dart](../frontend/lib/features/admin/classes/presentation/pages/supervision_cockpit_page.dart)
- [frontend/lib/features/admin/classes/presentation/widgets/class_alocar_docente_modal.dart](../frontend/lib/features/admin/classes/presentation/widgets/class_alocar_docente_modal.dart)
- [frontend/lib/features/admin/classes/presentation/widgets/class_regime_formula_modal.dart](../frontend/lib/features/admin/classes/presentation/widgets/class_regime_formula_modal.dart)
- [frontend/lib/features/admin/dashboard/presentation/pages/painel_geral_page.dart](../frontend/lib/features/admin/dashboard/presentation/pages/painel_geral_page.dart)
- [frontend/lib/features/admin/dashboard/presentation/widgets/admin_courses_grid_section.dart](../frontend/lib/features/admin/dashboard/presentation/widgets/admin_courses_grid_section.dart)
- [frontend/lib/features/admin/dashboard/presentation/widgets/admin_recent_protocols_panel.dart](../frontend/lib/features/admin/dashboard/presentation/widgets/admin_recent_protocols_panel.dart)
- [frontend/lib/features/admin/dashboard/presentation/widgets/emit_announcement_modal.dart](../frontend/lib/features/admin/dashboard/presentation/widgets/emit_announcement_modal.dart)
- [frontend/lib/features/admin/secretary/presentation/widgets/secretary_review_modal.dart](../frontend/lib/features/admin/secretary/presentation/widgets/secretary_review_modal.dart)
- [frontend/lib/features/admin/settings/presentation/widgets/academic_guidelines_tab.dart](../frontend/lib/features/admin/settings/presentation/widgets/academic_guidelines_tab.dart)
- [frontend/lib/features/admin/settings/presentation/widgets/security_credentials_tab.dart](../frontend/lib/features/admin/settings/presentation/widgets/security_credentials_tab.dart)
- [frontend/lib/features/admin/shared/controllers/admin_portal_controller.dart](../frontend/lib/features/admin/shared/controllers/admin_portal_controller.dart)
- [frontend/lib/features/admin/shared/data/admin_academic_data_source.dart](../frontend/lib/features/admin/shared/data/admin_academic_data_source.dart)
- [frontend/lib/features/admin/shared/data/admin_mock_data.dart](../frontend/lib/features/admin/shared/data/admin_mock_data.dart)
- [frontend/lib/features/admin/shell/presentation/pages/admin_shell_page.dart](../frontend/lib/features/admin/shell/presentation/pages/admin_shell_page.dart)
- [frontend/lib/features/admin/users/presentation/pages/users_page.dart](../frontend/lib/features/admin/users/presentation/pages/users_page.dart)
- [frontend/lib/features/admin/users/presentation/widgets/user_form_modal.dart](../frontend/lib/features/admin/users/presentation/widgets/user_form_modal.dart)
- [frontend/lib/features/admin/users/presentation/widgets/user_list_table.dart](../frontend/lib/features/admin/users/presentation/widgets/user_list_table.dart)
- [frontend/lib/features/admin/users/presentation/widgets/user_reset_password_dialog.dart](../frontend/lib/features/admin/users/presentation/widgets/user_reset_password_dialog.dart)
- [frontend/lib/features/admin/users/presentation/widgets/user_sessions_dialog.dart](../frontend/lib/features/admin/users/presentation/widgets/user_sessions_dialog.dart)
- [frontend/lib/features/auth/login/presentation/controllers/login_controller.dart](../frontend/lib/features/auth/login/presentation/controllers/login_controller.dart)
- [frontend/lib/features/auth/login/presentation/pages/login_page.dart](../frontend/lib/features/auth/login/presentation/pages/login_page.dart)
- [frontend/lib/features/auth/shared/data/auth_remote_datasource.dart](../frontend/lib/features/auth/shared/data/auth_remote_datasource.dart)
- [frontend/lib/features/auth/shared/data/auth_repository_impl.dart](../frontend/lib/features/auth/shared/data/auth_repository_impl.dart)
- [frontend/lib/features/auth/shared/domain/models/recovery_session.dart](../frontend/lib/features/auth/shared/domain/models/recovery_session.dart)
- [frontend/lib/features/auth/shared/external/auth_remote_datasource_impl.dart](../frontend/lib/features/auth/shared/external/auth_remote_datasource_impl.dart)
- [frontend/lib/features/student/shell/presentation/pages/student_portal_shell.dart](../frontend/lib/features/student/shell/presentation/pages/student_portal_shell.dart)
- [frontend/lib/features/student/shell/presentation/widgets/student_sidebar.dart](../frontend/lib/features/student/shell/presentation/widgets/student_sidebar.dart)
- [frontend/lib/features/teacher/shell/presentation/pages/docente_shell_page.dart](../frontend/lib/features/teacher/shell/presentation/pages/docente_shell_page.dart)
- [frontend/lib/main.dart](../frontend/lib/main.dart)
- [frontend/test/features/admin/admin_portal_views_test.dart](../frontend/test/features/admin/admin_portal_views_test.dart)
- [frontend/test/features/admin/settings/admin_configure_page_test.dart](../frontend/test/features/admin/settings/admin_configure_page_test.dart)
- [frontend/test/features/admin/users/user_form_modal_test.dart](../frontend/test/features/admin/users/user_form_modal_test.dart)
- [frontend/test/features/auth/auth_remote_datasource_impl_test.dart](../frontend/test/features/auth/auth_remote_datasource_impl_test.dart)
- [frontend/test/widget_test.dart](../frontend/test/widget_test.dart)

## Sugestões de commits

- `feat(auth): concluir autenticação, recuperação e revogação de sessões`
- `feat(admin): concluir APIs administrativas e integração do portal`
- `feat(seed): popular e validar os dados demonstrativos do ADMIN`

São sugestões; nenhum arquivo foi commitado ou enviado ao GitHub.
