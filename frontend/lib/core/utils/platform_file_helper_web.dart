// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
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
    final completer = Completer<PickedPlatformFile?>();
    final input = html.FileUploadInputElement();
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept = allowedExtensions
          .map((e) => e.startsWith('.') ? e : '.$e')
          .join(',');
    }
    input.style.display = 'none';
    html.document.body?.append(input);

    bool settled = false;
    void finish(PickedPlatformFile? result) {
      if (settled) return;
      settled = true;
      input.remove();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    input.onChange.first.then((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        finish(null);
        return;
      }
      final file = files.first;
      final reader = html.FileReader();
      reader.onLoadEnd.first.then((_) {
        final raw = reader.result;
        Uint8List bytes;
        if (raw is ByteBuffer) {
          bytes = Uint8List.view(raw);
        } else if (raw is Uint8List) {
          bytes = raw;
        } else if (raw is List<int>) {
          bytes = Uint8List.fromList(raw);
        } else {
          bytes = Uint8List(0);
        }
        finish(
          PickedPlatformFile(
            name: file.name,
            sizeBytes: file.size,
            mimeType: file.type.isEmpty ? 'application/octet-stream' : file.type,
            bytes: bytes,
          ),
        );
      });
      reader.onError.first.then((_) => finish(null));
      reader.readAsArrayBuffer(file);
    });

    input.click();
    return completer.future;
  }

  static Future<String?> saveOrDownloadFile({
    required String fileName,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    final data = Uint8List.fromList(bytes);
    final blob = html.Blob([data], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(url);
    });
    return fileName;
  }
}

