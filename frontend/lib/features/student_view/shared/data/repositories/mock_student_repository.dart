// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../domain/repositories/student_repository.dart';
import '../student_mock_data.dart';

/// Implementação padrão local em memória do repositório acadêmico do aluno.
/// Permite simulação assíncrona desacoplada de rede enquanto o backend é desenvolvido.
class MockStudentRepository implements IStudentRepository {
  final List<StudentDisciplineModel> _disciplines =
      List.from(StudentMockData.disciplines);
  final List<StudentCalendarEvent> _calendarEvents =
      List.from(StudentMockData.calendarEvents);
  final List<StudentDeliveryItem> _deliveries =
      List.from(StudentMockData.deliveries);
  String _personalNotes =
      '# Anotações da Aula 14 - Padrão Adapter\n\n'
      '- O Adapter converte a interface de uma classe em outra que o cliente espera.\n'
      '- Permite que classes com interfaces incompatíveis trabalhem juntas.\n'
      '- Exemplo prático: Integração com legado via Wrapper.';

  final List<Map<String, String>> _forumTopics = [
    {
      'autor': 'Mariana Rios Costa',
      'tempo': 'Há 2 horas',
      'titulo':
          'Dúvida na estrutura de classes do padrão Adapter com herança múltipla',
      'respostas': '2 respostas (Profa. Helena respondeu)',
    },
    {
      'autor': 'Lucas Silva Santos',
      'tempo': 'Ontem',
      'titulo':
          'Formato do arquivo de entrega: zip com testes unitários é obrigatório?',
      'respostas': '1 resposta (Monitor Victor respondeu)',
    },
  ];

  @override
  Future<List<StudentDisciplineModel>> getDisciplines() async {
    return List.unmodifiable(_disciplines);
  }

  @override
  Future<List<StudentCalendarEvent>> getCalendarEvents() async {
    return List.unmodifiable(_calendarEvents);
  }

  @override
  Future<List<StudentDeliveryItem>> getDeliveries() async {
    return List.unmodifiable(_deliveries);
  }

  @override
  Future<List<Map<String, String>>> getForumTopics() async {
    return List.unmodifiable(_forumTopics);
  }

  @override
  Future<String> getPersonalNotes() async {
    return _personalNotes;
  }

  @override
  Future<void> savePersonalNotes(String notes) async {
    _personalNotes = notes;
  }

  @override
  Future<void> submitDelivery({
    required String deliveryId,
    required String fileName,
    String? gitUrl,
    String? comments,
  }) async {
    final idx = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (idx != -1) {
      final current = _deliveries[idx];
      _deliveries[idx] = StudentDeliveryItem(
        id: current.id,
        title: current.title,
        disciplineCode: current.disciplineCode,
        disciplineName: current.disciplineName,
        dueDate: current.dueDate,
        dueHour: current.dueHour,
        weight: current.weight,
        status: 'Em Análise',
        score: current.score,
        feedback: 'Arquivo $fileName anexado pelo discente.',
        protocol: 'PROT-AVA-${current.id}',
        rubrics: current.rubrics,
      );
    }
  }
}

