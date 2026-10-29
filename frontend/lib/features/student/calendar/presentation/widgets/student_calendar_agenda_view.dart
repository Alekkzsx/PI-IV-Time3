// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Visualização em lista/agenda dos compromissos e prazos do estudante.
class StudentCalendarAgendaView extends StatefulWidget {
  final StudentPortalController controller;

  const StudentCalendarAgendaView({super.key, required this.controller});

  @override
  State<StudentCalendarAgendaView> createState() =>
      _StudentCalendarAgendaViewState();
}

class _StudentCalendarAgendaViewState extends State<StudentCalendarAgendaView> {
  String _selectedType = 'Todos';
  String _selectedPeriod = 'Todos os compromissos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de pesquisa e filtro de tipos
          _buildSearchAndTypeRow(),
          const SizedBox(height: 16),
          // Sub-abas de período e contador
          _buildPeriodTabsRow(),
          const SizedBox(height: 20),
          // Grupos de eventos
          _buildAgendaGroups(),
        ],
      ),
    );
  }

  Widget _buildSearchAndTypeRow() {
    final types = ['Todos', 'Entregas', 'Aulas', 'Fóruns', 'Avaliações'];

    return Row(
      children: [
        // Campo de busca
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por compromisso, matéria ou atividade...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Rótulo Tipo e Chips
        Row(
          children: [
            const Icon(Icons.tune, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            const Text(
              'Tipo:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 8),
            ...types.map((t) {
              final isSelected = _selectedType == t;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedType = t),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF26394A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF26394A)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodTabsRow() {
    final periods = [
      'Todos os compromissos',
      'Hoje',
      'Esta Semana',
      'Este mês',
    ];

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 8,
      children: [
        Wrap(
          spacing: 16,
          children: periods.map((p) {
            final isSelected = _selectedPeriod == p;
            return InkWell(
              key: Key(
                'calendar_period_${p.toLowerCase().replaceAll(' ', '_')}',
              ),
              onTap: () => setState(() => _selectedPeriod = p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          bottom: BorderSide(
                            color: Color(0xFF1D4ED8),
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Text(
          '${_filteredEvents.length} compromisso${_filteredEvents.length == 1 ? '' : 's'} encontrado${_filteredEvents.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildAgendaGroups() {
    final events = _filteredEvents;
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text(
            'Nenhum compromisso encontrado para os filtros selecionados.',
          ),
        ),
      );
    }
    final grouped = <String, List<StudentCalendarEvent>>{};
    for (final event in events) {
      (grouped[event.date] ??= []).add(event);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.expand((entry) {
        final date = DateTime.tryParse(entry.key);
        final label = date == null ? entry.key : _formatDate(date);
        final children = <Widget>[
          _buildGroupHeader(
            dateText: label,
            isToday: _isToday(date),
            countText:
                '${entry.value.length} ${entry.value.length == 1 ? 'item' : 'itens'}',
          ),
          const SizedBox(height: 10),
        ];
        for (final event in entry.value) {
          children.add(_buildEventCardFromEvent(event));
          children.add(const SizedBox(height: 12));
        }
        children.add(const SizedBox(height: 12));
        return children;
      }).toList(),
    );
  }

  List<StudentCalendarEvent> get _filteredEvents {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.events.where((event) {
      const typeFilters = {
        'Entregas': 'Entrega',
        'Aulas': 'Aula',
        'Fóruns': 'Fórum',
        'Avaliações': 'Avaliação',
      };
      final selectedType = typeFilters[_selectedType];
      if (selectedType != null && event.type != selectedType) {
        return false;
      }
      if (query.isNotEmpty &&
          !'${event.title} ${event.discipline} ${event.location}'
              .toLowerCase()
              .contains(query)) {
        return false;
      }
      final eventDate = DateTime.tryParse(event.date);
      if (eventDate == null) return false;
      final focusedDate = widget.controller.calendarFocusedDate;
      switch (_selectedPeriod) {
        case 'Hoje':
          if (!_sameDate(eventDate, focusedDate)) return false;
          break;
        case 'Esta Semana':
          final weekStart = focusedDate.subtract(
            Duration(days: focusedDate.weekday % 7),
          );
          final weekEnd = weekStart.add(const Duration(days: 7));
          if (eventDate.isBefore(weekStart) || !eventDate.isBefore(weekEnd)) {
            return false;
          }
          break;
        case 'Este mês':
          if (eventDate.year != focusedDate.year ||
              eventDate.month != focusedDate.month) {
            return false;
          }
          break;
      }
      return true;
    }).toList()..sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      return dateComparison != 0 ? dateComparison : a.time.compareTo(b.time);
    });
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return '${date.day} de ${months[date.month - 1]} • ${weekdays[date.weekday - 1]}, ${date.year}';
  }

  Widget _buildEventCardFromEvent(StudentCalendarEvent event) {
    final color = switch (event.type) {
      'Entrega' => const Color(0xFF16A34A),
      'Aula' => const Color(0xFF0D9488),
      'Fórum' => const Color(0xFFD97706),
      _ => const Color(0xFFDC2626),
    };
    final icon = switch (event.type) {
      'Entrega' => Icons.assignment_outlined,
      'Aula' => Icons.video_camera_front_outlined,
      'Fórum' => Icons.forum_outlined,
      _ => Icons.fact_check_outlined,
    };
    return _buildEventCard(
      time: event.time,
      stripColor: color,
      title: event.title,
      isUrgent: event.type == 'Entrega',
      disciplineTag: event.discipline,
      typeIcon: icon,
      typeName: event.type,
      description: 'Compromisso acadêmico registrado no calendário.',
      location: event.location,
    );
  }

  Widget _buildGroupHeader({
    required String dateText,
    required bool isToday,
    required String countText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HOJE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          countText,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required String time,
    required Color stripColor,
    required String title,
    required bool isUrgent,
    required String disciplineTag,
    required IconData typeIcon,
    required String typeName,
    required String description,
    required String location,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna de horário com ícone
          Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              const Text(
                'HORÁRIO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Faixa vertical de cor
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          // Conteúdo textual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18181B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        disciplineTag,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4B5563),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(typeIcon, size: 14, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      typeName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botão Detalhes
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$typeName • $disciplineTag'),
                    const SizedBox(height: 8),
                    Text('Horário: $time'),
                    const SizedBox(height: 8),
                    Text(description),
                    const SizedBox(height: 8),
                    Text('Local: $location'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
            icon: const Text(
              'Detalhes',
              style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
            label: const Icon(
              Icons.open_in_new,
              size: 13,
              color: Color(0xFF6B7280),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
