import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/core/academic/grade_calculator.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/admin/calendar/presentation/pages/calendar_page.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/pages/supervision_cockpit_page.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/widgets/course_matrix_syllabus_modal.dart';
import 'package:pi_iv_time3/features/admin/settings/presentation/widgets/academic_guidelines_tab.dart';
import 'package:pi_iv_time3/features/admin/settings/presentation/widgets/security_credentials_tab.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_remote_data_source.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_sessions_dialog.dart';

class _StubCourseAcademicDataSource implements AdminAcademicDataSource {
  String? patchedCode;
  Map<String, Object?>? patchedFields;

  @override
  Future<void> patchCourse(String code, Map<String, Object?> fields) async {
    patchedCode = code;
    patchedFields = fields;
  }

  @override
  Future<void> assignTeacherToClass({
    required String classCode,
    required String professorIdentity,
  }) async {}

  @override
  Future<List<AdminGradeAuditRow>> classGrades(String classCode) async => [];

  @override
  Future<void> createClass({
    required String code,
    required String courseCode,
    required String semester,
    required String shift,
    required String location,
    required int maxCapacity,
    String? subjectName,
    String? schedule,
    int? totalHours,
    String? professorIdentity,
  }) async {}

  @override
  Future<void> createClassSession({
    required String classCode,
    required String title,
    required DateTime startsAt,
  }) async {}

  @override
  Future<void> createCourse(AdminCourseModel course) async {}

  @override
  Future<void> createEnrollment({
    required String classCode,
    required String studentIdentity,
  }) async {}

  @override
  Future<List<AdminClassModel>> getClasses() async => [];

  @override
  Future<List<AdminCourseModel>> getCourses() async => [];

  @override
  Future<List<AdminEnrolledStudent>> getEnrollments(String classCode) async => [];

  @override
  Future<List<AdminUserModel>> getTeachers() async => [];

  @override
  Future<void> updateEnrollment({
    required String classCode,
    required String enrollmentId,
    required Map<String, Object?> fields,
  }) async {}
}

void main() {
  setUp(() {
    AppUserSession.instance.signIn(
      identity: 'admin.demo',
      profile: 'admin',
      accessToken: 'test-admin-jwt',
    );
    addTearDown(AppUserSession.instance.signOut);
  });

  group('Admin API Contracts & Resilient Parsers', () {
    test('classGrades parses Map payload returned by backend and legacy List payload', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/admin/classes/218131%20-%20APS-II/grades');
        return http.Response(
          jsonEncode({
            'classCode': '218131 - APS-II',
            'subjectName': 'Análise e Projeto de Sistemas II',
            'formulaRegime': 'autonomia_docente',
            'evaluationFormula': '(N1 × 0.4) + (N2 × 0.6)',
            'gradeLocked': false,
            'pautaHomologated': false,
            'chancelaCode': null,
            'grades': [
              {
                'studentId': 's1',
                'ra': '2024.1.00892',
                'studentName': 'Gabriel Soares',
                'assignmentsScore': 8.0,
                'p1Score': 9.0,
                'projectsScore': 7.5,
                'p2Score': 8.5,
                'n1': 8.6,
                'n2': 8.1,
                'finalAverage': 8.3,
                'attendanceRate': 95,
                'absences': 2,
                'hasGrades': true,
              },
            ],
          }),
          200,
        );
      });

      final ds = AdminAcademicRemoteDataSource(client: client);
      final rows = await ds.classGrades('218131 - APS-II');
      expect(rows, hasLength(1));
      expect(rows.first.studentName, 'Gabriel Soares');
      expect(rows.first.finalAverage, 8.3);
      expect(rows.first.hasGrades, isTrue);

      final legacyClient = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'studentId': 's2',
              'ra': '2024.1.00901',
              'studentName': 'Mariana Rios',
              'n1': 9.0,
              'n2': 9.0,
              'finalAverage': 9.0,
              'hasGrades': true,
            },
          ]),
          200,
        ),
      );
      final legacyRows = await AdminAcademicRemoteDataSource(
        client: legacyClient,
      ).classGrades('APS-II');
      expect(legacyRows, hasLength(1));
      expect(legacyRows.first.ra, '2024.1.00901');
    });

    test('classGrades throws explicit AdminAcademicApiException for invalid payload or malformed JSON', () async {
      final badShapeClient = MockClient(
        (_) async => http.Response(jsonEncode({'classCode': 'X', 'grades': 'not-a-list'}), 200),
      );
      await expectLater(
        AdminAcademicRemoteDataSource(client: badShapeClient).classGrades('X'),
        throwsA(
          isA<AdminAcademicApiException>().having(
            (e) => e.message,
            'message',
            'Resposta inválida da API.',
          ),
        ),
      );

      final brokenJsonClient = MockClient(
        (_) async => http.Response('<html>Bad Gateway</html>', 200),
      );
      await expectLater(
        AdminAcademicRemoteDataSource(client: brokenJsonClient).classGrades('X'),
        throwsA(
          isA<AdminAcademicApiException>().having(
            (e) => e.message,
            'message',
            'A API retornou uma resposta inválida.',
          ),
        ),
      );
    });

    test('getCourses and getClasses handle nullable or missing fields cleanly', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/admin/courses') {
          return http.Response(
            jsonEncode([
              {
                'code': 'ES-2026',
                'name': 'Engenharia de Software',
                'matrix': null,
                'workload': null,
                'studentsCount': null,
                'formula': null,
                'department': null,
                'modality': null,
                'components': [
                  {'code': 'COMP-1', 'name': 'Arquitetura', 'workloadHours': 80, 'semester': 4},
                ],
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'code': 'ES-01',
              'courseCode': 'ES-2026',
              'subjectName': null,
              'courseName': null,
              'semester': '2026/2',
              'shift': 'Noturno',
              'location': null,
              'maxCapacity': null,
              'enrolledStudents': [
                {'enrollmentId': 'e1', 'studentId': 's1', 'ra': 'RA-1', 'displayName': 'Aluno 1'},
              ],
            },
          ]),
          200,
        );
      });
      final ds = AdminAcademicRemoteDataSource(client: client);
      final courses = await ds.getCourses();
      final classes = await ds.getClasses();
      expect(courses.single.code, 'ES-2026');
      expect(courses.single.components.single['code'], 'COMP-1');
      expect(classes.single.enrolled, 1);
      expect(classes.single.maxCapacity, 40);
      expect(classes.single.professor, 'Não alocado');
    });

    test('AdminRemoteDataSource safely parses users, protocols with code, and auditLogs', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/users')) {
          return http.Response(
            jsonEncode([
              {'_id': 'u1', 'identity': 'admin.demo', 'name': 'Admin', 'email': 'a@b.com', 'active': true},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/protocols')) {
          return http.Response(
            jsonEncode([
              {
                '_id': 'p1',
                'code': 'PROT - 2026/0542',
                'studentName': 'Camila',
                'studentRa': '2024.1',
                'requestType': 'Segunda Chamada',
                'createdAt': '2026-09-20T10:00:00Z',
                'status': 'pendente',
                'justification': 'Atestado',
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {'_id': 'a1', 'createdAt': '2026-09-20', 'action': 'login', 'target': null},
          ]),
          200,
        );
      });
      final api = AuthenticatedApiClient(client: mockClient);
      final remote = AdminRemoteDataSource(api: api, authApi: api);

      final users = await remote.users();
      final protocols = await remote.protocols();
      final logs = await remote.auditLogs();

      expect(users.single.id, 'u1');
      expect(users.single.name, 'Admin');
      expect(protocols.single.code, 'PROT - 2026/0542');
      expect(protocols.single.status, 'pendente');
      expect(logs.single.targetUserId, isNull);
    });

    test('loadClassSupervision isolates supervisionError from shell remoteError and preserves enrollments', () async {
      final academicMock = MockClient((request) async {
        if (request.url.path.endsWith('/grades')) {
          return http.Response(jsonEncode({'message': 'Falha temporária nas pautas.'}), 500);
        }
        if (request.url.path.endsWith('/enrollments')) {
          return http.Response(
            jsonEncode([
              {'id': 'e1', 'studentId': 's1', 'studentIdentity': 'RA-10', 'displayName': 'Discente Ativo'},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final controller = AdminPortalController.forTesting(
        academicRemote: AdminAcademicRemoteDataSource(client: academicMock),
      );
      await controller.loadClassSupervision('APS-II');

      expect(controller.remoteError, isNull);
      expect(controller.supervisionError, 'Falha temporária nas pautas.');
      expect(controller.supervisedGrades, isEmpty);
      expect(controller.supervisedEnrollments, hasLength(1));
      expect(controller.supervisedEnrollments.single.displayName, 'Discente Ativo');
    });

    test('filteredProtocols normalizes seeded statuses (pendente, deferido, concluido)', () {
      final controller = AdminPortalController.forTesting();
      controller.protocols = [
        AdminProtocolModel(
          id: '1',
          studentName: 'A',
          studentRa: '1',
          requestType: 'Tipo',
          date: '2026',
          status: 'pendente',
          attachmentName: '',
          justification: 'J1',
        ),
        AdminProtocolModel(
          id: '2',
          studentName: 'B',
          studentRa: '2',
          requestType: 'Tipo',
          date: '2026',
          status: 'deferido',
          attachmentName: '',
          justification: 'J2',
        ),
        AdminProtocolModel(
          id: '3',
          studentName: 'C',
          studentRa: '3',
          requestType: 'Tipo',
          date: '2026',
          status: 'Aguardando Parecer',
          attachmentName: '',
          justification: 'J3',
        ),
      ];

      controller.setProtocolFilter('Aguardando Parecer');
      expect(controller.filteredProtocols.map((p) => p.id), ['1', '3']);

      controller.setProtocolFilter('Deferidos');
      expect(controller.filteredProtocols.map((p) => p.id), ['2']);
    });

    test('AdminCalendarMilestone.fromJson falls back to category field', () {
      final milestone = AdminCalendarMilestone.fromJson({
        '_id': 'cal-1',
        'title': 'Fechamento de Diário',
        'category': 'closing',
        'startsAt': '2026-11-20T12:00:00.000Z',
      });
      expect(milestone.id, 'cal-1');
      expect(milestone.type, 'closing');
    });
  });

  group('Admin Widget Fixes', () {
    testWidgets('CourseMatrixSyllabusModal renders ES-2026 schema and invokes patchCourse + onUpdated', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final stubDs = _StubCourseAcademicDataSource();
      var refreshed = false;
      final course = AdminCourseModel(
        code: 'ES-2026',
        name: 'Engenharia de Software',
        matrix: 'Matriz 2026/1',
        workload: '3.200h',
        studentsCount: 45,
        formula: '(N1 × 0.4) + (N2 × 0.6)',
        components: const [
          {
            'code': 'COMP-ES-401',
            'name': 'Engenharia de Requisitos',
            'workloadHours': 80,
            'semester': 4,
          },
          {
            'semestre': '5º Sem.',
            'disciplina': 'Arquitetura de Software',
            'carga': '60h',
            'docente': 'Prof. Carlos Silva',
          },
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseMatrixSyllabusModal(
              course: course,
              dataSource: stubDs,
              onUpdated: () => refreshed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('4º Sem.'), findsOneWidget);
      expect(find.text('COMP-ES-401 · Engenharia de Requisitos'), findsOneWidget);
      expect(find.text('80h'), findsOneWidget);
      expect(find.text('A definir / Colegiado'), findsOneWidget);
      expect(find.text('5º Sem.'), findsOneWidget);
      expect(find.text('Arquitetura de Software'), findsOneWidget);

      await tester.tap(find.text('Editar matriz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar Matriz'));
      await tester.pumpAndSettle();

      expect(stubDs.patchedCode, 'ES-2026');
      expect(stubDs.patchedFields?['components'], isA<List>());
      expect(refreshed, isTrue);
    });

    testWidgets('CalendarPage opens edit modal on closing milestone without Dropdown error', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AdminPortalController.instance;
      controller.calendarEvents = [
        const AdminCalendarMilestone(
          id: 'evt-1',
          title: 'Encerramento do Semestre',
          startsAt: '2026-12-15T12:00:00Z',
          type: 'closing',
        ),
      ];
      addTearDown(() => controller.calendarEvents = []);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CalendarPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marcos do calendário acadêmico'), findsOneWidget);
      expect(find.text('Fechamento'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar marco'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Editar Marco Acadêmico'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });

    testWidgets('SupervisionCockpitPage shows dynamic seats, clean labels, and guards unassigned professor', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AdminPortalController.instance;
      controller.supervisedEnrollments = [
        const AdminEnrolledStudent(
          enrollmentId: 'e1',
          studentId: 's1',
          ra: 'RA-001',
          displayName: 'Aluno Teste',
        ),
      ];
      controller.supervisedGrades = [
        const AdminGradeAuditRow(
          studentId: 's1',
          ra: 'RA-001',
          studentName: 'Aluno Teste',
          assignmentsScore: 0,
          p1Score: 0,
          projectsScore: 0,
          p2Score: 0,
          n1: 0,
          n2: 0,
          finalAverage: 0,
          attendanceRate: 100,
          absences: 0,
          hasGrades: false,
        ),
      ];
      addTearDown(() {
        controller.supervisedEnrollments = [];
        controller.supervisedGrades = [];
        controller.supervisionError = null;
      });

      final classModel = AdminClassModel(
        code: 'ENG-101',
        subjectName: 'Engenharia de Requisitos',
        location: 'Sala 10',
        enrolled: 1,
        maxCapacity: 30,
        professor: 'Não alocado',
        formulaRegime: 'Autonomia Docente',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupervisionCockpitPage(
              classModel: classModel,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Discentes & Vagas'));
      await tester.pump();
      expect(find.text('29 Vagas Disponíveis'), findsOneWidget);
      expect(find.text('6 Vagas Disponíveis'), findsNothing);

      await tester.tap(find.text('Atribuição Docente'));
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, isEmpty);

      await tester.tap(find.text('Confirmar Reatribuição'));
      await tester.pump();
      expect(
        find.text('Informe o nome, e-mail ou matrícula de um docente válido.'),
        findsOneWidget,
      );
    });

    testWidgets('UserSessionsDialog renders device and ipAddress fields when supplied', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final user = AdminUserModel(
        id: 'u1',
        name: 'Usuário Teste',
        email: 'u@example.com',
        profile: 'admin',
        departmentOrCourse: 'Secretaria',
        status: 'Ativo',
        twoFactorRequired: false,
        activeSessionsCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserSessionsDialog(
              user: user,
              sessions: const [
                {
                  'id': 's1',
                  'device': 'Firefox / Linux Desktop',
                  'ipAddress': '192.168.10.22',
                  'createdAt': '2026-11-18T10:00:00Z',
                  'expiresAt': '2026-11-19T10:00:00Z',
                  'current': true,
                },
              ],
              onTerminateAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Firefox / Linux Desktop'), findsOneWidget);
      expect(find.textContaining('192.168.10.22'), findsOneWidget);
      expect(find.text('Atual'), findsOneWidget);
    });

    testWidgets('SecurityCredentialsTab maps Java session keys (current, ipAddress, createdAt)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(jsonEncode({'twoFactorEnabled': false}), 200);
        }
        if (request.url.path == '/api/auth/sessions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'sess-1',
                'device': 'Chrome 131',
                'ipAddress': '10.0.0.5',
                'createdAt': '2026-11-18T08:00:00Z',
                'expiresAt': '2026-11-19T08:00:00Z',
                'current': true,
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/auth/security-logs') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('{}', 200);
      });

      final profileRemote = AuthProfileRemoteDataSource(
        api: AuthenticatedApiClient(client: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecurityCredentialsTab(profileRemote: profileRemote),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chrome 131 · Esta sessão'), findsOneWidget);
      expect(find.textContaining('10.0.0.5'), findsOneWidget);
    });

    testWidgets('AcademicGuidelinesTab accepts comma decimal input like 6,5', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AcademicGuidelinesTab()),
          ),
        ),
      );
      await tester.pump();

      final gradeField = find.byType(TextField).first;
      await tester.enterText(gradeField, '6,5');
      await tester.ensureVisible(find.text('Salvar diretrizes'));
      await tester.tap(find.text('Salvar diretrizes'));
      await tester.pump();

      expect(find.text('Informe valores numéricos válidos.'), findsNothing);
    });
  });

  group('Shared GradeCalculator & Admin Notifications/Rectifications', () {
    test('GradeCalculator & GradeRecord apply ponderada, equitativa, aritmetica, and dynamic thresholds', () {
      const custom = AcademicThresholds(
        minimumGrade: 7.0,
        minimumAttendance: 80.0,
        specialExamGrade: 5.0,
      );

      // Ponderada (0.4 / 0.6): N1 = (10*0.4 + 5*0.6)=7.0, N2=10.0 -> MS=8.8
      final pAvg = GradeCalculator.computeFinalAverage(
        assignmentsScore: 10.0,
        p1Score: 5.0,
        projectsScore: 10.0,
        p2Score: 10.0,
        formula: '(N1 × 0.4) + (N2 × 0.6)',
      );
      expect(pAvg, 8.8);

      // Equitativa (50% / 50%): (7.0*0.5) + (10.0*0.5) = 8.5
      final eAvg = GradeCalculator.computeFinalAverage(
        assignmentsScore: 10.0,
        p1Score: 5.0,
        projectsScore: 10.0,
        p2Score: 10.0,
        formula: 'Equitativa (N1 50% / N2 50%)',
      );
      expect(eAvg, 8.5);

      // Aritmetica: (8+6+10+8)/4 = 8.0
      final aAvg = GradeCalculator.computeFinalAverage(
        assignmentsScore: 8.0,
        p1Score: 6.0,
        projectsScore: 10.0,
        p2Score: 8.0,
        formula: 'Média aritmética de instrumentos contínuos',
      );
      expect(aAvg, 8.0);

      const examRecord = StudentGrade(
        studentId: 's1',
        ra: '1',
        studentName: 'Ana',
        attendanceRate: 85,
        assignmentsScore: 6.5,
        p1Score: 6.5,
        projectsScore: 6.5,
        p2Score: 6.5,
        hasGrades: true,
        thresholds: custom,
      );
      expect(examRecord.status, AcademicStatus.exame);

      const attendanceFailRecord = StudentGrade(
        studentId: 's2',
        ra: '2',
        studentName: 'Bia',
        attendanceRate: 78,
        assignmentsScore: 9.0,
        p1Score: 9.0,
        projectsScore: 9.0,
        p2Score: 9.0,
        hasGrades: true,
        thresholds: custom,
      );
      expect(attendanceFailRecord.status, AcademicStatus.reprovadoPorFalta);
    });

    test('AdminPortalController builds notifications from campusAlerts, decides rectifications, and unlocks pauta', () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/admin/rectifications/rect-1/decision') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['approved'], isTrue);
          expect(body['decisionNote'], 'Conferido');
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        if (request.url.path == '/api/admin/classes/IHC-305') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['gradeLocked'], isFalse);
          expect(body['pautaHomologated'], isFalse);
          return http.Response(jsonEncode({'ok': true}), 200);
        }
        if (request.url.path == '/api/admin/dashboard' ||
            request.url.path == '/api/admin/settings') {
          return http.Response(jsonEncode({}), 200);
        }
        return http.Response(jsonEncode([]), 200);
      });
      final api = AuthenticatedApiClient(client: client);
      final controller = AdminPortalController.forTesting(
        remote: AdminRemoteDataSource(api: api, authApi: api),
        academicRemote: AdminAcademicRemoteDataSource(client: client),
      );
      controller.protocols = [
        AdminProtocolModel(
          id: 'p1',
          code: 'PROT-1',
          studentName: 'Ana',
          studentRa: '1',
          requestType: 'Abono',
          date: '2026-11-18',
          status: 'Aguardando Parecer',
          attachmentName: '',
          justification: 'Atestado',
        ),
      ];
      controller.rectifications = const [
        AdminGradeRectificationModel(
          id: 'rect-1',
          code: 'RET-1',
          classCode: 'IHC-305',
          subjectName: 'IHC',
          studentId: 's1',
          studentRa: '1',
          studentName: 'Ana',
          teacherId: 't1',
          teacherName: 'Prof',
          stage: 'p1',
          previousScore: 5.0,
          newScore: 8.0,
          justification: 'Erro de digitação',
          status: 'Pendente',
          createdAt: '2026-11-18',
        ),
      ];
      controller.institutionalSettings = {
        'campusAlerts': {
          'notifyPendingProtocols': true,
          'notifyGradeRectifications': false,
        },
      };

      expect(controller.pendingRectifications, hasLength(1));
      expect(controller.institutionalNotifications.length, 1);
      expect(
        controller.institutionalNotifications.first['type'],
        'protocol',
      );

      final decided = await controller.decideRectification(
        id: 'rect-1',
        approved: true,
        decisionNote: 'Conferido',
      );
      final unlocked = await controller.unlockClassPauta('IHC-305');

      expect(decided, isTrue);
      expect(unlocked, isTrue);
      expect(
        calls,
        containsAll([
          'PATCH /api/admin/rectifications/rect-1/decision',
          'PATCH /api/admin/classes/IHC-305',
        ]),
      );
    });
  });
}
