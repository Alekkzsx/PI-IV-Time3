// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../data/admin_user_remote_data_source.dart';

/// Callback para conclusão de cadastro de usuário institucional.
typedef OnUserCreatedCallback =
    Future<String?> Function({
      required String name,
      required String email,
      required String profile,
      required String department,
      required bool require2FA,
    });

/// Modal institucional de cadastro de novos usuários (Discentes, Docentes, Administração).
class UserFormModal extends StatefulWidget {
  final OnUserCreatedCallback onUserCreated;

  const UserFormModal({super.key, required this.onUserCreated});

  static Future<void> show({
    required BuildContext context,
    required OnUserCreatedCallback onUserCreated,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => UserFormModal(onUserCreated: onUserCreated),
    );
  }

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _deptController = TextEditingController(
    text: 'Engenharia de Software (1º Semestre)',
  );
  String _selectedRole = 'Discente (Aluno)';
  String _generatedRa = '2024.2.01045';
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final profile = _selectedRole.contains('Discente')
        ? 'aluno'
        : _selectedRole.contains('Docente')
        ? 'docente'
        : 'admin';
    try {
      final identity = await widget.onUserCreated(
        name: name,
        email: email,
        profile: profile,
        department: _deptController.text.trim(),
        require2FA: profile != 'docente',
      );
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            profile == 'docente' && identity != null
                ? 'Docente cadastrado. Identidade: $identity. Oriente-o a usar “Esqueci minha senha” para definir a senha inicial.'
                : 'Usuário cadastrado com sucesso!',
          ),
        ),
      );
    } on AdminUserApiException catch (error) {
      if (mounted) {
        setState(() {
          _submissionError = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _selectRole(String role, String identity, String department) {
    if (_isSubmitting) return;
    setState(() {
      _selectedRole = role;
      _generatedRa = identity;
      _deptController.text = department;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do Modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GESTÃO DE IDENTIDADES & ACESSOS',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFF737373),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Novo Cadastro Institucional',
                            style: jakarta(
                              size: 22,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Tipo de Vínculo Acadêmico
                Text(
                  'Tipo de Vínculo Acadêmico',
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoleOption(
                      label: 'Discente (Aluno)',
                      isSelected: _selectedRole == 'Discente (Aluno)',
                      onTap: () => _selectRole(
                        'Discente (Aluno)',
                        '2024.2.01045',
                        'Engenharia de Software (1º Semestre)',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildRoleOption(
                      label: 'Docente (Professor)',
                      isSelected: _selectedRole == 'Docente (Professor)',
                      onTap: () => _selectRole(
                        'Docente (Professor)',
                        'DOC-88425',
                        'Departamento de Computação e Sistemas',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildRoleOption(
                      label: 'Administração',
                      isSelected: _selectedRole == 'Administração',
                      onTap: () => _selectRole(
                        'Administração',
                        'ADM-00135',
                        'Secretaria Geral Acadêmica & Auditoria',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Nome Completo do Usuário
                Text(
                  'Nome Completo do Usuário',
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (value) => (value?.trim().isNotEmpty ?? false)
                      ? null
                      : 'Informe o nome completo.',
                  style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Ex: Ana Clara Barbosa Ferreira',
                    hintStyle: jakarta(
                      size: 13.5,
                      color: const Color(0xFFA3A3A3),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // E-mail Institucional
                Text(
                  'E-mail Institucional',
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    final isValid = RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(email);
                    return isValid ? null : 'Informe um e-mail válido.';
                  },
                  style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'nome.sobrenome@universidade.edu.br',
                    hintStyle: jakarta(
                      size: 13.5,
                      color: const Color(0xFFA3A3A3),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Linha dupla: R.A. Gerado Oficial & Curso de Ingresso / Lotação
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'R.A. Gerado Oficial',
                            style: jakarta(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE5E5E5),
                              ),
                            ),
                            child: Text(
                              _generatedRa,
                              style: jakarta(
                                size: 13.5,
                                color: const Color(0xFF18181B),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Curso de Ingresso',
                            style: jakarta(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deptController,
                            validator: (value) =>
                                (value?.trim().isNotEmpty ?? false)
                                ? null
                                : 'Informe o curso ou lotação.',
                            style: jakarta(
                              size: 13.5,
                              color: const Color(0xFF18181B),
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E5E5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E5E5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF18181B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Instruções para o acesso inicial
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _selectedRole.contains('Docente')
                        ? 'Após o cadastro, o docente poderá usar “Esqueci minha senha” com este e-mail institucional para receber um código e definir sua senha.'
                        : 'O cadastro de alunos e administradores nesta tela permanece em modo de demonstração.',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_submissionError != null) ...[
                  Text(
                    _submissionError!,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botões de Ação
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isSubmitting ? 'Cadastrando...' : 'Concluir Cadastro',
                        style: jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: jakarta(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF525252),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
