// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/features/teacher/shared/data/teacher_remote_data_source.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_event.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_profile.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_dashboard_overview.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_protocol.dart';
import 'docente_fixtures.dart';

class FakeTeacherRemoteDataSource extends TeacherRemoteDataSource {
  static List<AssignmentItem> _withCompleteRoster(
    List<AssignmentItem> assignments,
  ) {
    final sessions = DocenteFixtures.defaultSessions;
    return assignments.map((assignment) {
      final students = sessions
          .where((session) => session.courseId == assignment.courseId)
          .expand((session) => session.attendanceList)
          .fold<Map<String, AttendanceStudent>>(
            {},
            (values, student) =>
                values..putIfAbsent(student.studentId, () => student),
          )
          .values;
      final studentIds = assignment.submissions
          .map((submission) => submission.studentId)
          .toSet();
      final missing = students
          .where((student) => !studentIds.contains(student.studentId))
          .map(
            (student) => StudentSubmission(
              id: 'fixture-${assignment.id}-${student.studentId}',
              studentId: student.studentId,
              ra: student.ra,
              studentName: student.name,
              status: SubmissionStatus.naoEntregue,
            ),
          );
      return assignment.copyWith(
        submissions: [...assignment.submissions, ...missing],
      );
    }).toList();
  }

  List<DocenteCourse> courses = DocenteFixtures.initialCourses;
  List<ClassSession> sessions = DocenteFixtures.defaultSessions;
  List<AssignmentItem> assignments = _withCompleteRoster(
    DocenteFixtures.initialAssignments,
  );
  List<StudentGrade> grades = DocenteFixtures.initialGradebook
      .map((grade) => grade.copyWith(courseId: 'course-aps2'))
      .toList();
  List<AcademicEvent> events = DocenteFixtures.initialEvents;
  List<AcademicNotice> notices = DocenteFixtures.initialNotices;
  List<TeacherProtocol> protocols = DocenteFixtures.initialProtocols;
  DocenteProfile profile = DocenteFixtures.initialProfile;
  TeacherDashboardOverview dashboard = DocenteFixtures.initialDashboard;
  Map<String, Object?>? lastCreatedAssignment;
  String? lastEvaluatedSubmissionId;

  TeacherDashboardSnapshot _snapshot() => TeacherDashboardSnapshot(
    profile: profile,
    dashboard: dashboard,
    regimentalLockActive: false,
    courses: courses,
    sessions: sessions,
    assignments: assignments,
    grades: grades,
    events: events,
    notices: notices,
    protocols: protocols,
  );

  @override
  Future<TeacherDashboardSnapshot> getBootstrap() async => _snapshot();

  @override
  Future<void> updateSessionAttendance({
    required String sessionId,
    required String contentProgram,
    required String methodology,
    required String location,
    required bool isHomologated,
    required List<Map<String, Object?>> attendanceList,
  }) async {
    sessions = sessions.map((session) {
      if (session.id != sessionId) return session;
      final students = attendanceList.map((record) {
        final original = session.attendanceList.firstWhere(
          (student) => student.studentId == record['studentId'],
        );
        final statusName = record['status']?.toString();
        final status = AttendanceStatus.values.firstWhere(
          (value) => value.name == statusName,
          orElse: () => original.status,
        );
        return original.copyWith(status: status);
      }).toList();
      return session.copyWith(
        contentProgram: contentProgram,
        methodology: methodology,
        location: location,
        isHomologated: isHomologated,
        attendanceList: students,
      );
    }).toList();
  }

  @override
  Future<void> advanceSyllabus(String classCode, String unitId) async {
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(
        syllabusUnits: course.syllabusUnits.map((unit) {
          if (unit.id != unitId) return unit;
          final nextClass = unit.completedClasses + 1;
          return unit.copyWith(
            completedClasses: nextClass > unit.totalClasses
                ? unit.totalClasses
                : nextClass,
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> createOrSelectSession({
    required String classCode,
    required DateTime date,
    int hours = 2,
  }) async {
    final course = courses.firstWhere((item) => item.code == classCode);
    final courseSessions = sessions
        .where((session) => session.courseId == course.id)
        .toList();
    final template = courseSessions.first;
    final sessionDate = DateTime(date.year, date.month, date.day);
    final session = template.copyWith(
      id: 'fixture-${course.id}-${sessionDate.toIso8601String()}',
      sessionNumber: courseSessions.length + 1,
      hours: hours,
      date: sessionDate,
      dateFormatted:
          '${sessionDate.day.toString().padLeft(2, '0')}/${sessionDate.month.toString().padLeft(2, '0')}/${sessionDate.year}',
      isHomologated: false,
    );
    sessions = [...sessions, session];
    return {'sessionId': session.id};
  }

  @override
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    required String time,
    required String type,
    required String location,
  }) async {
    events = [
      AcademicEvent(
        id: 'fixture-event-${events.length + 1}',
        title: title,
        date: date,
        time: time,
        type: EventType.values.firstWhere(
          (value) => value.name == type,
          orElse: () => EventType.aula,
        ),
        location: location,
      ),
      ...events,
    ];
    return {};
  }

  @override
  Future<Map<String, dynamic>> createAssignment({
    required String classCode,
    required Map<String, Object?> assignment,
  }) async {
    lastCreatedAssignment = assignment;
    return {'id': 'fixture-assignment-${assignments.length + 1}'};
  }

  @override
  Future<Map<String, dynamic>> evaluateSubmission({
    required String assignmentId,
    required String studentId,
    required double calculatedGrade,
    required String feedback,
    required List<Map<String, Object?>> evaluatedCriteria,
  }) async {
    lastEvaluatedSubmissionId = assignmentId;
    return {};
    assignments = assignments.map((assignment) {
      if (assignment.id != assignmentId) return assignment;
      return assignment.copyWith(
        submissions: assignment.submissions.map((sub) {
          if (sub.studentId != studentId) return sub;
          return sub.copyWith(
            grade: calculatedGrade,
            status: SubmissionStatus.corrigido,
            teacherFeedback: feedback,
          );
        }).toList(),
      );
    }).toList();
    return {
      'ok': true,
      'score': calculatedGrade,
      'consolidatedStageGrade': calculatedGrade,
      'stage': 'N1',
      'gradeField': 'assignmentsScore',
    };
  }

  @override
  Future<Map<String, dynamic>> updateGrade({
    required String classCode,
    required String studentId,
    double? assignmentsScore,
    double? p1Score,
    double? projectsScore,
    double? p2Score,
  }) async {
    final courseId = courses
        .firstWhere((c) => c.code == classCode, orElse: () => DocenteCourse.empty)
        .id;
    grades = grades.map((g) {
      if ((g.courseId != courseId && g.courseId != classCode) ||
          g.studentId != studentId) {
        return g;
      }
      return g.copyWith(
        assignmentsScore: assignmentsScore ?? g.assignmentsScore,
        p1Score: p1Score ?? g.p1Score,
        projectsScore: projectsScore ?? g.projectsScore,
        p2Score: p2Score ?? g.p2Score,
        hasGrades: true,
      );
    }).toList();
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> updateGradesBatch({
    required String classCode,
    required List<Map<String, Object?>> grades,
  }) async {
    for (final entry in grades) {
      await updateGrade(
        classCode: classCode,
        studentId: entry['studentId']!.toString(),
        assignmentsScore: (entry['assignmentsScore'] as num?)?.toDouble(),
        p1Score: (entry['p1Score'] as num?)?.toDouble(),
        projectsScore: (entry['projectsScore'] as num?)?.toDouble(),
        p2Score: (entry['p2Score'] as num?)?.toDouble(),
      );
    }
    return {'ok': true, 'updatedCount': grades.length};
  }

  @override
  Future<Map<String, dynamic>> publishNotice({
    required String targetCourse,
    required String targetAudience,
    required String classification,
    required String title,
    required String message,
  }) async {
    notices = [
      AcademicNotice(
        id: 'fixture-notice-${notices.length + 1}',
        author: profile.fullName,
        targetCourse: targetCourse,
        targetAudience: targetAudience,
        classification: NoticeClassification.values.firstWhere(
          (value) => value.name == classification,
          orElse: () => NoticeClassification.informativo,
        ),
        publishedAt: 'Hoje',
        title: title,
        message: message,
        readCount: 0,
        totalRecipients: courses
            .firstWhere((course) => course.code == targetCourse)
            .enrolledCount,
      ),
      ...notices,
    ];
    return {};
  }

  @override
  Future<Map<String, dynamic>> homologate(String classCode) async => {
    'pautaHomologated': true,
    'chancelaCode': 'SIG-TEST-001',
  };

  @override
  Future<void> deleteMaterial(String classCode, String materialId) async {
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(
        materials: course.materials.where((m) => m.id != materialId).toList(),
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> downloadMaterial(String materialId) async => {
    'id': materialId,
    'fileName': 'material_teste.pdf',
    'contentBase64': '',
  };

  @override
  Future<Map<String, dynamic>> updateSyllabusPlan({
    required String classCode,
    String? syllabus,
    String? objectives,
    String? methodology,
    String? evaluationFormula,
    List<Map<String, Object?>>? bibliography,
  }) async {
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(
        syllabus: syllabus ?? course.syllabus,
        objectives: objectives ?? course.objectives,
        methodology: methodology ?? course.methodology,
        evaluationFormula: evaluationFormula ?? course.evaluationFormula,
      );
    }).toList();
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> resolveForumTopic({
    required String classCode,
    required String topicId,
    required bool isResolved,
  }) async {
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(
        forumTopics: course.forumTopics.map((topic) {
          if (topic['id']?.toString() != topicId) return topic;
          return {...topic, 'isResolved': isResolved};
        }).toList(),
      );
    }).toList();
    return {'ok': true, 'isResolved': isResolved};
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    assignments = assignments.where((a) => a.id != assignmentId).toList();
  }

  @override
  Future<Map<String, dynamic>> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  }) async {
    final topic = <String, dynamic>{
      'id': 'topic-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'category': category ?? 'Discussão Acadêmica',
      'authorName': profile.fullName,
      'authorRole': 'docente',
      'isResolved': false,
      'replies': <Map<String, dynamic>>[],
    };
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(forumTopics: [topic, ...course.forumTopics]);
    }).toList();
    return topic;
  }

  @override
  Future<Map<String, dynamic>> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  }) async {
    final reply = {
      'id': 'reply-${DateTime.now().millisecondsSinceEpoch}',
      'authorName': profile.fullName,
      'authorRole': 'docente',
      'body': body,
    };
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(
        forumTopics: course.forumTopics.map((topic) {
          if (topic['id']?.toString() != topicId) return topic;
          final existingReplies = (topic['replies'] as List?)?.toList() ?? [];
          return {
            ...topic,
            'replies': [...existingReplies, reply],
          };
        }).toList(),
      );
    }).toList();
    return reply;
  }

  @override
  Future<List<Map<String, dynamic>>> saveSquads({
    required String classCode,
    required List<Map<String, Object?>> squads,
  }) async {
    final normalized = squads.map((e) => Map<String, dynamic>.from(e)).toList();
    courses = courses.map((course) {
      if (course.code != classCode) return course;
      return course.copyWith(squads: normalized);
    }).toList();
    return normalized;
  }
}

class FakeTeacherProfileRemoteDataSource extends AuthProfileRemoteDataSource {
  FakeTeacherProfileRemoteDataSource(this.teacher);

  final FakeTeacherRemoteDataSource teacher;

  @override
  Future<void> revokeSession(String sessionId) async {
    teacher.profile = teacher.profile.copyWith(
      activeSessions: teacher.profile.activeSessions
          .where((session) => session.id != sessionId)
          .toList(),
    );
  }

  @override
  Future<void> logoutOthers() async {
    teacher.profile = teacher.profile.copyWith(
      activeSessions: teacher.profile.activeSessions
          .where((session) => session.isCurrent)
          .toList(),
    );
  }

  @override
  Future<void> toggleTwoFactor({
    required String password,
    required bool enabled,
  }) async {
    teacher.profile = teacher.profile.copyWith(twoFactorEnabled: enabled);
  }
}
