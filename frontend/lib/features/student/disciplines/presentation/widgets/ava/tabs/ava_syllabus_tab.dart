// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaSyllabusTab]
///
/// Aba 7 do Cockpit AVA: Programa da Disciplina (Syllabus).
/// Apresenta a ementa oficial, metodologia, objetivos pedagógicos, unidades curriculares
/// e bibliografia homologada no PPC utilizando o Design System canônico do AVA.
class AvaSyllabusTab extends StatelessWidget {
  /// Controlador opcional injetado ou obtido do singleton.
  final StudentPortalController? controller;

  /// Cria uma nova instância de [AvaSyllabusTab].
  const AvaSyllabusTab({super.key, this.controller});

  StudentPortalController get _controller =>
      controller ?? StudentPortalController.instance;

  Future<void> _exportSyllabus(BuildContext context) async {
    final disc = _controller.selectedDiscipline;
    if (disc == null) return;

    final buffer = StringBuffer()
      ..writeln('====================================================')
      ..writeln('          AGM-RM • PLANO DE ENSINO REGIMENTAL       ')
      ..writeln('====================================================')
      ..writeln('Componente Curricular: ${disc.name} (${disc.code})')
      ..writeln('Docente Responsável:   ${disc.professor}')
      ..writeln('E-mail Docente:        ${disc.professorEmail}')
      ..writeln('Carga Horária Total:   ${disc.totalHours} horas letivas')
      ..writeln('Créditos Acadêmicos:   ${disc.credits}')
      ..writeln('Período Letivo:        ${disc.semester}')
      ..writeln('Fórmula de Avaliação:  ${disc.evaluationFormula}')
      ..writeln('----------------------------------------------------')
      ..writeln('\n1. EMENTA')
      ..writeln(disc.ementa.isNotEmpty
          ? disc.ementa
          : 'Abordagem teórico-prática voltada a padrões de projeto e desenvolvimento de software corporativo.')
      ..writeln('\n2. OBJETIVOS DE APRENDIZAGEM')
      ..writeln(disc.objectives.isNotEmpty
          ? disc.objectives
          : 'Capacitar o estudante na análise, modelagem e entrega de arquiteturas resilientes e testáveis.')
      ..writeln('\n3. METODOLOGIA DIDÁTICA')
      ..writeln(disc.methodology.isNotEmpty
          ? disc.methodology
          : 'Aulas expositivas dialogadas integradas a estudos de caso práticos, workshops e projetos integradores.')
      ..writeln('\n4. UNIDADES CURRICULARES PROGRAMADAS');

    if (disc.syllabusUnits.isEmpty) {
      buffer.writeln('  - Cronograma sob atualização homologada.');
    } else {
      for (var i = 0; i < disc.syllabusUnits.length; i++) {
        final u = disc.syllabusUnits[i];
        final title = (u['title'] ?? u['name'] ?? 'Unidade ${i + 1}').toString();
        buffer.writeln('  ${i + 1}. $title');
        final items = u['items'] as List?;
        if (items != null) {
          for (final item in items) {
            final itemTitle = (item['title'] ?? item['name'] ?? '').toString();
            buffer.writeln('     • $itemTitle');
          }
        }
      }
    }

    buffer.writeln('\n5. REFERÊNCIAS BIBLIOGRÁFICAS');
    if (disc.bibliography.isEmpty) {
      buffer.writeln('  - Bibliografia disponível na biblioteca física e digital.');
    } else {
      for (final b in disc.bibliography) {
        final type = b['type'] ?? 'Básica';
        final title = b['title'] ?? '';
        final authors = b['authors'] ?? '';
        final publisher = b['publisher'] ?? '';
        final year = b['year'] ?? '';
        buffer.writeln('  [$type] $authors. $title. $publisher, $year.');
      }
    }

    buffer
      ..writeln('====================================================')
      ..writeln('Emitido em: ${DateTime.now().toIso8601String()}')
      ..writeln('Plataforma Acadêmica AGM-RM • Secretaria Geral');

    final bytes = utf8.encode(buffer.toString());
    final fileName = 'plano_de_ensino_${disc.code.toLowerCase()}.txt';

    await PlatformFileHelper.saveOrDownloadFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/plain',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plano de Ensino ($fileName) baixado com sucesso.'),
          backgroundColor: const Color(0xFF18181B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final discipline = _controller.selectedDiscipline;
        final units = discipline?.syllabusUnits ?? const <Map<String, dynamic>>[];
        final bibliography =
            discipline?.bibliography ?? const <Map<String, dynamic>>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvaOpenSectionHeader(
              title:
                  'Programa da Disciplina${discipline == null ? '' : ' • ${discipline.name}'}',
              subtitle:
                  'Ementa regimental, objetivos de aprendizagem, metodologia e referências bibliográficas homologadas.',
              trailing: ElevatedButton.icon(
                onPressed: () => _exportSyllabus(context),
                icon: const Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  'Exportar Plano de Ensino',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Ementa e Metodologia
            AvaBannerSurfaceCard(
              title: 'Ementa do Componente Curricular',
              subtitle: 'Diretrizes curriculares e escopo metodológico',
              headerTrailing: const AvaStatusBadge(
                label: 'Regimental / PPC',
                variant: AvaBadgeVariant.success,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline?.ementa.isNotEmpty == true
                        ? discipline!.ementa
                        : 'Abordagem teórica e prática com ênfase em modelagem orientada a domínio, padrões de projeto e desenvolvimento de sistemas corporativos.',
                    style: jakarta(
                      size: 13,
                      color: const Color(0xFF3F3F46),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF4F4F5)),
                  const SizedBox(height: 14),
                  Text(
                    'Metodologia e Práticas Didáticas',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    discipline?.methodology.isNotEmpty == true
                        ? discipline!.methodology
                        : 'Aulas expositivas dialogadas integradas a estudos de caso práticos, workshops em laboratório e projetos em equipe com entregas síncronas e assíncronas.',
                    style: jakarta(
                      size: 13,
                      color: const Color(0xFF52525B),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Objetivos de Aprendizagem & Critérios
            AvaBannerSurfaceCard(
              title: 'Objetivos de Aprendizagem & Avaliação',
              subtitle: 'Competências regimentais e fórmula institucional de notas',
              headerTrailing: const AvaStatusBadge(
                label: 'Competências',
                variant: AvaBadgeVariant.neutral,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline?.objectives.isNotEmpty == true
                        ? discipline!.objectives
                        : 'Desenvolver competências de análise arquitetural, engenharia de requisitos corporativos e boas práticas de ciclo de vida de software.',
                    style: jakarta(
                      size: 13,
                      color: const Color(0xFF3F3F46),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF4F4F5)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                          size: 18,
                          color: Color(0xFF18181B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fórmula Regimental: ${discipline?.evaluationFormula.isNotEmpty == true ? discipline!.evaluationFormula : "(N1 × 0.4) + (N2 × 0.6)"}',
                            style: jakarta(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${discipline?.credits ?? 4} Créditos • ${discipline?.totalHours ?? 80}h',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Unidades Curriculares Previstas
            AvaBannerSurfaceCard(
              title: 'Unidades Curriculares Previstas',
              subtitle: 'Módulos didáticos homologados no plano de aula',
              headerTrailing: AvaStatusBadge(
                label: '${units.length} Unidades',
                variant: AvaBadgeVariant.neutral,
              ),
              child: units.isEmpty
                  ? Text(
                      'Cronograma detalhado em homologação pela coordenação de curso.',
                      style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < units.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 20, color: Color(0xFFF4F4F5)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF8F5),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: jakarta(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (units[i]['title'] ??
                                              units[i]['name'] ??
                                              'Unidade ${i + 1}')
                                          .toString(),
                                      style: jakarta(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF18181B),
                                      ),
                                    ),
                                    if (units[i]['summary'] != null &&
                                        units[i]['summary']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        units[i]['summary'].toString(),
                                        style: jakarta(
                                          size: 12,
                                          color: const Color(0xFF71717A),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    if (units[i]['items'] is List &&
                                        (units[i]['items'] as List)
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${(units[i]['items'] as List).length} tópicos e materiais vinculados',
                                        style: jakarta(
                                          size: 11.5,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Card 4: Bibliografia Básica e Complementar
            AvaBannerSurfaceCard(
              title: 'Bibliografia Básica e Complementar',
              subtitle: 'Acervo bibliográfico recomendado no Projeto Pedagógico',
              headerTrailing: AvaStatusBadge(
                label: '${bibliography.length} Obras',
                variant: AvaBadgeVariant.neutral,
              ),
              child: bibliography.isEmpty
                  ? Text(
                      'Acervo e títulos didáticos sob atualização no sistema integrado de bibliotecas.',
                      style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < bibliography.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AvaStatusBadge(
                                  label: (bibliography[i]['type'] ?? 'Básica')
                                      .toString(),
                                  variant: (bibliography[i]['type'] ==
                                          'Complementar')
                                      ? AvaBadgeVariant.neutral
                                      : AvaBadgeVariant.success,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (bibliography[i]['title'] ?? '')
                                            .toString(),
                                        style: jakarta(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: const Color(0xFF18181B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        (bibliography[i]['authors'] ?? '')
                                            .toString(),
                                        style: jakarta(
                                          size: 12,
                                          color: const Color(0xFF52525B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${bibliography[i]['publisher'] ?? ''} • ${bibliography[i]['year'] ?? ''}',
                                        style: jakarta(
                                          size: 11.5,
                                          color: const Color(0xFF71717A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
