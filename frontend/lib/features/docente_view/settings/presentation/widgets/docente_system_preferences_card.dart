// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card para gerenciamento de preferências do sistema, tema, acessibilidade e calendário acadêmico.
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
  String _typographyScale = 'Normal'; // 'Normal', 'Média (+10%)', 'Grande (+20%)'
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
                'Aparência & Tema',
                style: jakarta(size: 14, weight: FontWeight.w700, color: const Color(0xFF18181B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Defina o modo de exibição da interface em seus dispositivos.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildThemeOptionCard(
                      id: 'claro',
                      title: 'Claro (Padrão)',
                      description: 'Visual padrão com alto contraste e tons neutros de cinza e branco.',
                      icon: Icons.light_mode_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildThemeOptionCard(
                      id: 'escuro',
                      title: 'Modo Escuro',
                      description: 'Reduz o cansaço visual em ambientes de baixa luminosidade.',
                      icon: Icons.dark_mode_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildThemeOptionCard(
                      id: 'sistema',
                      title: 'Sincronizar com SO',
                      description: 'Alterna automaticamente conforme o tema do seu sistema operacional.',
                      icon: Icons.brightness_auto_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Acessibilidade & Leitura
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
                style: jakarta(size: 14, weight: FontWeight.w700, color: const Color(0xFF18181B)),
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
                        Text('Escala de Tipografia', style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Ajuste o tamanho base dos textos da plataforma.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildPillButton('Normal', _typographyScale == 'Normal', () => setState(() => _typographyScale = 'Normal')),
                      const SizedBox(width: 8),
                      _buildPillButton('Média (+10%)', _typographyScale == 'Média (+10%)', () => setState(() => _typographyScale = 'Média (+10%)')),
                      const SizedBox(width: 8),
                      _buildPillButton('Grande (+20%)', _typographyScale == 'Grande (+20%)', () => setState(() => _typographyScale = 'Grande (+20%)')),
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
                        Text('Densidade das Tabelas & Listas', style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Altere o espaçamento entre linhas e dados no diário e notas.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildPillButton('Confortável', _tableDensity == 'Confortável', () => setState(() => _tableDensity = 'Confortável')),
                      const SizedBox(width: 8),
                      _buildPillButton('Compacto', _tableDensity == 'Compacto', () => setState(() => _tableDensity = 'Compacto')),
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
                        Text('Modo de Alto Contraste', style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Bordas e elementos de interface reforçados para facilitar visualização.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _highContrast,
                      onChanged: (v) => setState(() => _highContrast = v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                        Text('Reduzir Movimento & Animações', style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Desativa transições suaves e animações para melhor fluidez em hardware modesto.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _reduceMotion,
                      onChanged: (v) => setState(() => _reduceMotion = v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Preferências do Calendário Acadêmico
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
                style: jakarta(size: 14, weight: FontWeight.w700, color: const Color(0xFF18181B)),
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
                        Text('Primeiro Dia da Semana', style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _firstDayOfWeek,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF71717A)),
                              style: jakarta(size: 12, weight: FontWeight.w500, color: const Color(0xFF18181B)),
                              onChanged: (v) {
                                if (v != null) setState(() => _firstDayOfWeek = v);
                              },
                              items: const [
                                DropdownMenuItem(value: 'Domingo (Padrão)', child: Text('Domingo (Padrão)')),
                                DropdownMenuItem(value: 'Segunda-feira', child: Text('Segunda-feira')),
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
                        Text('Visualização Padrão ao Abrir', style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _defaultCalendarView,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF71717A)),
                              style: jakarta(size: 12, weight: FontWeight.w500, color: const Color(0xFF18181B)),
                              onChanged: (v) {
                                if (v != null) setState(() => _defaultCalendarView = v);
                              },
                              items: const [
                                DropdownMenuItem(value: 'Visão Mensal (Grid Completo)', child: Text('Visão Mensal (Grid Completo)')),
                                DropdownMenuItem(value: 'Visão Semanal', child: Text('Visão Semanal')),
                                DropdownMenuItem(value: 'Visão Diária', child: Text('Visão Diária')),
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
                      value: _hideWeekends,
                      onChanged: (v) => setState(() => _hideWeekends = v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ocultar Fins de Semana por Padrão', style: jakarta(size: 12.5, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Não exibir Sábado e Domingo na grade semanal caso não haja aulas programadas.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            label: Text(
              'Salvar Preferências do Sistema',
              style: jakarta(size: 13, weight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOptionCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedTheme == id;

    return InkWell(
      onTap: () => setState(() => _selectedTheme = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF71717A),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF18181B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: jakarta(
                size: 11,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
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
}

