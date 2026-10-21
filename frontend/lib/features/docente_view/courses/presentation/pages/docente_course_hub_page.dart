// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/courses/presentation/widgets/syllabus_materials_modal.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/docente_view/shell/presentation/widgets/docente_footer.dart';
import 'package:pi_iv_time3/features/docente_view/shell/presentation/widgets/docente_sidebar.dart';

/// Sala de Aula Virtual AVA (Cockpit de Gestão da Disciplina) na visão do Docente.
/// Estruturada com Sub-Sidebar lateral de navegação e gestão completa de acessos do professor:
/// Livro de Notas (Gradebook), Diário de Presença, Módulos & Conteúdos, Tarefas & Submissões,
/// Fórum da Turma, Alunos Matriculados, Plano de Ensino e Equipes de Projeto.
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

  final List<Map<String, dynamic>> _sidebarNavItems = [
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
        title: const Text('Disparar Aviso à Turma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título do Aviso', hintText: 'Ex: Orientações para a entrega da Sprint 1'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mensagem aos 34 Alunos', hintText: 'Digite o comunicado que será enviado ao e-mail e app...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aviso disparado com sucesso aos 34 discentes da disciplina!'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B)),
            child: const Text('Disparar Aviso', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                    _buildTopHeader(),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sub-Sidebar Vertical da Disciplina (Padrão AVA / Print)
                          _buildClassSubSidebar(),

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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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

  // ==========================================
  // CABEÇALHO SUPERIOR DA DISCIPLINA COM ACESSOS DE COMANDO
  // ==========================================
  Widget _buildTopHeader() {
    final courseCode = widget.course.code.isNotEmpty ? widget.course.code : '218131 - APS-II';
    final courseTitle = widget.course.title.isNotEmpty ? widget.course.title : 'Análise e Projeto de Sistemas II';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb de navegação
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back, size: 13, color: Color(0xFF71717A)),
                      SizedBox(width: 4),
                      Text(
                        'Minhas Turmas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text('  >  ', style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA))),
              Text(courseCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A))),
            ],
          ),
          const SizedBox(height: 8),

          // Título e Botões de Comando e Acessos Rápidos do Professor
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Turma $courseCode • 34 Alunos Matriculados • Turno Noturno • Semestre 2026/2 • Sala Lab 04',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showQuickNoticeDialog,
                    icon: const Icon(Icons.campaign_outlined, size: 14, color: Color(0xFF09090B)),
                    label: const Text('Aviso à Turma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Abrindo assistente de criação de novo conteúdo didático...'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFF09090B)),
                    label: const Text('Novo Conteúdo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/video-call'),
                    icon: const Icon(Icons.videocam_rounded, size: 16, color: Colors.white),
                    label: const Text('Transmissão ao Vivo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SUB-SIDEBAR VERTICAL DA DISCIPLINA NO AVA (Acessos do Docente)
  // ==========================================
  Widget _buildClassSubSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      child: Column(
        children: [
          // Seção Superior: Menu de Abas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              itemCount: _sidebarNavItems.length,
              itemBuilder: (context, index) {
                final item = _sidebarNavItems[index];
                final isSelected = index == _activeTabIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => setState(() => _activeTabIndex = index),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF71717A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF27272A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item['badge'] != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white24
                                    : (item['badgeColor'] as Color? ?? const Color(0xFFF4F4F5)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item['badge'] as String,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (item['badgeTextColor'] as Color? ?? const Color(0xFF71717A)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Widget Inferior: Card Rápido de Saúde da Turma
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'PAINEL DA TURMA',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.4),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.insights, size: 13, color: Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(child: Text('Assiduidade:', style: TextStyle(fontSize: 11, color: Color(0xFF71717A)), overflow: TextOverflow.ellipsis)),
                    Text('94.8%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Expanded(child: Text('Média:', style: TextStyle(fontSize: 11, color: Color(0xFF71717A)), overflow: TextOverflow.ellipsis)),
                    Text('7.8', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Expanded(child: Text('Envios:', style: TextStyle(fontSize: 11, color: Color(0xFF71717A)), overflow: TextOverflow.ellipsis)),
                    Text('6 pend.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RENDERIZADOR DO CONTEÚDO PRINCIPAL
  // ==========================================
  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildGradebookTab();
      case 1:
        return _buildAttendanceTab();
      case 2:
        return _buildModulesTab();
      case 3:
        return _buildAssignmentsTab();
      case 4:
        return _buildForumTab();
      case 5:
        return _buildStudentsTab();
      case 6:
        return _buildSyllabusTab();
      case 7:
        return _buildProjectSquadsTab();
      default:
        return _buildGradebookTab();
    }
  }

  // ==========================================
  // 1. LIVRO DE NOTAS (GRADEBOOK)
  // ==========================================
  Widget _buildGradebookTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs do Livro de Notas
        LayoutBuilder(
          builder: (context, box) {
            final isSmall = box.maxWidth < 720;
            final t1 = _buildMetricTile(
              title: 'MÉDIA GERAL DA TURMA',
              value: '7.8',
              subtitle: 'Meta Institucional: 7.0',
              indicatorColor: const Color(0xFF16A34A),
            );
            final t2 = _buildMetricTile(
              title: 'TAXA DE APROVAÇÃO',
              value: '91.2%',
              subtitle: '31 de 34 com média >= 6.0',
              indicatorColor: const Color(0xFF16A34A),
            );
            final t3 = _buildMetricTile(
              title: 'PENDÊNCIAS DE LANÇAMENTO',
              value: '02 discentes',
              subtitle: 'Segunda chamada aguardando',
              indicatorColor: const Color(0xFFD97706),
            );
            final t4 = _buildMetricTile(
              title: 'REGIME DE AVALIAÇÃO',
              value: 'PPC Oficial',
              subtitle: 'N1 (40%) + N2 (60%)',
              indicatorColor: const Color(0xFF2563EB),
            );

            if (isSmall) {
              return Column(
                children: [
                  Row(children: [Expanded(child: t1), const SizedBox(width: 10), Expanded(child: t2)]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: t3), const SizedBox(width: 10), Expanded(child: t4)]),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: t1),
                const SizedBox(width: 12),
                Expanded(child: t2),
                const SizedBox(width: 12),
                Expanded(child: t3),
                const SizedBox(width: 12),
                Expanded(child: t4),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Barra de Ações do Gradebook
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filtrar discente por nome ou R.A...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF71717A)),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exportando Gradebook oficial em formato XLSX/CSV...')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 14, color: Color(0xFF09090B)),
                    label: const Text('Exportar Planilha Oficial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notas homologadas e sincronizadas com a Secretaria Acadêmica!')),
                      );
                    },
                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                    label: const Text('Salvar & Homologar Notas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabela do Gradebook
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 780),
              child: SizedBox(
                width: 820,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFBFBFC),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(
                        children: const [
                          Expanded(flex: 30, child: Text('DISCENTE / R.A.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)))),
                          Expanded(flex: 12, child: Text('P1 (PROVA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                          Expanded(flex: 12, child: Text('T1 (PROJETO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                          Expanded(flex: 14, child: Text('MÉDIA N1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                          Expanded(flex: 12, child: Text('P2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                          Expanded(flex: 12, child: Text('T2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                          Expanded(flex: 14, child: Text('MÉDIA FINAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                          Expanded(flex: 16, child: Text('SITUAÇÃO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),

                    _buildGradeRow('Mariana Rios Costa', '2024.1.00901', '9.5', '9.0', '9.3', '-', '-', '9.3', 'Aprovado', const Color(0xFF16A34A)),
                    _buildGradeRow('Gabriel Soares de Oliveira', '2024.1.00892', '8.0', '8.5', '8.2', '-', '-', '8.2', 'Aprovado', const Color(0xFF16A34A)),
                    _buildGradeRow('Rodrigo Antunes Nogueira', '2024.1.00938', '2ª Cham.', '7.0', 'Pend.', '-', '-', 'Pend.', 'Pendente', const Color(0xFFD97706)),
                    _buildGradeRow('Lucas Mendes Santos', '2024.1.00915', '7.0', '7.5', '7.2', '-', '-', '7.2', 'Aprovado', const Color(0xFF16A34A)),
                    _buildGradeRow('Camila Duarte Fagundes', '2024.1.00902', '8.5', '8.0', '8.3', '-', '-', '8.3', 'Aprovado', const Color(0xFF16A34A)),
                    _buildGradeRow('Vinicius Ferraz Toledo', '2024.1.00944', '5.0', '6.0', '5.4', '-', '-', '5.4', 'Em Atenção', const Color(0xFFDC2626)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeRow(
    String studentName,
    String ra,
    String p1,
    String t1,
    String n1,
    String p2,
    String t2,
    String finalGrade,
    String status,
    Color statusColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    Text('RA: $ra', style: const TextStyle(fontSize: 10, color: Color(0xFF71717A))),
                  ],
                ),
              ),
              Expanded(flex: 12, child: Text(p1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(flex: 12, child: Text(t1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(flex: 14, child: Text(n1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B)), textAlign: TextAlign.center)),
              Expanded(flex: 12, child: Text(p2, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
              Expanded(flex: 12, child: Text(t2, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)), textAlign: TextAlign.center)),
              Expanded(flex: 14, child: Text(finalGrade, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B)), textAlign: TextAlign.center)),
              Expanded(
                flex: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
      ],
    );
  }

  // ==========================================
  // 2. DIÁRIO DE PRESENÇA (CHAMADA ELETRÔNICA)
  // ==========================================
  Widget _buildAttendanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Diário de Presença & Frequência Eletrônica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                SizedBox(height: 4),
                Text('Controle diário de assiduidade e lançamento regimental de faltas.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
              ],
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Hoje: 20/09/2026 (Aula 14)', style: TextStyle(fontSize: 12, color: Color(0xFF09090B))),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Presença marcada para todos os 34 discentes da aula de hoje!')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                  label: const Text('Marcar Todos Presentes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Column(
            children: [
              _buildAttendanceItem('Mariana Rios Costa', '2024.1.00901', 0, 100),
              const Divider(height: 20, color: Color(0xFFF4F4F5)),
              _buildAttendanceItem('Gabriel Soares de Oliveira', '2024.1.00892', 2, 94.4),
              const Divider(height: 20, color: Color(0xFFF4F4F5)),
              _buildAttendanceItem('Rodrigo Antunes Nogueira', '2024.1.00938', 1, 97.2),
              const Divider(height: 20, color: Color(0xFFF4F4F5)),
              _buildAttendanceItem('Lucas Mendes Santos', '2024.1.00915', 3, 91.6),
              const Divider(height: 20, color: Color(0xFFF4F4F5)),
              _buildAttendanceItem('Camila Duarte Fagundes', '2024.1.00902', 2, 94.4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(String name, String ra, int absences, double rate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
            Text('RA: $ra • $absences faltas acumuladas ($rate% de presença)', style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCFCE7),
                foregroundColor: const Color(0xFF16A34A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Presente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF71717A),
                side: const BorderSide(color: Color(0xFFE4E4E7)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Falta', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 3. MÓDULOS & CONTEÚDOS (DOCENTE SUPERPOWERS)
  // ==========================================
  Widget _buildModulesTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna Principal de Unidades Didáticas
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Módulos & Conteúdos de Aprendizagem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Unidades ativas e materiais didáticos disponibilizados para a turma.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Criando nova unidade didática de ensino...')),
                      );
                    },
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text('Nova Unidade', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Unidade 1
              _buildDocenteUnitCard(
                tag: 'UNIDADE 1 • SEMANAS 1 A 4 • 20 HORAS LETIVAS',
                title: 'Unidade 1: Engenharia de Requisitos & Processos Ágeis de Software',
                items: [
                  'Plano de Ensino & Contrato Pedagógico da Disciplina (Pdf • 420 KB)',
                  'Slides da Aula 01: Processo Unificado e Engenharia de Software Moderna (Pdf • 3.8 MB)',
                  'Gravação da Aula Síncrona: Elicitação de Requisitos e Casos de Uso (Vídeo • 1h 35min)',
                  'Exercício 01: Mapeamento de Requisitos e Especificação de Casos de Uso (Tarefa • Prazo 05 Set)',
                ],
              ),
              const SizedBox(height: 20),

              // Unidade 2
              _buildDocenteUnitCard(
                tag: 'UNIDADE 2 • SEMANAS 5 A 9 • 24 HORAS LETIVAS • EM ANDAMENTO',
                title: 'Unidade 2: Modelagem Orientada a Objetos com Notação UML 2.5',
                items: [
                  'Slides da Aula 03: Diagrama de Classes, Multiplicidades e Visibilidade (Pdf • 4.2 MB)',
                  'Template Oficial de Diagramação (.drawio e .uml) (Arquivo • 180 KB)',
                  'Slides da Aula 04: Diagrama de Sequência e Interações Temporais (Pdf • 2.9 MB)',
                  'Entrega da Sprint 1: Diagrama de Classes e Sequência do AVA (Tarefa • Prazo Hoje)',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Coluna Lateral: Gestão Pedagógica Docente
        SizedBox(
          width: 310,
          child: Column(
            children: [
              // Card 1: Controle Docente da Turma
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CONTROLE DA TURMA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B), letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Em Andamento', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMetaRow('Carga Horária:', '80h (4 créditos)'),
                    const SizedBox(height: 8),
                    _buildMetaRow('Cumprimento:', '54h concluídas (67.5%)'),
                    const SizedBox(height: 8),
                    _buildMetaRow('Regime Semestral:', '100 Dias Letivos (Semana 10)'),
                    const SizedBox(height: 8),
                    _buildMetaRow('Pauta / Fechamento:', 'Diário Aberto para Lançamentos'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Ações Rápidas de Gestão Pedagógica
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AÇÕES DOCENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    _buildActionDocenteButton(Icons.upload_file, 'Upload de Slides ou Apostila'),
                    const SizedBox(height: 8),
                    _buildActionDocenteButton(Icons.add_task, 'Publicar Nova Tarefa'),
                    const SizedBox(height: 8),
                    _buildActionDocenteButton(Icons.announcement_outlined, 'Disparar Comunicado à Turma', onTap: _showQuickNoticeDialog),
                    const SizedBox(height: 8),
                    _buildActionDocenteButton(Icons.menu_book, 'Revisar Ementa / PPC', onTap: _openSyllabusModal),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: Correções Pendentes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('CORREÇÕES PENDENTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B), letterSpacing: 0.5)),
                        Text('6 envios', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Entrega da Sprint 1: 28 submetidos de 34 alunos.', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => _activeTabIndex = 3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        minimumSize: const Size(double.infinity, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: const Text('Corrigir Submissões', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocenteUnitCard({
    required String tag,
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 12),
                  label: const Text('Adicionar Item', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
          ...items.map((item) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.drag_indicator, size: 16, color: Color(0xFFA1A1AA)),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 10),
                          Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF09090B))),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF71717A)),
                            onPressed: () {},
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF71717A)),
                            onPressed: () {},
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionDocenteButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Executando ação do docente: $label')),
            );
          },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF09090B)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. TAREFAS & SUBMISSÕES
  // ==========================================
  Widget _buildAssignmentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tarefas, Trabalhos & Submissões', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                SizedBox(height: 4),
                Text('Acompanhe os envios dos estudantes, atribua notas e faça apontamentos de rubricas.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Nova Atividade', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildAssignmentCardItem(
          title: 'Entrega da Sprint 1: Diagrama de Classes e Sequência do AVA',
          deadline: 'Hoje às 23:59',
          submitted: 28,
          total: 34,
          graded: 18,
          isUrgent: true,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCardItem(
          title: 'Fórum Temático: Arquitetura de Software e Padrões de Projeto',
          deadline: '21/09 às 18:00',
          submitted: 34,
          total: 34,
          graded: 34,
          isUrgent: false,
        ),
        const SizedBox(height: 12),
        _buildAssignmentCardItem(
          title: 'Exercício 01: Mapeamento de Requisitos e Casos de Uso',
          deadline: '05/09 às 23:59',
          submitted: 32,
          total: 34,
          graded: 32,
          isUrgent: false,
        ),
      ],
    );
  }

  Widget _buildAssignmentCardItem({
    required String title,
    required String deadline,
    required int submitted,
    required int total,
    required int graded,
    required bool isUrgent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Correção Pendente', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('Prazo: $deadline • $submitted de $total alunos entregaram • $graded corrigidos', style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Abrindo submissões para correção: $title')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: const Text('Avaliar Submissões', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. FÓRUM DA TURMA
  // ==========================================
  Widget _buildForumTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Fórum de Discussões & Dúvidas Técnicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                SizedBox(height: 4),
                Text('Espaço colaborativo para tirar dúvidas e promover debates síncronos e assíncronos.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_comment_outlined, size: 14, color: Colors.white),
              label: const Text('Novo Tópico', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildForumThreadCard('Dúvidas sobre o Diagrama de Sequência (Sprint 1)', 'Mariana Rios Costa', '14 respostas • Última atividade há 2h'),
        const SizedBox(height: 12),
        _buildForumThreadCard('Sugestões de ferramentas CASE open-source', 'Profa. Dra. Helena Bittencourt', '8 respostas • Fixado pelo professor'),
        const SizedBox(height: 12),
        _buildForumThreadCard('Orientações para a Avaliação Substitutiva N1', 'Carlos Eduardo Mendes (Secretaria)', '3 respostas • Comunicado Oficial'),
      ],
    );
  }

  Widget _buildForumThreadCard(String title, String author, String details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
              const SizedBox(height: 4),
              Text('Autor: $author • $details', style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
            ],
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Participar', style: TextStyle(fontSize: 11, color: Color(0xFF09090B))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. ALUNOS MATRICULADOS
  // ==========================================
  Widget _buildStudentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Discentes Matriculados na Turma (34 alunos)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
            Text('Semestre 2026/2 • Turno Noturno', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Column(
            children: [
              _buildStudentRow('Mariana Rios Costa', '2024.1.00901', 'mariana.costa@aluno.universidade.edu.br', '100% Presença', 'Média 9.3'),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow('Gabriel Soares de Oliveira', '2024.1.00892', 'gabriel.oliveira@aluno.universidade.edu.br', '94.4% Presença', 'Média 8.2'),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow('Rodrigo Antunes Nogueira', '2024.1.00938', 'rodrigo.nogueira@aluno.universidade.edu.br', '97.2% Presença', 'Pendente 2ª Cham.'),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow('Lucas Mendes Santos', '2024.1.00915', 'lucas.santos@aluno.universidade.edu.br', '91.6% Presença', 'Média 7.2'),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow('Camila Duarte Fagundes', '2024.1.00902', 'camila.fagundes@aluno.universidade.edu.br', '94.4% Presença', 'Média 8.3'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(String name, String ra, String email, String attendance, String grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF4F4F5),
                child: Text(name.substring(0, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                  Text('RA: $ra • $email', style: const TextStyle(fontSize: 10, color: Color(0xFF71717A))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(attendance, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
              const SizedBox(width: 14),
              Text(grade, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                child: const Text('Prontuário', style: TextStyle(fontSize: 10, color: Color(0xFF09090B))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. PLANO DE ENSINO
  // ==========================================
  Widget _buildSyllabusTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Plano de Ensino & Ementa Homologada (CONSEPE)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
              ElevatedButton.icon(
                onPressed: _openSyllabusModal,
                icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                label: const Text('Editar / Gerenciar Ementa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('1. EMENTA DA DISCIPLINA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
          const SizedBox(height: 6),
          const Text(
            'Conceitos de análise e projeto orientado a objetos. Notação UML 2.5: diagramas estruturais e comportamentais. Processo Unificado e metodologias ágeis (Scrum, Kanban). Padrões de projeto GoF (Criacionais, Estruturais e Comportamentais). Arquitetura de software moderna e Clean Architecture.',
            style: TextStyle(fontSize: 12, color: Color(0xFF52525B), height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text('2. CRITÉRIOS DE AVALIAÇÃO (PPC OFICIAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
          const SizedBox(height: 6),
          const Text(
            'Média Semestral = (N1 × 0.40) + (N2 × 0.60). Onde N1 é composto por Prova Teórica P1 (70%) e Projeto Prático T1 (30%). Exame Final obrigatório para alunos com média entre 4.0 e 5.9.',
            style: TextStyle(fontSize: 12, color: Color(0xFF52525B), height: 1.4),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 8. EQUIPES DE PROJETO
  // ==========================================
  Widget _buildProjectSquadsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Equipes de Projeto & Squads Integradores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                  SizedBox(height: 4),
                  Text('Organização dos discentes em squads de desenvolvimento prático e entregas da Sprint.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.group_add, size: 14, color: Colors.white),
              label: const Text('Nova Equipe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSquadCard('Squad Alpha: Sistema de Gestão Hospitalar', 'Mariana Rios Costa (Líder), Gabriel Soares, Lucas Mendes, Camila Duarte', 'Sprint 1 Entregue (Nota 9.5)'),
        const SizedBox(height: 12),
        _buildSquadCard('Squad Beta: Plataforma de E-commerce Sustentável', 'Rodrigo Antunes (Líder), Vinicius Ferraz, Ana Paula Silva, Felipe Ramos', 'Sprint 1 em Correção'),
        const SizedBox(height: 12),
        _buildSquadCard('Squad Gamma: App de Logística e Rastreamento IoT', 'Beatriz Lima (Líder), Carlos Eduardo, Thiago Rocha, Larissa Santos', 'Sprint 1 Entregue (Nota 8.8)'),
      ],
    );
  }

  Widget _buildSquadCard(String squadName, String members, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(squadName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
                const SizedBox(height: 4),
                Text('Membros: $members', style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color indicatorColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09090B))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF71717A)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF09090B)),
          ),
        ),
      ],
    );
  }
}
