// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/foundation.dart';
import '../../../../../core/state/academic_bridge_service.dart';
import '../../../../../core/state/app_user_session.dart';
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
  }) : _recordSummary = recordSummary ?? defaultRecordSummary,
       _protocols = List<ProtocolRequest>.from(
         initialProtocols ?? defaultProtocols,
       ) {
    // Escuta despachos e pareceres oficiais emitidos pela Secretaria Geral (Admin)
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

  /// Rótulo formatado com a contagem total de requerimentos.
  String get protocolCountLabel {
    final count = _protocols.length;
    return count == 1
        ? '1 requerimento registrado'
        : '$count requerimentos registrados';
  }

  /// Lista pré-configurada de tipos de requerimento acadêmico.
  static const List<String> availableRequestTypes = [
    '2ª Chamada de Avaliação / Prova Substitutiva',
    'Horas Complementares',
    'Revisão de Nota / Menção Final',
    'Declaração ou Histórico Personalizado',
    'Trancamento de Matrícula ou Disciplina',
    'Regime Domiciliar / Licença Médica Especial',
  ];

  /// Lista pré-configurada de componentes curriculares e objetos padrão.
  static const List<String> availableCurricularObjects = [
    '218131 - APS-II (Análise e Projeto de Sistemas II) - Profa. Helena Bittencourt',
    '218132 - Banco de Dados Avançado - Prof. Roberto Tanaka',
    '218133 - Engenharia de Requisitos - Profa. Marina Silva',
    '218134 - Sistemas Distribuídos e Cloud - Prof. Carlos Mendes',
    'Validação de Curso Extracurricular (40h)',
    'Atividades Complementares e Extensão Universitária',
  ];

  /// Registra um novo protocolo de requerimento submetido pelo aluno.
  void addProtocolRequest({
    required String subjectType,
    required String componentObject,
    String justification = '',
    String? attachmentName,
  }) {
    if (!AppUserSession.instance.hasPermission('submit_protocols')) {
      debugPrint(
        '[StudentSecretariat] Abertura de protocolo negada para o perfil atual.',
      );
      return;
    }
    final nextNumber = 8835 + _protocols.length;
    final newProtocol = ProtocolRequest(
      protocolCode: 'PROT-2026/$nextNumber',
      submittedAt: 'Hoje, agora há pouco',
      subjectType: subjectType.trim(),
      componentObject: componentObject.trim(),
      justification: justification.trim().isEmpty
          ? 'Requerimento acadêmico formal cadastrado pelo portal do aluno.'
          : justification.trim(),
      attachmentName: attachmentName,
      status: ProtocolStatus.pending,
      officialOpinion:
          'Requerimento protocolado com sucesso. Sua solicitação encontra-se na fila de análise técnica e documental da Secretaria Geral Acadêmica (prazo estimado de resolução: até 3 dias úteis).',
      approverName: 'Fila de Análise — Secretaria Acadêmica Central',
      responseDate: 'Aguardando Despacho',
    );
    _protocols.insert(0, newProtocol);

    // Encaminha imediatamente para a Mesa da Secretaria Central do Administrador
    AcademicBridgeService.instance.submitProtocolFromStudent(
      protocolCode: newProtocol.protocolCode,
      studentName: 'Gabriel Soares de Oliveira',
      studentRa: '2024.1.00892',
      studentCourse: 'Engenharia de Software (5º Semestre)',
      subjectType: subjectType.trim(),
      justification: newProtocol.justification,
      attachmentName: attachmentName,
    );

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
      justification:
          'Submissão do certificado do curso avançado de Arquitetura em Nuvem e Microsserviços (40 horas), concluído na plataforma Alura com aprovação no exame de certificação.',
      attachmentName: 'Certificado_Cloud_Microsservicos_40h.pdf',
      officialOpinion:
          'Parecer Favorável (Deferido): O certificado anexado foi verificado e validado com autenticidade eletrônica comprovada. Foram homologadas 40 horas na categoria de Aperfeiçoamento Técnico e Extensão Universitária, integrando a carga horária complementar do curso.',
      approverName: 'Coordenação de Curso — Engenharia de Software',
      responseDate: '22/10/2026 às 18:30',
    ),
  ];
}
