// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/student_security_limits.dart';
import '../policies/student_security_policy.dart';

/// Resultado imutável da validação de URL de repositório Git.
class StudentUrlValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? normalizedUrl;

  const StudentUrlValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.normalizedUrl,
  });

  const StudentUrlValidationResult.success(String normalizedUrl)
      : this._(
         isValid: true,
         errorMessage: null,
         normalizedUrl: normalizedUrl,
       );

  const StudentUrlValidationResult.failure(String errorMessage)
      : this._(
         isValid: false,
         errorMessage: errorMessage,
         normalizedUrl: null,
       );
}

/// Validador estrito de repositórios Git acadêmicos e mitigador de SSRF (Server-Side Request Forgery).
abstract final class StudentGitRepositoryValidator {
  StudentGitRepositoryValidator._();

  static final RegExp _sshGitPattern = RegExp(
    r'^git@([a-zA-Z0-9.-]+):([a-zA-Z0-9._-]+)/([a-zA-Z0-9._-]+)(\.git)?$',
  );

  /// Valida e normaliza links de repositórios Git submetidos pelo aluno.
  ///
  /// - Exige protocolos seguros (`https://`) ou SSH (`git@...`).
  /// - Bloqueia esquemas perigosos (`javascript:`, `file:`, `data:`, `http:` inseguro).
  /// - Rejeita alvos de SSRF: loopback (`127.0.0.1`, `localhost`), IPs privados e cloud metadata (`169.254.169.254`).
  /// - Requer que o host pertença aos provedores autorizados ou possua estrutura Git autêntica.
  static StudentUrlValidationResult validateGitRepositoryUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return const StudentUrlValidationResult.failure('O link do repositório Git não pode estar vazio.');
    }

    final trimmed = rawUrl.trim();

    if (trimmed.length > StudentSecurityLimits.maxGitUrlLength) {
      return const StudentUrlValidationResult.failure(
        'O link do repositório excede o limite máximo permitido.',
      );
    }

    // 1. Tratamento para formato SSH git@
    if (trimmed.startsWith('git@')) {
      final match = _sshGitPattern.firstMatch(trimmed);
      if (match == null) {
        return const StudentUrlValidationResult.failure(
          'Formato de repositório SSH inválido. Exemplo: git@github.com:usuario/projeto.git',
        );
      }
      final host = match.group(1)?.toLowerCase() ?? '';
      if (isPrivateOrLoopbackHost(host)) {
        return const StudentUrlValidationResult.failure(
          'Endereço de rede local ou loopback não é permitido para repositórios.',
        );
      }
      return StudentUrlValidationResult.success(trimmed);
    }

    // 2. Bloqueio preventivo de esquemas de injeção direta
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('javascript:') ||
        lower.startsWith('data:') ||
        lower.startsWith('file:') ||
        lower.startsWith('ftp:') ||
        lower.startsWith('ws:') ||
        lower.startsWith('wss:')) {
      return const StudentUrlValidationResult.failure(
        'Esquema de URL não seguro ou inválido para repositórios acadêmicos.',
      );
    }

    // 3. Parsing formal de URI HTTPS
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const StudentUrlValidationResult.failure(
        'URL de repositório inválida. Utilize o formato HTTPS: https://github.com/usuario/projeto',
      );
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return const StudentUrlValidationResult.failure(
        'Por motivos de integridade e segurança, o repositório Git deve utilizar o protocolo HTTPS (https://).',
      );
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty) {
      return const StudentUrlValidationResult.failure('Host do repositório ausente.');
    }

    // 4. Mitigação de SSRF
    if (isPrivateOrLoopbackHost(host)) {
      return const StudentUrlValidationResult.failure(
        'Não é permitido submeter endereços de loopback, redes privadas ou metadados de servidor.',
      );
    }

    // 5. Verificação do caminho do repositório (deve ter pelo menos /org/repo)
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (pathSegments.length < 2) {
      return const StudentUrlValidationResult.failure(
        'O link deve apontar para um repositório específico (ex: https://github.com/usuario/repositorio).',
      );
    }

    // 6. Normalização: remove credenciais embebidas na URL (http-auth phishing: https://user:pass@evil.com)
    if (uri.userInfo.isNotEmpty) {
      return const StudentUrlValidationResult.failure(
        'URLs com credenciais de autenticação embutidas não são permitidas.',
      );
    }

    return StudentUrlValidationResult.success(trimmed);
  }

  /// Verifica se um host é loopback, rede interna RFC 1918 ou endereço de metadados cloud.
  static bool isPrivateOrLoopbackHost(String host) {
    final lower = host.toLowerCase().trim();

    // Loopback e nomes locais
    if (lower == 'localhost' ||
        lower.endsWith('.localhost') ||
        lower.endsWith('.local') ||
        lower.endsWith('.internal')) {
      return true;
    }

    // Endereço IPv4 Loopback
    if (lower.startsWith('127.')) {
      return true;
    }

    // Cloud Metadata Endpoints (AWS, GCP, Azure, DigitalOcean)
    if (lower == '169.254.169.254' || lower == 'metadata.google.internal') {
      return true;
    }

    // RFC 1918 Private Ranges
    // 10.0.0.0/8
    if (lower.startsWith('10.')) return true;

    // 192.168.0.0/16
    if (lower.startsWith('192.168.')) return true;

    // 172.16.0.0/12 (172.16.* até 172.31.*)
    if (lower.startsWith('172.')) {
      final parts = lower.split('.');
      if (parts.length >= 2) {
        final second = int.tryParse(parts[1]);
        if (second != null && second >= 16 && second <= 31) {
          return true;
        }
      }
    }

    // IPv6 Loopback e link-local
    if (lower == '::1' || lower == '[::1]' || lower.startsWith('fe80:')) {
      return true;
    }

    return false;
  }
}
