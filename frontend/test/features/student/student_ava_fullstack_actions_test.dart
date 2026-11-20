// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/portal_remote_data_source.dart';

void main() {
  group('Ações fullstack do Cockpit AVA discente na API Acadêmica (:3001)', () {
    setUp(() {
      AppUserSession.instance.signIn(
        identity: '202610401',
        profile: 'aluno',
        accessToken: 'student-jwt-teste',
      );
    });

    tearDown(() {
      AppUserSession.instance.signOut();
    });

    Map<String, dynamic> buildBootstrapPayload({
      String note = 'Resumo inicial',
      List<String> checklist = const [],
      List<Map<String, dynamic>> forumTopics = const [],
    }) => {
      'studentInfo': {
        'name': 'Mariana Costa',
        'courseName': 'Engenharia de Software',
        'semester': '4º Semestre',
      },
      'stats': {
        'activeDisciplines': 1,
        'averageAttendance': 92.0,
        'cr': 8.7,
        'academicStatus': 'Regular',
        'completedHoursSemester': 40,
        'totalHoursSemester': 80,
      },
      'disciplines': [
        {
          'code': 'PI4-2026-4N',
          'fullCode': 'PI-IV',
          'name': 'Projeto Integrador IV',
          'professor': 'Prof. Dr. Ricardo Vasconcelos',
          'progress': 0.5,
          'completedChecklistItems': checklist,
        },
      ],
      'deliveries': [
        {
          'id': 'assign-1',
          'title': 'Entrega Arquitetura',
          'disciplineCode': 'PI4-2026-4N',
          'disciplineName': 'Projeto Integrador IV',
          'dueDate': '20/11/2026',
          'dueHour': '23:59',
          'status': 'Pendente',
          'weight': 4,
        },
      ],
      'events': const [],
      'messages': const [],
      'personalNotes': {'PI4-2026-4N': note},
      'forumTopics': forumTopics,
    };

    test('Executa dúvidas, fórum, anotações, checklist e esclarecimento via :3001', () async {
      final calls = <String>[];
      String currentNote = 'Resumo inicial';
      final currentTopics = <Map<String, dynamic>>[];
      var checklist = <String>[];
      var checklistShouldFail = false;

      final mockClient = MockClient((request) async {
        calls.add('${request.method} ${request.url}');
        final path = request.url.path;

        if (request.method == 'GET' && path == '/api/student/bootstrap') {
          return http.Response(
            jsonEncode(
              buildBootstrapPayload(
                note: currentNote,
                checklist: checklist,
                forumTopics: currentTopics,
              ),
            ),
            200,
          );
        }

        if (request.method == 'GET' && path == '/api/student/timeline') {
          return http.Response(jsonEncode({'blocks': const []}), 200);
        }

        if (request.method == 'PUT' &&
            path == '/api/student/disciplines/PI4-2026-4N/notes') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          currentNote = body['content']?.toString() ?? '';
          return http.Response(jsonEncode({'ok': true}), 200);
        }

        if (request.method == 'POST' &&
            path == '/api/student/assignments/assign-1/doubts') {
          return http.Response(jsonEncode({'id': 'doubt-1'}), 201);
        }

        if (request.method == 'POST' &&
            path == '/api/student/disciplines/PI4-2026-4N/forum') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          currentTopics.add({
            'id': 'topic-1',
            'classCode': 'PI4-2026-4N',
            'title': body['title'],
            'body': body['body'],
            'replies': const [],
          });
          return http.Response(jsonEncode({'id': 'topic-1'}), 201);
        }

        if (request.method == 'POST' &&
            path == '/api/student/disciplines/PI4-2026-4N/forum/topic-1/reply') {
          return http.Response(jsonEncode({'ok': true}), 201);
        }

        if (request.method == 'PUT' &&
            path.contains('/checklist/')) {
          if (checklistShouldFail) {
            return http.Response(jsonEncode({'message': 'Falha simulada'}), 500);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final itemId = path.split('/').last;
          if (body['completed'] == true) {
            if (!checklist.contains(itemId)) checklist = [...checklist, itemId];
          } else {
            checklist = checklist.where((e) => e != itemId).toList();
          }
          return http.Response(
            jsonEncode({'completedChecklistItems': checklist}),
            200,
          );
        }

        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final controller = StudentPortalController.withRemoteDataSource(
        StudentRemoteDataSource(
          api: AuthenticatedApiClient.academic(client: mockClient),
        ),
      );

      await controller.loadRemote(force: true);
      expect(controller.selectedDiscipline?.code, 'PI4-2026-4N');

      await controller.updatePersonalNotes('Resumo atualizado no AVA');
      expect(controller.studentPersonalNotes, 'Resumo atualizado no AVA');

      await controller.postDoubt(
        assignmentId: 'assign-1',
        question: 'Como formatar as referências do relatório?',
      );

      await controller.createForumTopic(
        classCode: 'PI4-2026-4N',
        title: 'Dúvida sobre arquitetura',
        body: 'Podemos detalhar o diagrama C4?',
      );
      expect(controller.forumTopicsCountFor('PI4-2026-4N'), 1);

      await controller.replyForumTopic(
        classCode: 'PI4-2026-4N',
        topicId: 'topic-1',
        body: 'Sim, nível 2 e 3.',
      );

      await controller.toggleChecklistItem('PI4-2026-4N', 'unit-1');
      expect(controller.isChecklistItemCompleted('PI4-2026-4N', 'unit-1'), isTrue);

      // Reversão otimista quando a API retorna erro 500
      checklistShouldFail = true;
      await expectLater(
        controller.toggleChecklistItem('PI4-2026-4N', 'unit-2'),
        throwsA(isA<ApiException>()),
      );
      expect(controller.isChecklistItemCompleted('PI4-2026-4N', 'unit-2'), isFalse);

      expect(
        calls.every((entry) => entry.contains('http://127.0.0.1:3001/api/student/')),
        isTrue,
      );
      expect(
        calls,
        containsAll([
          'PUT http://127.0.0.1:3001/api/student/disciplines/PI4-2026-4N/notes',
          'POST http://127.0.0.1:3001/api/student/assignments/assign-1/doubts',
          'POST http://127.0.0.1:3001/api/student/disciplines/PI4-2026-4N/forum',
          'POST http://127.0.0.1:3001/api/student/disciplines/PI4-2026-4N/forum/topic-1/reply',
        ]),
      );
    });
  });
}
