// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Diálogo para bloqueio/suspensão ou reativação de usuário com exigência de justificativa regimental.
class UserSuspensionDialog extends StatefulWidget {
  final AdminUserModel user;
  final void Function(String reason, bool suspend) onConfirm;

  const UserSuspensionDialog({
    super.key,
    required this.user,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required AdminUserModel user,
    required void Function(String reason, bool suspend) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UserSuspensionDialog(user: user, onConfirm: onConfirm),
    );
  }

  @override
  State<UserSuspensionDialog> createState() => _UserSuspensionDialogState();
}

class _UserSuspensionDialogState extends State<UserSuspensionDialog> {
  late bool _willSuspend;
  String _selectedReason = 'Inadimplência de Matrícula / Pendência Documental';
  final TextEditingController _notesController = TextEditingController();

  final List<String> _reasonsList = const [
    'Inadimplência de Matrícula / Pendência Documental',
    'Processo Disciplinar / Decisão CONSEPE',
    'Suspeita de Fraude / Quebra de Segurança da Conta',
    'Solicitação Formal do Titular (Direito LGPD)',
    'Trancamento Compulsório de Semestre',
    'Outro Motivo Institucional',
  ];

  @override
  void initState() {
    super.initState();
    _willSuspend = widget.user.status == 'Ativo';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _willSuspend
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _willSuspend
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Icon(
                    _willSuspend
                        ? Icons.block_rounded
                        : Icons.check_circle_outline_rounded,
                    color: _willSuspend
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _willSuspend
                            ? 'Bloqueio Administrativo de Acesso'
                            : 'Reativação de Conta Institucional',
                        style: jakarta(
                          size: 18,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usuário: ${widget.user.name} (${widget.user.id})',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_willSuspend) ...[
              Text(
                'Motivo Institucional do Bloqueio',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  color: const Color(0xFFFAFAFA),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    style: jakarta(size: 13, color: const Color(0xFF18181B)),
                    items: _reasonsList.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Observações Adicionais / Número de Protocolo',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText:
                      'Ex: Conforme processo SEI-2026/88401 ou solicitação da Secretaria.',
                  hintStyle: jakarta(
                    size: 12.5,
                    color: const Color(0xFFA1A1AA),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ao suspender, todas as sessões ativas são revogadas e o usuário é notificado com instruções para regularização.',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reativação Imediata de Acesso',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A conta voltará a ter status "Ativo". O discente/docente poderá efetuar login normalmente com suas credenciais vigentes.',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w400,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    if (widget.user.suspensionReason != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Motivo anterior da suspensão: "${widget.user.suspensionReason}"',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF71717A),
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: jakarta(size: 13, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    final fullReason = _notesController.text.trim().isNotEmpty
                        ? '$_selectedReason (${_notesController.text.trim()})'
                        : _selectedReason;
                    widget.onConfirm(fullReason, _willSuspend);
                  },
                  icon: Icon(
                    _willSuspend
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _willSuspend ? 'Confirmar Suspensão' : 'Reativar Usuário',
                    style: jakarta(size: 13, weight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _willSuspend
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
