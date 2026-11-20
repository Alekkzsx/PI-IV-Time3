// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'student_sha256_engine.dart';

/// Validador criptográfico de não-repúdio e integridade acadêmica para a Visão do Aluno.
///
/// Compara em tempo constante hashes calculados no client antes do upload com os
/// comprovantes oficiais gerados pelo backend após o recebimento.
abstract final class StudentSubmissionIntegrityVerifier {
  StudentSubmissionIntegrityVerifier._();

  /// Calcula o hash SHA-256 de um arquivo acadêmico antes do envio.
  static String calculateFileSha256(List<int> fileBytes) {
    if (fileBytes.isEmpty) {
      // Hash SHA-256 oficial de payload vazio (e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
      return StudentSha256Engine.hashBytes(const []);
    }
    return StudentSha256Engine.hashBytes(fileBytes);
  }

  /// Verifica se o hash retornado no recibo do servidor corresponde bit-a-bit ao hash local.
  /// Utiliza comparação segura em tempo constante para mitigar timing attacks.
  static bool verifySubmissionReceipt({
    required List<int> localFileBytes,
    required String serverReceiptSha256,
  }) {
    if (serverReceiptSha256.trim().isEmpty) return false;
    final localHash = calculateFileSha256(localFileBytes);
    return constantTimeEquals(localHash, serverReceiptSha256.trim().toLowerCase());
  }

  /// Comparador em tempo constante de strings hexadecimais (mitigação de side-channel timing attack).
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Gera a assinatura de recibo acadêmico para atestação de entrega pelo aluno.
  static String generateAcademicReceiptProof({
    required String studentRa,
    required String assignmentId,
    required String protocolCode,
    required String fileSha256,
  }) {
    final payload = 'AGMRM-RECEIPT:$studentRa:$assignmentId:$protocolCode:$fileSha256';
    return StudentSha256Engine.hashString(payload);
  }
}
