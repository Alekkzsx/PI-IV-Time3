// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/recovery_footer_links.dart';
import '../../../../../shared/widgets/top_header_bar.dart';
import '../../../shared/domain/models/recovery_session.dart';
import '../../../shared/domain/auth_repository.dart';
import '../widgets/academic_identity_card.dart';
import '../widgets/password_reset_field.dart';
import '../widgets/password_strength_indicator.dart';

/// Tela de redefinição e cadastro de nova senha de acesso ao Portal AVA.
///
/// Exibida após a validação bem-sucedida da identidade ou token de recuperação,
/// permitindo ao discente, docente ou colaborador cadastrar uma nova senha segura,
/// acompanhar o medidor de entropia em tempo real ([PasswordStrengthIndicator]),
/// confirmar a correspondência entre os campos e retornar à tela de Login com dados sincronizados.
class ResetPasswordPage extends StatefulWidget {
  /// Callback opcional executado quando o usuário aciona o botão de voltar no cabeçalho.
  final VoidCallback? onBackToLogin;
  final AuthRepository repository;

  /// Sessão de recuperação opcional injetada diretamente.
  final RecoverySession? session;

  /// Cria uma instância da tela [ResetPasswordPage].
  const ResetPasswordPage({
    super.key,
    required this.repository,
    this.onBackToLogin,
    this.session,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  /// Comprimento mínimo exigido para a nova senha.
  static const int _minPasswordLength = 6;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _currentPassword = '';
  bool _isSaving = false;

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

  /// Valida as regras de negócio de nova senha e redireciona para a tela de Login com feedback.
  void _handleSavePassword(RecoverySession session) async {
    if (_isSaving) return;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma nova senha.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.length < _minPasswordLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem. Verifique a digitação.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.resetPassword(
        identity: session.identity,
        newPassword: password,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a senha. Tente novamente.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Senha institucional atualizada com sucesso! Redirecionando...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
          arguments: {
            'resetSuccess': true,
            'profile': session.profile,
            'identity': session.identity,
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A redefinição só é permitida após uma sessão de recuperação validada.
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final RecoverySession? session =
        widget.session ?? (routeArgs is RecoverySession ? routeArgs : null);

    if (session == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/recover-password', (route) => false),
            child: const Text('Iniciar recuperação de senha'),
          ),
        ),
      );
    }

    final firstName = session.displayName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TopHeaderBar(
                onBackTap:
                    widget.onBackToLogin ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    },
              ),
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
                        // Pill com saudação dinâmica para a pessoa autenticada
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
                          child: Text(
                            'Olá, $firstName 👋',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
                          'Sua identidade institucional foi confirmada. Cadastre sua nova senha de acesso para restabelecer o acesso seguro aos sistemas acadêmicos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AcademicIdentityCard(session: session),
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
                          hintText: 'Repita a nova senha com exatidão',
                          prefixIcon: Icons.shield_outlined,
                          isObscured: _obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _handleSavePassword(session),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B1325),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: const Color(0x260B1325),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          Icons.arrow_forward_rounded,
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
