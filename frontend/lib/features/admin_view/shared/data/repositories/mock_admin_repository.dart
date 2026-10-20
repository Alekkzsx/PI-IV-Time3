// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../domain/repositories/admin_repository.dart';
import '../admin_mock_data.dart';

/// Implementação padrão local em memória do repositório da gestão do campus.
/// Permite simulação assíncrona desacoplada de rede enquanto o backend é desenvolvido.
class MockAdminRepository implements IAdminRepository {
  final List<AdminUserModel> _users = List.from(AdminMockData.users);
  final List<AdminCourseModel> _courses = List.from(AdminMockData.courses);
  final List<AdminClassModel> _classes = List.from(AdminMockData.classes);
  final List<AdminProtocolModel> _protocols = List.from(AdminMockData.protocols);
  final List<AdminAuditLogModel> _auditLogs = List.from(AdminMockData.auditLogs);

  @override
  Future<List<AdminUserModel>> getUsers() async => List.unmodifiable(_users);

  @override
  Future<List<AdminCourseModel>> getCourses() async => List.unmodifiable(_courses);

  @override
  Future<List<AdminClassModel>> getClasses() async => List.unmodifiable(_classes);

  @override
  Future<List<AdminProtocolModel>> getProtocols() async => List.unmodifiable(_protocols);

  @override
  Future<List<AdminAuditLogModel>> getAuditLogs() async => List.unmodifiable(_auditLogs);

  @override
  Future<void> addUser(AdminUserModel user) async {
    _users.insert(0, user);
  }

  @override
  Future<void> toggleUserSuspension(String userId) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final current = _users[idx];
      current.status = current.status == 'Ativo' ? 'Suspenso' : 'Ativo';
    }
  }

  @override
  Future<void> decideProtocol(String protocolId, String decision, String notes) async {
    final idx = _protocols.indexWhere((p) => p.id == protocolId);
    if (idx != -1) {
      final p = _protocols[idx];
      p.status = decision;
      p.decisionNote = notes;
    }
  }
}
