// Desenvolvido por Rafael Henrique dos Santos Inácio

import '../../../../core/network/authenticated_api_client.dart';
import '../models/student_models.dart' as models;

class StudentDashboardSnapshot {
  final Map<String, dynamic> studentInfo;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> recordSummary;
  final Map<String, dynamic>? todayClass;
  final Map<String, dynamic>? freeSchedule;
  final List<models.StudentDisciplineModel> disciplines;
  final List<models.StudentDeliveryItem> deliveries;
  final List<models.StudentCalendarEvent> events;
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic> personalNotes;
  final List<Map<String, dynamic>> protocols;

  const StudentDashboardSnapshot({
    required this.studentInfo,
    required this.stats,
    required this.recordSummary,
    required this.todayClass,
    required this.freeSchedule,
    required this.disciplines,
    required this.deliveries,
    required this.events,
    required this.messages,
    required this.personalNotes,
    required this.protocols,
  });

  factory StudentDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final studentInfo = _asMap(json['studentInfo']);
    final stats = _asMap(json['stats']);
    if (studentInfo.isEmpty || stats.isEmpty) {
      throw const ApiException('A API retornou um painel acadêmico incompleto.');
    }

    return StudentDashboardSnapshot(
      studentInfo: studentInfo,
      stats: stats,
      recordSummary: _asMap(json['recordSummary']),
      todayClass: json['todayClass'] is Map
          ? _asMap(json['todayClass'])
          : null,
        freeSchedule: json['freeSchedule'] is Map
          ? _asMap(json['freeSchedule'])
          : null,
      disciplines: _asMaps(json['disciplines'])
          .map(models.StudentDisciplineModel.fromJson)
          .toList(),
      deliveries: _asMaps(json['deliveries'])
          .map(models.StudentDeliveryItem.fromJson)
          .toList(),
      events: _asMaps(json['events'])
          .map(models.StudentCalendarEvent.fromJson)
          .toList(),
      messages: _asMaps(json['messages']),
      personalNotes: _asMap(json['personalNotes']),
      protocols: _asMaps(json['protocols']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(_asMap).toList();
  }
}

class StudentRemoteDataSource {
  final AuthenticatedApiClient _api;

  StudentRemoteDataSource({AuthenticatedApiClient? api})
    : _api = api ?? AuthenticatedApiClient();

  Future<StudentDashboardSnapshot> getBootstrap() async {
    final response = await _api.getMap('/api/student/bootstrap');
    return StudentDashboardSnapshot.fromJson(response);
  }

  Future<Map<String, dynamic>> submitDelivery({
    required String assignmentId,
    required String fileName,
    required String fileSize,
    required String mimeType,
    required String contentBase64,
    String? gitUrl,
    String? comments,
  }) {
    return _api.postMap('/api/student/deliveries/$assignmentId/submit', {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'contentBase64': contentBase64,
      if (gitUrl != null) 'gitUrl': gitUrl,
      if (comments != null) 'comments': comments,
    });
  }

  Future<Map<String, dynamic>> addReminder({
    required String title,
    required String date,
    required String timeRange,
    required String courseCode,
    required String location,
  }) {
    return _api.postMap('/api/student/calendar/reminders', {
      'title': title,
      'date': date,
      'timeRange': timeRange,
      'courseCode': courseCode,
      'location': location,
    });
  }

  Future<Map<String, dynamic>> submitProtocol({
    required String requestType,
    required String targetComponent,
    required String justification,
    String? attachmentName,
    String? attachmentBase64,
  }) {
    return _api.postMap('/api/student/protocols', {
      'requestType': requestType,
      'targetComponent': targetComponent,
      'justification': justification,
      if (attachmentName != null) 'attachmentName': attachmentName,
      if (attachmentBase64 != null) 'attachmentBase64': attachmentBase64,
    });
  }
}