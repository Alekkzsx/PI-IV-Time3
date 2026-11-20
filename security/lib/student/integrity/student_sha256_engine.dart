// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:convert';
import 'dart:typed_data';

/// Motor criptográfico nativo SHA-256 (FIPS 180-4) implementado puramente em Dart.
///
/// Não possui dependências externas ou pacotes de terceiros, garantindo
/// conformidade estrita aos vetores de teste da RFC 6234 e portabilidade total.
abstract final class StudentSha256Engine {
  StudentSha256Engine._();

  // Constantes de arredondamento K do SHA-256 (primeiros 32 bits das partes fracionárias das raízes cúbicas dos primeiros 64 primos)
  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
  static int _ch(int x, int y, int z) => ((x & y) ^ ((~x) & z)) & 0xFFFFFFFF;
  static int _maj(int x, int y, int z) => ((x & y) ^ (x & z) ^ (y & z)) & 0xFFFFFFFF;
  static int _sigma0(int x) => (_rotr(x, 2) ^ _rotr(x, 13) ^ _rotr(x, 22)) & 0xFFFFFFFF;
  static int _sigma1(int x) => (_rotr(x, 6) ^ _rotr(x, 11) ^ _rotr(x, 25)) & 0xFFFFFFFF;
  static int _gamma0(int x) => (_rotr(x, 7) ^ _rotr(x, 18) ^ (x >>> 3)) & 0xFFFFFFFF;
  static int _gamma1(int x) => (_rotr(x, 17) ^ _rotr(x, 19) ^ (x >>> 10)) & 0xFFFFFFFF;

  /// Computa o hash SHA-256 de uma string UTF-8, retornando string hexadecimal de 64 caracteres.
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    return hashBytes(bytes);
  }

  /// Computa o hash SHA-256 de um buffer binário (`List<int>`), retornando string hexadecimal em minúsculas.
  static String hashBytes(List<int> input) {
    // 1. Valores de hash iniciais H0..H7 (primeiros 32 bits das raízes quadradas dos primeiros 8 primos)
    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    // 2. Pré-processamento e Preenchimento (Padding)
    final int byteLength = input.length;
    final int bitLength = byteLength * 8;

    // Tamanho após padding: precisa ser múltiplo de 64 bytes (512 bits)
    // byteLength + 1 byte (0x80) + K bytes zeros + 8 bytes comprimento em bits = 0 mod 64
    final int padZeroLength = (56 - ((byteLength + 1) % 64)) % 64;
    final int totalLength = byteLength + 1 + padZeroLength + 8;

    final Uint8List padded = Uint8List(totalLength);
    padded.setRange(0, byteLength, input);
    padded[byteLength] = 0x80;

    // Escreve o comprimento original de 64 bits em big-endian nos últimos 8 bytes
    final ByteData byteData = ByteData.sublistView(padded);
    byteData.setUint64(totalLength - 8, bitLength, Endian.big);

    // 3. Processa cada bloco de 512 bits (64 bytes)
    final Uint32List w = Uint32List(64);

    for (int offset = 0; offset < totalLength; offset += 64) {
      for (int t = 0; t < 16; t++) {
        w[t] = byteData.getUint32(offset + (t * 4), Endian.big);
      }

      for (int t = 16; t < 64; t++) {
        final s0 = _gamma0(w[t - 15]);
        final s1 = _gamma1(w[t - 2]);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xFFFFFFFF;
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      int f = h5;
      int g = h6;
      int h = h7;

      for (int t = 0; t < 64; t++) {
        final t1 = (h + _sigma1(e) + _ch(e, f, g) + _k[t] + w[t]) & 0xFFFFFFFF;
        final t2 = (_sigma0(a) + _maj(a, b, c)) & 0xFFFFFFFF;
        h = g;
        g = f;
        f = e;
        e = (d + t1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    // 4. Formata o digest de 256 bits em string hexadecimal de 64 caracteres
    final buffer = StringBuffer();
    for (final val in [h0, h1, h2, h3, h4, h5, h6, h7]) {
      buffer.write(val.toRadixString(16).padLeft(8, '0'));
    }
    return buffer.toString();
  }
}
