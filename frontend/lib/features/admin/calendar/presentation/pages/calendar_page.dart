// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 28.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho da Página
                      const Text(
                        'Calendário Acadêmico Oficial & Prazos Regimentais',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Parametrização das janelas de provas, controle das travas regimentais de notas e homologação de semestres.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF71717A),
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
  Widget _buildConsepeResolutionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'RESOLUÇÃO CONSEPE 2026/04',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF71717A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Semestre Letivo 2026/2 • Carga de 100 Dias Letivos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Semana 10 de 18',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'O regimento acadêmico prevê o bloqueio automatizado do lançamento de notas após o encerramento do prazo regulamentar. Qualquer retificação extemporânea exige protocolo com justificativa homologada pelo colegiado de curso.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF52525B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD TIMELINE DOS PRAZOS REGIMENTAIS
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
                const Expanded(
                  child: Text(
                    'Marcos do calend?rio acad?mico',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        : 'Di?rios abertos para digita??o',
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
                                    ? 'Configura??o da trava atualizada.'
                                    : _controller.remoteError ??
                                          'Falha ao atualizar a trava.',
                              ),
                            ),
                          );
                        },
                  child: Text(
                    _controller.isRegimentalLockActive
                        ? 'Liberar di?rios'
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
    return end == null ? date(start) : '${date(start)} ? ${date(end)}';
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

  Widget _buildBadge({
    required String label,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
