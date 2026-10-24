// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_gradebook_table.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_grades_formula_banner.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_grades_header.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';

/// Tab page for managing student official gradebook, PPC formula calculations, and issuing minutes.
class DocenteGradesTab extends StatelessWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteGradesTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedCourse = controller.selectedCourse;
        final gradebook = controller.gradebook;

        return LayoutBuilder(
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
                      horizontal: constraints.maxWidth >= 900 ? 40 : 20,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DocenteGradesHeader(
                            controller: controller,
                            selectedCourse: selectedCourse,
                          ),
                          const SizedBox(height: 20),
                          const DocenteGradesFormulaBanner(),
                          const SizedBox(height: 24),
                          DocenteGradebookTable(
                            controller: controller,
                            gradebook: gradebook,
                          ),
                        ],
                      ),
                    ),
                    const DocenteFooter(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
