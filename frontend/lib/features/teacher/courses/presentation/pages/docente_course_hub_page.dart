// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/create_assignment_modal.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/rubric_evaluation_modal.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_header.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_sidebar.dart';
import '../widgets/hub/course_hub_assignments_tab.dart';
import '../widgets/hub/course_hub_attendance_tab.dart';
import '../widgets/hub/course_hub_forum_tab.dart';
import '../widgets/hub/course_hub_gradebook_tab.dart';
import '../widgets/hub/course_hub_header.dart';
import '../widgets/hub/course_hub_modules_tab.dart';
import '../widgets/hub/course_hub_overview_tab.dart';
import '../widgets/hub/course_hub_squads_tab.dart';
import '../widgets/hub/course_hub_students_tab.dart';
import '../widgets/hub/course_hub_sub_sidebar.dart';
import '../widgets/hub/course_hub_syllabus_tab.dart';
import '../widgets/hub/course_hub_ui.dart';

/// Sala de Aula Virtual (AVA) coesa da disciplina no Portal Docente.
class DocenteCourseHubPage extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final int initialTabIndex;

  const DocenteCourseHubPage({
    super.key,
    required this.course,
    required this.controller,
    this.initialTabIndex = 0,
  });

  @override
  State<DocenteCourseHubPage> createState() => _DocenteCourseHubPageState();
}

class _DocenteCourseHubPageState extends State<DocenteCourseHubPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _activeTabIndex;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex.clamp(0, 8);
    if (widget.controller.selectedCourseId != widget.course.id) {
      widget.controller.selectCourse(widget.course.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.controller.refreshIfStale());
      }
    });
  }

  DocenteCourse get _currentCourse {
    final selected = widget.controller.selectedCourse;
    if (selected.id.isNotEmpty) return selected;
    return widget.course;
  }

  void _handleLogout() {
    AppUserSession.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _switchCourse(DocenteCourse target) {
    widget.controller.selectCourse(target.id);
    setState(() {});
  }

  Future<void> _openLiveStream(DocenteCourse course) async {
    await Navigator.of(
      context,
    ).pushNamed('/video-call', arguments: {'roomCode': course.code});
    if (mounted) {
      await widget.controller.loadRemote(force: true);
    }
  }

  Future<void> _openNewAssignmentModal(DocenteCourse course) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CreateAssignmentModal(
        controller: widget.controller,
        initialCourseId: course.id,
        lockCourse: true,
      ),
    );
  }

  Future<void> _openRubricModal(
    AssignmentItem assignment,
    StudentSubmission submission,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => RubricEvaluationModal(
        assignment: assignment,
        submission: submission,
        controller: widget.controller,
      ),
    );
  }

  Future<void> _openQuickNoticeModal(DocenteCourse course) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    var classification = NoticeClassification.informativo;
    var audience = 'Todos os Discentes da Turma';
    var isSending = false;

    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'COMUNICAÇÃO OFICIAL • ${course.code}',
      title: 'Publicar Aviso à Turma',
      subtitle:
          'O comunicado será exibido imediatamente no Portal e Mural dos alunos matriculados.',
      maxWidth: 560,
      disposeOnClose: [titleCtrl, msgCtrl],
      builder: (_) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<NoticeClassification>(
                    initialValue: classification,
                    isExpanded: true,
                    decoration: courseHubInputDecoration(
                      labelText: 'Classificação',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: NoticeClassification.informativo,
                        child: Text('Informativo'),
                      ),
                      DropdownMenuItem(
                        value: NoticeClassification.convocacao,
                        child: Text('Convocação'),
                      ),
                      DropdownMenuItem(
                        value: NoticeClassification.urgencia,
                        child: Text('Urgência'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => classification = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: audience,
                    isExpanded: true,
                    decoration: courseHubInputDecoration(
                      labelText: 'Público-Alvo',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos os Discentes da Turma',
                        child: Text('Toda a Turma'),
                      ),
                      DropdownMenuItem(
                        value: 'Equipes do Projeto Integrador',
                        child: Text('Equipes de Projeto'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => audience = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Título do Comunicado',
                hintText: 'Ex: Roteiro atualizado para a entrega da Sprint',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Mensagem aos Estudantes',
                hintText:
                    'Escreva as instruções ou lembretes importantes para a turma...',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CourseHubPillButton(
                  label: 'Cancelar',
                  variant: CourseHubButtonVariant.secondary,
                  onPressed: () => Navigator.of(modalCtx).pop(),
                ),
                const SizedBox(width: 8),
                CourseHubPillButton(
                  label: 'Publicar Comunicado',
                  icon: Icons.send_rounded,
                  isLoading: isSending,
                  onPressed: isSending
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final message = msgCtrl.text.trim();
                          if (title.isEmpty || message.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Informe o título e a mensagem do aviso.',
                                ),
                                backgroundColor: Color(0xFFB91C1C),
                              ),
                            );
                            return;
                          }
                          setModalState(() => isSending = true);
                          final ok = await widget.controller.publishNotice(
                            targetCourse: course.code,
                            targetAudience: audience,
                            classification: classification,
                            title: title,
                            message: message,
                          );
                          if (!modalCtx.mounted) return;
                          Navigator.of(modalCtx).pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Comunicado enviado aos alunos de ${course.code}.'
                                    : (widget.controller.remoteError ??
                                          'Não foi possível enviar o aviso.'),
                              ),
                              backgroundColor: ok
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewContentModal(DocenteCourse course) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleCtrl = TextEditingController();
    PickedPlatformFile? pickedFile;
    final unitOptions = course.syllabusUnits.isNotEmpty
        ? course.syllabusUnits
              .map((u) => 'Unidade ${u.unitNumber} - ${u.title}')
              .toList()
        : <String>['Unidade 1'];
    var selectedUnit = unitOptions.first;
    var selectedCategory = 'Slides de Aula';
    var isUploading = false;

    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'MATERIAIS DIDÁTICOS • ${course.code}',
      title: 'Publicar Novo Conteúdo / Material',
      subtitle:
          'Disponibilize apostilas, slides ou códigos-fonte para download pelos estudantes.',
      maxWidth: 560,
      disposeOnClose: [titleCtrl],
      builder: (_) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleCtrl,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Título do Material',
                hintText: 'Ex: Slides Aula 04 - Heurísticas de Nielsen',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    isExpanded: true,
                    decoration: courseHubInputDecoration(
                      labelText: 'Unidade Associada',
                    ),
                    items: unitOptions
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedUnit = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    isExpanded: true,
                    decoration: courseHubInputDecoration(
                      labelText: 'Categoria no AVA',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Slides de Aula',
                        child: Text('Slides de Aula'),
                      ),
                      DropdownMenuItem(
                        value: 'Material Complementar',
                        child: Text('Material Complementar'),
                      ),
                      DropdownMenuItem(
                        value: 'Laboratórios & Códigos',
                        child: Text('Laboratórios & Códigos'),
                      ),
                      DropdownMenuItem(
                        value: 'Institucional',
                        child: Text('Institucional'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedCategory = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: Color(0xFF52525B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pickedFile == null
                          ? 'Nenhum arquivo selecionado (PDF, DOCX, PPTX, ZIP, MD até 25 MB)'
                          : '${pickedFile!.name} (${pickedFile!.sizeLabel})',
                      style: jakarta(
                        size: 12.5,
                        weight: pickedFile == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: InstColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CourseHubPillButton(
                    label: pickedFile == null ? 'Escolher Arquivo' : 'Trocar',
                    variant: CourseHubButtonVariant.secondary,
                    compact: true,
                    onPressed: () async {
                      final file = await PlatformFileHelper.pickFile();
                      if (file == null) return;
                      setModalState(() {
                        pickedFile = file;
                        if (titleCtrl.text.trim().isEmpty) {
                          titleCtrl.text = file.name;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CourseHubPillButton(
                  label: 'Cancelar',
                  variant: CourseHubButtonVariant.secondary,
                  onPressed: () => Navigator.of(modalCtx).pop(),
                ),
                const SizedBox(width: 8),
                CourseHubPillButton(
                  label: 'Publicar Material',
                  icon: Icons.upload_rounded,
                  isLoading: isUploading,
                  onPressed: isUploading
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty || pickedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Informe um título e selecione um arquivo válido.',
                                ),
                                backgroundColor: Color(0xFFB91C1C),
                              ),
                            );
                            return;
                          }
                          setModalState(() => isUploading = true);
                          await widget.controller.publishMaterial(
                            course.id,
                            title,
                            pickedFile,
                            unitAssociated: selectedUnit,
                            category: selectedCategory,
                          );
                          if (!modalCtx.mounted) return;
                          Navigator.of(modalCtx).pop();
                          final err = widget.controller.remoteError;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                err ??
                                    'Material "$title" publicado e visível no AVA dos alunos.',
                              ),
                              backgroundColor: err == null
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewForumTopicModal(DocenteCourse course) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    var category = 'Discussão Acadêmica';
    var isSending = false;

    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'FÓRUM DA TURMA • ${course.code}',
      title: 'Novo Tópico de Discussão',
      subtitle:
          'Abra um debate ou tópico de orientações visível a todos os estudantes.',
      maxWidth: 560,
      disposeOnClose: [titleCtrl, bodyCtrl],
      builder: (_) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              isExpanded: true,
              decoration: courseHubInputDecoration(labelText: 'Categoria'),
              items: const [
                DropdownMenuItem(
                  value: 'Discussão Acadêmica',
                  child: Text('Discussão Acadêmica'),
                ),
                DropdownMenuItem(
                  value: 'Dúvida de Conteúdo',
                  child: Text('Dúvida de Conteúdo'),
                ),
                DropdownMenuItem(
                  value: 'Projeto Integrador',
                  child: Text('Projeto Integrador'),
                ),
                DropdownMenuItem(
                  value: 'Orientação de Avaliações',
                  child: Text('Orientação de Avaliações'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setModalState(() => category = v);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Título do Tópico',
                hintText: 'Ex: Dúvidas sobre Heurísticas e Prototipação',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Conteúdo / Pergunta Orientadora',
                hintText:
                    'Descreva o contexto ou pergunta para engajar os alunos...',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CourseHubPillButton(
                  label: 'Cancelar',
                  variant: CourseHubButtonVariant.secondary,
                  onPressed: () => Navigator.of(modalCtx).pop(),
                ),
                const SizedBox(width: 8),
                CourseHubPillButton(
                  label: 'Publicar Tópico',
                  icon: Icons.send_rounded,
                  isLoading: isSending,
                  onPressed: isSending
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final body = bodyCtrl.text.trim();
                          if (title.length < 2 || body.length < 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Preencha título e mensagem do tópico.',
                                ),
                                backgroundColor: Color(0xFFB91C1C),
                              ),
                            );
                            return;
                          }
                          setModalState(() => isSending = true);
                          final ok = await widget.controller.createForumTopic(
                            title: title,
                            body: body,
                            category: category,
                          );
                          if (!modalCtx.mounted) return;
                          Navigator.of(modalCtx).pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Tópico publicado no fórum da turma.'
                                    : (widget.controller.remoteError ??
                                          'Erro ao criar tópico.'),
                              ),
                              backgroundColor: ok
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateSquadModal(DocenteCourse course) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final projectTitleCtrl = TextEditingController();
    final repoUrlCtrl = TextEditingController();
    var sprintStatus = 'Em andamento';
    final selectedMembers = <String>{};
    var isSaving = false;

    final availableNames = <String>{};
    for (final st in course.enrolledStudents) {
      final name = (st['name'] ?? '').toString().trim();
      if (name.isNotEmpty) availableNames.add(name);
    }
    for (final st in widget.controller.studentsForSelectedCourse) {
      if (st.name.trim().isNotEmpty) availableNames.add(st.name.trim());
    }
    final sortedNames = availableNames.toList()..sort();

    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'SQUADS INTEGRADORES • ${course.code}',
      title: 'Criar Equipe de Projeto',
      subtitle:
          'Equipes criadas aparecem na aba Colaborações dos alunos para envio de repositório e sprints.',
      maxWidth: 600,
      disposeOnClose: [nameCtrl, projectTitleCtrl, repoUrlCtrl],
      builder: (_) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    style: jakarta(size: 13, color: InstColors.ink),
                    decoration: courseHubInputDecoration(
                      labelText: 'Nome da Equipe / Squad',
                      hintText: 'Ex: Squad Alpha',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: sprintStatus,
                    isExpanded: true,
                    decoration: courseHubInputDecoration(
                      labelText: 'Status da Sprint',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Planejamento',
                        child: Text('Planejamento'),
                      ),
                      DropdownMenuItem(
                        value: 'Em andamento',
                        child: Text('Em andamento'),
                      ),
                      DropdownMenuItem(
                        value: 'Em revisão',
                        child: Text('Em revisão'),
                      ),
                      DropdownMenuItem(
                        value: 'Concluído',
                        child: Text('Concluído'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => sprintStatus = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: projectTitleCtrl,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Título do Projeto Integrador (obrigatório)',
                hintText: 'Ex: Redesign Acessível do Portal de Saúde',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: repoUrlCtrl,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'URL do Repositório (opcional)',
                hintText: 'https://github.com/agmrm-time/projeto',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecionar Integrantes Matriculados (${selectedMembers.length})',
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w700,
                color: InstColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (sortedNames.isEmpty)
              Text(
                'Nenhum discente listado na turma para vincular.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedNames.map((name) {
                      final selected = selectedMembers.contains(name);
                      return FilterChip(
                        label: Text(
                          name,
                          style: jakarta(
                            size: 12,
                            weight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? Colors.white : InstColors.ink,
                          ),
                        ),
                        selected: selected,
                        backgroundColor: Colors.white,
                        selectedColor: InstColors.ink,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? InstColors.ink
                              : const Color(0xFFE5E7EB),
                        ),
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              selectedMembers.add(name);
                            } else {
                              selectedMembers.remove(name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CourseHubPillButton(
                  label: 'Cancelar',
                  variant: CourseHubButtonVariant.secondary,
                  onPressed: () => Navigator.of(modalCtx).pop(),
                ),
                const SizedBox(width: 8),
                CourseHubPillButton(
                  label: 'Salvar Equipe',
                  icon: Icons.check_rounded,
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          final squadName = nameCtrl.text.trim();
                          final projectTitle = projectTitleCtrl.text.trim();
                          if (squadName.length < 2 || projectTitle.length < 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Informe o nome da equipe e o título do projeto (mínimo 2 caracteres).',
                                ),
                                backgroundColor: Color(0xFFB91C1C),
                              ),
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final existing = course.squads.map((sq) {
                            return <String, Object?>{
                              if (sq['id'] != null) 'id': sq['id'].toString(),
                              'name': (sq['name'] ?? 'Equipe').toString(),
                              'projectTitle': (sq['projectTitle'] ??
                                      sq['name'] ??
                                      'Projeto')
                                  .toString(),
                              if ((sq['repoUrl'] ?? '').toString().isNotEmpty)
                                'repoUrl': sq['repoUrl'].toString(),
                              if ((sq['sprintStatus'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                'sprintStatus': sq['sprintStatus'].toString(),
                              'members': ((sq['members'] as List?) ?? const [])
                                  .map((e) => e.toString())
                                  .toList(),
                            };
                          }).toList();

                          existing.add({
                            'id':
                                'squad-${DateTime.now().millisecondsSinceEpoch}',
                            'name': squadName,
                            'projectTitle': projectTitle,
                            if (repoUrlCtrl.text.trim().isNotEmpty)
                              'repoUrl': repoUrlCtrl.text.trim(),
                            'sprintStatus': sprintStatus,
                            'members': selectedMembers.toList(),
                          });

                          final ok = await widget.controller.saveSquads(
                            existing,
                          );
                          if (!modalCtx.mounted) return;
                          Navigator.of(modalCtx).pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Equipe "$squadName" salva e publicada no AVA dos alunos.'
                                    : (widget.controller.remoteError ??
                                          'Erro ao salvar equipe.'),
                              ),
                              backgroundColor: ok
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(DocenteCourse course) {
    switch (_activeTabIndex) {
      case 0:
        return CourseHubOverviewTab(
          course: course,
          controller: widget.controller,
          onNewNotice: () => _openQuickNoticeModal(course),
          onNewAssignment: () => _openNewAssignmentModal(course),
          onNewContent: () => _openNewContentModal(course),
          onOpenLive: () => _openLiveStream(course),
          onSelectTab: (idx) => setState(() => _activeTabIndex = idx),
          onEvaluateSubmission: _openRubricModal,
        );
      case 1:
        return CourseHubModulesTab(
          course: course,
          controller: widget.controller,
          onAddContent: () => _openNewContentModal(course),
        );
      case 2:
        return CourseHubAssignmentsTab(
          course: course,
          controller: widget.controller,
          onNewAssignment: () => _openNewAssignmentModal(course),
          onOpenRubric: _openRubricModal,
        );
      case 3:
        return CourseHubForumTab(
          course: course,
          controller: widget.controller,
          onNewTopic: () => _openNewForumTopicModal(course),
        );
      case 4:
        return CourseHubAttendanceTab(
          course: course,
          controller: widget.controller,
        );
      case 5:
        return CourseHubGradebookTab(
          course: course,
          controller: widget.controller,
          gradebook: widget.controller.gradebook,
        );
      case 6:
        return CourseHubStudentsTab(
          course: course,
          controller: widget.controller,
          gradebook: widget.controller.gradebook,
          session: widget.controller.currentSession,
        );
      case 7:
        return CourseHubSyllabusTab(
          course: course,
          controller: widget.controller,
        );
      case 8:
      default:
        return CourseHubSquadsTab(
          course: course,
          controller: widget.controller,
          onAddSquad: () => _openCreateSquadModal(course),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final course = _currentCourse;
        final gradebook = widget.controller.gradebook;
        final graded = gradebook
            .where((g) => g.status != AcademicStatus.semNotas)
            .toList();
        final avgAttendance = gradebook.isNotEmpty
            ? gradebook.map((g) => g.attendanceRate).reduce((a, b) => a + b) /
                  gradebook.length
            : 100.0;
        final avgGrade = graded.isNotEmpty
            ? graded.map((g) => g.finalAverage).reduce((a, b) => a + b) /
                  graded.length
            : 0.0;

        final pendingGradingCount = widget.controller.assignmentsForSelectedCourse
            .expand((a) => a.submissions)
            .where((s) => s.status == SubmissionStatus.aguardandoCorrecao)
            .length;
        final openTopicsCount = course.forumTopics.where((t) {
          final replies = t['replies'];
          return t['isResolved'] != true &&
              !(replies is List && replies.isNotEmpty);
        }).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;
            final showSubSidebar = constraints.maxWidth >= 880;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.white,
              drawer: isDesktop
                  ? null
                  : Drawer(
                      width: 280,
                      backgroundColor: Colors.white,
                      child: DocenteSidebar(
                        controller: widget.controller,
                        onTabSelected: (_) {
                          Navigator.of(context).pop();
                          Navigator.of(context).maybePop();
                        },
                        onLogout: () {
                          Navigator.of(context).pop();
                          _handleLogout();
                        },
                      ),
                    ),
              body: Stack(
                children: [
                  Row(
                    children: [
                      if (isDesktop)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: widget.controller.isSidebarCollapsed
                              ? 76.0
                              : 280.0,
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DocenteHeader(
                              controller: widget.controller,
                              titleOverride: 'AVA • ${course.code}',
                              onOpenDrawer: isDesktop
                                  ? null
                                  : () =>
                                        _scaffoldKey.currentState?.openDrawer(),
                              onNavigateToCommunications: () {
                                widget.controller.navigateToTab(
                                  DocenteNavTab.comunicados,
                                );
                                Navigator.of(context).maybePop();
                              },
                            ),
                            CourseHubHeader(
                              course: course,
                              courses: widget.controller.courses,
                              onBack: () => Navigator.of(context).pop(),
                              onSwitchCourse: _switchCourse,
                              onNewNotice: () => _openQuickNoticeModal(course),
                              onNewContent: () => _openNewContentModal(course),
                              onNewAssignment: () =>
                                  _openNewAssignmentModal(course),
                              onLiveStream: () => _openLiveStream(course),
                            ),
                            if (!showSubSidebar)
                              CourseHubCompactTabBar(
                                activeIndex: _activeTabIndex,
                                onSelectTab: (idx) =>
                                    setState(() => _activeTabIndex = idx),
                              ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showSubSidebar)
                                    CourseHubSubSidebar(
                                      activeIndex: _activeTabIndex,
                                      onSelectTab: (idx) => setState(
                                        () => _activeTabIndex = idx,
                                      ),
                                      attendancePercentage: avgAttendance,
                                      averageGrade: avgGrade,
                                      hasAnyGrades: graded.isNotEmpty,
                                      pendingSubmissionsCount:
                                          pendingGradingCount,
                                      openTopicsCount: openTopicsCount,
                                    ),
                                  Expanded(
                                    child: ColoredBox(
                                      color: Colors.white,
                                      child: LayoutBuilder(
                                        builder: (context, contentConstraints) {
                                          return SingleChildScrollView(
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minHeight: contentConstraints
                                                    .maxHeight,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isDesktop
                                                              ? 32
                                                              : 16,
                                                          vertical: isDesktop
                                                              ? 26
                                                              : 18,
                                                        ),
                                                    child: _buildActiveTab(
                                                      course,
                                                    ),
                                                  ),
                                                  const DocenteFooter(),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isDesktop)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: DocenteSidebar(
                        controller: widget.controller,
                        onTabSelected: (_) => Navigator.of(context).maybePop(),
                        onLogout: _handleLogout,
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
}
