// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Modal de Inspeção Forense & Comparativo de Dados (Audit Diff Inspector).
/// Apresenta o antes e depois de mutações de banco de dados, privilégios e dados cadastrais.
class AuditDiffDialog extends StatefulWidget {
  final AdminAuditLogModel log;

  const AuditDiffDialog({super.key, required this.log});

  static Future<void> show({
    required BuildContext context,
    required AdminAuditLogModel log,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuditDiffDialog(log: log),
    );
  }

  @override
  State<AuditDiffDialog> createState() => _AuditDiffDialogState();
}

class _AuditDiffDialogState extends State<AuditDiffDialog> {
  bool _showRawJson = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final diffBefore = log.diffBefore ?? {};
    final diffAfter = log.diffAfter ?? {};

    // Coleta todas as chaves únicas entre os dois snapshots
    final allKeys = {...diffBefore.keys, ...diffAfter.keys}.toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 760,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Inspeção Forense de Auditoria (Diff)',
                            style: jakarta(
                              size: 18,
                              weight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              log.id,
                              style: jakarta(
                                size: 11,
                                weight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rastreabilidade imutável de alterações em conformidade com o Art. 6º e 46 da LGPD',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card com Metadados da Operação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaItem('Operador / Ator', '${log.actor} (${log.actorRole ?? "TI/Admin"})'),
                      ),
                      Expanded(
                        child: _buildMetaItem('Data / Hora', log.timestamp),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaItem(
                          'Usuário ou Objeto Impactado',
                          log.targetUserName != null
                              ? '${log.targetUserName} (${log.targetUserId})'
                              : 'Registro Global / Sistema',
                        ),
                      ),
                      Expanded(
                        child: _buildMetaItem('Endereço IP & Origem', log.ipAddress),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildMetaItem('Descrição Registrada', log.description),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Toggle Entre Comparador Visual e JSON Bruto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPARAÇÃO DETALHADA DE CAMPOS (ANTES VS DEPOIS)',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _showRawJson = !_showRawJson),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _showRawJson ? Icons.table_chart_outlined : Icons.code_rounded,
                          size: 15,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showRawJson ? 'Exibir Tabela Visual' : 'Exibir JSON Forense',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Conteúdo Comparativo
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _showRawJson
                  ? _buildRawJsonView(diffBefore, diffAfter)
                  : _buildVisualTableView(allKeys, diffBefore, diffAfter),
            ),
            const SizedBox(height: 24),

            // Rodapé
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Concluir Inspeção', style: jakarta(size: 13, weight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualTableView(
    List<String> keys,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    if (keys.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Este log não possui alterações de estado estruturadas (evento apenas informativo).',
          style: jakarta(size: 12.5, color: const Color(0xFF64748B)),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            // Cabeçalho da Tabela
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PROPRIEDADE / CAMPO',
                      style: jakarta(size: 11, weight: FontWeight.w700, color: const Color(0xFF475569)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'VALOR ANTERIOR (BEFORE)',
                      style: jakarta(size: 11, weight: FontWeight.w700, color: const Color(0xFFB91C1C)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NOVO VALOR (AFTER)',
                      style: jakarta(size: 11, weight: FontWeight.w700, color: const Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
            ),
            for (final key in keys) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        key,
                        style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF1E293B)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          before.containsKey(key) ? '${before[key]}' : '(vazio)',
                          style: jakarta(size: 12, color: const Color(0xFF991B1B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          after.containsKey(key) ? '${after[key]}' : '(removido)',
                          style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF065F46)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRawJsonView(Map<String, dynamic> before, Map<String, dynamic> after) {
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert({
      'auditId': widget.log.id,
      'timestamp': widget.log.timestamp,
      'actor': widget.log.actor,
      'ipAddress': widget.log.ipAddress,
      'snapshotBefore': before,
      'snapshotAfter': after,
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          jsonStr,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFF38BDF8),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: jakarta(size: 11, weight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: jakarta(size: 12.5, weight: FontWeight.w600, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
