// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Tabela responsiva de turmas ativas com indicadores de ensalamento, regime e ações de supervisão.
class ClassListTable extends StatelessWidget {
  final List<AdminClassModel> classes;
  final ValueChanged<AdminClassModel> onSupervise;
  final ValueChanged<AdminClassModel> onOpenRegime;
  final ValueChanged<AdminClassModel> onOpenAlocar;

  const ClassListTable({
    super.key,
    required this.classes,
    required this.onSupervise,
    required this.onOpenRegime,
    required this.onOpenAlocar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 1180.0;
          final tableWidth = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(),
                  for (final c in classes) _buildTableRow(context, c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    final headerStyle = jakarta(
      size: 11,
      weight: FontWeight.w700,
      color: const Color(0xFF737373),
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 22, child: Text('CÓDIGO / DISCIPLINA', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 18, child: Text('CURSO & TURNO', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 18, child: Text('LOCAL / ENSALAMENTO', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 12, child: Text('VAGAS OCUPADAS', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 18, child: Text('DOCENTE RESPONSÁVEL', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 16, child: Text('REGIME DE AVALIAÇÃO', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(
            flex: 26,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('AÇÕES', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AdminClassModel c) {
    final isAutonomia = c.formulaRegime == 'Autonomia Docente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Código / Disciplina
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.subjectName,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  c.code,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Curso & Turno
          Expanded(
            flex: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.courseName,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.semester,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  c.shift,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Local / Ensalamento
          Expanded(
            flex: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.location,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(0xFF525252),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Vagas Ocupadas
          Expanded(
            flex: 12,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${c.enrolled}',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    TextSpan(
                      text: ' / ${c.maxCapacity} vagas',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Docente Responsável
          Expanded(
            flex: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  size: 16,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.professor,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Regime de Avaliação
          Expanded(
            flex: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAutonomia ? const Color(0xFFECFDF5) : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAutonomia ? const Color(0xFFA7F3D0) : const Color(0xFFE4E4E7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAutonomia ? Icons.lock_open_outlined : Icons.lock_outline,
                          size: 12,
                          color: isAutonomia ? const Color(0xFF059669) : const Color(0xFF737373),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          c.formulaRegime,
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: isAutonomia ? const Color(0xFF059669) : const Color(0xFF737373),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAutonomia ? 'Docente define fórmula' : 'Trava Regimental',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w400,
                    color: isAutonomia ? const Color(0xFF059669) : const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Ações
          Expanded(
            flex: 26,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Supervisionar
                    InkWell(
                      onTap: () => onSupervise(c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Supervisionar',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Regime
                    InkWell(
                      onTap: () => onOpenRegime(c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.balance,
                              size: 13,
                              color: Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Regime',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Alocar
                    InkWell(
                      onTap: () => onOpenAlocar(c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          'Alocar',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
