// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Callback para conclusão de cadastro de usuário institucional.
typedef OnUserCreatedCallback =
    void Function({
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _deptController.dispose();
    super.dispose();
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
                      onTap: () {
                        setState(() {
                          _selectedRole = 'Discente (Aluno)';
                          _generatedRa = '2024.2.01045';
                          _deptController.text =
                              'Engenharia de Software (1º Semestre)';
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildRoleOption(
                      label: 'Docente (Professor)',
                      isSelected: _selectedRole == 'Docente (Professor)',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'Docente (Professor)';
                          _generatedRa = 'DOC-88425';
                          _deptController.text =
                              'Departamento de Computação e Sistemas';
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildRoleOption(
                      label: 'Administração',
                      isSelected: _selectedRole == 'Administração',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'Administração';
                          _generatedRa = 'ADM-00135';
                          _deptController.text =
                              'Secretaria Geral Acadêmica & Auditoria';
                        });
                      },
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

                // Aviso explicativo de 2FA
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
                    'Será encaminhado um e-mail com senha temporária criptografada e link para ativação de 2FA obrigatório no primeiro acesso.',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botões de Ação
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        final name = _nameController.text.trim();
                        final email = _emailController.text.trim();
                        final profile = _selectedRole.contains('Discente')
                            ? 'Discente'
                            : _selectedRole.contains('Docente')
                            ? 'Docente'
                            : 'Administrador';

                        widget.onUserCreated(
                          name: name,
                          email: email,
                          profile: profile,
                          department: _deptController.text.trim(),
                          require2FA: true,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Usuário cadastrado com sucesso! Credenciais e token 2FA despachados.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Concluir Cadastro',
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
