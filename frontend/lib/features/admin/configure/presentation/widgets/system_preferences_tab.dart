// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

/// Aba de configuração de Preferências do Sistema e Acessibilidade.
///
/// Permite alternar temas de interface (Claro, Escuro, SO), densidade de tabelas,
/// escala de tipografia, modo de alto contraste e preferências de calendário.
class SystemPreferencesTab extends StatefulWidget {
  const SystemPreferencesTab({super.key});

  @override
  State<SystemPreferencesTab> createState() => _SystemPreferencesTabState();
}

class _SystemPreferencesTabState extends State<SystemPreferencesTab> {
  int _selectedThemeIndex = 0; // 0: Claro, 1: Escuro, 2: SO
  int _typographyIndex = 0; // 0: Normal, 1: Média (+10%), 2: Grande (+20%)
  int _densityIndex = 0; // 0: Confortável, 1: Compacto

  bool _highContrast = false;
  bool _reduceMotion = false;

  String _firstDayOfWeek = 'Segunda-feira';
  String _defaultCalendarView = 'Mês Atual';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Aparência & Tema
        _buildSectionCard(
          title: 'Aparência & Tema',
          subtitle: 'Personalize a experiência visual do Portal e Ambiente Virtual de Aprendizagem.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return isNarrow
                  ? Column(
                      children: [
                        _buildThemeCard(0, Icons.wb_sunny_outlined, 'Claro (Padrão)', 'Ideal para ambientes luminosos'),
                        const SizedBox(height: 12),
                        _buildThemeCard(1, Icons.dark_mode_outlined, 'Modo Escuro', 'Menos fadiga visual noturna'),
                        const SizedBox(height: 12),
                        _buildThemeCard(2, Icons.desktop_windows_outlined, 'Sincronizar com SO', 'Ajusta conforme seu dispositivo'),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildThemeCard(0, Icons.wb_sunny_outlined, 'Claro (Padrão)', 'Ideal para ambientes luminosos')),
                        const SizedBox(width: 14),
                        Expanded(child: _buildThemeCard(1, Icons.dark_mode_outlined, 'Modo Escuro', 'Menos fadiga visual noturna')),
                        const SizedBox(width: 14),
                        Expanded(child: _buildThemeCard(2, Icons.desktop_windows_outlined, 'Sincronizar com SO', 'Ajusta conforme seu dispositivo')),
                      ],
                    );
            },
          ),
        ),

        const SizedBox(height: 20),

        // 2. Acessibilidade & Leitura
        _buildSectionCard(
          title: 'Acessibilidade & Leitura',
          subtitle: 'Ajustes para facilitar a visualização de textos, notas e materiais acadêmicos.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  return isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTypographySelector(),
                            const SizedBox(height: 20),
                            _buildDensitySelector(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTypographySelector()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildDensitySelector()),
                          ],
                        );
                },
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 18),

              // Toggles de Acessibilidade
              _buildToggleRow(
                title: 'Modo de Alto Contraste',
                subtitle: 'Realça as bordas e aumenta o contraste entre textos e planos de fundo.',
                value: _highContrast,
                onChanged: (val) => setState(() => _highContrast = val),
              ),
              const SizedBox(height: 14),
              _buildToggleRow(
                title: 'Reduzir Movimento & Animações',
                subtitle: 'Desativa transições rápidas e efeitos visuais animados.',
                value: _reduceMotion,
                onChanged: (val) => setState(() => _reduceMotion = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Preferências do Calendário Acadêmico
        _buildSectionCard(
          title: 'Preferências do Calendário Acadêmico',
          subtitle: 'Defina o comportamento inicial da sua agenda de aulas e entregas.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return isNarrow
                  ? Column(
                      children: [
                        _buildDropdownCard('Primeiro Dia da Semana', _firstDayOfWeek, ['Segunda-feira', 'Domingo'], (val) {
                          if (val != null) setState(() => _firstDayOfWeek = val);
                        }),
                        const SizedBox(height: 12),
                        _buildDropdownCard('Visualização Padrão ao Abrir', _defaultCalendarView, ['Mês Atual', 'Semana Atual', 'Agenda Diária'], (val) {
                          if (val != null) setState(() => _defaultCalendarView = val);
                        }),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildDropdownCard('Primeiro Dia da Semana', _firstDayOfWeek, ['Segunda-feira', 'Domingo'], (val) {
                            if (val != null) setState(() => _firstDayOfWeek = val);
                          }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownCard('Visualização Padrão ao Abrir', _defaultCalendarView, ['Mês Atual', 'Semana Atual', 'Agenda Diária'], (val) {
                            if (val != null) setState(() => _defaultCalendarView = val);
                          }),
                        ),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeCard(int index, IconData icon, String title, String subtitle) {
    final isSelected = _selectedThemeIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedThemeIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF0F172A)),
                const Spacer(),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.text_fields_rounded, size: 16, color: Color(0xFF475569)),
            SizedBox(width: 6),
            Text(
              'Escala de Tipografia',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildSegmentItem('Normal', 0, _typographyIndex, (idx) => setState(() => _typographyIndex = idx)),
              _buildSegmentItem('Média (+10%)', 1, _typographyIndex, (idx) => setState(() => _typographyIndex = idx)),
              _buildSegmentItem('Grande (+20%)', 2, _typographyIndex, (idx) => setState(() => _typographyIndex = idx)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDensitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.table_rows_outlined, size: 16, color: Color(0xFF475569)),
            SizedBox(width: 6),
            Text(
              'Densidade das Tabelas & Listas',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildSegmentItem('Confortável', 0, _densityIndex, (idx) => setState(() => _densityIndex = idx)),
              _buildSegmentItem('Compacto', 1, _densityIndex, (idx) => setState(() => _densityIndex = idx)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem(String text, int index, int selectedIndex, ValueChanged<int> onSelect) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Checkbox(
          value: value,
          activeColor: const Color(0xFF0F172A),
          onChanged: (val) => onChanged(val ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildDropdownCard(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
