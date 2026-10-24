// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/audit/presentation/widgets/audit_diff_dialog.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Modal completo do Dossiê do Titular (LGPD) e Trilha de Auditoria Individual do Usuário.
class UserDossierModal extends StatefulWidget {
  final AdminUserModel user;

  const UserDossierModal({super.key, required this.user});

  static Future<void> show({
    required BuildContext context,
    required AdminUserModel user,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UserDossierModal(user: user),
    );
  }

  @override
  State<UserDossierModal> createState() => _UserDossierModalState();
}

class _UserDossierModalState extends State<UserDossierModal> {
  int _selectedTab = 0; // 0: Dossiê Cadastral & Vínculos, 1: Trilha de Auditoria Individual

  @override
  Widget build(BuildContext context) {
    final controller = AdminPortalController.instance;
    final userLogs = controller.getUserAuditLogs(widget.user.id);
    final isAtivo = widget.user.status == 'Ativo';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 780,
        height: 620,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Identificação e Fechar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0] : 'U',
                    style: jakarta(size: 18, weight: FontWeight.w700, color: const Color(0xFF1E40AF)),
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
                            widget.user.name,
                            style: jakarta(
                              size: 19,
                              weight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AcademicStatusBadge(
                            label: widget.user.status,
                            type: isAtivo ? AcademicStatusType.ativo : AcademicStatusType.inativo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID / R.A.: ${widget.user.id} • ${widget.user.profile} • ${widget.user.email}',
                        style: jakarta(
                          size: 13,
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

            // Tab Switcher
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    title: 'Ficha Cadastral & Vínculos',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    index: 1,
                    title: 'Trilha de Auditoria Individual (${userLogs.length})',
                    icon: Icons.history_edu_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildCadastralTab(context)
                  : _buildAuditTab(context, userLogs),
            ),

            // Footer com Ações LGPD
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      'Dossiê compatível com o Art. 18 da LGPD (Direito de Acesso)',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dossiê digital de ${widget.user.name} exportado com sucesso.',
                          style: jakarta(size: 13, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF0F172A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text('Exportar Dossiê JSON/PDF', style: jakarta(size: 13, weight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: jakarta(
                size: 13,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCadastralTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bloco 1: Parâmetros de Conta & Acesso
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARÂMETROS DE ACESSO & SEGURANÇA',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildItem('Nível de Papel', widget.user.roleLevel)),
                    Expanded(child: _buildItem('Autenticação em 2 Etapas', widget.user.twoFactorRequired ? 'Obrigatória (Ativa)' : 'Opcional')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildItem('Sessões Ativas', '${widget.user.activeSessionsCount} dispositivo(s)')),
                    Expanded(child: _buildItem('Último Acesso Registrado', widget.user.lastLogin)),
                  ],
                ),
                if (widget.user.suspensionReason != null) ...[
                  const SizedBox(height: 12),
                  _buildItem('Justificativa da Suspensão', widget.user.suspensionReason!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bloco 2: Vínculo Curricular / Lotação Departamental
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VÍNCULO ACADÊMICO & ATIVIDADES',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                _buildItem('Curso / Departamento', widget.user.departmentOrCourse),
                const SizedBox(height: 12),
                _buildItem('Informações Integradas de Turma/Docência', widget.user.linkedInfo ?? 'Matrícula regularizada sem pendências regimentais.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTab(BuildContext context, List<AdminAuditLogModel> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.policy_outlined, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Nenhum evento registrado especificamente para este usuário',
              style: jakarta(size: 13.5, weight: FontWeight.w600, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Text(
              'Ações que impactam este cadastro gerarão registros automáticos aqui.',
              style: jakarta(size: 12, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, i) {
        final log = logs[i];
        final hasDiff = log.diffBefore != null || log.diffAfter != null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          log.actionType,
                          style: jakarta(size: 12.5, weight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.timestamp,
                          style: jakarta(size: 11.5, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.description,
                      style: jakarta(size: 12, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Operador: ${log.actor} (${log.ipAddress})',
                      style: jakarta(size: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (hasDiff) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => AuditDiffDialog.show(context: context, log: log),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 14),
                  label: Text('Diff', style: jakarta(size: 11.5, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: jakarta(size: 11.5, weight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
