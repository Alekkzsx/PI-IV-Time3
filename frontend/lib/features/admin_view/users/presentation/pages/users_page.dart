// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin_view/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';

/// Tela de Gestão de Usuários & Controle de Acessos da Visão do Administrador.
/// Permite cadastrar novos discentes/docentes com geração automática de R.A. e 2FA,
/// filtrar por perfil, realizar busca textual, redefinir senhas e suspender acessos.
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _controller.filteredUsers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usuários', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestão de Usuários & Controle de Acessos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Emissão de registros acadêmicos (R.A.), matrículas funcionais e governança de credenciais.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showNovoCadastroModal(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Cadastro Institucional'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterAndSearchBar(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = filteredList[index];
                final isAtivo = u.status == 'Ativo';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    child: Text(u.name[0]),
                  ),
                  title: Row(
                    children: [
                      Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(u.status, style: TextStyle(fontSize: 10, color: isAtivo ? const Color(0xFF16A34A) : const Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        backgroundColor: isAtivo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  subtitle: Text('${u.id} • ${u.email}\n${u.departmentOrCourse} • 2FA: ${u.twoFactorRequired ? "Obrigatório" : "Opcional"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text(u.profile, style: const TextStyle(fontSize: 11))),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _showResetSenhaDialog(context, u),
                        child: const Text('Reset Senha', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _controller.toggleUserStatus(u.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isAtivo ? Colors.red : Colors.green,
                        ),
                        child: Text(isAtivo ? 'Suspender' : 'Reativar', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BARRA DE FILTROS E BUSCA (Print 42)
  // ==========================================
  Widget _buildFilterAndSearchBar() {
    final profiles = ['Todos', 'Discentes', 'Docentes', 'Administração'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: profiles.map((p) {
            final isSelected = _controller.userFilter == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(p),
                selected: isSelected,
                onSelected: (_) => _controller.setUserFilter(p),
                selectedColor: const Color(0xFF0F172A),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }).toList(),
        ),
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _controller.setUserSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Buscar por nome, R.A. ou e-mail...',
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MODAL NOVO CADASTRO INSTITUCIONAL (Print 43)
  // ==========================================
  void _showNovoCadastroModal(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final deptController = TextEditingController(text: 'Engenharia de Software (4º Semestre)');
    String selectedProfile = 'Discente';
    bool require2FA = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Novo Cadastro Institucional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail Institucional', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProfile,
                    decoration: const InputDecoration(labelText: 'Perfil de Acesso', border: OutlineInputBorder()),
                    items: ['Discente', 'Docente', 'Administrador'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setModalState(() => selectedProfile = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Curso ou Lotação Funcional', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Exigir Autenticação 2FA no Primeiro Acesso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Medida de segurança institucional obrigatória para novas contas.', style: TextStyle(fontSize: 11)),
                    value: require2FA,
                    onChanged: (val) => setModalState(() => require2FA = val),
                    activeThumbColor: const Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  _controller.addUser(
                    name: nameController.text,
                    email: emailController.text,
                    profile: selectedProfile,
                    department: deptController.text,
                    require2FA: require2FA,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário cadastrado com sucesso! Credenciais e token 2FA despachados.')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              child: const Text('Concluir Cadastro'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIÁLOGO RESET DE SENHA
  // ==========================================
  void _showResetSenhaDialog(BuildContext context, AdminUserModel u) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Redefinição Segura de Credenciais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('Deseja enviar um link seguro de redefinição de senha com validade de 24 horas para o e-mail:\n\n${u.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link de redefinição enviado com sucesso para ${u.email}!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('Confirmar Envio'),
          ),
        ],
      ),
    );
  }
}
