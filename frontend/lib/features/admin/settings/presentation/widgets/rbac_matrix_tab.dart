// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/role_permission_policy.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

/// Aba de Configuração da Matriz de Permissões RBAC (Role-Based Access Control).
/// Apresenta as permissões efetivas dos três perfis autenticáveis.
class RbacMatrixTab extends StatefulWidget {
  const RbacMatrixTab({super.key});

  @override
  State<RbacMatrixTab> createState() => _RbacMatrixTabState();
}

class _RbacMatrixTabState extends State<RbacMatrixTab> {
  final AdminPortalController _controller = AdminPortalController.instance;

  final List<String> _roles = RolePermissionPolicy.roles;

  final List<_RbacPermissionItem> _permissions = const [
    _RbacPermissionItem(
      key: 'view_own_grades',
      label: 'Consultar o Próprio Boletim',
      description: 'Consulta das próprias notas e frequência acadêmica.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'view_class_grades',
      label: 'Consultar Pautas de Turma',
      description:
          'Consulta de notas e frequência de turmas sob responsabilidade ou auditoria.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'edit_grades',
      label: 'Editar & Lançar Notas no Diário',
      description:
          'Digitação de avaliações P1/P2/Sub e homologação de presenças.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'submit_assignments',
      label: 'Enviar Atividades Atribuídas',
      description: 'Submissão de entregas em atividades publicadas.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'manage_assignments',
      label: 'Criar e Avaliar Atividades',
      description: 'Publicação de atividades e correção de submissões.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'manage_attendance',
      label: 'Registrar Frequência',
      description: 'Registro e homologação de presença nas turmas docentes.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'manage_materials',
      label: 'Publicar Materiais de Aula',
      description: 'Disponibilização de materiais nas turmas docentes.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'publish_course_announcements',
      label: 'Publicar Avisos da Turma',
      description:
          'Envio de comunicados às turmas sob responsabilidade docente.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'submit_protocols',
      label: 'Solicitar Serviços Acadêmicos',
      description: 'Abertura de requerimentos pelo próprio aluno.',
      category: 'Secretaria',
    ),
    _RbacPermissionItem(
      key: 'manage_users',
      label: 'Gerenciar Usuários (Criar / Editar)',
      description:
          'Cadastro de discentes, docentes e alteração de lotação funcional.',
      category: 'Governança',
    ),
    _RbacPermissionItem(
      key: 'reset_passwords',
      label: 'Reset de Senhas & Revogar Sessões',
      description:
          'Emissão de links de recuperação e término forçado de sessões.',
      category: 'Segurança',
    ),
    _RbacPermissionItem(
      key: 'audit_diff_inspect',
      label: 'Auditoria & Trilha Forense (Diff)',
      description:
          'Inspeção do antes e depois de lançamentos de notas e cadastros.',
      category: 'Governança',
    ),
    _RbacPermissionItem(
      key: 'system_settings_2fa',
      label: 'Configurações de Servidor & 2FA',
      description:
          'Políticas de segurança, travas regimentais CONSEPE e backup.',
      category: 'Sistema',
    ),
    _RbacPermissionItem(
      key: 'dispatch_protocols',
      label: 'Despacho de Protocolos e Atestados',
      description:
          'Deferimento de requerimentos da secretaria com reflexo em diário.',
      category: 'Secretaria',
    ),
    _RbacPermissionItem(
      key: 'manage_classes',
      label: 'Gerenciar Turmas e Alocação Docente',
      description:
          'Alteração de regime acadêmico, ensalamento e docente responsável.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'publish_announcements',
      label: 'Publicar Comunicados',
      description:
          'Envio de comunicados institucionais ou direcionados a turmas.',
      category: 'Governança',
    ),
    _RbacPermissionItem(
      key: 'manage_video_calls',
      label: 'Abrir Videochamadas Administrativas',
      description: 'Iniciar chamadas em turmas sob supervisão administrativa.',
      category: 'Acadêmico',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Seção
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: InstColors.stoneActive,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: InstColors.border),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: InstColors.ink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Matriz de Permissões por Perfil',
                            style: jakarta(
                              size: 19,
                              weight: FontWeight.w700,
                              color: InstColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: InstColors.stoneActive,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: InstColors.border),
                          ),
                          child: Text(
                            'SOMENTE LEITURA',
                            style: jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              color: InstColors.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Política oficial aplicada em RolePermissionPolicy para os três perfis existentes: aluno, docente e admin.',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w400,
                        color: InstColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Aviso Institucional
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: InstColors.stone,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: InstColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: InstColors.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Auditoria oficial somente leitura: as permissões refletem exatamente os guardas de acesso aplicados no servidor e não criam perfis ou cargos adicionais.',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: InstColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabela Somente Leitura RBAC
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: InstColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 760,
                child: Column(
                  children: [
                    // Cabeçalho dos Perfis
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: InstColors.headerBg,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: Text(
                              'CAPACIDADE / OPERAÇÃO',
                              style: jakarta(
                                size: 11,
                                weight: FontWeight.w700,
                                color: InstColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          for (final role in _roles)
                            Expanded(
                              child: Center(
                                child: Text(
                                  _roleLabel(role),
                                  style: jakarta(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: InstColors.ink,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Linhas de Permissões
                    for (int i = 0; i < _permissions.length; i++) ...[
                      _buildPermissionRow(_permissions[i], i.isEven),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      RolePermissionPolicy.student => 'Aluno',
      RolePermissionPolicy.teacher => 'Docente',
      RolePermissionPolicy.admin => 'Admin',
      _ => role,
    };
  }

  Widget _buildPermissionRow(_RbacPermissionItem item, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : InstColors.hoverSurface,
        border: const Border(top: BorderSide(color: InstColors.border)),
      ),
      child: Row(
        children: [
          // Descrição do Módulo/Permissão
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: InstColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: InstColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // Indicadores somente leitura por perfil
          for (final role in _roles)
            Expanded(child: Center(child: _buildCheckbox(role, item.key))),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String role, String permKey) {
    final matrix = _controller.rbacMatrix;
    final isAllowed = matrix[permKey]?[role] ?? false;
    return Tooltip(
      message: '${_roleLabel(role)}: ${isAllowed ? "Permitido" : "Bloqueado"}',
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isAllowed ? InstColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAllowed ? InstColors.ink : InstColors.borderStrong,
            width: 1.5,
          ),
        ),
        child: isAllowed
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _RbacPermissionItem {
  final String key;
  final String label;
  final String description;
  final String category;

  const _RbacPermissionItem({
    required this.key,
    required this.label,
    required this.description,
    required this.category,
  });
}
