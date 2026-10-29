// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/shared/widgets/academic_empty_state.dart';
import '../widgets/widgets.dart';

/// Tela da Central de Entregas & Atividades Avaliativas da Visão do Aluno.
/// Totalmente refatorada e modularizada em sub-widgets de alta coesão:
/// - [DeliveriesKpiRow]: Painel de 4 cartões com prazos e média ponderada
/// - [DeliveriesFilterBar]: Abas de status com contadores, busca e filtro de disciplinas
/// - [DeliveryCardItem]: Cartão individual com metadados e ações contextuais
/// - [DeliverySubmissionModal]: Modal de submissão com dropzone, integridade e emissão de protocolo
/// - [DeliveryFeedbackModal]: Modal de devolutiva com rubricas avaliativas do docente
/// - [DeliveryReceiptModal]: Modal de comprovante oficial com assinatura e protocolo
class StudentDeliveriesPage extends StatefulWidget {
  const StudentDeliveriesPage({super.key});

  @override
  State<StudentDeliveriesPage> createState() => _StudentDeliveriesPageState();
}

class _StudentDeliveriesPageState extends State<StudentDeliveriesPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  String _searchQuery = '';
  String _selectedDiscipline = 'Todas as disciplinas';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allDeliveries = _controller.deliveries;

    // Métricas por Status para as Abas
    final totalCount = allDeliveries.length;
    final pendingCount = allDeliveries
        .where((d) => d.status == 'Pendente')
        .length;
    final inReviewCount = allDeliveries
        .where((d) => d.status == 'Em Análise')
        .length;
    final evaluatedCount = allDeliveries
        .where((d) => d.status == 'Avaliada')
        .length;

    // Lista única de disciplinas para o filtro
    final disciplineSet = <String>{'Todas as disciplinas'};
    for (final d in allDeliveries) {
      disciplineSet.add(d.disciplineName);
    }
    final disciplinesList = disciplineSet.toList();

    // Filtragem Reativa
    final filteredDeliveries = allDeliveries.where((d) {
      // 1. Filtro por Aba de Status
      if (_controller.activeDeliveryFilter != 'Todas' &&
          d.status != _controller.activeDeliveryFilter) {
        return false;
      }

      // 2. Filtro por Disciplina Selecionada
      if (_selectedDiscipline != 'Todas as disciplinas' &&
          d.disciplineName != _selectedDiscipline) {
        return false;
      }

      // 3. Filtro por Busca Textual
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchTitle = d.title.toLowerCase().contains(query);
        final matchCode = (d.activityCode ?? d.disciplineCode)
            .toLowerCase()
            .contains(query);
        final matchDiscipline = d.disciplineName.toLowerCase().contains(query);
        final matchDesc = (d.description ?? '').toLowerCase().contains(query);
        final matchProf = (d.professor ?? '').toLowerCase().contains(query);

        if (!matchTitle &&
            !matchCode &&
            !matchDiscipline &&
            !matchDesc &&
            !matchProf) {
          return false;
        }
      }

      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho Oficial da Página
          _buildHeader(),
          const SizedBox(height: 24),

          // 2. Indicadores de Desempenho (KPIs)
          DeliveriesKpiRow(deliveries: allDeliveries),
          const SizedBox(height: 24),

          // 3. Barra de Filtros e Busca
          DeliveriesFilterBar(
            activeTab: _controller.activeDeliveryFilter,
            totalCount: totalCount,
            pendingCount: pendingCount,
            inReviewCount: inReviewCount,
            evaluatedCount: evaluatedCount,
            onTabChanged: (newTab) {
              _controller.setDeliveryFilter(newTab);
            },
            searchQuery: _searchQuery,
            onSearchChanged: (val) {
              setState(() => _searchQuery = val);
            },
            selectedDiscipline: _selectedDiscipline,
            disciplinesList: disciplinesList,
            onDisciplineChanged: (val) {
              setState(() => _selectedDiscipline = val);
            },
          ),
          const SizedBox(height: 20),

          // 4. Listagem de Cartões de Atividade
          if (filteredDeliveries.isEmpty)
            AcademicEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Nenhuma atividade encontrada',
              description:
                  'Nenhum trabalho corresponde aos critérios de pesquisa ou status selecionados.',
              actionLabel: 'Limpar Filtros',
              onAction: () {
                setState(() {
                  _searchQuery = '';
                  _selectedDiscipline = 'Todas as disciplinas';
                  _controller.setDeliveryFilter('Todas');
                });
              },
            )
          else
            Column(
              children: filteredDeliveries.map((item) {
                return DeliveryCardItem(
                  key: ValueKey(item.id),
                  item: item,
                  onSubmit: () => DeliverySubmissionModal.show(context, item),
                  onReceipt: () => DeliveryReceiptModal.show(context, item),
                  onFeedback: () => DeliveryFeedbackModal.show(context, item),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO OFICIAL CONFORME MOCKUPS
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Central de Entregas & Atividades',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                  color: Color(0xFF18181B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gerencie prazos acadêmicos, envie seus trabalhos e acompanhe pareceres e notas oficiais.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF71717A),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Text(
            'Semestre Letivo: 2026/2',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
