// Desenvolvido por Guilherme Henrique Moreira e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin_view/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_footer.dart';

/// Tela de Cursos & Matrizes Curriculares (PPC) da Visão do Administrador.
/// Exibe a estrutura pedagógica institucional, carga horária regimental,
/// critérios de aprovação e o modal de detalhamento do ementário por período.
class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = AdminMockData.courses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        _buildHeader(isDesktop),
                        const SizedBox(height: 28),

                        // Grade de Cursos 2x2
                        if (isDesktop && courses.length >= 4) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildCourseCard(context, courses[0])),
                              const SizedBox(width: 24),
                              Expanded(child: _buildCourseCard(context, courses[1])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildCourseCard(context, courses[2])),
                              const SizedBox(width: 24),
                              Expanded(child: _buildCourseCard(context, courses[3])),
                            ],
                          ),
                        ] else ...[
                          for (int i = 0; i < courses.length; i++) ...[
                            if (i > 0) const SizedBox(height: 20),
                            _buildCourseCard(context, courses[i]),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cursos & Matrizes Curriculares (PPC)',
          style: jakarta(
            size: isDesktop ? 28 : 24,
            weight: FontWeight.w700,
            color: const Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Estrutura pedagógica institucional, carga horária regimental e parametrização das fórmulas de avaliação.',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, AdminCourseModel course) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges superiores (Código e Modalidade)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  course.code,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  course.modality,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF737373),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Título do Curso
          Text(
            course.name,
            style: jakarta(
              size: 18,
              weight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),

          // Lotação / Departamento
          Text(
            course.department,
            style: jakarta(
              size: 13,
              weight: FontWeight.w500,
              color: const Color(0xFF737373),
            ),
          ),
          const SizedBox(height: 22),

          // Informações Regimentais
          _buildMetaRow('Matriz Homologada:', course.matrix),
          const SizedBox(height: 8),
          _buildMetaRow('Carga Horária Total:', course.workload),
          const SizedBox(height: 8),
          _buildMetaRow(
            'Discentes Matriculados:',
            '${course.studentsCount} alunos',
          ),
          const SizedBox(height: 18),

          // Caixa de Critério Regimental de Aprovação
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 14,
                      color: Color(0xFF737373),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CRITÉRIO REGIMENTAL DE APROVAÇÃO',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w700,
                        color: const Color(0xFF737373),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  course.formula,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Botão Consultar Matriz Curricular & Ementário
          InkWell(
            onTap: () => _showMatrizCurricularModal(context, course),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Consultar Matriz Curricular & Ementário',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
        Text(
          value,
          style: jakarta(
            size: 13,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MODAL MATRIZ CURRICULAR & EMENTÁRIO
  // ==========================================
  void _showMatrizCurricularModal(
    BuildContext context,
    AdminCourseModel course,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MATRIZ CURRICULAR & COMPONENTES',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFF737373),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course.name,
                            style: jakarta(
                              size: 20,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course.matrix} • Carga Horária Total: ${course.workload}',
                            style: jakarta(
                              size: 13,
                              color: const Color(0xFF737373),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF737373),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Componentes Curriculares em Oferta no Período Letivo Vigente:',
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(3.0),
                      2: FlexColumnWidth(1.0),
                      3: FlexColumnWidth(2.5),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                        ),
                        children: [
                          _buildTh('PERÍODO'),
                          _buildTh('COMPONENTE CURRICULAR'),
                          _buildTh('CARGA'),
                          _buildTh('DOCENTE HOMOLOGADO'),
                        ],
                      ),
                      ...course.components.map((c) {
                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFF0F0F0),
                                width: 1,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                c['semestre'] as String,
                                style: jakarta(
                                  size: 12.5,
                                  color: const Color(0xFF737373),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                c['disciplina'] as String,
                                style: jakarta(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                c['carga'] as String,
                                style: jakarta(
                                  size: 12.5,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                c['docente'] as String,
                                style: jakarta(
                                  size: 12.5,
                                  color: const Color(0xFF525252),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Fechar',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTh(String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w700,
          color: const Color(0xFF737373),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
