// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Aba do Livro de Notas (Gradebook) da disciplina no Portal Docente.
class CourseHubGradebookTab extends StatelessWidget {
  final VoidCallback? onExport;
  final VoidCallback? onSaveGrades;

  const CourseHubGradebookTab({super.key, this.onExport, this.onSaveGrades});

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    children: [
                      Expanded(child: t1),
                      const SizedBox(width: 10),
                      Expanded(child: t2),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: t3),
                      const SizedBox(width: 10),
                      Expanded(child: t4),
                    ],
                  ),
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
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA1A1AA),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFF71717A),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onExport != null) {
                        onExport!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Exportando Gradebook oficial em formato XLSX/CSV...',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.download,
                      size: 14,
                      color: Color(0xFF09090B),
                    ),
                    label: const Text(
                      'Exportar Planilha Oficial',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (onSaveGrades != null) {
                        onSaveGrades!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notas homologadas e sincronizadas com a Secretaria Acadêmica!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Salvar & Homologar Notas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 30,
                            child: Text(
                              'DISCENTE / R.A.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              'P1 (PROVA)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              'T1 (PROJETO)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 14,
                            child: Text(
                              'MÉDIA N1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              'P2',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              'T2',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 14,
                            child: Text(
                              'MÉDIA FINAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 24,
                            child: Text(
                              'SITUAÇÃO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF71717A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE4E4E7),
                    ),
                    _buildGradeRow(
                      'Mariana Rios Costa',
                      '2024.1.00901',
                      '9.5',
                      '9.0',
                      '9.3',
                      '-',
                      '-',
                      '9.3',
                      'Aprovado',
                    ),
                    _buildGradeRow(
                      'Gabriel Soares de Oliveira',
                      '2024.1.00892',
                      '8.0',
                      '8.5',
                      '8.2',
                      '-',
                      '-',
                      '8.2',
                      'Aprovado',
                    ),
                    _buildGradeRow(
                      'Rodrigo Antunes Nogueira',
                      '2024.1.00938',
                      '2ª Cham.',
                      '7.0',
                      'Pend.',
                      '-',
                      '-',
                      'Pend.',
                      'Pendente',
                    ),
                    _buildGradeRow(
                      'Lucas Mendes Santos',
                      '2024.1.00915',
                      '7.0',
                      '7.5',
                      '7.2',
                      '-',
                      '-',
                      '7.2',
                      'Aprovado',
                    ),
                    _buildGradeRow(
                      'Camila Duarte Fagundes',
                      '2024.1.00902',
                      '8.5',
                      '8.0',
                      '8.3',
                      '-',
                      '-',
                      '8.3',
                      'Aprovado',
                    ),
                    _buildGradeRow(
                      'Vinicius Ferraz Toledo',
                      '2024.1.00944',
                      '5.0',
                      '6.0',
                      '5.4',
                      '-',
                      '-',
                      '5.4',
                      'Em Atenção',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildGradeRow(
    String studentName,
    String ra,
    String p1,
    String t1,
    String n1,
    String p2,
    String t2,
    String finalGrade,
    String status,
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
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    Text(
                      'RA: $ra',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  p1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  t1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 14,
                child: Text(
                  n1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  p2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  t2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 14,
                child: Text(
                  finalGrade,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 24,
                child: Center(child: AcademicStatusBadge.fromString(status)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
      ],
    );
  }

  static Widget _buildMetricTile({
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF09090B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF71717A)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
