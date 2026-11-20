// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/integrity/student_submission_integrity_verifier.dart';

void main() {
  group('StudentSubmissionIntegrityVerifier Tests', () {
    test('Verifica recibo de entrega idêntico com sucesso (não-repúdio)', () {
      final fileContent = 'Código fonte do trabalho do aluno para o PI-IV 2026';
      final fileBytes = fileContent.codeUnits;

      final expectedHash = StudentSubmissionIntegrityVerifier.calculateFileSha256(fileBytes);

      final isVerified = StudentSubmissionIntegrityVerifier.verifySubmissionReceipt(
        localFileBytes: fileBytes,
        serverReceiptSha256: expectedHash,
      );

      expect(isVerified, isTrue);
    });

    test('Detecta alteração de 1 único byte e recusa o recibo por corrupção ou adulteração', () {
      final originalBytes = [0x01, 0x02, 0x03, 0x04];
      final originalHash = StudentSubmissionIntegrityVerifier.calculateFileSha256(originalBytes);

      // Simula alteração do arquivo
      final tamperedBytes = [0x01, 0x02, 0x03, 0x05];

      final isVerified = StudentSubmissionIntegrityVerifier.verifySubmissionReceipt(
        localFileBytes: tamperedBytes,
        serverReceiptSha256: originalHash,
      );

      expect(isVerified, isFalse);
    });

    test('Comparação em tempo constante funciona contra timing attacks', () {
      expect(StudentSubmissionIntegrityVerifier.constantTimeEquals('abc', 'abc'), isTrue);
      expect(StudentSubmissionIntegrityVerifier.constantTimeEquals('abc', 'abd'), isFalse);
      expect(StudentSubmissionIntegrityVerifier.constantTimeEquals('abc', 'ab'), isFalse);
    });

    test('Gera assinatura de recibo determinística contendo RA, atividade e protocolo', () {
      final proof = StudentSubmissionIntegrityVerifier.generateAcademicReceiptProof(
        studentRa: '24802449',
        assignmentId: 'assign-123',
        protocolCode: 'AGR-2026-F1A2',
        fileSha256: 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );

      expect(proof.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(proof), isTrue);
    });
  });
}
