// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Biblioteca de Arquitetura de Segurança Corporativa de Defesa em Profundidade para o AGMRM.
///
/// Centraliza políticas de segurança, guardas de autenticação, sanitizadores de entrada,
/// avaliadores de entropia de senha e widgets de interface de segurança.
library;

// Políticas e Invariantes (Marco 1)
export 'policies/security_constants.dart';
export 'policies/generic_feedback_policy.dart';

// Validadores e Sanitizadores (Marco 2)
export 'validators/input_sanitizer.dart';
export 'validators/password_entropy_validator.dart';

// Autenticação e Ciclos de Vida de Tokens (Marcos 3 e 4)
export 'auth/lockout_state.dart';
export 'auth/rate_limiter.dart';
export 'auth/timing_attack_mitigation.dart';
export 'auth/token_lifecycle_manager.dart';

// Widgets de Apresentação
export 'widgets/lockout_countdown_banner.dart';
export 'widgets/token_timer_widget.dart';

// Arquitetura de Segurança da Visão do Aluno (Módulos Estruturados Semanticamente)
export 'student/student_security.dart';

