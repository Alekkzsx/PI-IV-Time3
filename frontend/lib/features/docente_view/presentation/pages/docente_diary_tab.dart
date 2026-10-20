// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/attendance_record.dart';
import '../controllers/docente_controller.dart';

/// Electronic class diary and interactive attendance register tab.
class DocenteDiaryTab extends StatefulWidget {
  final DocenteController controller;

  const DocenteDiaryTab({
    super.key,
    required this.controller,
  });

  @override
  State<DocenteDiaryTab> createState() => _DocenteDiaryTabState();
}

class _DocenteDiaryTabState extends State<DocenteDiaryTab> {
  late TextEditingController _contentController;
  late TextEditingController _methodologyController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.controller.currentSession.contentProgram,
    );
    _methodologyController = TextEditingController(
      text: widget.controller.currentSession.methodology,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _methodologyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.currentSession;
    final selectedCourse = widget.controller.selectedCourse;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Diário de Classe Eletrônico & Registro de Chamada',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Registro documental de presença, conteúdo ministrado e controle do teto regimental de faltas.',
                style: TextStyle(
                  fontSize: 14,
                  color: DocenteColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Course Selector Dropdown
              Row(
                children: [
                  const Text(
                    'Turma: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: DocenteColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DocenteColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCourse.id,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onChanged: (newId) {
                          if (newId != null) {
                            widget.controller.selectCourse(newId);
                          }
                        },
                        items: widget.controller.courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course.id,
                            child: Text(
                              '${course.code} - ${course.title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DocenteColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Session Card (MEC requirements)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: DocenteColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AULA Nº ${session.sessionNumber} • CARGA: ${session.hours}H/AULA',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: DocenteColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: session.isHomologated
                                ? DocenteColors.successLight
                                : DocenteColors.warningLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            session.isHomologated
                                ? 'Homologado no Sistema'
                                : 'Aguardando Homologação',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: session.isHomologated
                                  ? DocenteColors.success
                                  : DocenteColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.dateFormatted,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DocenteColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content field
                    const Text(
                      'Conteúdo Programático Específico Ministrado (Exigência Regimental MEC)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DocenteColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _contentController,
                      maxLines: 2,
                      onChanged: (val) {
                        widget.controller.updateSessionContent(
                          val,
                          _methodologyController.text,
                        );
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Methodology field
                    const Text(
                      'Metodologia e Recursos Aplicados',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DocenteColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _methodologyController,
                      maxLines: 2,
                      onChanged: (val) {
                        widget.controller.updateSessionContent(
                          _contentController.text,
                          val,
                        );
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Attendance List Table
              Container(
                decoration: BoxDecoration(
                  color: DocenteColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Registro de Chamada Discente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: DocenteColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${session.attendanceList.length} estudantes listados',
                            style: const TextStyle(
                              fontSize: 13,
                              color: DocenteColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: DocenteColors.border),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(DocenteColors.background),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 74,
                        columns: const [
                          DataColumn(label: Text('R.A.')),
                          DataColumn(label: Text('ESTUDANTE')),
                          DataColumn(label: Text('CHAMADA')),
                          DataColumn(label: Text('FALTAS ACUMULADAS')),
                          DataColumn(label: Text('FREQUÊNCIA')),
                          DataColumn(label: Text('SITUAÇÃO')),
                        ],
                        rows: session.attendanceList.map((student) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  student.ra,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: DocenteColors.textPrimary,
                                      ),
                                    ),
                                    if (student.observation != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: DocenteColors.infoLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          student.observation!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: DocenteColors.info,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                _buildPresenceButtons(student),
                              ),
                              DataCell(
                                Text(
                                  '${student.accumulatedAbsences} / ${student.maxAbsences} máx',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${student.attendanceRate}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: student.attendanceRate < 75.0
                                        ? DocenteColors.danger
                                        : DocenteColors.textPrimary,
                                  ),
                                ),
                              ),
                              DataCell(
                                _buildRiskBadge(student.riskLevel),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Actions and Save
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DocenteColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ao homologar o diário, a frequência é consolidada nos servidores acadêmicos e atualizada no portal do discente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: DocenteColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        widget.controller.homologateSession();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: DocenteColors.success,
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                                SizedBox(width: 10),
                                Text('Aula homologada e presenças consolidadas com sucesso!'),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Salvar e Homologar Aula'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DocenteColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceButtons(AttendanceStudent student) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPill(
          label: 'P',
          isSelected: student.status == AttendanceStatus.presente,
          activeBg: DocenteColors.success,
          onTap: () => widget.controller.toggleAttendance(
            student.studentId,
            AttendanceStatus.presente,
          ),
          tooltip: 'Marcar Presente',
        ),
        const SizedBox(width: 6),
        _buildPill(
          label: 'F',
          isSelected: student.status == AttendanceStatus.ausente,
          activeBg: DocenteColors.danger,
          onTap: () => widget.controller.toggleAttendance(
            student.studentId,
            AttendanceStatus.ausente,
          ),
          tooltip: 'Marcar Falta',
        ),
        const SizedBox(width: 6),
        _buildPill(
          label: 'J',
          isSelected: student.status == AttendanceStatus.justificada,
          activeBg: DocenteColors.warning,
          onTap: () => widget.controller.toggleAttendance(
            student.studentId,
            AttendanceStatus.justificada,
          ),
          tooltip: 'Marcar Falta Justificada',
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required Color activeBg,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : DocenteColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? activeBg : DocenteColors.borderDark,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : DocenteColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(AttendanceRiskLevel risk) {
    String text;
    Color color;
    Color bg;

    switch (risk) {
      case AttendanceRiskLevel.regular:
        text = 'Regular';
        color = DocenteColors.success;
        bg = DocenteColors.successLight;
        break;
      case AttendanceRiskLevel.atencao:
        text = 'Atenção';
        color = DocenteColors.warning;
        bg = DocenteColors.warningLight;
        break;
      case AttendanceRiskLevel.critico:
        text = 'Risco de Reprovação';
        color = DocenteColors.danger;
        bg = DocenteColors.dangerLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

