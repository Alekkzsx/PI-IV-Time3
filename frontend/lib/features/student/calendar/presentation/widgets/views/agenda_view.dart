// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import 'components/agenda_event_card.dart';

/// [AgendaView]
///
/// Componente de visualização em formato de lista/agenda cronológica do calendário.
/// Oferece filtragem multifacetada com busca textual em tempo real, agrupamento por data,
/// chips de categoria (Entregas, Aulas, Fóruns, Avaliações) e delega a renderização de cada
/// compromisso para [AgendaEventCard].
class AgendaView extends StatefulWidget {
  /// Controlador compartilhado do Portal do Aluno.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AgendaView].
  const AgendaView({super.key, required this.controller});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
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
          _buildSearchAndTypeRow(),
          const SizedBox(height: 16),
          _buildPeriodTabsRow(),
          const SizedBox(height: 20),
          _buildAgendaGroups(),
        ],
      ),
    );
  }

  Widget _buildSearchAndTypeRow() {
    final types = ['Todos', 'Entregas', 'Aulas', 'Fóruns', 'Avaliações'];

    return Row(
      children: [
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
          children.add(AgendaEventCard(event: event));
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
}

typedef StudentCalendarAgendaView = AgendaView;
