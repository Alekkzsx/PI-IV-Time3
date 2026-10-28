// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import '../../data/admin_mock_data.dart';

/// Contrato abstrato do repositório da gestão do campus e secretaria geral.
/// Prepara o ecossistema frontend para receber a injeção do cliente HTTP/REST do backend.
abstract class IAdminRepository {
  Future<List<AdminUserModel>> getUsers();
  Future<List<AdminCourseModel>> getCourses();
  Future<List<AdminClassModel>> getClasses();
  Future<List<AdminProtocolModel>> getProtocols();
  Future<List<AdminAuditLogModel>> getAuditLogs();
  Future<void> addUser(AdminUserModel user);
  Future<void> toggleUserSuspension(String userId);
  Future<void> decideProtocol(String protocolId, String decision, String notes);
}

