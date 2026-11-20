// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/validators/student_file_upload_validator.dart';

void main() {
  group('StudentFileUploadValidator Tests', () {
    test('Arquivo PDF legítimo com magic bytes e tamanho válido é aceito', () {
      final pdfBytes = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35];
      final result = StudentFileUploadValidator.validateDeliveryFile(
        fileName: 'relatorio_final.pdf',
        sizeBytes: 1024 * 1024,
        fileBytes: pdfBytes,
      );

      expect(result.isValid, isTrue);
      expect(result.sanitizedFileName, equals('relatorio_final.pdf'));
      expect(result.detectedExtension, equals('pdf'));
      expect(result.errorMessage, isNull);
    });

    test('Arquivo excedendo 7 MB é rejeitado categoricamente', () {
      final result = StudentFileUploadValidator.validateDeliveryFile(
        fileName: 'projeto.zip',
        sizeBytes: (7 * 1024 * 1024) + 1,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('limite regimental de 7 MB'));
    });

    test('Extensão perigosa (.exe, .bat, .svg) é sumariamente bloqueada', () {
      for (final badName in ['virus.exe', 'script.bat', 'payload.svg', 'webshell.php']) {
        final result = StudentFileUploadValidator.validateDeliveryFile(
          fileName: badName,
          sizeBytes: 1024,
        );
        expect(result.isValid, isFalse, reason: 'Arquivo $badName deve ser bloqueado');
      }
    });

    test('Bypass por extensão composta/dupla é interceptado', () {
      expect(StudentFileUploadValidator.hasDangerousDoubleExtension('trabalho.pdf.exe'), isTrue);
      expect(StudentFileUploadValidator.hasDangerousDoubleExtension('exercicio.php.png'), isTrue);

      final result = StudentFileUploadValidator.validateDeliveryFile(
        fileName: 'relatorio.pdf.exe',
        sizeBytes: 1024,
      );
      expect(result.isValid, isFalse);
    });

    test('Path traversal no nome do arquivo é neutralizado e sanitizado', () {
      expect(
        StudentFileUploadValidator.sanitizeFileName('../../etc/shadow'),
        equals('shadow'),
      );
      expect(
        StudentFileUploadValidator.sanitizeFileName(r'..\..\Windows\System32\cmd.exe'),
        equals('cmd.exe'),
      );
    });

    test('Null byte poisoning no nome do arquivo é expurgado', () {
      expect(
        StudentFileUploadValidator.sanitizeFileName('relatorio.pdf\x00.exe'),
        equals('relatorio.pdf.exe'),
      );
    });

    test('Validação de anexo de protocolo restringe estritamente a PDF e imagens rasterizadas', () {
      final pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final valid = StudentFileUploadValidator.validateProtocolAttachment(
        fileName: 'atestado.png',
        sizeBytes: 500 * 1024,
        fileBytes: pngBytes,
      );
      expect(valid.isValid, isTrue);

      final invalid = StudentFileUploadValidator.validateProtocolAttachment(
        fileName: 'codigo.dart',
        sizeBytes: 1024,
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.errorMessage, contains('Apenas documentos em PDF ou imagens'));
    });
  });
}
