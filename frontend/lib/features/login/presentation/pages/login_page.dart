// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/login_controller.dart';
import '../widgets/brand_panel.dart';
import '../widgets/login_profile_tabs.dart';

/// Página principal de autenticação de usuários no portal acadêmico.
/// Suporta layouts responsivos (desktop e compacto/mobile).
class LoginPage extends StatefulWidget {
  /// Controlador reativo opcional que orquestra as regras de negócio de login.
  ///
  /// Caso seja omitido (`null`), a tela operará em modo autônomo com simulação
  /// assíncrona local para prototipagem e visualização de interface.
  final LoginController? controller;

  /// Construtor de [LoginPage].
  const LoginPage({
    super.key,
    this.controller,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Estado da tela de autenticação [LoginPage].
///
/// Gerencia os controladores de texto do formulário, seleção de perfil dinâmico,
/// visibilidade da senha e submissão das credenciais.
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  UserProfile _selectedProfile = UserProfile.admin;

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

  /// Notifica a interface sobre atualizações de estado emitidas pelo [LoginController].
  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Indica se a interface está em estado de processamento/carregamento.
  bool get _isLoading => widget.controller?.isLoading ?? _localLoading;

  /// Retorna o rótulo do campo identificador adaptado ao perfil acadêmico selecionado.
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

  /// Retorna um formato ou exemplo de credencial de acordo com o perfil ativo.
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

  /// Retorna o texto informativo (placeholder) do campo de identificação do perfil.
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

  /// Executa o fluxo de validação e submissão da tentativa de autenticação.
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
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Login realizado com sucesso! Bem-vindo ao AVA.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
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
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.controller!.errorMessage ?? 'Falha ao autenticar.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
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
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Login realizado com sucesso! Bem-vindo ao AVA.',
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
  }

  /// Redireciona para o fluxo institucional de recuperação de senha acadêmica.
  void _handleForgotPassword() {
    Navigator.of(context).pushNamed('/recover-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // #F8FAFC
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          return isCompact ? _buildCompactLayout() : _buildDesktopLayout();
        },
      ),
    );
  }

  /// Constrói o layout de visualização desktop em duas colunas complementares.
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Coluna Esquerda: Painel Hero Cósmico (50% largura)
        const Expanded(
          child: BrandPanel(compact: false),
        ),
        // Coluna Direita: Área do Formulário de Login (50% largura)
        Expanded(
          child: _buildLoginContent(),
        ),
      ],
    );
  }

  /// Constrói o layout compacto responsivo para telas móveis ou janelas menores que 900px.
  Widget _buildCompactLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 520, // min-h-[520px]
              width: double.infinity,
              child: BrandPanel(compact: true),
            ),
            _buildLoginContent(isCompact: true),
          ],
        ),
      ),
    );
  }

  /// Constrói a área central com o formulário de login e seus controles interativos.
  ///
  /// O parâmetro [isCompact] adapta os paddings horizontais e verticais conforme a tela.
  Widget _buildLoginContent({bool isCompact = false}) {
    final errorMessage = widget.controller?.errorMessage;

    final formContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440), // max-w-[440px]
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho do Formulário
              Text(
                'Acesse seu AVA',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: isCompact ? 24 : 30, // text-2xl sm:text-3xl
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 12 : 13.5, // text-xs sm:text-sm
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Entre com seu R.A., Matrícula ou E-mail Institucional\n',
                    ),
                    TextSpan(
                      text: '(@universidade.edu.br)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Label do Seletor de Perfil
              Text(
                'SELECIONE SEU PERFIL',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 11, // text-[11px]
                  fontWeight: FontWeight.bold,
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

              // 1. Campo de Identificador
              _buildIdentityInput(),
              const SizedBox(height: 16),

              // 2. Campo de Senha
              _buildPasswordInput(),
              const SizedBox(height: 14),

              // 3. Linha do Checkbox e Link Esqueceu a Senha
              _buildCredentialRow(),

              // 4. Caixa de Alerta de Erro (Condicional)
              if (errorMessage != null && errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildErrorAlertBox(errorMessage),
              ],

              // 5. Botão de Ação Primária: "Entrar no AVA"
              const SizedBox(height: 20),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: isCompact
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: formContent,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 48,
              ),
              child: formContent,
            ),
    );
  }

  /// Constrói o campo de identificador (R.A., matrícula ou e-mail corporativo) com dica contextual.
  Widget _buildIdentityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _identityLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.slate800,
                  fontSize: 12, // text-xs font-semibold text-slate-800
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _identityExample,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textMuted,
                fontSize: 11, // text-[11px] font-mono text-slate-400
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _identityController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe seu identificador de acesso.';
            }
            return null;
          },
          decoration: _inputDecoration(
            hintText: _identityPlaceholder,
            prefixIcon: Icons.assignment_ind_outlined,
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de entrada de senha com controle de visibilidade (mostrar/ocultar senha).
  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Senha de Acesso',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.slate800,
            fontSize: 12, // text-xs font-semibold text-slate-800
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
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
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói a linha contendo o checkbox "Lembrar credencial" e a navegação "Esqueceu a senha?".
  Widget _buildCredentialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _rememberCredential = !_rememberCredential;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 16, // w-4 h-4
                    height: 16,
                    decoration: BoxDecoration(
                      color: _rememberCredential
                          ? AppColors.buttonPrimary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _rememberCredential
                            ? AppColors.buttonPrimary
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    child: _rememberCredential
                        ? const Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Lembrar credencial neste computador confiável',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, // text-xs text-slate-700
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _handleForgotPassword,
            child: Text(
              'Esqueceu a senha?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, // text-xs font-semibold text-slate-900
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói o quadro de aviso e alerta visual de erros retornados pela autenticação.
  Widget _buildErrorAlertBox(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12), // p-3
      decoration: BoxDecoration(
        color: AppColors.roseBackground, // bg-rose-50
        borderRadius: BorderRadius.circular(8), // rounded-lg
        border: Border.all(
          color: AppColors.roseBorder, // border-rose-200
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.roseIcon, // rose-600
            size: 16, // w-4 h-4
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.roseText, // text-rose-700
                fontSize: 12, // text-xs
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o botão de ação principal "Entrar no AVA" com feedback de carregamento reativo.
  Widget _buildLoginButton() {
    return SizedBox(
      height: 48, // py-3.5
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0B1325), // shadow-md
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary, // #0B1325
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.buttonPrimary.withValues(alpha: 0.75),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Autenticando...',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Entrar no AVA',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Retorna a estilização e decoração visual padronizada dos campos de texto do formulário.
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.textMuted,
        size: 16, // w-4 h-4
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
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
          color: AppColors.slate800,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.roseIcon),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.roseIcon,
          width: 1.4,
        ),
      ),
    );
  }
}