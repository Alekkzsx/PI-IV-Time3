// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Card atômico com digitação direta e slider sincronizado para atribuição de nota em um critério da rubrica.
class RubricCriterionTile extends StatefulWidget {
  final RubricCriterion criterion;
  final double currentScore;
  final ValueChanged<double> onScoreChanged;

  const RubricCriterionTile({
    super.key,
    required this.criterion,
    required this.currentScore,
    required this.onScoreChanged,
  });

  @override
  State<RubricCriterionTile> createState() => _RubricCriterionTileState();
}

class _RubricCriterionTileState extends State<RubricCriterionTile> {
  late final TextEditingController _scoreController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(
      text: _formatScore(widget.currentScore),
    );
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant RubricCriterionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.currentScore != widget.currentScore) {
      final nextText = _formatScore(widget.currentScore);
      if (_scoreController.text != nextText) {
        _scoreController.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _scoreController.dispose();
    super.dispose();
  }

  static String _formatScore(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scoreController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _scoreController.text.length,
      );
    } else {
      final parsed = double.tryParse(_scoreController.text.trim().replaceAll(',', '.'));
      final committed = parsed != null && parsed.isFinite
          ? double.parse(parsed.clamp(0.0, widget.criterion.maxScore).toStringAsFixed(1))
          : widget.currentScore;
      _scoreController.text = _formatScore(committed);
      if (committed != widget.currentScore) {
        widget.onScoreChanged(committed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxScore = widget.criterion.maxScore;
    final clamped = widget.currentScore.clamp(0.0, maxScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.criterion.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DocenteColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.criterion.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DocenteColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 68,
                    height: 34,
                    child: TextField(
                      controller: _scoreController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DocenteColors.charcoal,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: DocenteColors.offWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: DocenteColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: DocenteColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: DocenteColors.emerald, width: 1.5),
                        ),
                      ),
                      onChanged: (raw) {
                        final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
                        if (parsed != null && parsed.isFinite) {
                          widget.onScoreChanged(
                            double.parse(parsed.clamp(0.0, maxScore).toStringAsFixed(1)),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${maxScore.toStringAsFixed(1)} pts',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: DocenteColors.slate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DocenteColors.emerald,
              inactiveTrackColor: DocenteColors.border,
              thumbColor: DocenteColors.emerald,
              overlayColor: DocenteColors.emerald.withValues(alpha: 0.12),
              trackHeight: 6,
            ),
            child: Slider(
              value: clamped,
              min: 0.0,
              max: maxScore > 0 ? maxScore : 1.0,
              divisions: (maxScore * 10).round().clamp(1, 1000),
              onChanged: (val) {
                final rounded = double.parse(val.toStringAsFixed(1));
                _scoreController.text = _formatScore(rounded);
                widget.onScoreChanged(rounded);
              },
            ),
          ),
        ],
      ),
    );
  }
}
