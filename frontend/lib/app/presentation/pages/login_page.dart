// Desenvolvido por Murillo Caravita

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/brand_panel.dart';
import '../widgets/login_profile_tabs.dart';

/// Página principal de autenticação de usuários no portal acadêmico.
/// Suporta layouts responsivos (desktop e compacto/mobile).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  UserProfile _selectedProfile = UserProfile.aluno;

  bool _obscurePassword = true;
  bool _rememberCredential = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _identityLabel {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'R.A. do Aluno ou E-mail Acadêmico';
      case UserProfile.docente:
        return 'Matrícula do Docente ou E-mail Institucional';
      case UserProfile.admin:
        return 'Identificador ou E-mail Administrativo';
    }
  }

  String get _identityExample {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'ex: 2024.1.00892';
      case UserProfile.docente:
        return 'ex: DOC-40892';
      case UserProfile.admin:
        return 'ex: ADM-90812';
    }
  }

  String get _identityPlaceholder {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'Digite seu R.A. ou nome@aluno.universidade.edu.br';
      case UserProfile.docente:
        return 'Digite sua matrícula ou e-mail institucional';
      case UserProfile.admin:
        return 'Digite seu identificador administrativo';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    // Simulação temporária de requisição de login.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF059669),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Login realizado com sucesso!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleForgotPassword() {
    Navigator.of(context).pushNamed('/recover-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          return isCompact ? _buildCompactLayout() : _buildDesktopLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const Expanded(
          flex: 11,
          child: BrandPanel(compact: false),
        ),
        Expanded(
          flex: 9,
          child: _buildLoginContent(),
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 300,
              width: double.infinity,
              child: BrandPanel(compact: true),
            ),
            _buildLoginContent(isCompact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginContent({bool isCompact = false}) {
    return Container(
      width: double.infinity,
      color: AppColors.cardBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 24 : 48,
            vertical: isCompact ? 36 : 48,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Acesse seu AVA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre com seu R.A., Matrícula ou E-mail Institucional\n'
                    '(@universidade.edu.br)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'SELECIONE SEU PERFIL',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LoginProfileTabs(
                    selectedProfile: _selectedProfile,
                    onProfileChanged: (profile) {
                      setState(() {
                        _selectedProfile = profile;
                        _identityController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildIdentityInput(),
                  const SizedBox(height: 18),
                  _buildPasswordInput(),
                  const SizedBox(height: 14),
                  _buildCredentialRow(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _identityLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              _identityExample,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _identityController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe seu identificador.';
            }
            return null;
          },
          decoration: _inputDecoration(
            hintText: _identityPlaceholder,
            prefixIcon: Icons.badge_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Senha de Acesso',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe sua senha.';
            }
            if (value.length < 6) {
              return 'A senha precisa ter pelo menos 6 caracteres.';
            }
            return null;
          },
          decoration: _inputDecoration(
            hintText: 'Sua senha cadastrada no portal',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialRow() {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _rememberCredential,
            activeColor: AppColors.buttonDark,
            side: const BorderSide(
              color: AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (value) {
              setState(() {
                _rememberCredential = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Lembrar credencial neste computador confiável',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _handleForgotPassword,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Esqueceu a senha?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Entrar no AVA',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.textMuted,
        size: 18,
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.borderFocused,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.4,
        ),
      ),
    );
  }
}