// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_hero_header.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_kpi_card.dart';
import '../widgets/admin_regimental_deadlines_panel.dart';
import '../widgets/admin_secretariat_alerts_section.dart';
import '../widgets/emit_announcement_modal.dart';

/// Tela principal do painel geral da secretaria e gestão do campus.
class PainelGeralPage extends StatelessWidget {
  const PainelGeralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área principal do painel
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InstitutionalHeroHeader(
                  eyebrow: 'Painel Geral',
                  greeting: 'Bem-vindo, Carlos.',
                  subtitleItems: const [
                    'Secretaria Geral Acadêmica',
                    'Gestão Integrada do Campus 2026/2',
                  ],
                  trailingAction: ElevatedButton.icon(
                    onPressed: () => showEmitirComunicadoModal(context),
                    icon: const Icon(Icons.campaign, size: 18),
                    label: Text(
                      'Emitir Comunicado Institucional',
                      style: jakarta(size: 13, weight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Indicadores acadêmicos em cards
                const Row(
                  children: [
                    Expanded(
                      child: InstitutionalKpiCard(
                        title: 'DISCENTES ATIVOS',
                        value: '1.240',
                        subtitle: 'Matriculados',
                        footerLabel: 'Índice de Retenção',
                        footerValue: '96.4%',
                        stackFooter: true,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InstitutionalKpiCard(
                        title: 'CORPO DOCENTE',
                        value: '86',
                        subtitle: 'Professores',
                        footerLabel: 'Titulação Doutor/Mestre',
                        footerValue: '92.0%',
                        stackFooter: true,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InstitutionalKpiCard(
                        title: 'TURMAS EM ANDAMENTO',
                        value: '48',
                        subtitle: 'no Semestre 2026/2',
                        footerLabel: 'Alocação de Salas',
                        footerValue: '100% Homologado',
                        stackFooter: true,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InstitutionalKpiCard(
                        title: 'PROTOCOLOS DE SECRETARIA',
                        value: '07',
                        subtitle: 'Aguardando Parecer',
                        footerLabel: 'Tempo Médio de Resposta',
                        footerValue: '24 horas',
                        stackFooter: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Alertas e fechamento de período
                const AdminSecretariatAlertsSection(),
                const SizedBox(height: 32),

                // Seção de cursos e matrizes ativas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cursos & Matrizes Ativas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => showEmitirComunicadoModal(context),
                      child: const Text(
                        'Ver todos os cursos →',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Painel lateral com os prazos regimentais
          const Expanded(
            flex: 1,
            child: AdminRegimentalDeadlinesPanel(),
          ),
        ],
      ),
    );
  }
}
