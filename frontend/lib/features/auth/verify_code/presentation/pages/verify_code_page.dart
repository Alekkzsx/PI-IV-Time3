// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/widgets/top_header_bar.dart';
import '../../../shared/domain/auth_repository.dart';
import '../../../shared/domain/models/recovery_session.dart';

/// Tela de conferência de token de segurança OTP (One-Time Password) de 6 dígitos.
///
/// Permite ao discente ou colaborador validar o código numérico enviado para seu
/// e-mail institucional antes de receber a permissão de redefinição de senha.
/// Possui suporte a foco automático, avanço de cursor entre dígitos, colagem
/// de código completo e recuo suave via tecla Backspace.
class VerifyCodePage extends StatefulWidget {
  /// Identificador do discente ou e-mail alvo para exibição no cabeçalho informativo.
  final AuthRepository repository;

  /// Sessão de recuperação opcional injetada diretamente em testes ou fluxos embutidos.
  final RecoverySession? session;

  /// Cria uma instância da tela [VerifyCodePage].
  const VerifyCodePage({super.key, required this.repository, this.session});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  /// Quantidade de dígitos numéricos exigidos no código OTP.
  static const int _codeLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  bool _isHovered = false;
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isNavigating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus no primeiro campo ao carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Retorna o código agregado concatenando os caracteres dos 6 controladores.
  String get _currentCode {
    return _controllers.map((c) => c.text).join();
  }

  /// Verifica se todos os 6 dígitos do código OTP foram preenchidos.
  bool get _isCodeComplete {
    return RegExp(r'^\d{6}$').hasMatch(_currentCode);
  }

  /// Trata a alteração de conteúdo em cada um dos 6 campos de dígito.
  void _onFieldChanged(String value, int index) {
    if (_isVerifying || _isResending || _isNavigating) return;

    if (value.length > 1) {
      final rawDigits = value.replaceAll(RegExp(r'\D'), '');
      final digits = rawDigits.length > _codeLength
          ? rawDigits.substring(0, _codeLength)
          : rawDigits;
      for (final controller in _controllers) {
        controller.clear();
      }
      for (int i = 0; i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      setState(() => _errorMessage = null);
      if (digits.length == _codeLength) {
        _focusNodes[_codeLength - 1].unfocus();
      } else {
        _focusNodes[digits.length].requestFocus();
      }
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  /// Intercepta a tecla Backspace para limpar o campo anterior e recuar o foco
  /// quando o campo atual já estiver sem conteúdo.
  void _onKey(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        setState(() {
          _errorMessage = null;
        });
      }
    }
  }

  /// Executa a validação do token OTP digitado contra a credencial esperada.
  ///
  /// Em caso de sucesso, exibe notificação e navega para `/reset-password`
  /// repassando a [RecoverySession].
  Future<void> _handleConfirm(RecoverySession session) async {
    final code = _currentCode;
    if (!_isCodeComplete || _isVerifying || _isResending || _isNavigating) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await widget.repository.verifyOtpToken(
        identity: session.identity,
        code: code,
      );
      if (!mounted) return;

      if (isValid) {
        _isNavigating = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Código verificado com sucesso! Redirecionando...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/reset-password', arguments: session);
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Código inválido ou expirado. Confira os 6 dígitos e tente novamente.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Código inválido ou expirado. Tente novamente.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Não foi possível validar o código agora. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Restaura os 6 campos para vazio, reposiciona o foco no primeiro dígito
  /// e simula o reenvio de um novo token para o e-mail cadastrado.
  Future<void> _handleResendCode(RecoverySession session) async {
    if (_isResending || _isVerifying || _isNavigating) return;
    setState(() => _isResending = true);
    try {
      await widget.repository.recoverPassword(identity: session.identity);
      if (!mounted) return;
      for (final controller in _controllers) {
        controller.clear();
      }
      setState(() {
        _errorMessage = null;
      });
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Novo código enviado para ${session.maskedEmail}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Não foi possível reenviar o código. Tente novamente em instantes.';
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A sessão deve ser criada no pedido de recuperação e transportada pela rota.
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final RecoverySession? session =
        widget.session ?? (routeArgs is RecoverySession ? routeArgs : null);

    if (session == null) {
      return _MissingRecoverySession(
        onBack: () => Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/recover-password', (route) => false),
      );
    }

    final isComplete = _isCodeComplete;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Branding Header
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TopHeaderBar(
                onBackTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      '/recover-password',
                    );
                  }
                },
              ),
            ),

            // Central Content Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ícone Central com Badge Circular
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              session.profileIcon,
                              size: 26,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Badge com Perfil e Identificador Oficial
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '${session.roleBadge} • ${session.formattedIdentityLabel}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Título Principal
                        Text(
                          'Verifique seu e-mail',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtítulo com identificador e e-mail mascarado dinâmico
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              height: 1.5,
                              color: const Color(0xFF64748B),
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'Enviamos o código institucional de 6 dígitos para o endereço ',
                              ),
                              TextSpan(
                                text: session.maskedEmail,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              TextSpan(text: ' (${session.displayName}).'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Grade dos 6 Inputs OTP
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth
                                .clamp(0.0, 336.0)
                                .toDouble();
                            final gap = availableWidth >= 336
                                ? (availableWidth - 6 * 48) / 5
                                : 4.0;
                            final digitWidth =
                                (availableWidth - 5 * gap) / _codeLength;

                            return SizedBox(
                              width: availableWidth,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(_codeLength, (index) {
                                  final isFocused = _focusNodes[index].hasFocus;
                                  final hasError = _errorMessage != null;

                                  return Focus(
                                    onKeyEvent: (node, event) {
                                      _onKey(event, index);
                                      return KeyEventResult.ignored;
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: digitWidth,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: hasError
                                              ? const Color(0xFFEF4444)
                                              : isFocused
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFE2E8F0),
                                          width: isFocused || hasError
                                              ? 1.6
                                              : 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isFocused
                                                ? const Color(
                                                    0xFF0F172A,
                                                  ).withValues(alpha: 0.06)
                                                : Colors.black.withValues(
                                                    alpha: 0.02,
                                                  ),
                                            blurRadius: isFocused ? 6 : 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: TextField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          enabled:
                                              !_isVerifying &&
                                              !_isResending &&
                                              !_isNavigating,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (val) =>
                                              _onFieldChanged(val, index),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        const SizedBox(height: 24),

                        // Botão Confirmar Código
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 336),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: MouseRegion(
                              onEnter: (_) => setState(() => _isHovered = true),
                              onExit: (_) => setState(() => _isHovered = false),
                              cursor:
                                  isComplete &&
                                      !_isVerifying &&
                                      !_isResending &&
                                      !_isNavigating
                                  ? SystemMouseCursors.click
                                  : SystemMouseCursors.basic,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color:
                                      isComplete &&
                                          !_isVerifying &&
                                          !_isResending &&
                                          !_isNavigating
                                      ? (_isHovered
                                            ? const Color(0xFF05070B)
                                            : const Color(0xFF0B1325))
                                      : const Color(0xFF788292),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow:
                                      isComplete &&
                                          !_isVerifying &&
                                          !_isResending &&
                                          !_isNavigating
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF0B1325,
                                            ).withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        isComplete &&
                                            !_isVerifying &&
                                            !_isResending &&
                                            !_isNavigating
                                        ? () => _handleConfirm(session)
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isVerifying
                                                  ? 'Validando...'
                                                  : 'Confirmar Código',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    letterSpacing: -0.2,
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
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Rodapé Reenviar E-mail
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Não recebeu o código? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            InkWell(
                              onTap:
                                  _isResending || _isVerifying || _isNavigating
                                  ? null
                                  : () => _handleResendCode(session),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                child: Text(
                                  _isResending
                                      ? 'Reenviando...'
                                      : 'Reenviar e-mail',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingRecoverySession extends StatelessWidget {
  final VoidCallback onBack;

  const _MissingRecoverySession({required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset_outlined, size: 42),
            const SizedBox(height: 16),
            const Text(
              'Inicie a recuperação de senha para validar o código.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              child: const Text('Recuperar senha'),
            ),
          ],
        ),
      ),
    ),
  );
}
