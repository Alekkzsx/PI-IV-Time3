// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/validators/student_magic_bytes_inspector.dart';

void main() {
  group('StudentMagicBytesInspector Tests', () {
    test('Identifica cabeçalho PDF legítimo (%PDF-)', () {
      final validPdf = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34];
      expect(StudentMagicBytesInspector.verifySignature('pdf', validPdf), isTrue);
    });

    test('Identifica cabeçalho ZIP legítimo (PK\x03\x04)', () {
      final validZip = [0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x08, 0x00];
      expect(StudentMagicBytesInspector.verifySignature('zip', validZip), isTrue);
      expect(StudentMagicBytesInspector.verifySignature('docx', validZip), isTrue);
    });

    test('Identifica cabeçalho PNG legítimo (\x89PNG)', () {
      final validPng = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00];
      expect(StudentMagicBytesInspector.verifySignature('png', validPng), isTrue);
    });

    test('Identifica cabeçalho JPEG legítimo (\xFF\xD8\xFF)', () {
      final validJpg = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];
      expect(StudentMagicBytesInspector.verifySignature('jpg', validJpg), isTrue);
      expect(StudentMagicBytesInspector.verifySignature('jpeg', validJpg), isTrue);
    });

    test('Detecta e bloqueia executável Windows MZ camuflado como PDF', () {
      // Cabeçalho PE MZ
      final fakePdf = [0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00];
      expect(StudentMagicBytesInspector.hasExecutableHeader(fakePdf), isTrue);
      expect(StudentMagicBytesInspector.verifySignature('pdf', fakePdf), isFalse);
    });

    test('Detecta e bloqueia executável Linux ELF camuflado como ZIP', () {
      // Cabeçalho ELF \x7FELF
      final fakeZip = [0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01, 0x00];
      expect(StudentMagicBytesInspector.hasExecutableHeader(fakeZip), isTrue);
      expect(StudentMagicBytesInspector.verifySignature('zip', fakeZip), isFalse);
    });

    test('Arquivos de código-fonte (.dart, .py) não requerem magic number rígido', () {
      final dartCode = [0x76, 0x6F, 0x69, 0x64, 0x20, 0x6D, 0x61, 0x69, 0x6E]; // "void main"
      expect(StudentMagicBytesInspector.verifySignature('dart', dartCode), isTrue);
    });
  });
}
