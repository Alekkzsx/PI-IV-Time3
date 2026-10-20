// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import '../../domain/entities/academic_record_summary.dart';
import '../../domain/entities/protocol_request.dart';

/// Controlador reativo da tela de Secretaria Virtual & Requerimentos do aluno.
///
/// Gerencia os dados do Prontuário Acadêmico Regular e o histórico de
/// protocolos formais submetidos à Secretaria Acadêmica.
class StudentSecretariatController extends ChangeNotifier {
  final AcademicRecordSummary _recordSummary;
  final List<ProtocolRequest> _protocols;

  /// Cria uma instância de [StudentSecretariatController] com dados institucionais padrão.
  StudentSecretariatController({
    AcademicRecordSummary? recordSummary,
    List<ProtocolRequest>? initialProtocols,
  })  : _recordSummary = recordSummary ?? defaultRecordSummary,
        _protocols = List<ProtocolRequest>.from(
          initialProtocols ?? defaultProtocols,
        );

  /// Resumo do prontuário acadêmico regular do estudante.
  AcademicRecordSummary get recordSummary => _recordSummary;

  /// Lista imutável de protocolos de requerimento registrados.
  List<ProtocolRequest> get protocols => List.unmodifiable(_protocols);

  /// Rótulo formatado com a contagem total de requerimentos.
  String get protocolCountLabel {
    final count = _protocols.length;
    return count == 1
        ? '1 requerimento registrado'
        : '$count requerimentos registrados';
  }

  /// Registra um novo protocolo de requerimento submetido pelo aluno.
  void addProtocolRequest({
    required String subjectType,
    required String componentObject,
  }) {
    final nextNumber = 8835 + _protocols.length;
    final newProtocol = ProtocolRequest(
      protocolCode: 'PROT-2026/$nextNumber',
      submittedAt: 'Agora mesmo',
      subjectType: subjectType.trim(),
      componentObject: componentObject.trim(),
      status: ProtocolStatus.pending,
      officialOpinion:
          'Requerimento protocolado com sucesso. Sua solicitação encontra-se na fila de análise técnica da Secretaria Geral Acadêmica (prazo estimado: até 3 dias úteis).',
    );
    _protocols.insert(0, newProtocol);
    notifyListeners();
  }

  /// Prontuário padrão exibido na tela de Secretaria Virtual.
  static const AcademicRecordSummary defaultRecordSummary =
      AcademicRecordSummary(
    ra: '2024.1.00892',
    course: 'Engenharia de Software',
    academicIndex: '8.80 / 10.0',
    completedWorkload: '1480h de 3200h (46.3%)',
    activeEnrollmentBadge: 'Matrícula Vigente: 2026/2',
  );

  /// Protocolos padrão exibidos na tabela inicial da Secretaria Virtual.
  static const List<ProtocolRequest> defaultProtocols = [
    ProtocolRequest(
      protocolCode: 'PROT-2026/8835',
      submittedAt: 'Ontem, 16:20',
      subjectType: 'Horas Complementares',
      componentObject: 'Validação de Curso Extracurricular (40h)',
      status: ProtocolStatus.approved,
      officialOpinion:
          'Parecer Favorável (Deferido): Certificado autenticado eletronicamente junto à instituição emissora. Foram computadas 40 horas na categoria de Aperfeiçoamento Técnico e Extensão Universitária.',
    ),
  ];
}
