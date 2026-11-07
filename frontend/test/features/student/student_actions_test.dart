// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/student/calendar/presentation/widgets/student_calendar_sidebar.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/ava_syllabus_materials_tab.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/student_models.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/widgets/student_footer.dart';


void main() {
  testWidgets(
    'Feed do calendário informa que a assinatura não está disponível',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudentCalendarSidebar(
                controller: StudentPortalController(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('student_calendar_feed')),
      );
      await tester.tap(find.byKey(const Key('student_calendar_feed')));
      await tester.pump();

      expect(
        find.text(
          'A assinatura do feed do calendário ainda não está disponível.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Download de material não simula início de download', (
    tester,
  ) async {
    StudentPortalController.instance.disciplines = [
      StudentDisciplineModel(
        code: 'MAT101',
        name: 'Matemática',
        professor: 'Dr. Turing',
        time: '08:00 - 10:00',
        location: 'Sala 101',
        progress: 0.5,
        n1: 8.0,
        n2: 8.0,
        p1: 8.0,
        p2: 8.0,
        trab: 8.0,
        partialAverage: 8.0,
        attendancePercentage: 100,
        absences: 0,
        totalHours: 80,
        completedHours: 40,
        materials: const [
          StudentMaterialItem(
            id: 'mat-1',
            courseCode: 'MAT101',
            title: 'Plano de Ensino',
            fileName: 'Plano_de_Ensino_APS_II_2026_2.pdf',
            date: '01/02/2026',
            size: '1.2 MB',
            fileType: 'PDF',
          ),
        ],
      ),
    ];

    StudentPortalController.instance.selectDiscipline(
      StudentPortalController.instance.disciplines.first,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: AvaSyllabusMaterialsTab(activeTabIndex: 6)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byTooltip('Baixar Plano_de_Ensino_APS_II_2026_2.pdf'),
    );
    await tester.pump();

    expect(
      find.text(
        'O download de "Plano_de_Ensino_APS_II_2026_2.pdf" ainda não está disponível.',
      ),
      findsOneWidget,
    );
  });


  testWidgets('Rodapé se ajusta à largura desktop disponível', (tester) async {
    await tester.binding.setSurfaceSize(const Size(920, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 920, child: StudentFooter(isDesktop: true)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
