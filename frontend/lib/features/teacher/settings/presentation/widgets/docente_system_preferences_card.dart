// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'components/accessibility_calendar_section.dart';
import 'components/system_theme_settings_section.dart';

/// Card modular para gerenciamento de preferências do sistema, tema, acessibilidade e calendário acadêmico.
class DocenteSystemPreferencesCard extends StatefulWidget {
  const DocenteSystemPreferencesCard({super.key});

  @override
  State<DocenteSystemPreferencesCard> createState() =>
      _DocenteSystemPreferencesCardState();
}

class _DocenteSystemPreferencesCardState
    extends State<DocenteSystemPreferencesCard> {
  // Aparência & Tema
  String _selectedTheme = 'claro'; // 'claro', 'escuro', 'sistema'

  // Acessibilidade & Leitura
  String _typographyScale =
      'Normal'; // 'Normal', 'Média (+10%)', 'Grande (+20%)'
  String _tableDensity = 'Confortável'; // 'Confortável', 'Compacto'
  bool _highContrast = false;
  bool _reduceMotion = false;

  // Preferências do Calendário Acadêmico
  String _firstDayOfWeek = 'Domingo (Padrão)';
  String _defaultCalendarView = 'Visão Mensal (Grid Completo)';
  bool _hideWeekends = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Aparência & Tema
        SystemThemeSettingsSection(
          selectedTheme: _selectedTheme,
          onThemeSelected: (id) => setState(() => _selectedTheme = id),
        ),
        const SizedBox(height: 20),

        // 2. Acessibilidade & Calendário
        AccessibilityCalendarSection(
          typographyScale: _typographyScale,
          onTypographyScaleChanged: (v) => setState(() => _typographyScale = v),
          tableDensity: _tableDensity,
          onTableDensityChanged: (v) => setState(() => _tableDensity = v),
          highContrast: _highContrast,
          onHighContrastChanged: (v) => setState(() => _highContrast = v),
          reduceMotion: _reduceMotion,
          onReduceMotionChanged: (v) => setState(() => _reduceMotion = v),
          firstDayOfWeek: _firstDayOfWeek,
          onFirstDayOfWeekChanged: (v) => setState(() => _firstDayOfWeek = v),
          defaultCalendarView: _defaultCalendarView,
          onDefaultCalendarViewChanged: (v) =>
              setState(() => _defaultCalendarView = v),
          hideWeekends: _hideWeekends,
          onHideWeekendsChanged: (v) => setState(() => _hideWeekends = v),
        ),
        const SizedBox(height: 20),

        // Botão Salvar Preferências
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preferências do sistema salvas com sucesso!'),
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
              'Salvar Preferências do Sistema',
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
