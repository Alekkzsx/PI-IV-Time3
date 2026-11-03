import 'dart:convert';
import 'dart:typed_data';

class PickedPlatformFile {
  final String name;
  final int sizeBytes;
  final String mimeType;
  final Uint8List bytes;

  const PickedPlatformFile({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.bytes,
  });

  String get base64Content => base64Encode(bytes);

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }
}

class PlatformFileHelper {
  const PlatformFileHelper._();

  static Future<PickedPlatformFile?> pickFile({
    List<String>? allowedExtensions,
  }) async {
    return null;
  }

  static Future<String?> saveOrDownloadFile({
    required String fileName,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    return fileName;
  }
}

