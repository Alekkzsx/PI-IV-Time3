import 'package:pi_iv_time3/features/student/shared/models/student_models.dart';

class StudentFixtures {
  static const studentRa = '202610401';

  static final disciplines = [
    const StudentDisciplineModel(
      code: 'APS-II',
      fullCode: '218131 - APS-II',
      name: 'Análise e Projeto de Sistemas II',
      professor: 'Docente de teste',
      time: 'Segunda-feira, 19:00 às 20:40',
      location: 'Laboratório de teste',
      progress: 0.68,
      n1: 8.5,
      n2: 9.0,
      p1: 8.5,
      p2: 9.0,
      trab: 9.5,
      partialAverage: 8.8,
      attendancePercentage: 96,
      absences: 1,
      totalHours: 80,
      completedHours: 54,
    ),
    const StudentDisciplineModel(
      code: 'BD-II',
      fullCode: '218132 - BD-II',
      name: 'Banco de Dados II',
      professor: 'Docente de teste',
      time: 'Terça-feira, 19:00 às 20:40',
      location: 'Laboratório de teste',
      progress: 0.5,
      n1: 8.8,
      n2: 9.0,
      p1: 9.0,
      p2: 9.0,
      trab: 8.5,
      partialAverage: 8.8,
      attendancePercentage: 94,
      absences: 2,
      totalHours: 80,
      completedHours: 40,
    ),
    const StudentDisciplineModel(
      code: 'FIS',
      fullCode: '218133 - FIS',
      name: 'Filosofia, Informação e Sociedade',
      professor: 'Docente de teste',
      time: 'Quarta-feira, 19:00 às 20:40',
      location: 'Sala de teste',
      progress: 0.35,
      n1: 8.0,
      n2: 0,
      p1: 8.0,
      p2: 0,
      trab: 8.0,
      partialAverage: 8.0,
      attendancePercentage: 90,
      absences: 3,
      totalHours: 80,
      completedHours: 28,
      syllabusUnits: [
        {
          'title':
              'Unidade 1: Ética na Sociedade Algorítmica e Inteligência Artificial',
          'description': 'Ética e inteligência artificial.',
        },
      ],
      materials: [
        StudentMaterialItem(
          id: 'material-1',
          courseCode: 'FIS',
          title: 'Texto Base: O Dilema das Redes e a Automação do Julgamento Moral',
          fileName: 'texto-base.pdf',
          date: '2026-09-20',
          size: '1 MB',
          fileType: 'PDF',
        ),
      ],
    ),
    const StudentDisciplineModel(
      code: 'FSO',
      fullCode: '218134 - FSO',
      name: 'Fundamentos de Sistemas Operacionais',
      professor: 'Docente de teste',
      time: 'Quinta-feira, 19:00 às 20:40',
      location: 'Sala de teste',
      progress: 0.4,
      n1: 7.5,
      n2: 0,
      p1: 7.5,
      p2: 0,
      trab: 8.0,
      partialAverage: 7.7,
      attendancePercentage: 88,
      absences: 4,
      totalHours: 80,
      completedHours: 32,
    ),
  ];

  static final deliveries = [
    const StudentDeliveryItem(
      id: 'DEL-01',
      sourceAssignmentId: 'asg-1',
      title: 'Entrega de teste de padrões de projeto',
      disciplineCode: 'APS-II',
      disciplineName: 'Análise e Projeto de Sistemas II',
      dueDate: '25/11/2026',
      dueHour: '23:59',
      status: 'Pendente',
      weight: 4,
      activityCode: 'APS - ATV - 04',
    ),
  ];

  static final calendarEvents = [
    StudentCalendarEvent(
      id: 'event-1',
      title: 'Aula Síncrona: Padrões de Projeto GoF',
      date: _today,
      time: '19:00 - 20:40',
      type: 'Aula',
      discipline: 'APS-II',
      location: 'Sala Virtual AVA / Lab 04',
    ),
    StudentCalendarEvent(
      id: 'event-2',
      title: 'Entrega: Padrões Adapter e Facade',
      date: _today,
      time: '23:59',
      type: 'Entrega',
      discipline: 'APS-II',
      location: 'AVA',
    ),
    StudentCalendarEvent(
      id: 'event-3',
      title: 'Avaliação Parcial N1: Álgebra Relacional e SQL',
      date: _tomorrow,
      time: '19:00',
      type: 'Avaliação',
      discipline: 'BD-II',
      location: 'Sala de teste',
    ),
  ];
}

String get _today {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

String get _tomorrow {
  final date = DateTime.now().add(const Duration(days: 1));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
