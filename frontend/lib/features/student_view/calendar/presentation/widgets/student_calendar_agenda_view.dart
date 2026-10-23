// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Visualização em lista/agenda dos compromissos e prazos do estudante.
class StudentCalendarAgendaView extends StatefulWidget {
  final StudentPortalController controller;

  const StudentCalendarAgendaView({
    super.key,
    required this.controller,
  });

  @override
  State<StudentCalendarAgendaView> createState() => _StudentCalendarAgendaViewState();
}

class _StudentCalendarAgendaViewState extends State<StudentCalendarAgendaView> {
  String _selectedType = 'Todos';
  String _selectedPeriod = 'Todos os compromissos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de pesquisa e filtro de tipos
          _buildSearchAndTypeRow(),
          const SizedBox(height: 16),
          // Sub-abas de período e contador
          _buildPeriodTabsRow(),
          const SizedBox(height: 20),
          // Grupos de eventos
          _buildAgendaGroups(),
        ],
      ),
    );
  }

  Widget _buildSearchAndTypeRow() {
    final types = ['Todos', 'Entregas', 'Aulas', 'Fóruns', 'Avaliações'];

    return Row(
      children: [
        // Campo de busca
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por compromisso, matéria ou atividade...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Rótulo Tipo e Chips
        Row(
          children: [
            const Icon(Icons.tune, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            const Text(
              'Tipo:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 8),
            ...types.map((t) {
              final isSelected = _selectedType == t;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedType = t),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26394A) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF26394A) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodTabsRow() {
    final periods = ['Todos os compromissos', 'Hoje', 'Esta Semana', 'Mês de Setembro'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: periods.map((p) {
            final isSelected = _selectedPeriod == p;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => setState(() => _selectedPeriod = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? const Border(bottom: BorderSide(color: Color(0xFF1D4ED8), width: 2))
                        : null,
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Text(
          '9 compromissos encontrados',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildAgendaGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grupo 1: 20 de Setembro
        _buildGroupHeader(
          dateText: '20 de Setembro • Domingo, 2026',
          isToday: true,
          countText: '2 itens',
        ),
        const SizedBox(height: 10),
        _buildEventCard(
          time: '19:00',
          stripColor: const Color(0xFF0D9488),
          title: 'Aula Ao Vivo: Revisão de Casos de Uso e UML',
          isUrgent: true,
          disciplineTag: '218131 - ANÁLISE E PROJETO DE SISTEMAS II (MAT) 0103-04-26-2s',
          typeIcon: Icons.video_camera_front_outlined,
          typeName: 'Aula Remota',
          description:
              'Encontro síncrono para tirar dúvidas sobre o projeto prático e validação de requisitos funcionais.',
          location: 'Microsoft Teams • Sala Virtual 02',
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          time: '23:59',
          stripColor: const Color(0xFF16A34A),
          title: 'Entrega: Diagrama de Classes e Sequência',
          isUrgent: true,
          disciplineTag: '218131 - ANÁLISE E PROJETO DE SISTEMAS II (MAT) 0103-04-26-2s',
          typeIcon: Icons.assignment_outlined,
          typeName: 'Entrega de Trabalho',
          description:
              'Envio do arquivo PDF ou link do repositório contendo a modelagem completa dos diagramas UML de classes e...',
          location: 'Ambiente Virtual de Aprendizagem (AVA)',
        ),
        const SizedBox(height: 24),

        // Grupo 2: 21 de Setembro
        _buildGroupHeader(
          dateText: '21 de Setembro • Segunda-feira, 2026',
          isToday: false,
          countText: '1 item',
        ),
        const SizedBox(height: 10),
        _buildEventCard(
          time: '18:00',
          stripColor: const Color(0xFFD97706),
          title: 'Fórum Temático: Ética na Inteligência Artificial',
          isUrgent: true,
          disciplineTag: '218131 - FILOSOFIA, INFORMAÇÃO E SOCIEDADE (MAT) 0103-04-26-2s',
          typeIcon: Icons.forum_outlined,
          typeName: 'Fórum Temático',
          description:
              'Participação obrigatória no fórum com no mínimo 1 postagem autoral comentando sobre vieses algorítmicos e 2...',
          location: 'Fórum de Discussão AVA',
        ),
        const SizedBox(height: 24),

        // Grupo 3: 22 de Setembro
        _buildGroupHeader(
          dateText: '22 de Setembro • Terça-feira, 2026',
          isToday: false,
          countText: '1 item',
        ),
        const SizedBox(height: 10),
        _buildEventCard(
          time: '19:00',
          stripColor: const Color(0xFFDC2626),
          title: 'Aula Remota: Threads e Escalonamento de CPU',
          isUrgent: false,
          disciplineTag: '218131 - FUNDAMENTOS DE SISTEMAS OPERACIONAIS',
          typeIcon: Icons.video_camera_front_outlined,
          typeName: 'Aula Remota',
          description:
              'Apresentação prática sobre criação de processos, threads POSIX e algoritmos Round-Robin.',
          location: 'Microsoft Teams • Sala Virtual 01',
        ),
      ],
    );
  }

  Widget _buildGroupHeader({
    required String dateText,
    required bool isToday,
    required String countText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HOJE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          countText,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required String time,
    required Color stripColor,
    required String title,
    required bool isUrgent,
    required String disciplineTag,
    required IconData typeIcon,
    required String typeName,
    required String description,
    required String location,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna de horário com ícone
          Column(
            children: [
              const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              const Text(
                'HORÁRIO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Faixa vertical de cor
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          // Conteúdo textual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18181B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        disciplineTag,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4B5563),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(typeIcon, size: 14, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      typeName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botão Detalhes
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Text('Detalhes', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
            label: const Icon(Icons.open_in_new, size: 13, color: Color(0xFF6B7280)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
