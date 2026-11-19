// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';

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
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48.0 : 20.0,
                    vertical: 36.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho da Página
                      Text(
                        'Calendário Acadêmico Oficial & Prazos Regimentais',
                        style: jakarta(
                          size: isDesktop ? 26 : 22,
                          weight: FontWeight.w700,
                          color: const Color(0xFF09090B),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Parametrização das janelas de provas, controle das travas regimentais de notas e homologação de semestres.',
                        style: jakarta(
                          size: 14,
                          color: const Color(0xFF737373),
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildTimelineCard(),
                    ],
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
                      size: 16,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _controller.isSavingRemote
                      ? null
                      : () => _editEvent(),
                  icon: const Icon(Icons.add, size: 17),
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
                tag: _formatEventTag(_controller.calendarEvents[index].type),
                dateText: _formatEventDate(
                  _controller.calendarEvents[index].startsAt,
                  _controller.calendarEvents[index].endsAt,
                ),
                title: _controller.calendarEvents[index].title,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar marco',
                      onPressed: () =>
                          _editEvent(_controller.calendarEvents[index]),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Excluir marco',
                      onPressed: () =>
                          _deleteEvent(_controller.calendarEvents[index].id),
                      icon: const Icon(Icons.delete_outline),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _controller.isRegimentalLockActive
                        ? InstColors.danger
                        : InstColors.ink,
                    foregroundColor: Colors.white,
                  ),
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
    String date(DateTime value) =>
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return end == null ? date(start) : '${date(start)} – ${date(end)}';
  }

  String _normalizeCalendarType(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'holiday':
        return 'holiday';
      case 'deadline':
        return 'deadline';
      case 'closing':
        return 'closing';
      case 'institutional':
        return 'institutional';
      default:
        return 'academic';
    }
  }

  String _formatEventTag(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'academic':
        return 'Acadêmico';
      case 'deadline':
        return 'Prazo';
      case 'holiday':
        return 'Feriado';
      case 'closing':
        return 'Fechamento';
      case 'institutional':
        return 'Institucional';
      case 'administrative':
        return 'Administrativo';
      case 'exam':
        return 'Avaliação';
      case 'event':
        return 'Evento';
      default:
        return raw.trim().isEmpty ? 'Acadêmico' : raw;
    }
  }

  String? _inputDate(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String value) =>
      DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));

  Future<void> _pickDateTimeFor(TextEditingController target) async {
    final initial = _parseDate(target.text) ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    target.text =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _editEvent([AdminCalendarMilestone? event]) async {
    final title = TextEditingController(text: event?.title ?? '');
    final description = TextEditingController(text: event?.description ?? '');
    final starts = TextEditingController(
      text:
          _inputDate(event?.startsAt) ??
          _inputDate(
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          )!,
    );
    final ends = TextEditingController(text: _inputDate(event?.endsAt) ?? '');
    var type = _normalizeCalendarType(event?.type);
    String? validationError;

    final values = await AcademicModalDialog.show<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AcademicModalDialog(
          title: event == null
              ? 'Novo Marco Acadêmico'
              : 'Editar Marco Acadêmico',
          subtitle:
              'Os marcos publicados são sincronizados com o calendário dos portais Docente e Discente.',
          icon: Icons.event_note_outlined,
          cancelLabel: 'Cancelar',
          confirmLabel: 'Salvar marco',
          onConfirm: () {
            final start = _parseDate(starts.text);
            final end = ends.text.trim().isEmpty
                ? null
                : _parseDate(ends.text);
            if (title.text.trim().length < 2 ||
                start == null ||
                (ends.text.trim().isNotEmpty && end == null) ||
                (end != null && end.isBefore(start))) {
              setDialogState(() {
                validationError =
                    'Verifique título e datas válidas (término posterior ao início).';
              });
              return;
            }
            Navigator.pop(dialogContext, {
              'title': title.text.trim(),
              'description': description.text.trim(),
              'type': type,
              'isMilestone': true,
              'startsAt': start.toUtc().toIso8601String(),
              'endsAt': end?.toUtc().toIso8601String(),
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (validationError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: InstColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    validationError!,
                    style: jakarta(size: 12.5, color: InstColors.danger),
                  ),
                ),
              ],
              TextField(
                controller: title,
                decoration: InstText.inputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: InstText.inputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InstText.inputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: 'academic',
                    child: Text('Acadêmico'),
                  ),
                  DropdownMenuItem(value: 'deadline', child: Text('Prazo')),
                  DropdownMenuItem(value: 'closing', child: Text('Fechamento')),
                  DropdownMenuItem(
                    value: 'institutional',
                    child: Text('Institucional'),
                  ),
                  DropdownMenuItem(value: 'holiday', child: Text('Feriado')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: starts,
                decoration: InstText.inputDecoration(
                  labelText: 'Início (AAAA-MM-DD HH:MM)',
                  suffixIcon: IconButton(
                    tooltip: 'Selecionar data e hora',
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    onPressed: () => _pickDateTimeFor(starts),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ends,
                decoration: InstText.inputDecoration(
                  labelText: 'Término opcional (AAAA-MM-DD HH:MM)',
                  suffixIcon: IconButton(
                    tooltip: 'Selecionar data e hora',
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    onPressed: () => _pickDateTimeFor(ends),
                  ),
                ),
              ),
            ],
          ),
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
    final confirm = await AcademicModalDialog.show<bool>(
      context: context,
      builder: (dialogContext) => AcademicModalDialog(
        title: 'Excluir Marco Acadêmico?',
        subtitle: 'Esta ação não pode ser desfeita nos portais.',
        icon: Icons.delete_outline_rounded,
        cancelLabel: 'Cancelar',
        confirmLabel: 'Excluir',
        isConfirmDestructive: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
        child: Text(
          'Confirma a exclusão permanente deste marco do calendário oficial?',
          style: jakarta(size: 13.5, color: InstColors.ink),
        ),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF52525B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                dateText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF09090B),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
