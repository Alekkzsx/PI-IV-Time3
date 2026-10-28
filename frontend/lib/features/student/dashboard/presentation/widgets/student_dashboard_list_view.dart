// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

enum StudentListItemType {
  document,
  forum,
}

class StudentListItemData {
  final String id;
  final StudentListItemType type;
  final String title;
  final String subtitle;
  final String status;
  final bool hasClockIcon;
  final bool initialCompleted;

  const StudentListItemData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    this.hasClockIcon = false,
    this.initialCompleted = false,
  });
}

/// Visão em lista cronológica (Timeline/Agenda) do Painel Geral do Aluno.
///
/// Exibe o histórico de entregas, fóruns e materiais por data, prazos imediatos,
/// o estado vazio com o mascote oficial Sir Nicolau e os marcos semestrais até 2027.
class StudentDashboardListView extends StatefulWidget {
  const StudentDashboardListView({super.key});

  @override
  State<StudentDashboardListView> createState() => _StudentDashboardListViewState();
}

class _StudentDashboardListViewState extends State<StudentDashboardListView> {
  late final Map<String, bool> _completedState = {
    'item_17_sep': true,
    'item_18_sep': false,
    'item_19_sep': true,
    'item_20_sep_1': false,
    'item_20_sep_2': false,
    'item_21_sep': false,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. Quinta-feira, 17 de setembro
          // ==========================================
          _buildDateHeader('Quinta-feira, 17 de setembro'),
          const SizedBox(height: 14),
          _buildTaskItem(
            const StudentListItemData(
              id: 'item_17_sep',
              type: StudentListItemType.document,
              title: 'Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional',
              subtitle: 'Banco de Dados II • Profª. Dra. Eliane Ramos',
              status: 'Concluído',
              initialCompleted: true,
            ),
          ),
          const SizedBox(height: 32),

          // ==========================================
          // 2. Sexta-feira, 18 de setembro
          // ==========================================
          _buildDateHeader('Sexta-feira, 18 de setembro'),
          const SizedBox(height: 14),
          _buildTaskItem(
            const StudentListItemData(
              id: 'item_18_sep',
              type: StudentListItemType.forum,
              title: 'Fórum Avaliativo: Impactos éticos da IA em Sistemas Críticos',
              subtitle: 'Ética e Legislação • Prof. Marcos Vinícius',
              status: '3 participações',
              initialCompleted: false,
            ),
          ),
          const SizedBox(height: 32),

          // ==========================================
          // 3. Ontem, 19 de setembro
          // ==========================================
          _buildDateHeader('Ontem, 19 de setembro'),
          const SizedBox(height: 14),
          _buildTaskItem(
            const StudentListItemData(
              id: 'item_19_sep',
              type: StudentListItemType.document,
              title: 'Material Complementar: Estudo de Caso de Microsserviços',
              subtitle: 'Arquitetura de Software • Prof. Carlos Eduardo',
              status: 'Concluído',
              initialCompleted: true,
            ),
          ),
          const SizedBox(height: 32),

          // ==========================================
          // 4. Hoje, 20 de setembro
          // ==========================================
          _buildDateHeader('Hoje, 20 de setembro'),
          const SizedBox(height: 14),
          _buildTaskItem(
            const StudentListItemData(
              id: 'item_20_sep_1',
              type: StudentListItemType.document,
              title: 'Atividade Prática 03: Implementação de API REST',
              subtitle: 'Engenharia de Software • Envio pelo AVA até 23:59',
              status: 'até 23:59',
              hasClockIcon: true,
              initialCompleted: false,
            ),
          ),
          const SizedBox(height: 14),
          _buildTaskItem(
            const StudentListItemData(
              id: 'item_20_sep_2',
              type: StudentListItemType.forum,
              title: 'Fórum Temático: Desafios da Concorrência em Sistemas Distribuídos',
              subtitle: 'Sistemas Distribuídos • 12 novas respostas no tópico',
              status: 'Tópico aberto',
              initialCompleted: false,
            ),
          ),
          const SizedBox(height: 32),

          // ==========================================
          // 5. Amanhã, 21 de setembro
          // ==========================================
          _buildDateHeader('Amanhã, 21 de setembro'),
          const SizedBox(height: 14),
          _buildTaskItem(
            const StudentListItemData(
              id: 'item_21_sep',
              type: StudentListItemType.forum,
              title: 'Fórum de Dúvidas: Preparação para a Avaliação A1',
              subtitle: 'Cálculo Diferencial e Integral • Profª. Sandra Helena',
              status: 'até 18:00',
              hasClockIcon: true,
              initialCompleted: false,
            ),
          ),
          const SizedBox(height: 36),

          // ==========================================
          // 6. setembro 22 a dezembro 12 (Empty State)
          // ==========================================
          _buildDateHeader('setembro 22 a dezembro 12'),
          const SizedBox(height: 28),
          Center(
            child: Image.asset(
              'images/SirNicolau.png',
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.golf_course_rounded,
                      size: 48,
                      color: Color(0xFFA1A1AA),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nada planejado ainda',
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w500,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 36),

          // ==========================================
          // 7. domingo, 13 de dezembro
          // ==========================================
          _buildMilestoneSection(
            dateHeader: 'domingo, 13 de dezembro',
            description: 'Término das avaliações semestrais',
          ),
          const SizedBox(height: 36),

          // ==========================================
          // 8. segunda-feira, 14 de dezembro a janeiro 10
          // ==========================================
          _buildMilestoneSection(
            dateHeader: 'segunda-feira, 14 de dezembro a janeiro 10',
            description: 'Férias e encerramento de notas',
          ),
          const SizedBox(height: 36),

          // ==========================================
          // 9. fevereiro 2027
          // ==========================================
          _buildMilestoneSection(
            dateHeader: 'fevereiro 2027',
            description: 'Início das aulas do próximo período letivo',
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: jakarta(
            size: 14,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
      ],
    );
  }

  Widget _buildTaskItem(StudentListItemData item) {
    final isCompleted = _completedState[item.id] ?? item.initialCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox quadrado (preenchido com check quando concluído, contorno quando pendente)
          InkWell(
            key: Key('btn_toggle_${item.id}'),
            onTap: () {
              setState(() {
                _completedState[item.id] = !isCompleted;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isCompleted ? const Color(0xFF18181B) : const Color(0xFFD4D4D8),
                  width: 1.5,
                ),
                color: isCompleted ? const Color(0xFF18181B) : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Ícone temático: Documento ou Fórum
          Icon(
            item.type == StudentListItemType.document
                ? Icons.description_outlined
                : Icons.chat_bubble_outline_rounded,
            size: 18,
            color: const Color(0xFF52525B),
          ),
          const SizedBox(width: 12),

          // Título e identificador da disciplina / docente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Status / Horário à direita
          if (item.hasClockIcon)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Text(
                  item.status,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            )
          else
            Text(
              item.status,
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSection({
    required String dateHeader,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(dateHeader),
        const SizedBox(height: 18),
        Center(
          child: Text(
            description,
            style: jakarta(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ),
      ],
    );
  }
}
