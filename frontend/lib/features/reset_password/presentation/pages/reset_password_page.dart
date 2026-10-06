// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/recovery_footer_links.dart';
import '../../../../shared/widgets/top_header_bar.dart';
import '../widgets/academic_identity_card.dart';
import '../widgets/password_reset_field.dart';
import '../widgets/password_strength_indicator.dart';

/// Tela de redefinição e cadastro de nova senha de acesso ao Portal AVA.
///
/// Exibida após a validação bem-sucedida da identidade ou token de recuperação,
/// permitindo ao discente cadastrar uma nova senha segura, acompanhar o medidor
/// de entropia em tempo real ([PasswordStrengthIndicator]), confirmar a correspondência
/// entre os campos e retornar à tela de Login.
class ResetPasswordPage extends StatefulWidget {
  /// Callback opcional executado quando o usuário aciona o botão de voltar no cabeçalho.
  final VoidCallback? onBackToLogin;

  /// Cria uma instância da tela [ResetPasswordPage].
  ///
  /// Parâmetros:
  /// - [onBackToLogin]: Callback de navegação reversa opcional.
  const ResetPasswordPage({
    super.key,
    this.onBackToLogin,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  /// Comprimento mínimo exigido para a nova senha.
  static const int _minPasswordLength = 6;

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

  /// Valida as regras de negócio de nova senha (tamanho mínimo de 6 dígitos e
  /// correspondência exata com a confirmação) e redireciona para a tela de Login.
  void _handleSavePassword() {
    if (_passwordController.text.length < _minPasswordLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha redefinida com sucesso! Retornando...'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        const AcademicIdentityCard(),
                        const SizedBox(height: 24),
                        PasswordResetField(
                          controller: _passwordController,
                          label: 'NOVA SENHA',
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
                        PasswordStrengthIndicator(password: _currentPassword),
                        const SizedBox(height: 20),
                        PasswordResetField(
                          controller: _confirmPasswordController,
                          label: 'CONFIRMAR NOVA SENHA',
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
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleSavePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64748B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                        ),
                        const SizedBox(height: 32),
                        const RecoveryFooterLinks(),
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
