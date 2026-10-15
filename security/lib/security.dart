// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Enterprise Defense-in-Depth Security Architecture Library for AGMRM.
///
/// Centralizes security policies, authentication guards, input sanitizers,
/// password entropy evaluators, and security UI widgets.
library;

// Policies & Invariants (Milestone 1)
export 'policies/security_constants.dart';
export 'policies/generic_feedback_policy.dart';

// Validators & Sanitizers (Milestone 2)
export 'validators/input_sanitizer.dart';
export 'validators/password_entropy_validator.dart';

// Authentication & Token Lifecycles (Milestones 3 & 4)
export 'auth/lockout_state.dart';
export 'auth/rate_limiter.dart';
export 'auth/timing_attack_mitigation.dart';
export 'auth/token_lifecycle_manager.dart';

// Presentation Widgets
export 'widgets/lockout_countdown_banner.dart';
export 'widgets/token_timer_widget.dart';
