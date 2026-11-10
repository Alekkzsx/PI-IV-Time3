// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Seção molecular de acessibilidade, leitura e preferências do calendário acadêmico.
class AccessibilityCalendarSection extends StatelessWidget {
  final String typographyScale;
  final ValueChanged<String> onTypographyScaleChanged;
  final String tableDensity;
  final ValueChanged<String> onTableDensityChanged;
  final bool highContrast;
  final ValueChanged<bool> onHighContrastChanged;
  final bool reduceMotion;
  final ValueChanged<bool> onReduceMotionChanged;
  final String firstDayOfWeek;
  final ValueChanged<String> onFirstDayOfWeekChanged;
  final String defaultCalendarView;
  final ValueChanged<String> onDefaultCalendarViewChanged;
  final bool hideWeekends;
  final ValueChanged<bool> onHideWeekendsChanged;

  const AccessibilityCalendarSection({
    super.key,
    required this.typographyScale,
    required this.onTypographyScaleChanged,
    required this.tableDensity,
    required this.onTableDensityChanged,
    required this.highContrast,
    required this.onHighContrastChanged,
    required this.reduceMotion,
    required this.onReduceMotionChanged,
    required this.firstDayOfWeek,
    required this.onFirstDayOfWeekChanged,
    required this.defaultCalendarView,
    required this.onDefaultCalendarViewChanged,
    required this.hideWeekends,
    required this.onHideWeekendsChanged,
  });

  Widget _buildPillButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFE4E4E7),
          ),
        ),
        child: Text(
          label,
          style: jakarta(
            size: 11.5,
            weight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF18181B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Acessibilidade & Leitura
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acessibilidade & Leitura',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajuste tamanhos de fontes, espaçamentos e opções de acessibilidade visual.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),

              // Escala de Tipografia
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escala de Tipografia',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ajuste o tamanho base dos textos da plataforma.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildPillButton(
                        'Normal',
                        typographyScale == 'Normal',
                        () => onTypographyScaleChanged('Normal'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        'Média (+10%)',
                        typographyScale == 'Média (+10%)',
                        () => onTypographyScaleChanged('Média (+10%)'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        'Grande (+20%)',
                        typographyScale == 'Grande (+20%)',
                        () => onTypographyScaleChanged('Grande (+20%)'),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Densidade das Tabelas & Listas
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Densidade das Tabelas & Listas',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Altere o espaçamento entre linhas e dados no diário e notas.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildPillButton(
                        'Confortável',
                        tableDensity == 'Confortável',
                        () => onTableDensityChanged('Confortável'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        'Compacto',
                        tableDensity == 'Compacto',
                        () => onTableDensityChanged('Compacto'),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Modo de Alto Contraste
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo de Alto Contraste',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bordas e elementos de interface reforçados para facilitar visualização.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: highContrast,
                      onChanged: (v) => onHighContrastChanged(v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Reduzir Movimento & Animações
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reduzir Movimento & Animações',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Desativa transições suaves e animações para melhor fluidez em hardware modesto.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: reduceMotion,
                      onChanged: (v) => onReduceMotionChanged(v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Preferências do Calendário Acadêmico
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferências do Calendário Acadêmico',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure os parâmetros padrão para exibição da sua grade e agenda.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primeiro Dia da Semana',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: firstDayOfWeek,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: Color(0xFF71717A),
                              ),
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w500,
                                color: const Color(0xFF18181B),
                              ),
                              onChanged: (v) {
                                if (v != null) {
                                  onFirstDayOfWeekChanged(v);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'Domingo (Padrão)',
                                  child: Text('Domingo (Padrão)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Segunda-feira',
                                  child: Text('Segunda-feira'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visualização Padrão ao Abrir',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: defaultCalendarView,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: Color(0xFF71717A),
                              ),
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w500,
                                color: const Color(0xFF18181B),
                              ),
                              onChanged: (v) {
                                if (v != null) {
                                  onDefaultCalendarViewChanged(v);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'Visão Mensal (Grid Completo)',
                                  child: Text('Visão Mensal (Grid Completo)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Visão Semanal',
                                  child: Text('Visão Semanal'),
                                ),
                                DropdownMenuItem(
                                  value: 'Visão Diária',
                                  child: Text('Visão Diária'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Ocultar Fins de Semana por Padrão
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: hideWeekends,
                      onChanged: (v) => onHideWeekendsChanged(v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ocultar Fins de Semana por Padrão',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Não exibir Sábado e Domingo na grade semanal caso não haja aulas programadas.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
