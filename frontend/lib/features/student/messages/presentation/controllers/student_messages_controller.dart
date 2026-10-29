// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/foundation.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import '../../domain/entities/academic_message.dart';

/// Controlador reativo de estado da tela de Mensagens e Comunicados do aluno.
///
/// Gerencia a filtragem por categoria ([activeFilter]), a busca textual por termo
/// ou docente ([searchQuery]) e a marcação de leitura de comunicados.
class StudentMessagesController extends ChangeNotifier {
  final List<AcademicMessage> _allMessages;
  MessageFilter _activeFilter = MessageFilter.all;
  String _searchQuery = '';

  /// Cria uma instância de [StudentMessagesController] inicializando os comunicados oficiais.
  StudentMessagesController({List<AcademicMessage>? initialMessages})
      : _allMessages = List<AcademicMessage>.from(
          initialMessages ?? defaultMessages,
        ) {
    _syncBridgeNotices();
    AcademicBridgeService.instance.onNoticeBroadcasted = _onNoticeReceived;
  }

  void _syncBridgeNotices() {
    for (final n in AcademicBridgeService.instance.broadcastNotices.reversed) {
      _insertNoticeIfAbsent(n);
    }
  }

  void _onNoticeReceived(Map<String, dynamic> notice) {
    _insertNoticeIfAbsent(notice);
    notifyListeners();
  }

  void _insertNoticeIfAbsent(Map<String, dynamic> n) {
    final id = n['id'] as String? ?? 'msg-${n.hashCode}';
    if (_allMessages.any((m) => m.id == id)) return;
    _allMessages.insert(
      0,
      AcademicMessage(
        id: id,
        sender: n['senderName'] as String? ?? 'Coordenação Institucional',
        category: n['senderRole'] == 'admin'
            ? MessageCategory.institutional
            : MessageCategory.discipline,
        isNew: true,
        dateLabel: 'Hoje',
        title: n['title'] as String? ?? 'Comunicado',
        body: n['content'] as String? ?? '',
      ),
    );
  }

  /// Filtro de categoria atualmente ativo.
  MessageFilter get activeFilter => _activeFilter;

  /// Termo de busca textual atualmente aplicado.
  String get searchQuery => _searchQuery;

  /// Lista de comunicados filtrados conforme [activeFilter] e [searchQuery].
  List<AcademicMessage> get filteredMessages {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return _allMessages.where((msg) {
      final matchesCategory = switch (_activeFilter) {
        MessageFilter.all => true,
        MessageFilter.institutional =>
          msg.category == MessageCategory.institutional,
        MessageFilter.discipline =>
          msg.category == MessageCategory.discipline,
      };

      if (!matchesCategory) return false;
      if (normalizedQuery.isEmpty) return true;

      return msg.sender.toLowerCase().contains(normalizedQuery) ||
          msg.title.toLowerCase().contains(normalizedQuery) ||
          msg.body.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }

  /// Altera a aba de filtro ativa e notifica os ouvintes da tela.
  void setFilter(MessageFilter filter) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      notifyListeners();
    }
  }

  /// Atualiza o termo de busca textual e notifica os ouvintes da tela.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Marca um comunicado específico como lido (remove o selo 'Novo').
  void markAsRead(String id) {
    final index = _allMessages.indexWhere((m) => m.id == id);
    if (index != -1 && _allMessages[index].isNew) {
      _allMessages[index] = _allMessages[index].copyWith(isNew: false);
      notifyListeners();
    }
  }

  /// Conjunto padrão de comunicados institucionais e acadêmicos da tela do aluno.
  static const List<AcademicMessage> defaultMessages = [
    AcademicMessage(
      id: 'msg-01',
      sender: 'Secretaria Geral Acadêmica (ADM-00129)',
      category: MessageCategory.institutional,
      isNew: true,
      dateLabel: '18/09/2026',
      title: 'Período Oficial de Validação de Atividades Complementares 2026/2',
      body:
          'A Secretaria Geral Acadêmica informa que o prazo para submissão de certificados e cursos de extensão para cômputo de horas complementares encerra-se em 30 de novembro.',
    ),
    AcademicMessage(
      id: 'msg-02',
      sender: 'Diretoria de Tecnologia e Informação (DTI)',
      category: MessageCategory.institutional,
      isNew: true,
      dateLabel: '15/09/2026',
      title: 'Manutenção Preventiva dos Ambientes Virtuais de Aprendizagem',
      body:
          'No próximo sábado, das 02:00 às 05:00, os servidores de banco de dados do AVA passarão por otimização técnica. Não haverá impacto nas entregas programadas.',
    ),
    AcademicMessage(
      id: 'msg-03',
      sender: 'Prof. Carlos Eduardo (APS-II)',
      category: MessageCategory.discipline,
      isNew: true,
      dateLabel: 'Hoje, 14:10',
      title: 'Feedback da Sprint 1 e Orientações para o Diagrama UML',
      body:
          'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
    ),
    AcademicMessage(
      id: 'msg-04',
      sender: 'Profª. Eliane Ramos (BD-II)',
      category: MessageCategory.discipline,
      isNew: true,
      dateLabel: 'Ontem, 17:45',
      title: 'Material de Apoio: Normalização em 3FN e BCNF',
      body:
          'Disponibilizei os slides com os exercícios resolvidos em aula sobre dependências funcionais e índices.',
    ),
    AcademicMessage(
      id: 'msg-05',
      sender: 'Secretaria Acadêmica AGMRM',
      category: MessageCategory.discipline,
      isNew: false,
      dateLabel: '18 de set',
      title: 'Prazo para Validação de Atividades Complementares 2026/2',
      body:
          'Lembramos a todos os estudantes que o envio de certificados de cursos e palestras para cômputo de horas complementares segue até o dia 30/11.',
    ),
  ];
}
