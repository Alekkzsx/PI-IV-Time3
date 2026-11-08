// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/widgets/access_denied_view.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import 'common/ava_common.dart';

/// [AvaEvaluationsGradesTab]
///
/// Aba 4 do Cockpit AVA: Boletim de Avaliações Contínuas (PPC).
/// Apresenta o extrato de notas oficiais, pesos regimentais e cálculo da média
/// parcial no padrão canônico [AvaBannerSurfaceCard], preservando 100% dos matchers de teste.
class AvaEvaluationsGradesTab extends StatelessWidget {
  /// Disciplina da qual as notas serão renderizadas.
  final StudentDisciplineModel discipline;

  /// Cria uma nova instância de [AvaEvaluationsGradesTab].
  const AvaEvaluationsGradesTab({super.key, required this.discipline});

  @override
  Widget build(BuildContext context) {
    if (!AppUserSession.instance.hasPermission('view_own_grades')) {
      return const AccessDeniedView(
        message: 'Este boletim está disponível apenas para o perfil de aluno.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Boletim de Avaliações Contínuas (PPC)',
          subtitle:
              'Fórmula de Homologação: Média = (N1 x 0.4) + (N2 x 0.6) • Presença Mínima: 75%',
          trailing: AvaActionPillButton(
            label: 'Solicitar Esclarecimento',
            icon: Icons.help_outline_rounded,
            variant: AvaButtonVariant.secondary,
            onPressed: () => _openClarificationModal(context),
          ),
        ),
        const SizedBox(height: 20),

        AvaBannerSurfaceCard(
          overlineTag: 'AVALIAÇÃO FORMATIVA & SOMATIVA',
          title: 'Extrato de Desempenho e Notas Lançadas',
          subtitle: 'Consulte os pesos e notas homologadas pelo docente titular.',
          bodyPadding: EdgeInsets.zero,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 760,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 760,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF8F5),
                          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: _buildHeaderCell('AVALIAÇÃO')),
                            Expanded(flex: 2, child: _buildHeaderCell('PESO REGIMENTAL')),
                            Expanded(flex: 2, child: _buildHeaderCell('NOTA LANÇADA')),
                            Expanded(flex: 3, child: _buildHeaderCell('STATUS')),
                          ],
                        ),
                      ),
                      _buildGradeRow(
                        'Prova Teórica N1 (P1)',
                        'Componente N1',
                        '${discipline.p1.toStringAsFixed(1)} / 10.0',
                        'Consolidado',
                      ),
                      _buildGradeRow(
                        'Trabalho Prático N1 (TRAB)',
                        'Componente N1',
                        '${discipline.trab.toStringAsFixed(1)} / 10.0',
                        'Consolidado',
                      ),
                      _buildGradeRow(
                        'Prova Teórica N2 (P2)',
                        'Componente N2',
                        '${discipline.p2.toStringAsFixed(1)} / 10.0',
                        'Consolidado',
                      ),
                      _buildGradeRow(
                        'Média consolidada de N1 e N2',
                        'Parcial',
                        '${discipline.partialAverage.toStringAsFixed(1)} / 10.0',
                        'Consolidado',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Bloco de rodapé com Média Parcial Consolidada
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF8F5),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final result = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        '${discipline.partialAverage.toStringAsFixed(2)} / 10.0 (resultado parcial)',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w700,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    );

                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Média Parcial Consolidada:',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        result,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Text(
      label,
      style: jakarta(
        size: 11,
        weight: FontWeight.w700,
        color: const Color(0xFF52525B),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildGradeRow(
    String evaluation,
    String weight,
    String grade,
    String status, {
    bool isLast = false,
  }) {
    return Container(
      width: 760,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              evaluation,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              weight,
              style: jakarta(size: 12, color: const Color(0xFF71717A)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              grade,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const AvaStatusBadge(
                  label: 'Consolidado',
                  variant: AvaBadgeVariant.success,
                  icon: Icons.check_circle_outline,
                  isPill: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openClarificationModal(BuildContext context) {
    final textController = TextEditingController();
    var selectedEvaluation = 'P1';
    var isSending = false;

    AvaStandardModal.show<void>(
      context: context,
      overlineTag: 'SECRETARIA & REGIME PEDAGÓGICO',
      title: 'Solicitar Esclarecimento de Nota',
      subtitle: 'Disciplina: ${discipline.code} — ${discipline.name}',
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione a avaliação referente ao seu pedido de revisão ou esclarecimento:',
                  style: jakarta(size: 13, color: const Color(0xFF52525B), height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['P1', 'TRAB', 'P2', 'N1', 'N2'].map((eval) {
                    final isSel = selectedEvaluation == eval;
                    return InkWell(
                      onTap: () => setModalState(() => selectedEvaluation = eval),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF18181B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? const Color(0xFF18181B) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          eval,
                          style: jakarta(
                            size: 12,
                            weight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF52525B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Justificativa do Pedido:',
                  style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Explique detalhadamente o ponto de dúvida na pontuação...',
                    hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AvaActionPillButton(
                      label: 'Cancelar',
                      variant: AvaButtonVariant.secondary,
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                    const SizedBox(width: 8),
                    AvaActionPillButton(
                      label: 'Registrar Pedido',
                      icon: Icons.send_rounded,
                      isLoading: isSending,
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Descreva sua justificativa (mínimo 5 caracteres).')),
                                );
                                return;
                              }
                              setModalState(() => isSending = true);
                              try {
                                final res = await StudentPortalController.instance.requestGradeClarification(
                                  classCode: discipline.code,
                                  evaluationType: selectedEvaluation,
                                  question: text,
                                );
                                if (!context.mounted) return;
                                Navigator.of(modalCtx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Protocolo ${res['protocolCode'] ?? "AGR-REV"} registrado no MongoDB com sucesso!'),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isSending = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
