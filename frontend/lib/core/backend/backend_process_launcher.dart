// Exportação condicional para evitar import de dart:io no Flutter Web.
export 'backend_process_launcher_stub.dart'
    if (dart.library.io) 'backend_process_launcher_io.dart';
