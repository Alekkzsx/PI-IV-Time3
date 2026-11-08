// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';

/// Tela do Calendário Acadêmico Oficial e Prazos Regimentais (CONSEPE) na Visão do Administrador.
/// Exibe as janelas de avaliação, controle das travas regimentais de notas e homologação de semestres.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final AdminPortalController _controller = AdminPortalController.instance;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabeçalho da Página
                          Text(
                            'Calendário Acadêmico Oficial & Prazos Regimentais',
                            style: jakarta(
                              size: 22,
                              weight: FontWeight.w700,
                              color: const Color(0xFF09090B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Parametrização das janelas de provas, controle das travas regimentais de notas e homologação de semestres.',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w400,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                          const SizedBox(height: 28),

                          if (_controller.remoteError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _controller.remoteError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          _buildResolutionSummary(),
                          const SizedBox(height: 24),
                          _buildTimelineCard(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rodapé Institucional
                const AdminFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResolutionSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESOLUÇÃO CONSEPE 2026/04',
                style: jakarta(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFF71717A),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Semestre Letivo 2026/2 • Carga de 100 Dias Letivos',
                style: jakarta(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          );
          final weekBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Text(
              'Semana 10 de 18',
              style: jakarta(
                size: 10,
                weight: FontWeight.w600,
                color: const Color(0xFF15803D),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (constraints.maxWidth < 560) ...[
                heading,
                const SizedBox(height: 10),
                weekBadge,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    weekBadge,
                  ],
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
              Text(
                'O regimento acadêmico prevê o bloqueio automatizado do lançamento de notas após o encerramento do prazo regulamentar. Qualquer retificação extemporânea exige protocolo com justificativa homologada pelo colegiado de curso.',
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w400,
                  color: const Color(0xFF71717A),
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CARD RESOLUÇÃO CONSEPE 2026/04
  // ==========================================
  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Marcos do calendário acadêmico',
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _controller.isSavingRemote
                      ? null
                      : () => _editEvent(),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar marco'),
                ),
              ],
            ),
          ),
          if (_controller.calendarEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhum marco cadastrado.'),
            )
          else
            for (
              var index = 0;
              index < _controller.calendarEvents.length;
              index++
            ) ...[
              if (index > 0) const Divider(height: 1, color: Color(0xFFF4F4F5)),
              _buildTimelineRow(
                tag: _controller.calendarEvents[index].type,
                dateText: _formatEventDate(
                  _controller.calendarEvents[index].startsAt,
                  _controller.calendarEvents[index].endsAt,
                ),
                title: _controller.calendarEvents[index].title,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEventStatus(_controller.calendarEvents[index]),
                    PopupMenuButton<String>(
                      tooltip: 'Ações do marco',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _editEvent(_controller.calendarEvents[index]);
                        } else {
                          _deleteEvent(_controller.calendarEvents[index].id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar marco'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir marco'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _controller.isRegimentalLockActive
                        ? 'Trava regimental ativa'
                        : 'Diários abertos para digitação',
                  ),
                ),
                ElevatedButton(
                  onPressed: _controller.isSavingRemote
                      ? null
                      : () async {
                          final saved = await _controller
                              .persistRegimentalLock();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? 'Configuração da trava atualizada.'
                                    : _controller.remoteError ??
                                          'Falha ao atualizar a trava.',
                              ),
                            ),
                          );
                        },
                  child: Text(
                    _controller.isRegimentalLockActive
                        ? 'Liberar diários'
                        : 'Ativar trava',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(String startsAt, String? endsAt) {
    final start = DateTime.tryParse(startsAt)?.toLocal();
    final end = DateTime.tryParse(endsAt ?? '')?.toLocal();
    if (start == null) return startsAt;
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
    String date(DateTime value, {bool includeTime = false}) {
      final date =
          '${value.day} de ${months[value.month - 1]} de ${value.year}';
      if (!includeTime || (value.hour == 0 && value.minute == 0)) return date;
      final time =
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
      return '$date às $time';
    }

    return end == null
        ? date(start, includeTime: true)
        : '${date(start)} a ${date(end, includeTime: true)}';
  }

  Widget _buildEventStatus(AdminCalendarMilestone event) {
    final startsAt = DateTime.tryParse(event.startsAt)?.toLocal();
    final endsAt = DateTime.tryParse(event.endsAt ?? '')?.toLocal();
    final now = DateTime.now();
    final label = startsAt == null || startsAt.isAfter(now)
        ? 'Futuro'
        : endsAt != null && endsAt.isBefore(now)
        ? 'Encerrado'
        : 'Em Andamento';
    final color = label == 'Em Andamento'
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF52525B);
    final background = label == 'Em Andamento'
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFFAFAFA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: label == 'Em Andamento'
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE4E4E7),
        ),
      ),
      child: Text(
        label,
        style: jakarta(size: 10, weight: FontWeight.w500, color: color),
      ),
    );
  }

  String? _inputDate(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String value) =>
      DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));

  Future<void> _editEvent([AdminCalendarMilestone? event]) async {
    final title = TextEditingController(text: event?.title ?? '');
    final description = TextEditingController(text: event?.description ?? '');
    final starts = TextEditingController(
      text:
          _inputDate(event?.startsAt) ??
          DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String()
              .substring(0, 16),
    );
    final ends = TextEditingController(text: _inputDate(event?.endsAt) ?? '');
    var type = event?.type ?? 'academic';
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(event == null ? 'Novo marco' : 'Editar marco'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'T?tulo'),
                  ),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descri??o'),
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'academic',
                        child: Text('Acad?mico'),
                      ),
                      DropdownMenuItem(value: 'deadline', child: Text('Prazo')),
                      DropdownMenuItem(
                        value: 'holiday',
                        child: Text('Feriado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  TextField(
                    controller: starts,
                    decoration: const InputDecoration(
                      labelText: 'In?cio (AAAA-MM-DD HH:MM)',
                    ),
                  ),
                  TextField(
                    controller: ends,
                    decoration: const InputDecoration(
                      labelText: 'T?rmino opcional (AAAA-MM-DD HH:MM)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final start = _parseDate(starts.text);
                final end = ends.text.trim().isEmpty
                    ? null
                    : _parseDate(ends.text);
                if (title.text.trim().length < 2 ||
                    start == null ||
                    (ends.text.trim().isNotEmpty && end == null))
                  return;
                Navigator.pop(context, {
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'type': type,
                  'startsAt': start.toUtc().toIso8601String(),
                  'endsAt': end?.toUtc().toIso8601String(),
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    starts.dispose();
    ends.dispose();
    if (values == null) return;
    final saved = event == null
        ? await _controller.createCalendarEvent(values)
        : await _controller.updateCalendarEvent(event.id, values);
    if (mounted && !saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.remoteError ?? 'Falha ao salvar.')),
      );
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir marco?'),
        content: const Text('Esta a??o n?o pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final deleted = await _controller.deleteCalendarEvent(id);
    if (mounted && !deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.remoteError ?? 'Falha ao excluir.')),
      );
    }
  }

  Widget _buildTimelineRow({
    required String tag,
    required String dateText,
    required String title,
    required Widget trailing,
  }) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF52525B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                dateText,
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w400,
                  color: const Color(0xFF71717A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF09090B),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: trailing),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              trailing,
            ],
          );
        },
      ),
    );
  }
}
