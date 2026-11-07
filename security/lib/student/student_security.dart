// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Camada de Segurança Exclusiva para a Visão do Aluno da Plataforma AGMRM.
///
/// Organizada em 6 diretórios semânticos de responsabilidade única:
/// - policies/     : Limites invariantes e regras regimentais
/// - validators/   : Validadores de arquivos, magic bytes e repositórios Git
/// - sanitizers/   : Higienizadores anti-XSS e anti-injeção para fóruns e markdown
/// - rate_limiting/: Controle de vazão discente por janelas deslizantes
/// - integrity/    : Motor SHA-256 em Dart puro e atestação de recibos
/// - widgets/      : Componentes visuais defensivos
library;

// Policies
export 'policies/student_security_limits.dart';
export 'policies/student_security_policy.dart';

// Validators
export 'validators/student_magic_bytes_inspector.dart';
export 'validators/student_file_upload_validator.dart';
export 'validators/student_git_repository_validator.dart';

// Sanitizers
export 'sanitizers/student_text_input_sanitizer.dart';
export 'sanitizers/student_forum_content_sanitizer.dart';

// Rate Limiting
export 'rate_limiting/student_action_type.dart';
export 'rate_limiting/student_action_rate_limiter.dart';

// Integrity
export 'integrity/student_sha256_engine.dart';
export 'integrity/student_submission_integrity_verifier.dart';

// Defensive UI Widgets
export 'widgets/student_password_entropy_meter.dart';
export 'widgets/student_integrity_badge.dart';
export 'widgets/student_rate_limit_cooldown_banner.dart';
