// Desenvolvido por Murillo Caravita - RA: 25014012

import '../../data/student_mock_data.dart';

/// Contrato abstrato do repositório de dados acadêmicos do discente.
/// Prepara o ecossistema frontend para receber a injeção do cliente HTTP/REST do backend.
abstract class IStudentRepository {
  Future<List<StudentDisciplineModel>> getDisciplines();
  Future<List<StudentCalendarEvent>> getCalendarEvents();
  Future<List<StudentDeliveryItem>> getDeliveries();
  Future<List<Map<String, String>>> getForumTopics();
  Future<String> getPersonalNotes();
  Future<void> savePersonalNotes(String notes);
  Future<void> submitDelivery({
    required String deliveryId,
    required String fileName,
    String? gitUrl,
    String? comments,
  });
}

