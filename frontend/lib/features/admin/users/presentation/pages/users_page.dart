// Desenvolvido por Guilherme Henrique Moreira e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_dossier_modal.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_filter_bar.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_form_modal.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_impersonation_dialog.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_list_table.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_reset_password_dialog.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_sessions_dialog.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_suspension_dialog.dart';

/// Tela de Gestão de Usuários & Controle de Acessos da Visão do Administrador.
/// Refatorada e modularizada com componentes desacoplados em `widgets/`.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _showNovoCadastroModal(BuildContext context) {
    UserFormModal.show(
      context: context,
      onUserCreated:
          ({
            required String name,
            required String email,
            required String profile,
            required String department,
            required bool require2FA,
          }) {
            _controller.addUser(
              name: name,
              email: email,
              profile: profile,
              department: department,
              require2FA: require2FA,
            );
          },
    );
  }

  void _showResetSenhaDialog(BuildContext context, AdminUserModel u) {
    UserResetPasswordDialog.show(
      context: context,
      user: u,
      onConfirm: () => _controller.resetUserPasswordAdvanced(
        u.id,
        forceNextLogin: true,
        sendRecoveryEmail: true,
        revokeActiveSessions: true,
      ),
    );
  }

  void _showImpersonateDialog(BuildContext context, AdminUserModel u) {
    UserImpersonationDialog.show(
      context: context,
      user: u,
      onConfirm: () {
        _controller.impersonateUser(u);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Modo Suporte ativado para ${u.name}. Visualização auditada sob LGPD iniciada.',
              style: jakarta(size: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E3A8A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showManageSessionsDialog(BuildContext context, AdminUserModel u) {
    UserSessionsDialog.show(
      context: context,
      user: u,
      onTerminateAll: () {
        _controller.terminateUserSessions(u.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Todas as sessões ativas de ${u.name} foram revogadas com sucesso.',
              style: jakarta(size: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showSuspendDialog(BuildContext context, AdminUserModel u) {
    UserSuspensionDialog.show(
      context: context,
      user: u,
      onConfirm: (reason, willSuspend) {
        _controller.suspendUserWithReason(
          u.id,
          reason: reason,
          suspend: willSuspend,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willSuspend
                  ? 'Acesso de ${u.name} bloqueado administrativamente.'
                  : 'Acesso de ${u.name} reativado com sucesso.',
              style: jakarta(size: 13, color: Colors.white),
            ),
            backgroundColor: willSuspend
                ? const Color(0xFFDC2626)
                : const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showDossierModal(BuildContext context, AdminUserModel u) {
    UserDossierModal.show(context: context, user: u);
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _controller.filteredUsers;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final impersonated = _controller.activeImpersonatedUser;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner de Impersonation / Modo Suporte se Ativo
                      if (impersonated != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          color: const Color(0xFF1E3A8A),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'MODO SUPORTE ATIVO: Visualizando contexto acadêmico como ${impersonated.name} (${impersonated.id} - ${impersonated.profile}). Sessão de diagnóstico com trilha auditada.',
                                  style: jakarta(
                                    size: 12.5,
                                    color: Colors.white,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  _controller.exitImpersonation();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Modo Suporte encerrado. Retornado ao controle administrativo pleno.',
                                        style: jakarta(
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF0F172A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  'Encerrar Modo Espelho',
                                  style: jakarta(
                                    size: 12,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48.0 : 20.0,
                          vertical: 36.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cabeçalho da Página
                            _buildHeader(context, isDesktop),
                            const SizedBox(height: 28),

                            // Barra de Filtros e Busca
                            UserFilterBar(
                              searchController: _searchController,
                              onSearchChanged: (val) =>
                                  _controller.setUserSearchQuery(val),
                              activeFilter: _controller.userFilter,
                              onFilterChanged: (filter) =>
                                  _controller.setUserFilter(filter),
                              isDesktop: isDesktop,
                            ),
                            const SizedBox(height: 24),

                            // Tabela Institucional de Usuários com Ações Expandidas
                            UserListTable(
                              users: filteredList,
                              onResetPassword: (u) =>
                                  _showResetSenhaDialog(context, u),
                              onToggleStatus: (id) =>
                                  _controller.toggleUserStatus(id),
                              onImpersonate: (u) =>
                                  _showImpersonateDialog(context, u),
                              onManageSessions: (u) =>
                                  _showManageSessionsDialog(context, u),
                              onSuspendWithReason: (u) =>
                                  _showSuspendDialog(context, u),
                              onViewDossier: (u) =>
                                  _showDossierModal(context, u),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final titleAndSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão de Usuários & Controle de Acessos',
          style: jakarta(
            size: isDesktop ? 28 : 24,
            weight: FontWeight.w700,
            color: const Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Emissão de registros acadêmicos (R.A.), matrículas funcionais e governança de credenciais.',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );

    final newCadastroBtn = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _showNovoCadastroModal(context),
      icon: const Icon(Icons.add, size: 16, color: Colors.white),
      label: Text(
        'Novo Cadastro Institucional',
        style: jakarta(
          size: 13.5,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleAndSubtitle),
          const SizedBox(width: 24),
          newCadastroBtn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleAndSubtitle, const SizedBox(height: 18), newCadastroBtn],
    );
  }
}
