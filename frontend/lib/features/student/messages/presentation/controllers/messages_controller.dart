// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import '../../../shared/controllers/portal_controller.dart';
import '../../../shared/data/portal_remote_data_source.dart';
import '../../domain/entities/academic_message.dart';

/// [MessagesController]
///
/// Controlador de estado reativo ([ChangeNotifier]) para a Central de Mensagens discente.
/// Gerencia a lista de comunicados recebidos, filtragem por categoria (Institucional / Disciplina),
/// busca textual em tempo real e operações de marcação de mensagens lidas no servidor.
class MessagesController extends ChangeNotifier {
  final StudentRemoteDataSource _remote;
  final StudentPortalController _portalController;
  final List<AcademicMessage> _allMessages = [];
  MessageFilter _activeFilter = MessageFilter.all;
  String _searchQuery = '';

  /// Flag que indica se há requisição assíncrona de busca ou atualização em andamento.
  bool isLoading = false;

  /// Mensagem de erro capturada durante a última operação remota, se houver.
  String? error;

  /// Cria uma nova instância de [MessagesController] com injeção opcional de dependências.
  MessagesController({
    StudentRemoteDataSource? remote,
    StudentPortalController? portalController,
  }) : _remote = remote ?? StudentRemoteDataSource(),
       _portalController = portalController ?? StudentPortalController.instance;

  /// Retorna o filtro de categoria atualmente selecionado.
  MessageFilter get activeFilter => _activeFilter;

  /// Retorna o termo de busca textual digitado pelo aluno.
  String get searchQuery => _searchQuery;

  /// Retorna a lista de comunicados após aplicação do filtro de categoria e da busca textual.
  List<AcademicMessage> get filteredMessages {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _allMessages
        .where((msg) {
          final matchesCategory = switch (_activeFilter) {
            MessageFilter.all => true,
            MessageFilter.institutional =>
              msg.category == MessageCategory.institutional,
            MessageFilter.discipline =>
              msg.category == MessageCategory.discipline,
          };
          return matchesCategory &&
              (normalizedQuery.isEmpty ||
                  msg.sender.toLowerCase().contains(normalizedQuery) ||
                  msg.title.toLowerCase().contains(normalizedQuery) ||
                  msg.body.toLowerCase().contains(normalizedQuery));
        })
        .toList(growable: false);
  }

  /// Sincroniza a lista de mensagens com o servidor acadêmico via [PortalController].
  ///
  /// Executa:
  /// 1. Ativação da flag [isLoading] e limpeza de erros prévios.
  /// 2. Disparo da carga de dados remota via `loadRemote()`.
  /// 3. Conversão de cada mensagem JSON em instância de [AcademicMessage].
  /// 4. Notificação dos ouvintes da interface.
  Future<void> loadFromServer() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _portalController.loadRemote();
      _allMessages
        ..clear()
        ..addAll(_portalController.messages.map(_fromJson));
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Converte um mapa serializado em entidade [AcademicMessage] com tolerância a variações de chave.
  AcademicMessage _fromJson(Map<String, dynamic> json) {
    final categoryValue = (json['category'] ?? json['senderRole'])
        ?.toString()
        .toLowerCase();
    final category =
        categoryValue == 'discipline' ||
            categoryValue == 'aluno' ||
            categoryValue == 'docente'
        ? MessageCategory.discipline
        : MessageCategory.institutional;
    final date = (json['createdAt'] ?? json['date'] ?? '').toString();
    return AcademicMessage(
      id: (json['id'] ?? json['_id']).toString(),
      sender: (json['senderName'] ?? json['sender'] ?? 'Comunicado acadêmico')
          .toString(),
      category: category,
      isNew: json['isNew'] is bool
          ? json['isNew'] as bool
          : json['isRead'] != true && json['read'] != true,
      dateLabel: (json['dateLabel'] ?? date).toString(),
      title: (json['title'] ?? 'Comunicado').toString(),
      body: (json['content'] ?? json['body'] ?? '').toString(),
    );
  }

  /// Altera o filtro de categoria de mensagens ativo.
  ///
  /// Parâmetros:
  /// - [filter]: Novo filtro desejado ([MessageFilter]).
  void setFilter(MessageFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  /// Define o termo de busca textual e atualiza a filtragem reativa.
  ///
  /// Parâmetros:
  /// - [query]: String com o texto a buscar.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Marca uma mensagem individual como lida no servidor e atualiza o estado local.
  ///
  /// Parâmetros:
  /// - [id]: Identificador da mensagem.
  Future<void> markAsRead(String id) async {
    final index = _allMessages.indexWhere((message) => message.id == id);
    if (index < 0 || !_allMessages[index].isNew) return;
    await _remote.markMessageRead(id);
    await _portalController.loadRemote(force: true);
    await loadFromServer();
  }

  /// Marca todas as mensagens não lidas como lidas de forma atômica no backend.
  Future<void> markAllRead() async {
    await _remote.markAllRead();
    await _portalController.loadRemote(force: true);
    await loadFromServer();
  }
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentMessagesController = MessagesController;
