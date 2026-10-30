// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/pages/courses_page.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import '../helpers/fake_admin_academic_data_source.dart';

void main() {
  testWidgets('renders every course in the desktop grid', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final additionalCourse = AdminCourseModel(
      code: 'ADM-TEST',
      name: 'Curso adicional de teste',
      matrix: '2026',
      workload: '3.000h',
      studentsCount: 10,
      formula: 'Média 7,0',
      components: const [],
    );
    AdminMockData.courses.add(additionalCourse);
    addTearDown(() => AdminMockData.courses.remove(additionalCourse));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoursesPage(dataSource: FakeAdminAcademicDataSource()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(additionalCourse.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
