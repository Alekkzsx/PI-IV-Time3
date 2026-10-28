// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Orquestrador de inicialização automática das pastas mães (server/, backend/, security/).
///
/// Disparado automaticamente na execução de `flutter run` dentro de `frontend/`.
/// Garante que o servidor nativo Java na porta 8080 e os módulos integrados
/// estejam ativos e respondendo antes e durante a execução da interface.
class BackendProcessLauncher {
  static bool _hasAttemptedStart = false;

  /// Garante que o servidor Java nativo e os serviços das pastas mães estejam em execução.
  static Future<void> ensureBackendRunning() async {
    if (kIsWeb) {
      // Em execução web o navegador roda em sandbox restrito sem acesso a processos do SO.
      return;
    }

    if (_hasAttemptedStart) return;
    _hasAttemptedStart = true;

    try {
      // 1. Testa se o servidor das pastas mães já está ativo na porta 8080
      final isAlreadyRunning = await _pingBackend();
      if (isAlreadyRunning) {
        debugPrint('[BackendLauncher] Servidor Java e modulos das pastas maes ja estao ativos na porta 8080.');
        return;
      }

      // 2. Localiza a raiz do projeto e as pastas mães
      final projectRoot = _resolveProjectRoot();
      if (projectRoot == null) {
        debugPrint('[BackendLauncher] Diretorio raiz do projeto nao encontrado.');
        return;
      }

      final serverDir = Directory('${projectRoot.path}${Platform.pathSeparator}server');
      if (!serverDir.existsSync()) {
        debugPrint('[BackendLauncher] Pasta server nao encontrada em: ${serverDir.path}');
        return;
      }

      debugPrint('[BackendLauncher] Inicializando servidor Java e modulos das pastas maes a partir de: ${serverDir.path}...');

      // 3. Garante que os arquivos Java estejam compilados na pasta server/bin
      final binDir = Directory('${serverDir.path}${Platform.pathSeparator}bin');
      final mainClass = File('${binDir.path}${Platform.pathSeparator}main${Platform.pathSeparator}Main.class');
      if (!mainClass.existsSync()) {
        await _compileJavaSources(serverDir, binDir);
      }

      // 4. Inicializa o servidor Java como processo independente (detached)
      if (Platform.isWindows) {
        // Disparo desacoplado no Windows via powershell escondido para nao travar o console do Flutter
        await Process.start(
          'powershell',
          [
            '-NoProfile',
            '-WindowStyle',
            'Hidden',
            '-Command',
            'Start-Process -FilePath "java" -ArgumentList "-cp bin main.Main" -WorkingDirectory "${serverDir.path}" -WindowStyle Hidden',
          ],
          workingDirectory: serverDir.path,
          mode: ProcessStartMode.detached,
        );
      } else {
        await Process.start(
          'java',
          ['-cp', 'bin', 'main.Main'],
          workingDirectory: serverDir.path,
          mode: ProcessStartMode.detached,
        );
      }

      // 5. Aguarda brevemente a porta 8080 abrir e confirma a disponibilidade
      bool started = false;
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (await _pingBackend()) {
          started = true;
          break;
        }
      }

      if (started) {
        debugPrint('[BackendLauncher] Servidor Java (server/) e Backend iniciados com sucesso na porta 8080!');
      } else {
        debugPrint('[BackendLauncher] Processo disparado. Conectando aos servicos em segundo plano...');
      }
    } catch (e) {
      debugPrint('[BackendLauncher] Aviso ao tentar inicializar o backend: $e');
    }
  }

  /// Compila as fontes Java de server/src para server/bin de forma transparente
  static Future<void> _compileJavaSources(Directory serverDir, Directory binDir) async {
    try {
      if (!binDir.existsSync()) {
        binDir.createSync(recursive: true);
      }
      final srcDir = Directory('${serverDir.path}${Platform.pathSeparator}src');
      final javaFiles = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.java'))
          .map((f) => f.path)
          .toList();

      if (javaFiles.isEmpty) return;

      final javacCmd = Platform.isWindows ? 'javac.exe' : 'javac';
      final compileResult = await Process.run(
        javacCmd,
        ['--release', '8', '-encoding', 'UTF-8', '-d', binDir.path, ...javaFiles],
        workingDirectory: serverDir.path,
      );

      if (compileResult.exitCode != 0) {
        // Tentativa de fallback sem a flag --release caso o JDK seja antigo (Java 8 nativo)
        await Process.run(
          javacCmd,
          ['-encoding', 'UTF-8', '-d', binDir.path, ...javaFiles],
          workingDirectory: serverDir.path,
        );
      }
    } catch (_) {
      // Ignora erro de compilacao em runtime se os binarios ja existirem
    }
  }

  /// Verifica se o servidor HTTP nativo está respondendo requisições
  static Future<bool> _pingBackend() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 300);
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:8080/api/videocall/rooms'));
      final response = await request.close();
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  /// Navega recursivamente pelas pastas acima até encontrar a raiz do repositório
  static Directory? _resolveProjectRoot() {
    Directory current = Directory.current;
    for (int i = 0; i < 5; i++) {
      final serverFolder = Directory('${current.path}${Platform.pathSeparator}server');
      if (serverFolder.existsSync()) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }
}
