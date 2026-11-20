// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/student_security_limits.dart';
import '../policies/student_security_policy.dart';
import 'student_magic_bytes_inspector.dart';

/// Resultado imutável e tipado da validação de arquivo submetido pelo aluno.
class StudentFileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String sanitizedFileName;
  final String? detectedExtension;

  const StudentFileValidationResult._({
    required this.isValid,
    this.errorMessage,
    required this.sanitizedFileName,
    this.detectedExtension,
  });

  const StudentFileValidationResult.success({
    required String sanitizedFileName,
    String? detectedExtension,
  }) : this._(
         isValid: true,
         errorMessage: null,
         sanitizedFileName: sanitizedFileName,
         detectedExtension: detectedExtension,
       );

  const StudentFileValidationResult.failure(String errorMessage)
      : this._(
         isValid: false,
         errorMessage: errorMessage,
         sanitizedFileName: '',
         detectedExtension: null,
       );
}

/// Validador estrutural e adversarial de arquivos para entregas acadêmicas e anexos de secretaria.
abstract final class StudentFileUploadValidator {
  StudentFileUploadValidator._();

  static final RegExp _nullBytePattern = RegExp(r'(\x00|%00|\u0000)');
  static final RegExp _pathTraversalPattern = RegExp(r'(\.\./|\.\.\\|/\.\.|\\/|\.\.)');

  /// Sanitiza o nome de um arquivo neutralizando caminhos relativos, null bytes e caracteres não-ASCII.
  static String sanitizeFileName(String rawName) {
    if (rawName.isEmpty) return 'arquivo_sem_nome';

    // 1. Remove sequências nulas
    var cleaned = rawName.replaceAll(_nullBytePattern, '');

    // 2. Extrai apenas o nome base (stripping de qualquer caminho de diretório)
    cleaned = cleaned.replaceAll('\\', '/');
    if (cleaned.contains('/')) {
      cleaned = cleaned.split('/').last;
    }

    // 3. Remove caracteres perigosos de path traversal restantes
    cleaned = cleaned.replaceAll(_pathTraversalPattern, '');

    // 4. Remove caracteres não-ASCII e de controle
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    cleaned = cleaned.trim();
    if (cleaned.isEmpty || cleaned == '.') {
      return 'arquivo_anexo';
    }

    // 5. Trunca respeitando o limite regimental
    if (cleaned.length > StudentSecurityLimits.maxFileNameLength) {
      final ext = getFileExtension(cleaned);
      final dotExt = ext.isNotEmpty ? '.$ext' : '';
      final maxBase = StudentSecurityLimits.maxFileNameLength - dotExt.length;
      cleaned = '${cleaned.substring(0, maxBase)}$dotExt';
    }

    return cleaned;
  }

  /// Extrai a extensão em minúsculas (sem o ponto).
  static String getFileExtension(String fileName) {
    final cleaned = fileName.trim();
    final dotIndex = cleaned.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == cleaned.length - 1) return '';
    return cleaned.substring(dotIndex + 1).toLowerCase();
  }

  /// Detecta se o arquivo possui extensões compostas perigosas (ex: `relatorio.pdf.exe`).
  static bool hasDangerousDoubleExtension(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length <= 2) return false;

    // Se qualquer uma das extensões intermediárias ou a final for perigosa
    for (int i = 1; i < parts.length; i++) {
      if (StudentSecurityPolicy.blockedDangerousExtensions.contains(parts[i])) {
        return true;
      }
    }
    return false;
  }

  /// Valida artefato de entrega de atividade acadêmica na Visão do Aluno.
  static StudentFileValidationResult validateDeliveryFile({
    required String fileName,
    required int sizeBytes,
    List<int>? fileBytes,
  }) {
    // 1. Checagem de arquivo vazio
    if (sizeBytes <= 0 || (fileBytes != null && fileBytes.isEmpty)) {
      return const StudentFileValidationResult.failure(
        'O arquivo selecionado está vazio ou não pôde ser lido.',
      );
    }

    // 2. Teto regimental (7 MB)
    if (sizeBytes > StudentSecurityLimits.maxDeliveryFileBytes) {
      return const StudentFileValidationResult.failure(
        'O arquivo excede o limite regimental de 7 MB.',
      );
    }

    // 3. Sanitização do nome
    final sanitizedName = sanitizeFileName(fileName);
    final ext = getFileExtension(sanitizedName);

    if (ext.isEmpty) {
      return const StudentFileValidationResult.failure(
        'O arquivo deve possuir uma extensão válida (ex: .pdf, .zip).',
      );
    }

    // 4. Bloqueio imediato de extensões perigosas ou duplas
    if (StudentSecurityPolicy.blockedDangerousExtensions.contains(ext) ||
        hasDangerousDoubleExtension(fileName)) {
      return StudentFileValidationResult.failure(
        'A extensão .$ext é bloqueada por políticas de segurança institucional.',
      );
    }

    // 5. Conformidade com a whitelist de entregas acadêmicas
    if (!StudentSecurityPolicy.allowedDeliveryExtensions.contains(ext)) {
      return StudentFileValidationResult.failure(
        'O formato .$ext não é permitido para submissão de atividades.',
      );
    }

    // 6. Inspeção de Magic Bytes (quando os bytes estão disponíveis)
    if (fileBytes != null) {
      if (StudentMagicBytesInspector.hasExecutableHeader(fileBytes)) {
        return const StudentFileValidationResult.failure(
          'Arquivo com assinatura executável maliciosa detectada e bloqueada.',
        );
      }

      if (!StudentMagicBytesInspector.verifySignature(ext, fileBytes)) {
        return StudentFileValidationResult.failure(
          'Inconsistência entre a extensão .$ext e o conteúdo binário do arquivo (MIME spoofing detectado).',
        );
      }
    }

    return StudentFileValidationResult.success(
      sanitizedFileName: sanitizedName,
      detectedExtension: ext,
    );
  }

  /// Valida anexo probatório para requerimentos da Secretaria Geral.
  static StudentFileValidationResult validateProtocolAttachment({
    required String fileName,
    required int sizeBytes,
    List<int>? fileBytes,
  }) {
    if (sizeBytes <= 0 || (fileBytes != null && fileBytes.isEmpty)) {
      return const StudentFileValidationResult.failure(
        'O anexo selecionado está vazio ou inválido.',
      );
    }

    if (sizeBytes > StudentSecurityLimits.maxProtocolAttachmentBytes) {
      return const StudentFileValidationResult.failure(
        'O anexo de secretaria excede o limite máximo de 7 MB.',
      );
    }

    final sanitizedName = sanitizeFileName(fileName);
    final ext = getFileExtension(sanitizedName);

    if (ext.isEmpty) {
      return const StudentFileValidationResult.failure(
        'O comprovante deve ser um arquivo com extensão válida (.pdf, .png, .jpg).',
      );
    }

    // Bloqueia qualquer extensão que não esteja estritamente na whitelist de secretaria
    if (!StudentSecurityPolicy.allowedProtocolExtensions.contains(ext)) {
      return StudentFileValidationResult.failure(
        'Apenas documentos em PDF ou imagens (.png, .jpg) são aceitos pela Secretaria Geral.',
      );
    }

    if (fileBytes != null) {
      if (!StudentMagicBytesInspector.verifySignature(ext, fileBytes)) {
        return StudentFileValidationResult.failure(
          'O cabeçalho do documento .$ext não corresponde à sua assinatura binária autêntica.',
        );
      }
    }

    return StudentFileValidationResult.success(
      sanitizedFileName: sanitizedName,
      detectedExtension: ext,
    );
  }
}
