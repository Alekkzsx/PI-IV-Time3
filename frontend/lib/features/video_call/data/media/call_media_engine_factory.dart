// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'call_media_engine.dart';
import 'call_media_engine_stub.dart'
    if (dart.library.html) 'call_media_engine_web.dart' as impl;

/// Factory multiplataforma que instancia o motor de mídia real na Web e o stub seguro em testes VM.
ICallMediaEngine createPlatformMediaEngine() => impl.createCallMediaEngine();

