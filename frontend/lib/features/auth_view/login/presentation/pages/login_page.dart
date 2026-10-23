// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/login_controller.dart';
import '../widgets/brand_panel.dart';
import '../widgets/login_form_fields.dart';
import '../widgets/login_profile_tabs.dart';

/// Página principal de autenticação de usuários no portal acadêmico.
/// Suporta layouts responsivos (desktop e compacto/mobile).
class LoginPage extends StatefulWidget {
  final LoginController? controller;

  const LoginPage({super.key, this.controller});

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
  bool _localLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isLoading => widget.controller?.isLoading ?? _localLoading;

  String get _identityLabel {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'R.A. do Aluno ou E-mail Acadêmico';
      case UserProfile.docente:
        return 'Matrícula do Docente ou E-mail Institucional';
      case UserProfile.admin:
        return 'Identificação Administrativa ou E-mail Corporativo';
    }
  }

  String get _identityExample {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'ex: 2024.1.00892';
      case UserProfile.docente:
        return 'ex: DOC-40892';
      case UserProfile.admin:
        return 'ex: ADM-00123';
    }
  }

  String get _identityPlaceholder {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'Digite seu R.A. ou nome@aluno.universidade.edu.br';
      case UserProfile.docente:
        return 'Digite sua matrícula ou e-mail institucional';
      case UserProfile.admin:
        return 'Digite seu login ou admin@universidade.edu.br';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final identity = _identityController.text.trim();
    final password = _passwordController.text;
    final profileName = _selectedProfile.name;

    if (widget.controller != null) {
      final success = await widget.controller!.login(
        identity: identity,
        password: password,
        profile: profileName,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF059669),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Login realizado com sucesso! Bem-vindo ao AVA.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );

        _redirectAfterLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.controller!.errorMessage ?? 'Falha ao autenticar.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      setState(() {
        _localLoading = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _localLoading = false;
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
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Login realizado com sucesso! Bem-vindo ao AVA.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );

      _redirectAfterLogin();
    }
  }

  void _redirectAfterLogin() {
    if (_selectedProfile == UserProfile.admin) {
      Navigator.of(context).pushReplacementNamed('/admin-shell');
    } else if (_selectedProfile == UserProfile.aluno) {
      Navigator.of(context).pushReplacementNamed('/student/home');
    } else if (_selectedProfile == UserProfile.docente) {
      Navigator.of(context).pushReplacementNamed('/docente/home');
    }
  }

  void _handleForgotPassword() {
    Navigator.of(context).pushNamed('/recover-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: BrandPanel(compact: false)),
        Expanded(child: _buildLoginContent(isCompact: false)),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 520,
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
    final errorMessage = widget.controller?.errorMessage;

    final formContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Acesse seu AVA',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0F172A),
                  fontSize: isCompact ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: isCompact ? 13 : 14,
                    height: 1.45,
                  ),
                  children: const [
                    TextSpan(
                      text:
                          'Entre com seu R.A., Matrícula ou E-mail Institucional\n',
                    ),
                    TextSpan(
                      text: '(@universidade.edu.br)',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'SELECIONE SEU PERFIL',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              LoginProfileTabs(
                selectedProfile: _selectedProfile,
                onProfileChanged: (profile) {
                  setState(() {
                    _selectedProfile = profile;
                    _identityController.clear();
                    widget.controller?.clearError();
                  });
                },
              ),
              const SizedBox(height: 20),
              LoginIdentityField(
                controller: _identityController,
                label: _identityLabel,
                example: _identityExample,
                placeholder: _identityPlaceholder,
              ),
              const SizedBox(height: 16),
              LoginPasswordField(
                controller: _passwordController,
                obscurePassword: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onSubmitted: _handleLogin,
              ),
              const SizedBox(height: 14),
              LoginCredentialRow(
                rememberCredential: _rememberCredential,
                onToggleRemember: (val) {
                  setState(() {
                    _rememberCredential = val;
                  });
                },
                onForgotPassword: _handleForgotPassword,
              ),
              if (errorMessage != null && errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                LoginErrorAlertBox(errorMessage: errorMessage),
              ],
              const SizedBox(height: 20),
              LoginSubmitButton(
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      height: isCompact ? null : double.infinity,
      color: Colors.white,
      child: isCompact
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: formContent,
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 48,
                ),
                child: formContent,
              ),
            ),
    );
  }
}
