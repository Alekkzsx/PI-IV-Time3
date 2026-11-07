// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/validators/student_git_repository_validator.dart';

void main() {
  group('StudentGitRepositoryValidator Tests', () {
    test('Repositórios HTTPS legítimos (GitHub, GitLab, PUC) são aceitos e normalizados', () {
      final resGithub = StudentGitRepositoryValidator.validateGitRepositoryUrl(
        'https://github.com/usuario/projeto-pi4',
      );
      expect(resGithub.isValid, isTrue);
      expect(resGithub.normalizedUrl, equals('https://github.com/usuario/projeto-pi4'));

      final resGitlab = StudentGitRepositoryValidator.validateGitRepositoryUrl(
        'https://gitlab.puc-campinas.edu.br/aluno/sistema-academico.git',
      );
      expect(resGitlab.isValid, isTrue);
    });

    test('Repositórios via SSH git@ padrão são aceitos', () {
      final resSsh = StudentGitRepositoryValidator.validateGitRepositoryUrl(
        'git@github.com:usuario/projeto.git',
      );
      expect(resSsh.isValid, isTrue);
    });

    test('Esquemas inseguros (javascript:, file:, data:, http:) são bloqueados', () {
      for (final badUrl in [
        'javascript:alert(1)',
        'data:text/html,<script>alert(1)</script>',
        'file:///etc/passwd',
        'http://github.com/usuario/projeto', // HTTP não-criptografado
      ]) {
        final res = StudentGitRepositoryValidator.validateGitRepositoryUrl(badUrl);
        expect(res.isValid, isFalse, reason: 'URL $badUrl deve ser rejeitada');
      }
    });

    test('Mitigação rigorosa contra SSRF: bloqueia loopback, localhost e metadata de cloud', () {
      for (final ssrfUrl in [
        'https://localhost/repo',
        'https://127.0.0.1/admin',
        'https://169.254.169.254/latest/meta-data/',
        'https://10.0.0.1/banco',
        'https://192.168.1.1/internal-repo',
        'https://172.20.0.5/api',
      ]) {
        final res = StudentGitRepositoryValidator.validateGitRepositoryUrl(ssrfUrl);
        expect(res.isValid, isFalse, reason: 'Alvo SSRF $ssrfUrl deve ser bloqueado');
      }
    });

    test('Bloqueia credenciais embutidas na URL (anti-phishing / credential leakage)', () {
      final res = StudentGitRepositoryValidator.validateGitRepositoryUrl(
        'https://aluno:senha123@github.com/usuario/repo',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('credenciais de autenticação embutidas'));
    });
  });
}
