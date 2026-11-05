// Desenvolvido por Rafael Henrique dos Santos Inácio

import '../../../../core/network/authenticated_api_client.dart';
import '../models/student_models.dart' as models;
import 'dart:convert';

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
  final List<Map<String, dynamic>> forumTopics;

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
    required this.forumTopics,
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
      forumTopics: _asMaps(json['forumTopics']),
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

  Future<List<models.StudentBoletimPeriod>> getBoletim() async {
    final response = await _api.getList('/api/student/boletim');
    return response.map(models.StudentBoletimPeriod.fromJson).toList();
  }

  Future<Map<String, dynamic>> createEnrollmentDeclaration() =>
      _api.postMap('/api/student/enrollment-declaration', const {});

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

  Future<Map<String, dynamic>> postDoubt({
    required String assignmentId,
    required String question,
  }) {
    return _api.postMap(
      '/api/student/assignments/$assignmentId/doubts',
      {'question': question},
    );
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

  Future<void> markMessageRead(String id) async {
    await _api.patchMap('/api/student/messages/$id/read', const {});
  }

  Future<void> markAllRead() async {
    await _api.postMap('/api/student/messages/read-all');
  }

  Future<void> saveNote({
    required String classCode,
    required String content,
  }) async {
    await _api.putMap('/api/student/disciplines/$classCode/notes', {
      'content': content,
    });
  }

  Future<Map<String, dynamic>> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  }) {
    return _api.postMap('/api/student/disciplines/$classCode/forum', {
      'title': title,
      'body': body,
      if (category != null) 'category': category,
    });
  }

  Future<Map<String, dynamic>> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  }) {
    return _api.postMap(
      '/api/student/disciplines/$classCode/forum/$topicId/reply',
      {'body': body},
    );
  }

  Future<Map<String, dynamic>> downloadMaterial(String id) =>
      _api.getMap('/api/files/materials/$id');

  Future<Map<String, dynamic>> downloadSubmission(String id) =>
      _api.getMap('/api/files/submissions/$id');

  Future<Map<String, dynamic>> downloadProtocol(String id) =>
      _api.getMap('/api/files/protocols/$id');

  Future<StudentTimelineResponse> getTimeline() async {
    final response = await _api.getMap('/api/student/timeline');
    return StudentTimelineResponse.fromJson(response);
  }

  List<int> decodeFileContent(Map<String, dynamic> response) {
    final encoded = response['contentBase64']?.toString();
    if (encoded == null || encoded.isEmpty) {
      throw const ApiException('A API não retornou o conteúdo do arquivo.');
    }
    try {
      return base64Decode(encoded);
    } on FormatException {
      throw const ApiException('O conteúdo do arquivo está inválido.');
    }
  }
}

class StudentTimelineResponse {
  final String generatedAt;
  final List<StudentTimelineBlock> blocks;

  const StudentTimelineResponse({
    required this.generatedAt,
    required this.blocks,
  });

  factory StudentTimelineResponse.fromJson(Map<String, dynamic> json) {
    final list = json['blocks'] as List? ?? const [];
    return StudentTimelineResponse(
      generatedAt: json['generatedAt']?.toString() ?? '',
      blocks: list
          .whereType<Map>()
          .map((m) => StudentTimelineBlock.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class StudentTimelineItem {
  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final bool completed;
  final String trailingType;
  final String trailingText;

  const StudentTimelineItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.trailingType,
    required this.trailingText,
  });

  factory StudentTimelineItem.fromJson(Map<String, dynamic> json) {
    final trailing = json['trailing'] is Map
        ? Map<String, dynamic>.from(json['trailing'])
        : const <String, dynamic>{};
    return StudentTimelineItem(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'assignment',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      completed: json['completed'] == true,
      trailingType: trailing['type']?.toString() ?? 'text',
      trailingText: trailing['text']?.toString() ?? '',
    );
  }
}

class StudentTimelineBlock {
  final String type;
  final String label;
  final List<StudentTimelineItem> items;
  final bool mascot;
  final String message;
  final String description;

  const StudentTimelineBlock({
    required this.type,
    required this.label,
    this.items = const [],
    this.mascot = false,
    this.message = '',
    this.description = '',
  });

  factory StudentTimelineBlock.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? const [];
    return StudentTimelineBlock(
      type: json['type']?.toString() ?? 'day',
      label: json['label']?.toString() ?? '',
      items: itemsList
          .whereType<Map>()
          .map((m) => StudentTimelineItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      mascot: json['mascot'] == true,
      message: json['message']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
