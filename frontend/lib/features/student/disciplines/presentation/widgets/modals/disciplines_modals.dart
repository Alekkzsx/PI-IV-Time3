// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/ava/common/ava_common.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';

/// [DisciplinesModals]
///
/// Utilitário estático responsável pelos diálogos modais canônicos do catálogo de disciplinas
/// e do Cockpit AVA: Boletim & Histórico Escolar Oficial, Plano de Ensino Regimental e
/// Canal Direto de Atendimento com Docente (conectados ao Backend/MongoDB).
class DisciplinesModals {
  DisciplinesModals._();

  /// Exibe o modal com o Boletim & Histórico Escolar Oficial vindo de `/api/student/boletim`.
  static Future<void> showBoletimModal(
    BuildContext context, {
    required StudentPortalController controller,
  }) async {
    try {
      final periods = await controller.loadBoletim();
      if (!context.mounted) return;

      await AvaStandardModal.show<void>(
        context: context,
        maxWidth: 780,
        overlineTag: 'SECRETARIA ACADÊMICA & REGISTRO ESCOLAR',
        title: 'Boletim & Histórico Escolar Oficial',
        subtitle:
            '${AppUserSession.instance.effectiveName} • R.A.: ${AppUserSession.instance.identity ?? ''}',
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (periods.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Não há histórico escolar disponível.',
                    style: jakarta(size: 13, color: const Color(0xFF71717A)),
                  ),
                ),
              ),
            ...periods.map((period) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: AvaBannerSurfaceCard(
                  overlineTag: 'PERÍODO LETIVO HOMOLOGADO',
                  title: period.period,
                  bodyPadding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 680),
                      child: Table(
                        border: const TableBorder(
                          horizontalInside: BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(105),
                          1: FlexColumnWidth(2.6),
                          2: FixedColumnWidth(62),
                          3: FixedColumnWidth(62),
                          4: FixedColumnWidth(72),
                          5: FixedColumnWidth(68),
                          6: FixedColumnWidth(108),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAF8F5),
                            ),
                            children: [
                              _buildTableHeaderCell('CÓDIGO'),
                              _buildTableHeaderCell('DISCIPLINA'),
                              _buildTableHeaderCell('N1'),
                              _buildTableHeaderCell('N2'),
                              _buildTableHeaderCell('MÉDIA'),
                              _buildTableHeaderCell('FALTAS'),
                              _buildTableHeaderCell('RESULTADO'),
                            ],
                          ),
                          ...period.items.map((item) {
                            final situacao =
                                item['situacao']?.toString() ?? 'Em Curso';
                            final isApproved =
                                situacao.toLowerCase().contains('aprov') ||
                                situacao.toLowerCase().contains('regular') ||
                                situacao.toLowerCase().contains('curso');
                            return TableRow(
                              children: [
                                _buildTableCell(
                                  item['codigo']?.toString() ?? '',
                                ),
                                _buildTableCell(
                                  item['disciplina']?.toString() ?? '',
                                  isBold: true,
                                ),
                                _buildTableCell(item['n1']?.toString() ?? '—'),
                                _buildTableCell(item['n2']?.toString() ?? '—'),
                                _buildTableCell(
                                  item['media']?.toString() ?? '—',
                                  isBold: true,
                                ),
                                _buildTableCell(
                                  item['faltas']?.toString() ?? '0',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: AvaStatusBadge(
                                      label: situacao,
                                      variant: isApproved
                                          ? AvaBadgeVariant.success
                                          : AvaBadgeVariant.warning,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          AvaActionPillButton(
            label: 'Exportar Boletim Oficial',
            icon: Icons.download_rounded,
            variant: AvaButtonVariant.secondary,
            onPressed: () async {
              final buffer = StringBuffer()
                ..writeln('BOLETIM & HISTÓRICO ESCOLAR OFICIAL — AGMRM')
                ..writeln('===========================================')
                ..writeln('Estudante: ${AppUserSession.instance.effectiveName}')
                ..writeln('R.A.: ${AppUserSession.instance.identity ?? "—"}')
                ..writeln('');
              for (final period in periods) {
                buffer.writeln('Período: ${period.period}');
                for (final item in period.items) {
                  buffer.writeln(
                    '- [${item['codigo']}] ${item['disciplina']} | N1: ${item['n1'] ?? "-"} | N2: ${item['n2'] ?? "-"} | Média: ${item['media'] ?? "-"} | Faltas: ${item['faltas'] ?? 0} | ${item['situacao'] ?? ""}',
                  );
                }
                buffer.writeln('');
              }
              final savedPath = await PlatformFileHelper.saveAndLaunchFile(
                bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
                fileName: 'boletim_historico_oficial.txt',
                mimeType: 'text/plain; charset=utf-8',
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    savedPath == null
                        ? 'Não foi possível exportar o boletim escolar.'
                        : 'Boletim oficial exportado: $savedPath',
                  ),
                ),
              );
            },
          ),
          AvaActionPillButton(
            label: 'Fechar',
            variant: AvaButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  static Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: jakarta(
          size: 10,
          weight: FontWeight.w700,
          color: const Color(0xFF71717A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Text(
        text,
        style: jakarta(
          size: 11.5,
          weight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF18181B),
        ),
      ),
    );
  }

  /// Exibe o modal com o Plano de Ensino & Ementa Homologada real da disciplina no MongoDB.
  static void showPlanoEnsinoModal(
    BuildContext context, {
    StudentDisciplineModel? discipline,
  }) {
    final controller = StudentPortalController.instance;
    final d = discipline ?? controller.selectedDiscipline;
    final courseName = controller.studentInfo['courseName']?.toString() ?? '';
    final subtitleText = d != null
        ? '${d.name} (${d.code}) • Docente: ${d.professor}'
        : (courseName.isNotEmpty ? courseName : 'Plano de Ensino Institucional');

    AvaStandardModal.show<void>(
      context: context,
      maxWidth: 680,
      overlineTag: 'PLANO DE ENSINO & EMENTA HOMOLOGADA',
      title: d != null ? d.name : 'Plano de Ensino & Ementa Homologada',
      subtitle: subtitleText,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AvaStatusBadge(
                  label: 'Turma ${d.fullCode ?? d.code}',
                  variant: AvaBadgeVariant.neutral,
                ),
                AvaStatusBadge(
                  label: '${d.totalHours}h (${d.credits} créditos)',
                  variant: AvaBadgeVariant.neutral,
                ),
                AvaStatusBadge(
                  label: 'Fórmula: ${d.evaluationFormula}',
                  variant: AvaBadgeVariant.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (d != null && d.ementa.trim().isNotEmpty) ...[
            _buildSyllabusSection('EMENTA OFICIAL', d.ementa),
            const SizedBox(height: 14),
          ],
          if (d != null && d.objectives.trim().isNotEmpty) ...[
            _buildSyllabusSection('OBJETIVOS PEDAGÓGICOS', d.objectives),
            const SizedBox(height: 14),
          ],
          if (d != null && d.methodology.trim().isNotEmpty) ...[
            _buildSyllabusSection(
              'METODOLOGIA & CONDUÇÃO DIDÁTICA',
              d.methodology,
            ),
            const SizedBox(height: 14),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRITÉRIOS REGIMENTAIS DE AVALIAÇÃO',
                  style: jakarta(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Fórmula da Disciplina: ${d?.evaluationFormula ?? "(N1 × 0.4) + (N2 × 0.6)"}\n'
                  '• Frequência Mínima Obrigatória: 75% (máximo de ${d?.maxAbsenceHours ?? 20}h de faltas)\n'
                  '• Média Mínima para Aprovação Direta: 6.0 pontos',
                  style: jakarta(
                    size: 12,
                    color: const Color(0xFF3F3F46),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (d != null && d.syllabusUnits.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'UNIDADES CURRICULARES PROGRAMADAS',
              style: jakarta(
                size: 10.5,
                weight: FontWeight.w700,
                color: const Color(0xFF71717A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...d.syllabusUnits.map((unit) {
              final unitTitle =
                  unit['title']?.toString() ??
                  unit['name']?.toString() ??
                  unit['unit']?.toString() ??
                  'Unidade Didática';
              final items = unit['items'] is List
                  ? (unit['items'] as List).length
                  : 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: Color(0xFF166534),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unitTitle,
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                    if (items > 0)
                      AvaStatusBadge(
                        label: '$items itens',
                        variant: AvaBadgeVariant.neutral,
                      ),
                  ],
                ),
              );
            }),
          ],
          if (d != null && d.bibliography.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'BIBLIOGRAFIA BÁSICA E COMPLEMENTAR',
              style: jakarta(
                size: 10.5,
                weight: FontWeight.w700,
                color: const Color(0xFF71717A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...d.bibliography.map((book) {
              final title = book['title']?.toString() ?? '';
              final author = book['author']?.toString() ?? '';
              final year = book['year']?.toString() ?? '';
              final type = book['type']?.toString() ?? 'Referência';
              final line = [
                if (author.isNotEmpty) author,
                if (title.isNotEmpty) title,
                if (year.isNotEmpty) year,
              ].join(' • ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvaStatusBadge(
                      label: type,
                      variant: AvaBadgeVariant.neutral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: jakarta(
                          size: 12,
                          color: const Color(0xFF3F3F46),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
      actions: [
        if (d != null)
          AvaActionPillButton(
            label: 'Exportar Plano (.txt)',
            icon: Icons.download_rounded,
            variant: AvaButtonVariant.secondary,
            onPressed: () async {
              final content = StringBuffer()
                ..writeln('PLANO DE ENSINO HOMOLOGADO — ${d.name} (${d.code})')
                ..writeln('Docente: ${d.professor} | Carga Horária: ${d.totalHours}h')
                ..writeln('Fórmula: ${d.evaluationFormula}')
                ..writeln('')
                ..writeln('EMENTA:')
                ..writeln(d.ementa.isEmpty ? 'Conforme PPC vigente.' : d.ementa)
                ..writeln('')
                ..writeln('OBJETIVOS:')
                ..writeln(d.objectives)
                ..writeln('')
                ..writeln('METODOLOGIA:')
                ..writeln(d.methodology);
              final safeCode = d.code.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
              final path = await PlatformFileHelper.saveAndLaunchFile(
                bytes: Uint8List.fromList(utf8.encode(content.toString())),
                fileName: 'plano_ensino_$safeCode.txt',
                mimeType: 'text/plain; charset=utf-8',
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    path == null
                        ? 'Não foi possível exportar o Plano de Ensino.'
                        : 'Plano de Ensino exportado: $path',
                  ),
                ),
              );
            },
          ),
        if (d != null && controller.selectedDiscipline?.code == d.code)
          AvaActionPillButton(
            label: 'Abrir Aba Programa',
            icon: Icons.menu_book_rounded,
            variant: AvaButtonVariant.subtle,
            onPressed: () {
              Navigator.of(context).pop();
              controller.setAvaTab(7);
            },
          ),
        AvaActionPillButton(
          label: 'Entendido',
          variant: AvaButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Exibe o modal canônico para contato direto e envio de e-mail institucional ao Docente Titular.
  static Future<void> showContactProfessorModal(
    BuildContext context, {
    required StudentDisciplineModel discipline,
  }) async {
    final subjectCtrl = TextEditingController(
      text: 'Dúvida Acadêmica — ${discipline.code}',
    );
    final messageCtrl = TextEditingController();
    bool isSending = false;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> submit() async {
              final subject = subjectCtrl.text.trim();
              final message = messageCtrl.text.trim();
              if (subject.length < 3 || message.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Informe o assunto e descreva sua mensagem ao docente.',
                    ),
                  ),
                );
                return;
              }
              setModalState(() => isSending = true);
              try {
                final res = await StudentPortalController.instance
                    .contactProfessor(
                      classCode: discipline.code,
                      subject: subject,
                      message: message,
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                final protocol = res['protocolCode']?.toString() ?? 'ENVIADO';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mensagem enviada a ${discipline.professor} (Protocolo: $protocol).',
                    ),
                  ),
                );
              } catch (error) {
                setModalState(() => isSending = false);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            }

            return AvaStandardModal(
              overlineTag: 'CANAL DIRETO DOCENTE • ${discipline.code}',
              title: 'Contatar ${discipline.professor}',
              subtitle: discipline.professorEmail.isNotEmpty
                  ? 'Destinatário institucional: ${discipline.professorEmail}'
                  : 'Sua mensagem será registrada no AVA e encaminhada ao e-mail institucional do docente.',
              maxWidth: 560,
              actions: [
                AvaActionPillButton(
                  label: 'Cancelar',
                  variant: AvaButtonVariant.secondary,
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                AvaActionPillButton(
                  label: 'Enviar Mensagem',
                  icon: Icons.send_rounded,
                  isLoading: isSending,
                  variant: AvaButtonVariant.primary,
                  onPressed: isSending ? null : submit,
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASSUNTO',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF71717A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subjectCtrl,
                    style: jakarta(size: 13, color: const Color(0xFF18181B)),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFFAF8F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF18181B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MENSAGEM / ORIENTAÇÃO SOLICITADA',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF71717A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 5,
                    style: jakarta(size: 13, color: const Color(0xFF18181B)),
                    decoration: InputDecoration(
                      hintText:
                          'Descreva sua dúvida sobre conteúdo, entregas ou agendamento de plantão...',
                      hintStyle: jakarta(
                        size: 12.5,
                        color: const Color(0xFFA1A1AA),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF18181B)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSyllabusSection(String overline, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline,
            style: jakarta(
              size: 10.5,
              weight: FontWeight.w700,
              color: const Color(0xFF71717A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: jakarta(
              size: 12.5,
              color: const Color(0xFF3F3F46),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

typedef StudentDisciplinesModals = DisciplinesModals;
