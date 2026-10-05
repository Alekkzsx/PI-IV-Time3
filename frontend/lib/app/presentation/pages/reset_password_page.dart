// Desenvolvido por Rafael Henrique Inácio

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/academic_identity_card.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/top_header_bar.dart';

class ResetPasswordPage extends StatefulWidget {
  final VoidCallback? onBackToLogin;

  const ResetPasswordPage({
    super.key,
    this.onBackToLogin,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _currentPassword = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior de navegação
            TopHeaderBar(
              onBackTap: widget.onBackToLogin ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retornando para a tela de Login...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
            ),
            // Conteúdo central rolável
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Badge de Saudação
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // slate-100
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: const Text(
                            'Olá, Gabriel Martins 👋',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Título Principal
                        const Text(
                          'Crie sua nova senha de acesso ao\nPortal AVA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtítulo
                        const Text(
                          'Sua identidade acadêmica foi confirmada. Escolha e confirme sua nova senha de acesso para restabelecer a conta no Portal AVA.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Card com Informações do Estudante
                        const AcademicIdentityCard(),
                        const SizedBox(height: 24),

                        // Campo: Nova Senha
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildFieldLabel('NOVA SENHA'),
                        ),
                        _buildPasswordField(
                          controller: _passwordController,
                          hintText: 'Digite sua nova senha segura',
                          prefixIcon: Icons.lock_outline,
                          isObscured: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Indicador de Força de Senha
                        PasswordStrengthIndicator(
                          password: _currentPassword,
                        ),
                        const SizedBox(height: 20),

                        // Campo: Confirmar Nova Senha
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildFieldLabel('CONFIRMAR NOVA SENHA'),
                        ),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          hintText: 'Repita a nova senha',
                          prefixIcon: Icons.shield_outlined,
                          isObscured: _obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 28),

                        // Botão Principal de Ação
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Senha redefinida com sucesso! Retornando...',
                                  ),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Future.delayed(const Duration(milliseconds: 600), () {
                                if (mounted) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushReplacementNamed(context, '/');
                                  }
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64748B), // Slate acinzentado do design
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Salvar Nova Senha e Voltar para Login',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Rodapé de Suporte e Ajuda
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(text: 'Precisa de ajuda com sua conta? '),
                              TextSpan(
                                text: 'Fale com a Secretaria Acadêmica',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Central de Ajuda',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Text(
                              'Perguntas Frequentes',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

