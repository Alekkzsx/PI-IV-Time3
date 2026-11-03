// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/login_controller.dart';
import '../widgets/brand_panel.dart';
import '../widgets/login_form_fields.dart';
import '../widgets/login_profile_tabs.dart';
import '../../../../../core/network/authenticated_api_client.dart';
import '../../../../../core/state/app_user_session.dart';
import '../../../shared/presentation/change_password_dialog.dart';

/// Página principal de autenticação de usuários no portal acadêmico.
/// Suporta layouts responsivos (desktop e compacto/mobile), propagação dinâmica de perfis
/// e recepção de feedbacks de redefinição de senha e prontidão para 2FA.
class LoginPage extends StatefulWidget {
  final LoginController controller;

  const LoginPage({super.key, required this.controller});

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
  bool _argumentsChecked = false;
  String? _successBannerMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final remembered = AppUserSession.instance.getRememberedIdentity();
    if (remembered != null) {
      _identityController.text = remembered;
      _rememberCredential = true;
    } else {
      _rememberCredential = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsChecked) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['resetSuccess'] == true) {
        if (args['profile'] is UserProfile) {
          _selectedProfile = args['profile'] as UserProfile;
        }
        if (args['identity'] is String &&
            (args['identity'] as String).isNotEmpty) {
          _identityController.text = args['identity'] as String;
        }
        _successBannerMessage =
            'Sua senha foi redefinida com sucesso. Digite sua nova credencial para acessar.';
      }
      _argumentsChecked = true;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _isLoading => widget.controller.isLoading;

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
        return 'ex: 202610401';
      case UserProfile.docente:
        return 'ex: docente.agmrm';
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
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final identity = _identityController.text.trim();
    final password = _passwordController.text;
    final profile = _selectedProfile;
    final profileName = profile.name;

    var success = await widget.controller.login(
      identity: identity,
      password: password,
      profile: profileName,
    );

    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    if (widget.controller.requiresTwoFactor) {
      success =
          await showDialog<bool>(
            context: context,
            builder: (_) => _LoginCodeDialog(
              controller: widget.controller,
              identity: identity,
            ),
          ) ??
          false;
      if (!mounted) return;
    }
    if (success) {
      try {
        final account = await AuthenticatedApiClient().request(
          'GET',
          '/api/auth/me',
        );
        if (account is Map) {
          AppUserSession.instance.applyProfileMap(
            Map<String, dynamic>.from(account),
          );
        }
        if (!mounted) return;
        if (account is Map && account['requirePasswordChange'] == true) {
          await showPasswordChangeDialog(context, requiredChange: true);
          return;
        }
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
    }

    if (success) {
      AppUserSession.instance.setRememberedIdentity(
        _rememberCredential ? identity : null,
      );
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

      _redirectAfterLogin(profile);
    } else {
      final errorMessage = widget.controller.requiresTwoFactor
          ? 'Esta conta exige verificação em duas etapas, indisponível neste fluxo.'
          : widget.controller.errorMessage ?? 'Falha ao autenticar.';
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
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _redirectAfterLogin(UserProfile profile) {
    if (profile == UserProfile.admin) {
      Navigator.of(context).pushReplacementNamed('/admin-shell');
    } else if (profile == UserProfile.aluno) {
      Navigator.of(context).pushReplacementNamed('/student/home');
    } else if (profile == UserProfile.docente) {
      Navigator.of(context).pushReplacementNamed('/docente/home');
    }
  }

  void _handleForgotPassword() {
    // Transmite dinamicamente o perfil ativo para a tela de recuperação
    Navigator.of(
      context,
    ).pushNamed('/recover-password', arguments: _selectedProfile);
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
    final errorMessage = widget.controller.errorMessage;

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

              // Banner de feedback de senha redefinida com sucesso
              if (_successBannerMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successBannerMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF15803D),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF16A34A),
                        ),
                        onPressed: () {
                          setState(() {
                            _successBannerMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],

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
                  if (_isLoading) return;
                  setState(() {
                    _selectedProfile = profile;
                    _identityController.clear();
                    widget.controller.clearError();
                  });
                },
              ),
              const SizedBox(height: 20),
              LoginIdentityField(
                controller: _identityController,
                label: _identityLabel,
                example: _identityExample,
                placeholder: _identityPlaceholder,
                onChanged: (_) => widget.controller.clearError(),
              ),
              const SizedBox(height: 16),
              LoginPasswordField(
                controller: _passwordController,
                obscurePassword: _obscurePassword,
                onChanged: (_) => widget.controller.clearError(),
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
              LoginSubmitButton(isLoading: _isLoading, onPressed: _handleLogin),
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

class _LoginCodeDialog extends StatefulWidget {
  final LoginController controller;
  final String identity;
  const _LoginCodeDialog({required this.controller, required this.identity});
  @override
  State<_LoginCodeDialog> createState() => _LoginCodeDialogState();
}

class _LoginCodeDialogState extends State<_LoginCodeDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.controller.verifyTwoFactorToken(
      identity: widget.identity,
      code: _code.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = widget.controller.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Verificação em duas etapas'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Informe o código de seis dígitos enviado ao e-mail cadastrado. Ele expira em cinco minutos.',
        ),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Código de acesso'),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? 'Validando...' : 'Confirmar'),
      ),
    ],
  );
}
