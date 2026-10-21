// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_sidebar.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_kpi_card.dart';
import '../widgets/admin_courses_grid_section.dart';
import '../widgets/admin_recent_protocols_panel.dart';
import '../widgets/admin_regimental_deadlines_panel.dart';
import '../widgets/admin_secretariat_alerts_section.dart';
import '../widgets/emit_announcement_modal.dart';

/// Tela principal do painel geral da secretaria e gestão do campus.
class PainelGeralPage extends StatelessWidget {
  final ValueChanged<AdminNavTab>? onNavigateTab;

  const PainelGeralPage({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: 36.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho de Boas-Vindas e Ação Institucional
                  _buildHeroHeader(context, isDesktop),
                  const SizedBox(height: 36),

                  // Indicadores acadêmicos em cards (4 KPIs)
                  _buildMetricsRow(isDesktop),
                  const SizedBox(height: 36),

                  // Grid Principal (2 colunas principais + 1 lateral de apoio)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna Principal (Alertas & Matrizes de Cursos)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AdminSecretariatAlertsSection(),
                              const SizedBox(height: 36),
                              AdminCoursesGridSection(
                                onSeeAll: () {
                                  onNavigateTab?.call(AdminNavTab.cursos);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Coluna Lateral de Apoio (Prazos & Últimos Requerimentos)
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminRegimentalDeadlinesPanel(
                                onNavigateTarget: (target) {
                                  if (target == 'calendario') {
                                    onNavigateTab?.call(AdminNavTab.calendario);
                                  } else if (target == 'secretaria') {
                                    onNavigateTab?.call(AdminNavTab.secretaria);
                                  } else if (target == 'turmas') {
                                    onNavigateTab?.call(AdminNavTab.turmas);
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                              AdminRecentProtocolsPanel(
                                onSeeAll: () {
                                  onNavigateTab?.call(AdminNavTab.secretaria);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSecretariatAlertsSection(),
                        const SizedBox(height: 32),
                        AdminCoursesGridSection(
                          onSeeAll: () {
                            onNavigateTab?.call(AdminNavTab.cursos);
                          },
                        ),
                        const SizedBox(height: 32),
                        AdminRegimentalDeadlinesPanel(
                          onNavigateTarget: (target) {
                            if (target == 'calendario') {
                              onNavigateTab?.call(AdminNavTab.calendario);
                            } else if (target == 'secretaria') {
                              onNavigateTab?.call(AdminNavTab.secretaria);
                            } else if (target == 'turmas') {
                              onNavigateTab?.call(AdminNavTab.turmas);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        AdminRecentProtocolsPanel(
                          onSeeAll: () {
                            onNavigateTab?.call(AdminNavTab.secretaria);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isDesktop) {
    final titleAndSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo, Carlos.',
          style: jakarta(
            size: 42,
            weight: FontWeight.w600,
            color: const Color(0xFF000000),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Secretaria Geral Acadêmica',
              style: jakarta(
                size: 16.5,
                weight: FontWeight.w700,
                color: const Color(0xFF000000),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '•',
                style: jakarta(
                  size: 16,
                  color: const Color(0xFFD4D4D4),
                ),
              ),
            ),
            Text(
              'Gestão Integrada do Campus 2026/2',
              style: jakarta(
                size: 16.5,
                weight: FontWeight.w600,
                color: const Color(0xFF737373),
              ),
            ),
          ],
        ),
      ],
    );

    final emitButton = ElevatedButton.icon(
      onPressed: () => showEmitirComunicadoModal(context),
      icon: const Icon(Icons.campaign_outlined, size: 17, color: Colors.white),
      label: Text(
        'Emitir Comunicado Institucional',
        style: jakarta(size: 13.5, weight: FontWeight.w600, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: titleAndSubtitle),
          const SizedBox(width: 24),
          emitButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleAndSubtitle,
        const SizedBox(height: 20),
        emitButton,
      ],
    );
  }

  Widget _buildMetricsRow(bool isDesktop) {
    const cards = [
      InstitutionalKpiCard(
        title: 'DISCENTES ATIVOS',
        value: '1.240',
        subtitle: 'Matriculados',
        footerLabel: 'Índice de Retenção',
        footerValue: '96.4%',
        progress: 0.964,
      ),
      InstitutionalKpiCard(
        title: 'CORPO DOCENTE',
        value: '86',
        subtitle: 'Professores',
        footerLabel: 'Titulação Doutor/Mestre',
        footerValue: '92.0%',
        progress: 0.920,
      ),
      InstitutionalKpiCard(
        title: 'TURMAS EM ANDAMENTO',
        value: '48',
        subtitle: 'no Semestre 2026/2',
        footerLabel: 'Alocação de Salas',
        footerValue: '100% Homologado',
        progress: 1.0,
      ),
      InstitutionalKpiCard(
        title: 'PROTOCOLOS DE SECRETARIA',
        value: '07',
        subtitle: 'Aguardando Parecer',
        footerLabel: 'Tempo Médio de Resposta',
        footerValue: '24 horas',
        progress: 0.70,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          cards[i],
        ],
      ],
    );
  }
}
