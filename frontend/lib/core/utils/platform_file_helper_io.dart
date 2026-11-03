import 'dart:convert';
import 'dart:io';
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
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    try {
      if (Platform.isWindows) {
        final filter = (allowedExtensions != null && allowedExtensions.isNotEmpty)
            ? 'Arquivos Permitidos (${allowedExtensions.map((e) => '*.${e.replaceAll('.', '')}').join(';')})|${allowedExtensions.map((e) => '*.${e.replaceAll('.', '')}').join(';')}|Todos os arquivos (*.*)|*.*'
            : 'Todos os arquivos (*.*)|*.*';
        final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dlg = New-Object System.Windows.Forms.OpenFileDialog
\$dlg.Filter = '$filter'
if (\$dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dlg.FileName
}
''';
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-STA',
          '-Command',
          script,
        ]);
        final selectedPath = result.stdout.toString().trim();
        if (selectedPath.isEmpty) return null;
        final file = File(selectedPath);
        if (!file.existsSync()) return null;
        final bytes = await file.readAsBytes();
        final name = selectedPath.split(Platform.pathSeparator).last;
        return PickedPlatformFile(
          name: name,
          sizeBytes: bytes.length,
          mimeType: _guessMimeType(name),
          bytes: bytes,
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> saveOrDownloadFile({
    required String fileName,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return fileName;
    }
    try {
      final home =
          Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      final downloadsDir = home != null
          ? Directory('$home${Platform.pathSeparator}Downloads')
          : Directory.systemTemp;
      final targetDir =
          downloadsDir.existsSync() ? downloadsDir : Directory.systemTemp;
      final sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final outFile = File(
        '${targetDir.path}${Platform.pathSeparator}$sanitized',
      );
      await outFile.writeAsBytes(bytes, flush: true);
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  static String _guessMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'text/plain';
    return 'application/octet-stream';
  }
}

