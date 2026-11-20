// Desenvolvido por Murillo Caravita - RA: 25014012
// Utilitário multiplataforma de seleção e download real de arquivos sem pacotes externos.
export 'platform_file_helper_stub.dart'
    if (dart.library.html) 'platform_file_helper_web.dart'
    if (dart.library.io) 'platform_file_helper_io.dart';

