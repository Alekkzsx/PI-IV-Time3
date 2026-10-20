// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Tela de Calendário Acadêmico da Visão do Aluno.
/// Suporta alternância dinâmica entre visualização em Mês e visualização em Agenda,
/// filtros por categoria e por disciplina, e modal de criação de novo evento.
class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({super.key});

  @override
  State<StudentCalendarPage> createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área Esquerda: Calendário Principal
          Expanded(flex: 3, child: _buildMainCalendarArea()),
          const SizedBox(width: 24),
          // Área Direita: Mini Calendário e Filtros
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildMiniCalendar(),
                const SizedBox(height: 24),
                _buildFiltersCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÁREA PRINCIPAL DO CALENDÁRIO
  // ==========================================
  Widget _buildMainCalendarArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (_controller.calendarViewMode == 'Mês') ...[
            _buildDaysOfWeek(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildMonthGrid(),
          ] else ...[
            _buildAgendaView(),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: const Text('Hoje', style: TextStyle(color: Color(0xFF18181B))),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
              const SizedBox(width: 12),
              const Text('Outubro de 2026', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
            ],
          ),
          Row(
            children: [
              // Alternador Mês / Agenda
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildModeButton('Mês'),
                    _buildModeButton('Agenda'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateEventModal(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Evento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode) {
    final isSelected = _controller.calendarViewMode == mode;
    return InkWell(
      onTap: () => _controller.setCalendarViewMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
        ),
        child: Text(
          mode,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: days.map((d) {
          return Expanded(
            child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          );
        }).toList(),
      ),
    );
  }

  // Visualização Mês (Print 25)
  Widget _buildMonthGrid() {
    return SizedBox(
      height: 480,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 35,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final dayNumber = index - 3;
          final isCurrentMonth = dayNumber >= 1 && dayNumber <= 31;
          final isToday = dayNumber == 20;

          // Eventos para o dia 20
          List<Widget> dayEvents = [];
          if (dayNumber == 20 && isCurrentMonth) {
            dayEvents.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                child: const Text('19:00 Aula APS-II', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            );
            dayEvents.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                child: const Text('23:59 Entrega Adapter', style: TextStyle(fontSize: 9, color: Color(0xFFDC2626), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            );
          } else if (dayNumber == 22 && isCurrentMonth) {
            dayEvents.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                child: const Text('20:50 Prova BD-II', style: TextStyle(fontSize: 9, color: Color(0xFFD97706), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF1F5F9)),
              color: isToday ? const Color(0xFFF8FAFC) : Colors.white,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCurrentMonth)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: isToday ? const BoxDecoration(color: Color(0xFF18181B), shape: BoxShape.circle) : null,
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ...dayEvents,
              ],
            ),
          );
        },
      ),
    );
  }

  // Visualização Agenda (Print 26)
  Widget _buildAgendaView() {
    final filteredEvents = _controller.events.where((e) {
      return _controller.activeEventTypes.contains(e.type) && _controller.activeDisciplineFilters.contains(e.discipline);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compromissos e Prazos do Semestre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
          const SizedBox(height: 16),
          if (filteredEvents.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Nenhum evento correspondente aos filtros selecionados.')))
          else
            ...filteredEvents.map((e) {
              Color tagColor = const Color(0xFF18181B);
              if (e.type == 'Entrega') tagColor = const Color(0xFFDC2626);
              if (e.type == 'Aula') tagColor = const Color(0xFF16A34A);
              if (e.type == 'Avaliação') tagColor = const Color(0xFFD97706);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 44, decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${e.discipline} • ${e.date} • ${e.time} • ${e.location}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(e.type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tagColor)),
                      backgroundColor: tagColor.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // SIDEBAR: MINI CALENDÁRIO & FILTROS
  // ==========================================
  Widget _buildMiniCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: const [
          Text('Outubro 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 8),
          Text('Segunda-feira, 20 de Outubro', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    final eventCategories = [
      {'tipo': 'Aula', 'cor': const Color(0xFF16A34A)},
      {'tipo': 'Entrega', 'cor': const Color(0xFFDC2626)},
      {'tipo': 'Avaliação', 'cor': const Color(0xFFD97706)},
      {'tipo': 'Fórum', 'cor': const Color(0xFF2563EB)},
    ];

    final disciplines = ['APS-II', 'BD-II', 'FIS', 'FSO'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtrar por Categoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...eventCategories.map((cat) {
            final tipo = cat['tipo'] as String;
            final cor = cat['cor'] as Color;
            final isChecked = _controller.activeEventTypes.contains(tipo);
            return InkWell(
              onTap: () => _controller.toggleEventTypeFilter(tipo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tipo, style: const TextStyle(fontSize: 13))),
                    Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: const Color(0xFF18181B)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Filtrar por Disciplina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...disciplines.map((d) {
            final isChecked = _controller.activeDisciplineFilters.contains(d);
            return InkWell(
              onTap: () => _controller.toggleDisciplineFilter(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(d, style: const TextStyle(fontSize: 13))),
                    Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: const Color(0xFF18181B)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL CRIAR/EDITAR EVENTO (Print 27)
  // ==========================================
  void _showCreateEventModal(BuildContext context) {
    final titleController = TextEditingController();
    final dateController = TextEditingController(text: '2026-10-25');
    final timeController = TextEditingController(text: '19:00 - 20:40');
    final locController = TextEditingController(text: 'Sala Virtual AVA / Lab 04');
    String selectedType = 'Aula';
    String selectedDiscipline = 'APS-II';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Criar Novo Evento Acadêmico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título do Evento', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Data (AAAA-MM-DD)', border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Horário', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo de Evento', border: OutlineInputBorder()),
                    items: ['Aula', 'Entrega', 'Avaliação', 'Fórum'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setModalState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDiscipline,
                    decoration: const InputDecoration(labelText: 'Disciplina Vinculada', border: OutlineInputBorder()),
                    items: ['APS-II', 'BD-II', 'FIS', 'FSO'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => setModalState(() => selectedDiscipline = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: locController, decoration: const InputDecoration(labelText: 'Local ou Link da Sala Virtual', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _controller.addCalendarEvent(
                    title: titleController.text,
                    date: dateController.text,
                    time: timeController.text,
                    type: selectedType,
                    discipline: selectedDiscipline,
                    location: locController.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento acadêmico agendado com sucesso!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
              child: const Text('Salvar Evento'),
            ),
          ],
        ),
      ),
    );
  }
}
