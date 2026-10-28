// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Aba principal (Página inicial) do AVA da disciplina:
/// "Módulos & Conteúdos de Aprendizagem" com unidades didáticas, checklist interativo,
/// materiais de leitura e entregas vinculadas.
class StudentAvaHomeTab extends StatefulWidget {
  final StudentDisciplineModel discipline;
  final VoidCallback onNavigateToAssignments;

  const StudentAvaHomeTab({
    super.key,
    required this.discipline,
    required this.onNavigateToAssignments,
  });

  @override
  State<StudentAvaHomeTab> createState() => _StudentAvaHomeTabState();
}

class _StudentAvaHomeTabState extends State<StudentAvaHomeTab> {
  // Estado local para controle do checklist de leitura e conclusão dos itens
  final Map<String, bool> _completedItems = {
    'item_1': false,
    'item_2': false,
    'item_3': false,
    'item_4': false,
  };

  void _toggleItem(String key) {
    setState(() {
      _completedItems[key] = !(_completedItems[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 20),
        _buildUnitCard(),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos & Conteúdos de Aprendizagem',
          style: jakarta(
            size: 18,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Acesse as unidades didáticas, assista às videoaulas e baixe os materiais disponibilizados pelo professor.',
          style: jakarta(
            size: 12.5,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitCard() {
    final isFis = widget.discipline.code == 'FIS';

    final overline = isFis
        ? 'UNIDADE 1 • SEMANAS 1 A 6 • 16 HORAS LETIVAS'
        : 'UNIDADE 1 • SEMANAS 1 A 6 • 20 HORAS LETIVAS';

    final unitTitle = isFis
        ? 'Unidade 1: Ética na Sociedade Algorítmica e Inteligência Artificial'
        : 'Unidade 1: Arquitetura de Software e Padrões Estruturais (GoF)';

    final item1Title = isFis
        ? 'Texto Base: O Dilema das Redes e a Automação do Julgamento Moral'
        : 'Texto Base: Princípios SOLID e Aplicação Prática dos Padrões GoF';
    final item1Subtitle = isFis ? 'Leitura • 16 páginas' : 'Leitura • 24 páginas';

    final item2Title = isFis
        ? 'Fórum Temático: Vieses Algorítmicos e Responsabilidade Civil de IAs Autônomas'
        : 'Fórum Prático: Comparativo de Implementação Adapter vs Facade em Dart';
    final item2Subtitle = isFis
        ? 'Tarefa • Prazo: Amanhã, 21/09 às 18:00'
        : 'Tarefa • Prazo: Hoje às 23:59';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit Header
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overline,
                  style: jakarta(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        unitTitle,
                        style: jakarta(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '2 itens didáticos',
                      style: jakarta(
                        size: 11.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Item 1: Leitura / Material
          _buildDidacticItem(
            itemKey: 'item_1',
            icon: Icons.menu_book_outlined,
            iconBgColor: const Color(0xFFEFF6FF),
            iconBorderColor: const Color(0xFFBFDBFE),
            iconColor: const Color(0xFF2563EB),
            title: item1Title,
            subtitle: item1Subtitle,
            actionLabel: 'Acessar',
            isActionUrgent: false,
            onActionTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Abrindo leitor digital: $item1Title')),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),

          // Item 2: Tarefa / Fórum Temático
          _buildDidacticItem(
            itemKey: 'item_2',
            icon: Icons.schedule_rounded,
            iconBgColor: const Color(0xFFFFFBEB),
            iconBorderColor: const Color(0xFFFDE68A),
            iconColor: const Color(0xFFD97706),
            title: item2Title,
            subtitle: item2Subtitle,
            actionLabel: 'Ver Entrega',
            isActionUrgent: true,
            onActionTap: widget.onNavigateToAssignments,
          ),
        ],
      ),
    );
  }

  Widget _buildDidacticItem({
    required String itemKey,
    required IconData icon,
    required Color iconBgColor,
    required Color iconBorderColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required bool isActionUrgent,
    required VoidCallback onActionTap,
  }) {
    final isChecked = _completedItems[itemKey] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Checkbox circular de conclusão
          InkWell(
            key: Key('chk_$itemKey'),
            onTap: () => _toggleItem(itemKey),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked ? const Color(0xFF16A34A) : const Color(0xFFD4D4D8),
                  width: 1.5,
                ),
                color: isChecked ? const Color(0xFF16A34A) : Colors.transparent,
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Ícone temático
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBgColor,
              border: Border.all(color: iconBorderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),

          // Informações do item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: jakarta(
                    size: 11.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Botão de ação
          if (isActionUrgent)
            OutlinedButton(
              key: Key('btn_action_$itemKey'),
              onPressed: onActionTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                actionLabel,
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFFB45309),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              key: Key('btn_action_$itemKey'),
              onPressed: onActionTap,
              icon: const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF18181B)),
              label: Text(
                actionLabel,
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
        ],
      ),
    );
  }
}

