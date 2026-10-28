// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Tabela responsiva de usuários com identificação, perfil, curso/lotação, status e ações de segurança.
class UserListTable extends StatelessWidget {
  final List<AdminUserModel> users;
  final ValueChanged<AdminUserModel> onResetPassword;
  final ValueChanged<String> onToggleStatus;
  final ValueChanged<AdminUserModel>? onImpersonate;
  final ValueChanged<AdminUserModel>? onManageSessions;
  final ValueChanged<AdminUserModel>? onSuspendWithReason;
  final ValueChanged<AdminUserModel>? onViewDossier;

  const UserListTable({
    super.key,
    required this.users,
    required this.onResetPassword,
    required this.onToggleStatus,
    this.onImpersonate,
    this.onManageSessions,
    this.onSuspendWithReason,
    this.onViewDossier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da Tabela
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF2F0EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        'IDENTIFICAÇÃO',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 260,
                      child: Text(
                        'NOME DO USUÁRIO',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      child: Text(
                        'PERFIL',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 250,
                      child: Text(
                        'CURSO / LOTAÇÃO',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 125,
                      child: Text(
                        'STATUS',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 440,
                      child: Text(
                        'AÇÕES DE SEGURANÇA & GOVERNANÇA',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Linhas da Tabela
              for (final u in users) _buildTableRow(context, u),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AdminUserModel u) {
    final isAtivo = u.status == 'Ativo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: Row(
        children: [
          // Identificação
          SizedBox(
            width: 130,
            child: Text(
              u.id,
              style: jakarta(
                size: 13.5,
                weight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Nome do Usuário & E-mail
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name,
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  u.email,
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Perfil
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildProfileBadge(u.profile),
            ),
          ),
          const SizedBox(width: 16),

          // Curso / Lotação
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.departmentOrCourse,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w400,
                    color: const Color(0xFF525252),
                  ),
                ),
                if (u.activeSessionsCount > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${u.activeSessionsCount} sessão(ões) ativa(s)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF059669),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Status
          SizedBox(
            width: 125,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AcademicStatusBadge(
                label: u.status,
                type: isAtivo
                    ? AcademicStatusType.ativo
                    : AcademicStatusType.inativo,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Ações de Segurança & Governança
          SizedBox(
            width: 440,
            child: Row(
              children: [
                // 1. Reset Senha
                InkWell(
                  onTap: () => onResetPassword(u),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.vpn_key_outlined,
                          size: 13,
                          color: Color(0xFF18181B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reset Senha',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Dossiê & Logs
                InkWell(
                  onTap: () => onViewDossier?.call(u),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Dossiê & Logs',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Menu Contextual de Governança
                PopupMenuButton<String>(
                  tooltip: 'Mais Ações de Governança',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 15,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  onSelected: (val) {
                    switch (val) {
                      case 'impersonate':
                        onImpersonate?.call(u);
                        break;
                      case 'sessions':
                        onManageSessions?.call(u);
                        break;
                      case 'suspend':
                        if (onSuspendWithReason != null) {
                          onSuspendWithReason!(u);
                        } else {
                          onToggleStatus(u.id);
                        }
                        break;
                      case 'dossier':
                        onViewDossier?.call(u);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'impersonate',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Modo Suporte (Impersonate)',
                            style: jakarta(size: 12.5),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sessions',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.power_settings_new_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Encerrar Sessões (${u.activeSessionsCount})',
                            style: jakarta(size: 12.5),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'suspend',
                      child: Row(
                        children: [
                          Icon(
                            isAtivo
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: isAtivo
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAtivo
                                ? 'Suspender com Justificativa'
                                : 'Reativar Usuário',
                            style: jakarta(size: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'dossier',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Dossiê do Titular (LGPD)',
                            style: jakarta(size: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildProfileBadge(String profile) {
    Color bg;
    Color border;
    Color textColor;

    if (profile == 'Docente') {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF2563EB);
    } else if (profile == 'Administrador') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    } else {
      bg = const Color(0xFFF4F4F5);
      border = const Color(0xFFE4E4E7);
      textColor = const Color(0xFF52525B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        profile,
        style: jakarta(size: 12, weight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
