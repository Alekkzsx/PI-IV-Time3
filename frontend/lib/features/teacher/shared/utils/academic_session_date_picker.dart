// Desenvolvido por Murillo Caravita - RA: 25014012
// Utilitário institucional para seleção de datas de aulas restritas aos dias regimentais da disciplina

import 'package:flutter/material.dart';
import '../domain/models/docente_course.dart';

Future<DateTime?> showAcademicSessionDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DocenteCourse course,
}) async {
  final allowedWeekdays = course.classWeekdays;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
    helpText: 'CALENDÁRIO DA TURMA (${course.classDaysLabel.toUpperCase()})',
    confirmText: 'SELECIONAR AULA',
    cancelText: 'CANCELAR',
    selectableDayPredicate: (DateTime day) {
      return allowedWeekdays.contains(day.weekday);
    },
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF18181B),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF18181B),
          ),
        ),
        child: child!,
      );
    },
  );
}
