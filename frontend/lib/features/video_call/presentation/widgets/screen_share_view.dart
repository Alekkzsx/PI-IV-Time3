// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Palco de apresentação de compartilhamento de tela em modo Spotlight.
///
/// Exibe a viewport primária de destaque da transmissão de tela, com moldura
/// em realce anil (`Colors.indigoAccent`), ícone representativo e título institucional.
class ScreenShareView extends StatelessWidget {
  /// Nome opcional do participante apresentador exibido no cabeçalho ou legenda.
  final String? presenterName;

  /// Callback opcional disparado caso o usuário decida parar a própria apresentação.
  final VoidCallback? onStopSharing;

  const ScreenShareView({
    super.key,
    this.presenterName,
    this.onStopSharing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('screen_share_view'),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigoAccent, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.present_to_all,
              color: Colors.indigoAccent,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              'Apresentação de Tela Ativa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (presenterName != null && presenterName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Apresentado por $presenterName',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
