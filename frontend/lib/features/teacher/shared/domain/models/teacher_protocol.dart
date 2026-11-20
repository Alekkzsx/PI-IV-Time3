// Desenvolvido por Murillo Caravita - RA: 25014012
// Modelo de domínio para requerimentos acadêmicos das turmas do docente

enum TeacherProtocolStatus { deferido, pendente, indeferido }

class TeacherProtocol {
  final String id;
  final String code; // 'PROT - 2026/0541'
  final String studentName;
  final String studentRa;
  final String requestType;
  final String targetComponent;
  final String description;
  final TeacherProtocolStatus status;
  final String createdAt;
  final String? documentUrl;
  final String? officialResponse;

  const TeacherProtocol({
    required this.id,
    required this.code,
    required this.studentName,
    required this.studentRa,
    required this.requestType,
    required this.targetComponent,
    required this.description,
    required this.status,
    required this.createdAt,
    this.documentUrl,
    this.officialResponse,
  });

  TeacherProtocol copyWith({
    String? id,
    String? code,
    String? studentName,
    String? studentRa,
    String? requestType,
    String? targetComponent,
    String? description,
    TeacherProtocolStatus? status,
    String? createdAt,
    String? documentUrl,
    String? officialResponse,
  }) {
    return TeacherProtocol(
      id: id ?? this.id,
      code: code ?? this.code,
      studentName: studentName ?? this.studentName,
      studentRa: studentRa ?? this.studentRa,
      requestType: requestType ?? this.requestType,
      targetComponent: targetComponent ?? this.targetComponent,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      documentUrl: documentUrl ?? this.documentUrl,
      officialResponse: officialResponse ?? this.officialResponse,
    );
  }
}
