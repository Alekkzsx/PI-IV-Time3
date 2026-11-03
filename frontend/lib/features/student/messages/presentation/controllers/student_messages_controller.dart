import 'package:flutter/foundation.dart';
import '../../../shared/controllers/student_portal_controller.dart';
import '../../../shared/data/student_remote_data_source.dart';
import '../../domain/entities/academic_message.dart';

class StudentMessagesController extends ChangeNotifier {
  final StudentRemoteDataSource _remote;
  final List<AcademicMessage> _allMessages = [];
  MessageFilter _activeFilter = MessageFilter.all;
  String _searchQuery = '';
  bool isLoading = false;
  String? error;

  StudentMessagesController({StudentRemoteDataSource? remote})
    : _remote = remote ?? StudentRemoteDataSource() {
    loadFromServer();
  }

  MessageFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

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
      return matchesCategory &&
          (normalizedQuery.isEmpty ||
              msg.sender.toLowerCase().contains(normalizedQuery) ||
              msg.title.toLowerCase().contains(normalizedQuery) ||
              msg.body.toLowerCase().contains(normalizedQuery));
    }).toList(growable: false);
  }

  Future<void> loadFromServer() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await StudentPortalController.instance.loadRemote();
      _allMessages
        ..clear()
        ..addAll(
          StudentPortalController.instance.messages.map(_fromJson),
        );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  AcademicMessage _fromJson(Map<String, dynamic> json) {
    final categoryValue =
        (json['category'] ?? json['senderRole'])?.toString().toLowerCase();
    final category = categoryValue == 'discipline' ||
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

  void setFilter(MessageFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _allMessages.indexWhere((message) => message.id == id);
    if (index < 0 || !_allMessages[index].isNew) return;
    await _remote.markMessageRead(id);
    await StudentPortalController.instance.loadRemote(force: true);
    await loadFromServer();
  }

  Future<void> markAllRead() async {
    await _remote.markAllRead();
    await StudentPortalController.instance.loadRemote(force: true);
    await loadFromServer();
  }
}
