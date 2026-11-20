// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'components/notification_channels_section.dart';
import 'components/notification_digest_section.dart';

/// Card modular para gerenciamento de preferências de canais e categorias de notificações institucionais.
class DocenteNotificationPrefsCard extends StatefulWidget {
  const DocenteNotificationPrefsCard({super.key});

  @override
  State<DocenteNotificationPrefsCard> createState() =>
      _DocenteNotificationPrefsCardState();
}

class _DocenteNotificationPrefsCardState
    extends State<DocenteNotificationPrefsCard> {
  // Notificações - Canais e Categorias
  bool _prazosPortal = true;
  bool _prazosEmail = true;
  String _antecedenciaPrazos = '24 horas antes (1 dia)';

  bool _notasPortal = true;
  bool _notasEmail = true;

  bool _forunsPortal = true;
  bool _forunsEmail = false;

  bool _mensagensPortal = true;
  bool _mensagensEmail = true;

  bool _comunicadosPortal = true;
  bool _comunicadosEmail = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Canais de Comunicação
        const NotificationChannelsSection(),
        const SizedBox(height: 20),

        // 2. Categorias & Frequência de Alertas
        NotificationDigestSection(
          prazosPortal: _prazosPortal,
          prazosEmail: _prazosEmail,
          antecedenciaPrazos: _antecedenciaPrazos,
          onPrazosPortalChanged: (v) =>
              setState(() => _prazosPortal = v ?? false),
          onPrazosEmailChanged: (v) =>
              setState(() => _prazosEmail = v ?? false),
          onAntecedenciaChanged: (v) {
            if (v != null) {
              setState(() => _antecedenciaPrazos = v);
            }
          },
          notasPortal: _notasPortal,
          notasEmail: _notasEmail,
          onNotasPortalChanged: (v) =>
              setState(() => _notasPortal = v ?? false),
          onNotasEmailChanged: (v) => setState(() => _notasEmail = v ?? false),
          forunsPortal: _forunsPortal,
          forunsEmail: _forunsEmail,
          onForunsPortalChanged: (v) =>
              setState(() => _forunsPortal = v ?? false),
          onForunsEmailChanged: (v) =>
              setState(() => _forunsEmail = v ?? false),
          mensagensPortal: _mensagensPortal,
          mensagensEmail: _mensagensEmail,
          onMensagensPortalChanged: (v) =>
              setState(() => _mensagensPortal = v ?? false),
          onMensagensEmailChanged: (v) =>
              setState(() => _mensagensEmail = v ?? false),
          comunicadosPortal: _comunicadosPortal,
          comunicadosEmail: _comunicadosEmail,
          onComunicadosPortalChanged: (v) =>
              setState(() => _comunicadosPortal = v ?? false),
          onComunicadosEmailChanged: (v) =>
              setState(() => _comunicadosEmail = v ?? false),
        ),
        const SizedBox(height: 20),

        // Ação de Salvar Preferências
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Preferências de notificação salvas com sucesso!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Salvar Preferências de Notificação',
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
