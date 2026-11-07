// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Inspeciona o cabeçalho binário (Magic Bytes) de arquivos para prevenir ataques de MIME Spoofing.
///
/// Impede que arquivos maliciosos executáveis (.exe, .sh) sejam disfarçados com extensões
/// acadêmicas legítimas (.pdf, .zip).
abstract final class StudentMagicBytesInspector {
  StudentMagicBytesInspector._();

  // Assinaturas binárias conhecidas (Magic Numbers)
  // PDF: %PDF- (0x25, 0x50, 0x44, 0x46, 0x2D)
  static const List<int> _pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D];

  // ZIP / DOCX / PPTX / XLSX: PK\x03\x04 (0x50, 0x4B, 0x03, 0x04)
  static const List<int> _zipHeader = [0x50, 0x4B, 0x03, 0x04];

  // PNG: \x89PNG\r\n\x1a\n (0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
  static const List<int> _pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  // JPEG / JPG: \xFF\xD8\xFF (0xFF, 0xD8, 0xFF)
  static const List<int> _jpegHeader = [0xFF, 0xD8, 0xFF];

  // Executáveis Windows PE: MZ (0x4D, 0x5A)
  static const List<int> _peHeader = [0x4D, 0x5A];

  // Executáveis Linux ELF: \x7FELF (0x7F, 0x45, 0x4C, 0x46)
  static const List<int> _elfHeader = [0x7F, 0x45, 0x4C, 0x46];

  /// Detecta se o arquivo binário possui cabeçalho de executável perigoso (PE ou ELF).
  static bool hasExecutableHeader(List<int> bytes) {
    if (bytes.length < 4) return false;
    // Checa MZ (Windows PE .exe, .dll, .scr)
    if (bytes[0] == _peHeader[0] && bytes[1] == _peHeader[1]) {
      return true;
    }
    // Checa ELF (Linux binários compilados)
    if (_matchesHeader(bytes, _elfHeader)) {
      return true;
    }
    return false;
  }

  /// Verifica se os bytes correspondem à extensão declarada para formatos estritos.
  /// Retorna `true` se o cabeçalho for consistente ou se a extensão não requer checagem binária estrita (ex: arquivos texto/código).
  static bool verifySignature(String extension, List<int> bytes) {
    if (bytes.isEmpty) return false;
    final ext = extension.toLowerCase().replaceAll('.', '').trim();

    // Rejeição imediata se houver assinatura de executável camuflada
    if (hasExecutableHeader(bytes)) {
      return false;
    }

    switch (ext) {
      case 'pdf':
        return _matchesHeader(bytes, _pdfHeader);
      case 'zip':
      case 'docx':
      case 'xlsx':
      case 'pptx':
        return _matchesHeader(bytes, _zipHeader);
      case 'png':
        return _matchesHeader(bytes, _pngHeader);
      case 'jpg':
      case 'jpeg':
        return _matchesHeader(bytes, _jpegHeader);
      default:
        // Formatos de código ou texto plano (.c, .java, .py, .txt, .sql, .md) não possuem magic number fixo
        return true;
    }
  }

  static bool _matchesHeader(List<int> bytes, List<int> expectedHeader) {
    if (bytes.length < expectedHeader.length) return false;
    for (int i = 0; i < expectedHeader.length; i++) {
      if (bytes[i] != expectedHeader[i]) return false;
    }
    return true;
  }
}
