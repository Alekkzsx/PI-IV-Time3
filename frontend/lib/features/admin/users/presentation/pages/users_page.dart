// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import '../../../../../core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_dossier_modal.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_filter_bar.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_form_modal.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_list_table.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_reset_password_dialog.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_sessions_dialog.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_suspension_dialog.dart';
import '../widgets/user_edit_dialog.dart';

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
            required String identity,
            required String password,
            required String name,
            required String email,
            required String profile,
            required String department,
            required bool require2FA,
          }) async {
            final ok = await _controller.persist(
              () => _controller.remote.request('POST', '/users', {
                'identity': identity,
                'password': password,
                'displayName': name,
                'email': email,
                'profile': profile,
                'departmentOrCourse': department,
                'twoFactorRequired': require2FA,
              }),
            );
            if (!ok) {
              throw ApiException(
                _controller.remoteError ?? 'Não foi possível cadastrar.',
              );
            }
          },
    );
  }

  Future<void> _perform(Future<bool> action, String message) async {
    final ok = await action;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? message
              : _controller.remoteError ?? 'Não foi possível concluir.',
        ),
      ),
    );
  }

  void _showResetSenhaDialog(BuildContext context, AdminUserModel u) {
    UserResetPasswordDialog.show(
      context: context,
      user: u,
      onConfirm: () async {
        if (!await _controller.persistResetPassword(u.id)) {
          throw ApiException(
            _controller.remoteError ?? 'Falha ao solicitar recupera??o.',
          );
        }
      },
    );
  }

  void _showManageSessionsDialog(BuildContext context, AdminUserModel u) {
    UserSessionsDialog.show(
      context: context,
      user: u,
      onTerminateAll: () => _perform(
        _controller.persistRevokeSessions(u.id),
        'Sessões revogadas.',
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminUserModel u) {
    UserSuspensionDialog.show(
      context: context,
      user: u,
      onConfirm: (reason, suspend) => _perform(
        _controller.persistUserStatus(u.id, active: !suspend, reason: reason),
        suspend ? 'Usuário suspenso.' : 'Usuário reativado.',
      ),
    );
  }

  Future<void> _showDossierModal(BuildContext context, AdminUserModel u) async {
    try {
      final dossier = await _controller.remote.dossier(u.id);
      if (context.mounted) {
        UserDossierModal.show(context: context, user: u, dossier: dossier);
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _controller.filteredUsers;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

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
                              onEdit: (user) =>
                                  showUserEditDialog(context, user),
                              users: filteredList,
                              onResetPassword: (u) =>
                                  _showResetSenhaDialog(context, u),
                              onToggleStatus: (id) => _perform(
                                _controller.persistUserStatus(
                                  id,
                                  active:
                                      _controller.users
                                          .firstWhere((u) => u.id == id)
                                          .status !=
                                      'Ativo',
                                ),
                                'Status atualizado.',
                              ),
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
