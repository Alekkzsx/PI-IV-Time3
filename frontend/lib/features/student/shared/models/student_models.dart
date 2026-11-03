// Modelos de domínio reais do Portal do Aluno (alimentados pela API e MongoDB).

class StudentMaterialItem {
  final String id;
  final String courseCode;
  final String title;
  final String fileName;
  final String date;
  final String size;
  final String fileType;
  final String unitAssociated;
  final String downloadUrl;

  const StudentMaterialItem({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.fileName,
    required this.date,
    required this.size,
    required this.fileType,
    this.unitAssociated = 'Unidade 1',
    this.downloadUrl = '',
  });

  factory StudentMaterialItem.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    return StudentMaterialItem(
      id: id,
      courseCode: json['courseCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      fileType:
          (json['fileType'] ?? json['type'])?.toString().toUpperCase() ?? 'PDF',
      unitAssociated: json['unitAssociated']?.toString() ?? '',
      downloadUrl:
          json['downloadUrl']?.toString() ??
          (id.isNotEmpty ? '/api/files/materials/$id' : ''),
    );
  }
}

class StudentForumReply {
  final String id;
  final String authorName;
  final String authorRole;
  final String body;
  final String date;

  const StudentForumReply({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.date,
  });

  factory StudentForumReply.fromJson(Map<String, dynamic> json) {
    return StudentForumReply(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? 'aluno',
      body: (json['body'] ?? json['content'])?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

class StudentForumTopic {
  final String id;
  final String classCode;
  final String title;
  final String body;
  final String category;
  final String authorName;
  final String authorRole;
  final String date;
  final bool isPinned;
  final List<StudentForumReply> replies;

  const StudentForumTopic({
    required this.id,
    required this.classCode,
    required this.title,
    required this.body,
    this.category = 'Geral',
    required this.authorName,
    this.authorRole = 'aluno',
    required this.date,
    this.isPinned = false,
    this.replies = const [],
  });

  factory StudentForumTopic.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];
    return StudentForumTopic(
      id: json['id']?.toString() ?? '',
      classCode: json['classCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: (json['body'] ?? json['content'])?.toString() ?? '',
      category: json['category']?.toString() ?? 'Geral',
      authorName: json['authorName']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isPinned: json['isPinned'] == true,
      replies: rawReplies is List
          ? rawReplies
                .whereType<Map>()
                .map(
                  (e) =>
                      StudentForumReply.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class StudentDisciplineModel {
  final String code;
  final String roomCode;
  final String name;
  final String professor;
  final String schedule;
  final String time;
  final String location;
  final String roomStatus;
  final bool isLive;
  final double progress;
  final double n1;
  final double n2;
  final double p1;
  final double p2;
  final double trab;
  final double partialAverage;
  final double attendancePercentage;
  final int absences;
  final int totalHours;
  final int completedHours;
  final String? fullCode;
  final bool hasPendingTask;
  final int maxAbsenceHours;
  final String evaluationFormula;
  final String semester;
  final bool isLab;
  final List<Map<String, dynamic>> syllabusUnits;
  final List<Map<String, dynamic>> squads;
  final List<StudentMaterialItem> materials;

  const StudentDisciplineModel({
    required this.code,
    String? roomCode,
    required this.name,
    required this.professor,
    String? schedule,
    required this.time,
    required this.location,
    this.roomStatus = 'Sala Fechada',
    this.isLive = false,
    required this.progress,
    required this.n1,
    required this.n2,
    required this.p1,
    required this.p2,
    required this.trab,
    required this.partialAverage,
    required this.attendancePercentage,
    required this.absences,
    required this.totalHours,
    required this.completedHours,
    this.fullCode,
    this.hasPendingTask = false,
    this.maxAbsenceHours = 20,
    this.evaluationFormula = '(N1 × 0.4) + (N2 × 0.6)',
    this.semester = '',
    this.isLab = false,
    this.syllabusUnits = const [],
    this.squads = const [],
    this.materials = const [],
  }) : roomCode = roomCode ?? code,
       schedule = schedule ?? time;

  factory StudentDisciplineModel.fromJson(Map<String, dynamic> json) {
    double numOrZero(Object? v) =>
        v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    int intOrZero(Object? v) =>
        v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

    final code = json['code']?.toString() ?? '';
    final rawMats = json['materials'];
    final rawUnits = json['syllabusUnits'];
    final rawSquads = json['squads'];

    return StudentDisciplineModel(
      code: code,
      roomCode: json['roomCode']?.toString() ?? code,
      fullCode: json['fullCode']?.toString() ?? code,
      name: json['name']?.toString() ?? code,
      professor: json['professor']?.toString() ?? '',
      schedule: json['schedule']?.toString() ?? json['time']?.toString() ?? '',
      time: json['time']?.toString() ?? json['schedule']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      roomStatus:
          json['roomStatus']?.toString() ??
          (json['isLive'] == true ? 'Ao Vivo' : 'Sala Fechada'),
      isLive: json['isLive'] == true,
      progress: numOrZero(json['progress']),
      n1: numOrZero(json['n1']),
      n2: numOrZero(json['n2']),
      p1: numOrZero(json['p1']),
      p2: numOrZero(json['p2']),
      trab: numOrZero(json['trab']),
      partialAverage: numOrZero(json['partialAverage']),
      attendancePercentage: json['attendancePercentage'] == null
          ? 0.0
          : numOrZero(json['attendancePercentage']),
      absences: intOrZero(json['absences']),
      totalHours: intOrZero(json['totalHours']),
      completedHours: intOrZero(json['completedHours']),
      maxAbsenceHours: intOrZero(json['maxAbsenceHours']),
      hasPendingTask: json['hasPendingTask'] == true,
      evaluationFormula:
          json['evaluationFormula']?.toString() ?? '(N1 × 0.4) + (N2 × 0.6)',
      semester: json['semester']?.toString() ?? '',
      isLab: json['isLab'] == true,
      syllabusUnits: rawUnits is List
          ? rawUnits
                .whereType<Map>()
                .map((u) => Map<String, dynamic>.from(u))
                .toList()
          : const [],
      squads: rawSquads is List
          ? rawSquads
                .whereType<Map>()
                .map((s) => Map<String, dynamic>.from(s))
                .toList()
          : const [],
      materials: rawMats is List
          ? rawMats
                .whereType<Map>()
                .map(
                  (m) => StudentMaterialItem.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList()
          : const [],
    );
  }

  StudentDisciplineModel copyWith({
    bool? isLive,
    String? roomStatus,
    List<StudentMaterialItem>? materials,
  }) {
    return StudentDisciplineModel(
      code: code,
      roomCode: roomCode,
      fullCode: fullCode,
      name: name,
      professor: professor,
      schedule: schedule,
      time: time,
      location: location,
      roomStatus: roomStatus ?? this.roomStatus,
      isLive: isLive ?? this.isLive,
      progress: progress,
      n1: n1,
      n2: n2,
      p1: p1,
      p2: p2,
      trab: trab,
      partialAverage: partialAverage,
      attendancePercentage: attendancePercentage,
      absences: absences,
      totalHours: totalHours,
      completedHours: completedHours,
      hasPendingTask: hasPendingTask,
      maxAbsenceHours: maxAbsenceHours,
      evaluationFormula: evaluationFormula,
      semester: semester,
      isLab: isLab,
      syllabusUnits: syllabusUnits,
      squads: squads,
      materials: materials ?? this.materials,
    );
  }
}

class StudentDoubtItem {
  final String id;
  final String studentName;
  final String question;
  final String askedAt;
  final String? reply;
  final String? repliedAt;

  const StudentDoubtItem({
    required this.id,
    required this.studentName,
    required this.question,
    required this.askedAt,
    this.reply,
    this.repliedAt,
  });

  factory StudentDoubtItem.fromJson(Map<String, dynamic> json) {
    return StudentDoubtItem(
      id: json['id']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      askedAt: json['askedAt']?.toString() ?? '',
      reply: json['reply']?.toString(),
      repliedAt: json['repliedAt']?.toString(),
    );
  }
}

class StudentDeliveryItem {
  final String id;
  final String? sourceAssignmentId;
  final String title;
  final String disciplineCode;
  final String disciplineName;
  final String dueDate;
  final String dueHour;
  final String status; // 'Pendente', 'Em Análise', 'Avaliada'
  final double weight;
  final double? score;
  final String? feedback;
  final String? protocol;
  final String? sha256;
  final String? fileName;
  final String? fileSize;
  final String? gitUrl;
  final String? comments;
  final String? submissionId;
  final List<Map<String, dynamic>> rubrics;
  final List<StudentDoubtItem> doubts;
  final String? activityCode;
  final String? description;
  final String? professor;
  final String? deadlineBadge;
  final bool isUrgent;
  final String? allowedFormats;
  final String? submissionDate;
  final String? feedbackDate;
  final double maxScore;
  final int attachmentCount;

  const StudentDeliveryItem({
    required this.id,
    this.sourceAssignmentId,
    required this.title,
    required this.disciplineCode,
    required this.disciplineName,
    required this.dueDate,
    required this.dueHour,
    required this.status,
    required this.weight,
    this.score,
    this.feedback,
    this.protocol,
    this.sha256,
    this.fileName,
    this.fileSize,
    this.gitUrl,
    this.comments,
    this.submissionId,
    this.rubrics = const [],
    this.doubts = const [],
    this.activityCode,
    this.description,
    this.professor,
    this.deadlineBadge,
    this.isUrgent = false,
    this.allowedFormats,
    this.submissionDate,
    this.feedbackDate,
    this.maxScore = 0,
    this.attachmentCount = 0,
  });

  factory StudentDeliveryItem.fromJson(Map<String, dynamic> json) {
    final rawRubrics = json['rubrics'];
    final rawDoubts = json['doubts'];
    return StudentDeliveryItem(
      id: json['id']?.toString() ?? '',
      sourceAssignmentId:
          json['sourceAssignmentId']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      disciplineCode: json['disciplineCode']?.toString() ?? '',
      disciplineName: json['disciplineName']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      dueHour: json['dueHour']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      weight: json['weight'] is num ? (json['weight'] as num).toDouble() : 0,
      score: json['score'] is num ? (json['score'] as num).toDouble() : null,
      feedback: json['feedback']?.toString(),
      protocol: json['protocol']?.toString(),
      sha256: json['sha256']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize']?.toString(),
      gitUrl: json['gitUrl']?.toString(),
      comments: json['comments']?.toString(),
      submissionId: json['submissionId']?.toString(),
      rubrics: rawRubrics is List
          ? rawRubrics
                .whereType<Map>()
                .map((r) => Map<String, dynamic>.from(r))
                .toList()
          : const [],
      doubts: rawDoubts is List
          ? rawDoubts
                .whereType<Map>()
                .map(
                  (d) =>
                      StudentDoubtItem.fromJson(Map<String, dynamic>.from(d)),
                )
                .toList()
          : const [],
      activityCode: json['activityCode']?.toString(),
      description: json['description']?.toString(),
      professor: json['professor']?.toString(),
      deadlineBadge: json['deadlineBadge']?.toString(),
      isUrgent: json['isUrgent'] == true,
      allowedFormats: json['allowedFormats']?.toString(),
      submissionDate: json['submissionDate']?.toString(),
      feedbackDate: json['feedbackDate']?.toString(),
      maxScore: json['maxScore'] is num
          ? (json['maxScore'] as num).toDouble()
          : 0.0,
      attachmentCount: json['attachmentCount'] is num
          ? (json['attachmentCount'] as num).toInt()
          : 0,
    );
  }
}

class StudentCalendarEvent {
  final String id;
  final String title;
  final String date;
  final String time;
  final String type;
  final String discipline;
  final String location;

  const StudentCalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    required this.discipline,
    required this.location,
  });

  factory StudentCalendarEvent.fromJson(Map<String, dynamic> json) {
    return StudentCalendarEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: (json['time'] ?? json['timeRange'])?.toString() ?? '',
      type: (json['type'] ?? json['category'])?.toString() ?? '',
      discipline: (json['discipline'] ?? json['courseCode'])?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }
}

class StudentBoletimPeriod {
  final String period;
  final List<Map<String, dynamic>> items;

  const StudentBoletimPeriod({required this.period, required this.items});

  factory StudentBoletimPeriod.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return StudentBoletimPeriod(
      period: json['period']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const [],
    );
  }
}
