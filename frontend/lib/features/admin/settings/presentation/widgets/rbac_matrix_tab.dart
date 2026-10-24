// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Murillo Caravita - RA: 25014012 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

/// Aba de Configuração da Matriz de Permissões RBAC (Role-Based Access Control).
/// Permite visualização e ajuste granular de privilégios de acesso entre discentes, docentes,
/// coordenação, secretaria e administração do sistema.
class RbacMatrixTab extends StatefulWidget {
  const RbacMatrixTab({super.key});

  @override
  State<RbacMatrixTab> createState() => _RbacMatrixTabState();
}

class _RbacMatrixTabState extends State<RbacMatrixTab> {
  final AdminPortalController _controller = AdminPortalController.instance;

  final List<String> _roles = const [
    'Discente',
    'Docente',
    'Coordenador',
    'Secretaria',
    'Admin Operacional',
    'Super Admin',
  ];

  final List<_RbacPermissionItem> _permissions = const [
    _RbacPermissionItem(
      key: 'view_grades',
      label: 'Visualizar Boletim & Notas',
      description: 'Consulta de notas, faltas e coeficientes acadêmicos das turmas.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'edit_grades',
      label: 'Editar & Lançar Notas no Diário',
      description: 'Digitação de avaliações P1/P2/Sub e homologação de presenças.',
      category: 'Acadêmico',
    ),
    _RbacPermissionItem(
      key: 'manage_users',
      label: 'Gerenciar Usuários (Criar / Editar)',
      description: 'Cadastro de discentes, docentes e alteração de lotação funcional.',
      category: 'Governança',
    ),
    _RbacPermissionItem(
      key: 'reset_passwords',
      label: 'Reset de Senhas & Revogar Sessões',
      description: 'Emissão de links de recuperação e término forçado de sessões.',
      category: 'Segurança',
    ),
    _RbacPermissionItem(
      key: 'impersonate_support',
      label: 'Modo Suporte / Impersonation',
      description: 'Visualização diagnóstica sob a perspectiva exata do discente/docente.',
      category: 'Segurança',
    ),
    _RbacPermissionItem(
      key: 'audit_diff_inspect',
      label: 'Auditoria & Trilha Forense (Diff)',
      description: 'Inspeção do antes e depois de lançamentos de notas e cadastros.',
      category: 'Governança',
    ),
    _RbacPermissionItem(
      key: 'system_settings_2fa',
      label: 'Configurações de Servidor & 2FA',
      description: 'Políticas de segurança, travas regimentais CONSEPE e backup.',
      category: 'Sistema',
    ),
    _RbacPermissionItem(
      key: 'dispatch_protocols',
      label: 'Despacho de Protocolos e Atestados',
      description: 'Deferimento de requerimentos da secretaria com reflexo em diário.',
      category: 'Secretaria',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: Color(0xFF1D4ED8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matriz de Governança de Acessos & Papéis (RBAC)',
                      style: jakarta(
                        size: 19,
                        weight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Controle granular de privilégios e salvaguardas institucionais conforme diretrizes do CONSEPE e LGPD.',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w400,
                        color: const Color(0xFF64748B),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'As alterações nesta matriz têm efeito imediato nas permissões de visualização e edição de todos os usuários vinculados.',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabela Interativa RBAC
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 980,
                child: Column(
                  children: [
                    // Cabeçalho dos Perfis
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: const Color(0xFFF1F5F9),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 300,
                            child: Text(
                              'CAPACIDADE / OPERAÇÃO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          for (final role in _roles)
                            Expanded(
                              child: Center(
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: role == 'Super Admin'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF0F172A),
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
          const SizedBox(height: 24),

          // Barra Inferior de Ações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _controller.resetRbacToDefault();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Matriz de permissões restaurada para o padrão oficial MEC/CONSEPE.',
                        style: jakarta(size: 13, color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF475569),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: Text(
                  'Restaurar Padrão Institucional',
                  style: jakarta(size: 13, weight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _controller.saveRbacMatrixChanges();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Matriz de permissões salva com sucesso e registrada na trilha de auditoria (Diff).',
                        style: jakarta(size: 13, color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(
                  'Salvar & Propagar Políticas de Acesso',
                  style: jakarta(size: 13, weight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(_RbacPermissionItem item, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Descrição do Módulo/Permissão
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.label,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Colunas dos Perfis com Checkboxes Interativos
          for (final role in _roles)
            Expanded(
              child: Center(
                child: _buildCheckbox(role, item.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String role, String permKey) {
    final matrix = _controller.rbacMatrix;
    final isAllowed = matrix[permKey]?[role] ?? false;
    final isSuperAdmin = role == 'Super Admin';

    return Tooltip(
      message: isSuperAdmin
          ? 'Super Admin possui acesso irrestrito regimental'
          : '$role: ${isAllowed ? "Permitido" : "Bloqueado"}',
      child: InkWell(
        onTap: isSuperAdmin
            ? null
            : () {
                _controller.toggleRbacPermission(role, permKey);
                setState(() {});
              },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isAllowed
                ? (isSuperAdmin ? const Color(0xFFDC2626) : const Color(0xFF2563EB))
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isAllowed
                  ? (isSuperAdmin ? const Color(0xFFDC2626) : const Color(0xFF2563EB))
                  : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: isAllowed
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
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
