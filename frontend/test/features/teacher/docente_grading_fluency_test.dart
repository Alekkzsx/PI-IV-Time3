// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/rubric_evaluation_modal.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_gradebook_table.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/data/teacher_remote_data_source.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import '../../helpers/fake_teacher_remote_data_source.dart';

class _TrackingFakeRemote extends FakeTeacherRemoteDataSource {
  int bootstrapCalls = 0;
  int batchGradeCalls = 0;
  int evaluateCalls = 0;
  List<Map<String, Object?>> lastBatchPayload = const [];

  @override
  Future<TeacherDashboardSnapshot> getBootstrap() async {
    bootstrapCalls++;
    return super.getBootstrap();
  }

  @override
  Future<Map<String, dynamic>> updateGradesBatch({
    required String classCode,
    required List<Map<String, Object?>> grades,
  }) async {
    batchGradeCalls++;
    lastBatchPayload = grades;
    return super.updateGradesBatch(classCode: classCode, grades: grades);
  }

  @override
  Future<Map<String, dynamic>> evaluateSubmission({
    required String assignmentId,
    required String studentId,
    required double calculatedGrade,
    required String feedback,
    required List<Map<String, Object?>> evaluatedCriteria,
  }) async {
    evaluateCalls++;
    return super.evaluateSubmission(
      assignmentId: assignmentId,
      studentId: studentId,
      calculatedGrade: calculatedGrade,
      feedback: feedback,
      evaluatedCriteria: evaluatedCriteria,
    );
  }
}

void main() {
  group('Fluidez no lançamento de notas e avaliação de rubrica docente', () {
    late _TrackingFakeRemote remote;
    late DocenteController controller;

    setUp(() async {
      AppUserSession.instance.signIn(
        identity: 'DOC-88410',
        profile: 'docente',
        accessToken: 'test-teacher-token',
      );
      addTearDown(AppUserSession.instance.signOut);
      remote = _TrackingFakeRemote();
      controller = DocenteController(
        remoteDataSource: remote,
        profileRemoteDataSource: FakeTeacherProfileRemoteDataSource(remote),
      );
      addTearDown(controller.dispose);
      await controller.loadRemote();
    });

    testWidgets(
      'DocenteGradebookTable permite digitação direta, recalcula média ao vivo e salva em lote sem recarregar bootstrap',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final initialBootstrap = remote.bootstrapCalls;
        final targetStudent = controller.gradebook.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (_, _) => DocenteGradebookTable(
                    controller: controller,
                    gradebook: controller.gradebook,
                  ),
                ),
              ),
            ),
          ),
        );

        final p1Field = find.descendant(
          of: find.byKey(
            ValueKey(
              'grade-${targetStudent.courseId}-${targetStudent.studentId}-p1',
            ),
          ),
          matching: find.byType(TextField),
        );
        expect(p1Field, findsOneWidget);

        await tester.enterText(p1Field, '9,5');
        await tester.pump();

        expect(controller.pendingGradeChangesCount, 1);
        expect(
          controller.gradebook.first.p1Score,
          closeTo(9.5, 0.01),
        );
        expect(find.text('Salvar Notas (1)'), findsOneWidget);

        await tester.tap(find.text('Salvar Notas (1)'));
        await tester.pumpAndSettle();

        expect(remote.batchGradeCalls, 1);
        expect(remote.lastBatchPayload.single['p1Score'], 9.5);
        expect(controller.pendingGradeChangesCount, 0);
        expect(remote.bootstrapCalls, initialBootstrap);
      },
    );

    testWidgets(
      'RubricEvaluationModal permite lançar nota direta quando não há critérios e navegar para próximo aluno',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final baseAssignment = controller.assignments.first;
        final sub1 = baseAssignment.submissions[0].copyWith(
          status: SubmissionStatus.aguardandoCorrecao,
          grade: null,
        );
        final sub2 = baseAssignment.submissions[1].copyWith(
          status: SubmissionStatus.naoEntregue,
          grade: null,
        );
        final noCriteriaAssignment = baseAssignment.copyWith(
          rubricCriteria: const [],
          submissions: [sub1, sub2],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => RubricEvaluationModal(
                  assignment: noCriteriaAssignment,
                  submission: sub1,
                  controller: controller,
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Atribuição Direta de Nota (0,0 a 10,0)'),
          findsOneWidget,
        );
        expect(find.text('9'), findsOneWidget);

        await tester.tap(find.text('9'));
        await tester.pump();

        expect(find.text('Nota Final: 9.0 / 10.0'), findsOneWidget);

        await tester.tap(find.text('Salvar Correção'));
        await tester.pumpAndSettle();

        expect(remote.evaluateCalls, 1);
        final evaluated = controller.assignments
            .firstWhere((a) => a.id == baseAssignment.id)
            .submissions
            .firstWhere((s) => s.studentId == sub1.studentId);
        expect(evaluated.status, SubmissionStatus.corrigido);
        expect(evaluated.grade, 9.0);
      },
    );

    test('Permite revisar nota já corrigida e avaliar submissão naoEntregue sem recarregar bootstrap', () async {
      final initialBootstrap = remote.bootstrapCalls;
      final assignment = controller.assignments.first;
      final naoEntregue = assignment.submissions.firstWhere(
        (s) => s.status == SubmissionStatus.naoEntregue,
      );

      final firstSave = await controller.evaluateRubric(
        assignmentId: assignment.id,
        submissionId: naoEntregue.id,
        calculatedGrade: 7.5,
        feedback: 'Apresentação presencial.',
        evaluatedCriteria: const [],
      );
      expect(firstSave, isTrue);

      final secondSave = await controller.evaluateRubric(
        assignmentId: assignment.id,
        submissionId: naoEntregue.id,
        calculatedGrade: 8.8,
        feedback: 'Revisado após verificação.',
        evaluatedCriteria: const [],
      );
      expect(secondSave, isTrue);

      final updated = controller.assignments
          .firstWhere((a) => a.id == assignment.id)
          .submissions
          .firstWhere((s) => s.id == naoEntregue.id);
      expect(updated.grade, 8.8);
      expect(updated.status, SubmissionStatus.corrigido);
      expect(remote.bootstrapCalls, initialBootstrap);
    });
  });
}
