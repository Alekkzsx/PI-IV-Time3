// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Orquestrador de inicialização automática dos serviços locais (`backend/` :3001 e `server/` :8080)
/// em execução Desktop (`flutter run -d windows`).
class BackendProcessLauncher {
  static bool _hasAttemptedStart = false;

  static Future<void> ensureBackendRunning() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    if (_hasAttemptedStart) return;
    _hasAttemptedStart = true;

    final projectRoot = _resolveProjectRoot();
    if (projectRoot == null) return;

    await Future.wait([
      _ensureNodeBackendRunning(projectRoot),
      _ensureJavaServerRunning(projectRoot),
    ]);
  }

  static Future<void> _ensureNodeBackendRunning(Directory projectRoot) async {
    try {
      if (await _pingUrl('http://127.0.0.1:3001/health')) {
        debugPrint('[BackendLauncher] API TypeScript já ativa na porta 3001.');
        return;
      }
      final backendDir = Directory(
        '${projectRoot.path}${Platform.pathSeparator}backend',
      );
      if (!backendDir.existsSync()) return;

      if (Platform.isWindows) {
        await Process.start(
          'powershell',
          [
            '-NoProfile',
            '-WindowStyle',
            'Hidden',
            '-Command',
            'Start-Process -FilePath "npm.cmd" -ArgumentList "run dev" -WorkingDirectory "${backendDir.path}" -WindowStyle Hidden',
          ],
          workingDirectory: backendDir.path,
          mode: ProcessStartMode.detached,
        );
      } else {
        await Process.start(
          'npm',
          ['run', 'dev'],
          workingDirectory: backendDir.path,
          mode: ProcessStartMode.detached,
        );
      }
    } catch (e) {
      debugPrint('[BackendLauncher] Aviso ao iniciar backend TypeScript: $e');
    }
  }

  static Future<void> _ensureJavaServerRunning(Directory projectRoot) async {
    try {
      if (await _pingUrl('http://127.0.0.1:8080/api/videocall/rooms')) {
        debugPrint('[BackendLauncher] Servidor Java já ativo na porta 8080.');
        return;
      }
      final serverDir = Directory(
        '${projectRoot.path}${Platform.pathSeparator}server',
      );
      if (!serverDir.existsSync()) return;

      final runBat = File(
        '${serverDir.path}${Platform.pathSeparator}run-server.bat',
      );
      if (Platform.isWindows && runBat.existsSync()) {
        await Process.start(
          'powershell',
          [
            '-NoProfile',
            '-WindowStyle',
            'Hidden',
            '-Command',
            'Start-Process -FilePath "${runBat.path}" -WorkingDirectory "${serverDir.path}" -WindowStyle Hidden',
          ],
          workingDirectory: serverDir.path,
          mode: ProcessStartMode.detached,
        );
      } else {
        final binDir = Directory(
          '${serverDir.path}${Platform.pathSeparator}bin',
        );
        if (binDir.existsSync()) {
          await Process.start(
            'java',
            ['-cp', 'bin', 'main.Main'],
            workingDirectory: serverDir.path,
            mode: ProcessStartMode.detached,
          );
        }
      }
    } catch (e) {
      debugPrint('[BackendLauncher] Aviso ao iniciar servidor Java: $e');
    }
  }

  static Future<bool> _pingUrl(String url) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(milliseconds: 350);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      client.close(force: true);
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Directory? _resolveProjectRoot() {
    Directory current = Directory.current;
    for (int i = 0; i < 5; i++) {
      final serverFolder = Directory(
        '${current.path}${Platform.pathSeparator}server',
      );
      if (serverFolder.existsSync()) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }
}

