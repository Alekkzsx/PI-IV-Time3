// Persistência multiplataforma de sessão sem dependências externas.
export 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart'
    if (dart.library.io) 'session_storage_io.dart';

