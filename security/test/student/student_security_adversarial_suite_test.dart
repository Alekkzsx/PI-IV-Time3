// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';

// Importa todas as suítes especializadas da arquitetura semântica do aluno
import 'policies/student_security_policy_test.dart' as policies_tests;
import 'validators/student_magic_bytes_inspector_test.dart' as magic_bytes_tests;
import 'validators/student_file_upload_validator_test.dart' as file_validator_tests;
import 'validators/student_git_repository_validator_test.dart' as git_validator_tests;
import 'sanitizers/student_text_input_sanitizer_test.dart' as text_sanitizer_tests;
import 'sanitizers/student_forum_content_sanitizer_test.dart' as forum_sanitizer_tests;
import 'rate_limiting/student_action_rate_limiter_test.dart' as rate_limiter_tests;
import 'integrity/student_sha256_engine_test.dart' as sha256_tests;
import 'integrity/student_submission_integrity_verifier_test.dart' as integrity_tests;

void main() {
  group('Student Security Layer — Master Adversarial & Functional Suite', () {
    policies_tests.main();
    magic_bytes_tests.main();
    file_validator_tests.main();
    git_validator_tests.main();
    text_sanitizer_tests.main();
    forum_sanitizer_tests.main();
    rate_limiter_tests.main();
    sha256_tests.main();
    integrity_tests.main();
  });
}
