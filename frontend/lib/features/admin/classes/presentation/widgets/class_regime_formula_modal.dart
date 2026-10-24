// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Diálogo modal especializado para governança e definição do regime de fórmula da turma.
class ClassRegimeFormulaModal extends StatefulWidget {
  final AdminClassModel classModel;
  final ValueChanged<String> onSaveRegime;

  const ClassRegimeFormulaModal({
    super.key,
    required this.classModel,
    required this.onSaveRegime,
  });

  static Future<void> show({
    required BuildContext context,
    required AdminClassModel classModel,
    required ValueChanged<String> onSaveRegime,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ClassRegimeFormulaModal(
        classModel: classModel,
        onSaveRegime: onSaveRegime,
      ),
    );
  }

  @override
  State<ClassRegimeFormulaModal> createState() => _ClassRegimeFormulaModalState();
}

class _ClassRegimeFormulaModalState extends State<ClassRegimeFormulaModal> {
  late String _currentRegime;

  @override
  void initState() {
    super.initState();
    _currentRegime = widget.classModel.formulaRegime;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classModel;
    final isAutonomia = _currentRegime == 'Autonomia Docente';
    final isAdmin = _currentRegime == 'Impor pelo Admin';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 660,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Modal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: const Icon(
                      Icons.balance,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GOVERNANÇA & PRERROGATIVAS DE AVALIAÇÃO',
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xFF737373),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Regime da Fórmula da Nota Final',
                          style: jakarta(
                            size: 20,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF737373)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Caixa de Identificação da Disciplina
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c.code} – ${c.subjectName}',
                            style: jakarta(
                              size: 14,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            c.courseName,
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Docente Regente: ',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          TextSpan(
                            text: c.professor,
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Título da Seção
              Text(
                'DEFINIR PRERROGATIVA DA FÓRMULA DE AVALIAÇÃO',
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Opções selecionáveis lado a lado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Impor pelo Admin
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentRegime = 'Impor pelo Admin'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAdmin ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                            width: isAdmin ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: isAdmin ? const Color(0xFF059669) : const Color(0xFF737373),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Impor pelo Admin',
                                    style: jakarta(
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF18181B),
                                    ),
                                  ),
                                ),
                                if (isAdmin)
                                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'O Admin/DTI fixa a fórmula de cálculo de forma compulsória. O professor fica com a fórmula travada em modo somente leitura no AVA.',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Card 2: Autonomia Docente
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentRegime = 'Autonomia Docente'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAutonomia ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                            width: isAutonomia ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_open_outlined,
                                  size: 18,
                                  color: isAutonomia ? const Color(0xFF059669) : const Color(0xFF737373),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Autonomia Docente',
                                    style: jakarta(
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF18181B),
                                    ),
                                  ),
                                ),
                                if (isAutonomia)
                                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Concede autonomia plena ao professor para decidir e parametrizar a fórmula da sua disciplina diretamente no seu AVA.',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Callout Informativo Dinâmico
              if (isAutonomia)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF059669)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Autonomia Pedagógica Habilitada:\n',
                                style: jakarta(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF047857),
                                  height: 1.35,
                                ),
                              ),
                              TextSpan(
                                text: 'O docente ',
                                style: jakarta(size: 12.5, weight: FontWeight.w400, color: const Color(0xFF065F46)),
                              ),
                              TextSpan(
                                text: c.professor,
                                style: jakarta(size: 12.5, weight: FontWeight.w700, color: const Color(0xFF065F46)),
                              ),
                              TextSpan(
                                text:
                                    ' visualizará um botão de configuração no AVA para escolher a fórmula matemática que preferir, adicionar ou remover instrumentos de avaliação, ajustar pesos e congelar/destravar notas.',
                                style: jakarta(
                                  size: 12.5,
                                  weight: FontWeight.w400,
                                  color: const Color(0xFF065F46),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_clock_outlined, size: 20, color: Color(0xFF475569)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Trava Regimental Aplicada:\n',
                                style: jakarta(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  height: 1.35,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'A fórmula de cálculo regimental (Média = N1 × 0.4 + N2 × 0.6) será imposta compulsoriamente. O professor regente visualizará o diário com os pesos bloqueados em modo de visualização estrita.',
                                style: jakarta(
                                  size: 12.5,
                                  weight: FontWeight.w400,
                                  color: const Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Rodapé com Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF525252)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSaveRegime(_currentRegime);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Regime atualizado para: $_currentRegime',
                            style: jakarta(size: 13, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF18181B),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF34D399)),
                        const SizedBox(width: 8),
                        Text(
                          'Salvar Diretriz da Disciplina',
                          style: jakarta(size: 13, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
