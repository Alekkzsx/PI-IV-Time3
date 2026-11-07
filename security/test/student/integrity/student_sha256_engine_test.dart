// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/integrity/student_sha256_engine.dart';

void main() {
  group('StudentSha256Engine Tests (RFC 6234 Compliance)', () {
    test('Calcula hash SHA-256 oficial para string vazia', () {
      final hash = StudentSha256Engine.hashString('');
      expect(hash, equals('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'));
    });

    test('Calcula hash SHA-256 oficial para "abc" (Vetor de teste 1 da RFC 6234)', () {
      final hash = StudentSha256Engine.hashString('abc');
      expect(hash, equals('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'));
    });

    test('Calcula hash SHA-256 oficial para frase padrão de 448 bits (Vetor de teste 2)', () {
      final hash = StudentSha256Engine.hashString(
        'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
      );
      expect(hash, equals('248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'));
    });

    test('Calcula hash SHA-256 de buffer binário de bytes arbitrários com precisão', () {
      final bytes = [0x01, 0x02, 0x03, 0x04, 0x05];
      final hash = StudentSha256Engine.hashBytes(bytes);

      expect(hash.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });
  });
}
