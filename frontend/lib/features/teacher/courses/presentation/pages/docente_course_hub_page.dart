// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_assignments_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_attendance_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_forum_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_gradebook_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_header.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_modules_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_squads_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_students_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_sub_sidebar.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/hub/course_hub_syllabus_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/widgets/syllabus_materials_modal.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_sidebar.dart';

/// Sala de Aula Virtual AVA (Cockpit de Gestão da Disciplina) na visão do Docente.
/// Modularizada com Clean Architecture e subcomponentes desacoplados em `widgets/hub/`.
class DocenteCourseHubPage extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;

  const DocenteCourseHubPage({
    super.key,
    required this.course,
    required this.controller,
  });

  @override
  State<DocenteCourseHubPage> createState() => _DocenteCourseHubPageState();
}

class _DocenteCourseHubPageState extends State<DocenteCourseHubPage> {
  int _activeTabIndex = 0; // 0 = Livro de Notas, 1 = Diário, 2 = Módulos, etc.

  static const List<Map<String, dynamic>> _sidebarNavItems = [
    {
      'label': 'Livro de Notas (Gradebook)',
      'icon': Icons.star_border_rounded,
      'badge': null,
    },
    {
      'label': 'Diário de Presença',
      'icon': Icons.calendar_today_outlined,
      'badge': null,
    },
    {
      'label': 'Módulos & Conteúdos',
      'icon': Icons.layers_outlined,
      'badge': null,
    },
    {
      'label': 'Tarefas & Submissões',
      'icon': Icons.description_outlined,
      'badge': null,
    },
    {
      'label': 'Fórum da Turma',
      'icon': Icons.chat_bubble_outline,
      'badge': null,
    },
    {
      'label': 'Alunos Matriculados',
      'icon': Icons.groups_outlined,
      'badge': null,
    },
    {
      'label': 'Plano de Ensino',
      'icon': Icons.menu_book_outlined,
      'badge': null,
    },
    {
      'label': 'Equipes de Projeto',
      'icon': Icons.emoji_events_outlined,
      'badge': null,
    },
  ];

  void _openSyllabusModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => SyllabusMaterialsModal(
        course: widget.course,
        controller: widget.controller,
      ),
    );
  }

  void _showQuickNoticeDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disparar Aviso ? Turma'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'T?tulo do Aviso'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mensagem aos estudantes',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();
              if (title.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha o t?tulo e a mensagem.'),
                  ),
                );
                return;
              }
              final published = await widget.controller.publishNotice(
                targetCourse: widget.course.title,
                targetAudience: 'Todos os discentes da turma',
                classification: NoticeClassification.informativo,
                title: title,
                message: message,
              );
              if (!mounted || !dialogContext.mounted) return;
              if (!published) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'N?o foi poss?vel publicar o aviso para esta turma.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Aviso publicado para os ${widget.course.enrolledCount} discentes da disciplina.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
            ),
            child: const Text(
              'Disparar Aviso',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      messageController.dispose();
    });
  }

  Future<void> _showForumTopicDialog() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo t?pico do f?rum'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'T?tulo'),
              ),
              TextField(
                controller: body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mensagem'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty || body.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, [
                title.text.trim(),
                body.text.trim(),
              ]);
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    title.dispose();
    body.dispose();
    if (values == null || !mounted) return;
    final created = await widget.controller.createForumTopic(
      title: values[0],
      body: values[1],
    );
    if (mounted && !created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.remoteError ?? 'N?o foi poss?vel criar o t?pico.',
          ),
        ),
      );
    }
  }

  Future<void> _createSquadDialog() async {
    final name = TextEditingController();
    final members = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Criar equipe'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome da equipe'),
              ),
              TextField(
                controller: members,
                decoration: const InputDecoration(
                  labelText: 'Identidades dos membros (separadas por v?rgula)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, [
                name.text.trim(),
                members.text.trim(),
              ]);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    name.dispose();
    members.dispose();
    if (values == null || !mounted) return;
    await widget.controller.saveSquads([
      ...widget.controller.selectedCourse.squads,
      {
        'name': values[0],
        'members': values[1]
            .split(',')
            .map((member) => member.trim())
            .where((member) => member.isNotEmpty)
            .toList(),
        'status': 'Ativa',
      },
    ]);
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) =>
              CourseHubGradebookTab(controller: widget.controller),
        );
      case 1:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) =>
              CourseHubAttendanceTab(controller: widget.controller),
        );
      case 2:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => CourseHubModulesTab(
            controller: widget.controller,
            onNewUnit: _openSyllabusModal,
            onUploadSlides: _openSyllabusModal,
            onPublishAssignment: () => setState(() => _activeTabIndex = 3),
            onQuickNotice: _showQuickNoticeDialog,
            onReviewSyllabus: _openSyllabusModal,
            onNavigateToAssignments: () => setState(() => _activeTabIndex = 3),
          ),
        );
      case 3:
        return const CourseHubAssignmentsTab();
      case 4:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => CourseHubForumTab(
            controller: widget.controller,
            onNewTopic: _showForumTopicDialog,
          ),
        );
      case 5:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => CourseHubStudentsTab(
            course: widget.course,
            students: widget.controller.studentsForSelectedCourse,
            grades: widget.controller.gradebook,
          ),
        );
      case 6:
        return CourseHubSyllabusTab(onEditSyllabus: _openSyllabusModal);
      case 7:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => CourseHubSquadsTab(
            controller: widget.controller,
            onNewSquad: _createSquadDialog,
          ),
        );
      default:
        return CourseHubGradebookTab(controller: widget.controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1050;

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFC),
          body: Row(
            children: [
              // 1. Barra Lateral Institucional do Portal Docente
              if (isDesktop)
                DocenteSidebar(
                  controller: widget.controller,
                  onLogout: () => Navigator.of(context).pop(),
                ),

              // 2. Cockpit Central da Disciplina
              Expanded(
                child: Column(
                  children: [
                    CourseHubHeader(
                      course: widget.course,
                      onBack: () => Navigator.of(context).pop(),
                      onQuickNotice: _showQuickNoticeDialog,
                      onNewContent: null,
                      onLiveClass: () {
                        Navigator.of(context).pushNamed(
                          '/video-call',
                          arguments: {'roomCode': widget.course.code},
                        );
                      },
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sub-Sidebar Vertical da Disciplina
                          CourseHubSubSidebar(
                            activeTabIndex: _activeTabIndex,
                            onTabSelected: (index) =>
                                setState(() => _activeTabIndex = index),
                            items: _sidebarNavItems,
                          ),

                          // Área Central Dinâmica com Conteúdo e Rodapé Padronizado
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 28,
                                            vertical: 24,
                                          ),
                                          child: _buildActiveTabContent(),
                                        ),
                                        const DocenteFooter(),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
        );
      },
    );
  }
}
