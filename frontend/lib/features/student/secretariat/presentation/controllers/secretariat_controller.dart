// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/foundation.dart';
import '../../../../../core/network/authenticated_api_client.dart';
import '../../../../../core/state/app_user_session.dart';
import '../../../../../core/state/academic_bridge_service.dart';
import '../../../shared/controllers/portal_controller.dart';
import '../../../shared/data/portal_remote_data_source.dart';
import '../../domain/entities/academic_record_summary.dart';
import '../../domain/entities/protocol_request.dart';

/// [SecretariatController]
///
/// Controlador de estado reativo ([ChangeNotifier]) da Secretaria Virtual do discente.
/// Gerencia os dados do Prontuário Acadêmico Regular, a listagem e submissão de protocolos formais,
/// a escuta reativa de despachos e pareceres homologados pelo módulo administrativo
/// via [AcademicBridgeService] e a emissão de declarações digitais de matrícula.
class SecretariatController extends ChangeNotifier {
  AcademicRecordSummary _recordSummary;
  final List<ProtocolRequest> _protocols;
  final StudentRemoteDataSource _remote;
  final StudentPortalController _portalController;

  /// Cria uma nova instância de [SecretariatController] com injeção opcional de fontes remotas.
  SecretariatController({
    AcademicRecordSummary? recordSummary,
    List<ProtocolRequest>? initialProtocols,
    StudentRemoteDataSource? remoteDataSource,
    StudentPortalController? portalController,
  }) : _recordSummary = recordSummary ?? emptyRecordSummary,
       _protocols = List<ProtocolRequest>.from(initialProtocols ?? const []),
       _remote = remoteDataSource ?? StudentRemoteDataSource(),
       _portalController =
           portalController ?? StudentPortalController.instance {
    AcademicBridgeService.instance.onStudentProtocolUpdated =
        (protocolCode, isApproved, officialNote, approverName) {
          final index = _protocols.indexWhere(
            (p) => p.protocolCode == protocolCode,
          );
          if (index != -1) {
            final old = _protocols[index];
            _protocols[index] = ProtocolRequest(
              protocolCode: old.protocolCode,
              submittedAt: old.submittedAt,
              subjectType: old.subjectType,
              componentObject: old.componentObject,
              justification: old.justification,
              attachmentName: old.attachmentName,
              status: isApproved
                  ? ProtocolStatus.approved
                  : ProtocolStatus.rejected,
              officialOpinion: officialNote,
              approverName: approverName,
              responseDate:
                  'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            );
            notifyListeners();
          }
        };
  }

  /// Resumo do prontuário acadêmico regular do estudante.
  AcademicRecordSummary get recordSummary => _recordSummary;

  /// Lista imutável de protocolos de requerimento registrados.
  List<ProtocolRequest> get protocols => List.unmodifiable(_protocols);

  /// Sincroniza o prontuário e os protocolos com a API do servidor acadêmico.
  ///
  /// Executa:
  /// 1. Chamada forçada ao endpoint de bootstrap discente via [PortalController].
  /// 2. Atualização dos campos de curso, RA, CR e horas integralizadas em [AcademicRecordSummary].
  /// 3. Conversão tipada de cada protocolo retornado pelo backend.
  /// 4. Notificação dos ouvintes da interface.
  Future<void> loadFromServer() async {
    final portal = _portalController;
    await portal.loadRemote(force: true);
    final snapshot = portal.remoteDashboard;
    if (snapshot == null) return;

    final summary = snapshot.recordSummary;
    _recordSummary = AcademicRecordSummary(
      ra:
          summary['ra']?.toString() ??
          snapshot.studentInfo['ra']?.toString() ??
          '',
      course:
          summary['course']?.toString() ??
          snapshot.studentInfo['courseName']?.toString() ??
          '',
      academicIndex: summary['academicIndex']?.toString() ?? '—',
      completedWorkload: summary['completedWorkload']?.toString() ?? '—',
      activeEnrollmentBadge: summary['activeEnrollmentBadge']?.toString() ?? '',
    );
    _protocols
      ..clear()
      ..addAll(snapshot.protocols.map(_protocolFromJson));
    notifyListeners();
  }

  /// Converte um mapa serializado em entidade tipada [ProtocolRequest].
  static ProtocolRequest _protocolFromJson(Map<String, dynamic> json) {
    final status = switch (json['status']?.toString().toLowerCase()) {
      'approved' || 'deferido' => ProtocolStatus.approved,
      'rejected' || 'indeferido' => ProtocolStatus.rejected,
      _ => ProtocolStatus.pending,
    };
    return ProtocolRequest(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      protocolCode: (json['protocolCode'] ?? json['code'] ?? json['id'])
          .toString(),
      submittedAt: (json['submittedAt'] ?? json['createdAt'] ?? '').toString(),
      subjectType: (json['subjectType'] ?? json['requestType'] ?? '')
          .toString(),
      componentObject:
          (json['componentObject'] ?? json['targetComponent'] ?? '').toString(),
      status: status,
      officialOpinion:
          (json['officialOpinion'] ??
                  json['decisionNote'] ??
                  'Aguardando análise da Secretaria Acadêmica.')
              .toString(),
      justification: json['justification']?.toString() ?? '',
      attachmentName: json['attachmentName']?.toString(),
      approverName: (json['approverName'] ?? json['signedBy'])?.toString(),
      responseDate: (json['responseDate'] ?? json['decidedAt'])?.toString(),
    );
  }

  /// Rótulo formatado com a contagem total de requerimentos cadastrados.
  String get protocolCountLabel {
    final count = _protocols.length;
    return count == 1
        ? '1 requerimento registrado'
        : '$count requerimentos registrados';
  }

  /// Lista pré-configurada com as categorias oficiais de requerimento acadêmico.
  static const List<String> availableRequestTypes = [
    '2ª Chamada de Avaliação / Prova Substitutiva',
    'Horas Complementares',
    'Revisão de Nota / Menção Final',
    'Declaração ou Histórico Personalizado',
    'Trancamento de Matrícula ou Disciplina',
    'Regime Domiciliar / Licença Médica Especial',
  ];

  /// Lista de componentes curriculares disponíveis para associação ao requerimento.
  List<String> get availableCurricularObjects => [
    'Geral',
    ...StudentPortalController.instance.disciplines.map(
      (discipline) => '${discipline.code} - ${discipline.name}',
    ),
    'Atividades Complementares e Extensão Universitária',
  ];

  /// Submete um novo requerimento formal na Secretaria Acadêmica.
  ///
  /// Parâmetros:
  /// - [subjectType]: Assunto ou categoria do pedido.
  /// - [componentObject]: Disciplina ou setor acadêmico de destino.
  /// - [justification]: Justificativa circunstanciada do pedido.
  /// - [attachmentName]: Nome do documento comprobatório anexo.
  /// - [attachmentBase64]: Conteúdo em Base64 do anexo comprobatório.
  Future<void> addProtocolRequest({
    required String subjectType,
    required String componentObject,
    String justification = '',
    String? attachmentName,
    String? attachmentBase64,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem abrir requerimentos.');
    }
    await _remote.submitProtocol(
      requestType: subjectType.trim(),
      targetComponent: componentObject.trim(),
      justification: justification.trim(),
      attachmentName: attachmentName,
      attachmentBase64: attachmentBase64,
    );
    await loadFromServer();
  }

  /// Requisita ao backend a emissão imediata de uma declaração digital de matrícula.
  ///
  /// Retorna um mapa contendo os metadados do documento emitido e o hash de autenticação.
  Future<Map<String, dynamic>> issueEnrollmentDeclaration() async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem emitir declarações.');
    }

    return _remote.createEnrollmentDeclaration();
  }

  /// Realiza o download dos documentos probatórios anexados a um protocolo específico.
  Future<String?> downloadProtocol(String id) =>
      _portalController.downloadProtocol(id);

  /// Prontuário padrão vazio utilizado antes da conclusão da carga inicial.
  static const AcademicRecordSummary emptyRecordSummary = AcademicRecordSummary(
    ra: '',
    course: '',
    academicIndex: '—',
    completedWorkload: '—',
    activeEnrollmentBadge: '',
  );
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentSecretariatController = SecretariatController;
