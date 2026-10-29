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
      'badge': '8',
    },
    {
      'label': 'Tarefas & Submissões',
      'icon': Icons.description_outlined,
      'badge': '6 pend.',
      'badgeColor': Color(0xFFFEF3C7),
      'badgeTextColor': Color(0xFFD97706),
    },
    {
      'label': 'Fórum da Turma',
      'icon': Icons.chat_bubble_outline,
      'badge': '2',
    },
    {
      'label': 'Alunos Matriculados',
      'icon': Icons.groups_outlined,
      'badge': '34',
    },
    {
      'label': 'Plano de Ensino',
      'icon': Icons.menu_book_outlined,
      'badge': null,
    },
    {
      'label': 'Equipes de Projeto',
      'icon': Icons.emoji_events_outlined,
      'badge': '3 squads',
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Disparar Aviso à Turma',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Aviso',
                  hintText: 'Ex: Orientações para a entrega da Sprint 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mensagem aos 34 Alunos',
                  hintText:
                      'Digite o comunicado que será enviado ao e-mail e app...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final message = messageController.text.trim();
              if (title.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha o título e a mensagem do aviso.'),
                  ),
                );
                return;
              }
              final published = widget.controller.publishNotice(
                targetCourse: widget.course.title,
                targetAudience: 'Todos os discentes da turma',
                classification: NoticeClassification.informativo,
                title: title,
                message: message,
              );
              if (!published) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Não foi possível publicar o aviso para esta turma.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
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
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return const CourseHubGradebookTab();
      case 1:
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) =>
              CourseHubAttendanceTab(controller: widget.controller),
        );
      case 2:
        return CourseHubModulesTab(
          onNewUnit: null,
          onUploadSlides: null,
          onPublishAssignment: () {
            setState(() => _activeTabIndex = 3);
          },
          onQuickNotice: _showQuickNoticeDialog,
          onReviewSyllabus: _openSyllabusModal,
          onNavigateToAssignments: () {
            setState(() => _activeTabIndex = 3);
          },
        );
      case 3:
        return const CourseHubAssignmentsTab();
      case 4:
        return const CourseHubForumTab();
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
        return const CourseHubSquadsTab();
      default:
        return const CourseHubGradebookTab();
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
