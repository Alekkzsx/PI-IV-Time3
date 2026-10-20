// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_hero_header.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_kpi_card.dart';
import '../widgets/docente_courses_preview_section.dart';
import '../widgets/docente_deadlines_notices_section.dart';
import '../widgets/docente_live_class_card.dart';

/// Visão principal do Painel Geral do Portal Docente.
class DocenteDashboardTab extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback onOpenVideoCall;
  final void Function(String courseId) onOpenCourseHub;

  const DocenteDashboardTab({
    super.key,
    required this.controller,
    required this.onOpenVideoCall,
    required this.onOpenCourseHub,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Section
              const InstitutionalHeroHeader(
                greeting: 'Bem-vinda, Helena.',
                subtitleItems: [
                  'Departamento de Computação',
                  'Docência 2026/2',
                ],
              ),
              const SizedBox(height: 32),

              // 4 KPI Metric Cards
              _buildKpiMetricsGrid(context),
              const SizedBox(height: 32),

              // Aula do Dia & Plantão Card
              DocenteLiveClassCard(
                onOpenVideoCall: onOpenVideoCall,
                onOpenCourseHub: onOpenCourseHub,
              ),
              const SizedBox(height: 32),

              // Minhas Turmas Cards
              DocenteCoursesPreviewSection(controller: controller),
              const SizedBox(height: 32),

              // Bottom Split: Prazos e Entregas + Mensagens e Avisos
              DocenteDeadlinesNoticesSection(controller: controller),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMetricsGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;

    const cards = [
      InstitutionalKpiCard(
        title: 'TURMAS ATIVAS',
        value: '03',
        subtitle: 'no Semestre',
        footerLabel: 'Discentes Matriculados',
        footerValue: '101 alunos',
        progress: 1.0,
      ),
      InstitutionalKpiCard(
        title: 'ENTREGAS DO MÊS',
        value: '04',
        subtitle: 'Cadastradas',
        footerLabel: 'Próximo Vencimento',
        footerValue: 'Hoje, 23:59',
        progress: 0.5,
      ),
      InstitutionalKpiCard(
        title: 'CARGA HORÁRIA TOTAL',
        value: '158h',
        subtitle: '/ 240h',
        footerLabel: 'Cumprimento do Plano',
        footerValue: '65.8%',
        progress: 0.658,
      ),
      InstitutionalKpiCard(
        title: 'FREQUÊNCIA MÉDIA',
        value: '94.8%',
        subtitle: 'das Turmas',
        footerLabel: 'Situação Geral',
        footerValue: 'Regular',
        progress: 0.948,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map(
              (c) => SizedBox(
                width: (width - 80) / (width > 600 ? 2 : 1),
                child: c,
              ),
            )
            .toList(),
      );
    }
  }
}
