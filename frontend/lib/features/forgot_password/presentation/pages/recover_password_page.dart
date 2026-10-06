// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/recovery_footer_links.dart';
import '../../../../shared/widgets/top_header_bar.dart';
import '../controllers/recover_password_controller.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/profile_selector_tabs.dart';
import '../widgets/recovery_input_field.dart';
import '../widgets/security_alert_banner.dart';

class RecoverPasswordPage extends StatefulWidget {
  final RecoverPasswordController controller;

  const RecoverPasswordPage({
    super.key,
    required this.controller,
  });

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  late final RecoverPasswordController _controller;
  UserProfile _selectedProfile = UserProfile.aluno;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  String _getInputTitle() {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'R.A. do Aluno ou E-mail Acadêmico';
      case UserProfile.docente:
        return 'Matrícula do Docente ou E-mail Institucional';
      case UserProfile.admin:
        return 'Identificador ou E-mail Administrativo';
    }
  }

  String _getInputExample() {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'ex: 2024.1.00892';
      case UserProfile.docente:
        return 'ex: DOC-40892';
      case UserProfile.admin:
        return 'ex: ADM-90812';
    }
  }

  String _getInputPlaceholder() {
    switch (_selectedProfile) {
      case UserProfile.aluno:
        return 'Digite seu R.A. ou nome@aluno.universidade.edu.br';
      case UserProfile.docente:
        return 'Digite sua matrícula ou e-mail institucional';
      case UserProfile.admin:
        return 'Digite seu identificador administrativo';
    }
  }

  void _handleSubmit() async {
    final success = await _controller.submit();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Código de verificação enviado! Redirecionando...',
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
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(context).pushNamed(
            '/verify-code',
            arguments: _controller.identity,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Branding Header
            TopHeaderBar(
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
            // Central Content Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Título Principal
                        Text(
                          'Esqueceu sua senha?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),

                        // Subtítulo descritivo (Generico para Aluno, Docente e Admin)
                        Text(
                          'Informe seu R.A., Matrícula ou E-mail Institucional cadastrado.\nEnviaremos um link temporário para restauração da credencial.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),

                        // Seletor de Perfil (Aluno, Docente, Admin)
                        ProfileSelectorTabs(
                          selectedProfile: _selectedProfile,
                          onProfileChanged: (profile) {
                            setState(() {
                              _selectedProfile = profile;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Campo de entrada com Rótulo Duplo (Dinâmico por perfil)
                        RecoveryInputField(
                          inputTitle: _getInputTitle(),
                          example: _getInputExample(),
                          placeholder: _getInputPlaceholder(),
                          errorMessage: _controller.errorMessage,
                          onChanged: _controller.setIdentity,
                          onSubmitted: _handleSubmit,
                        ),
                        const SizedBox(height: 16),

                        // Alerta de Segurança Âmbar (Validade de 5 minutos)
                        const SecurityAlertBanner(),
                        const SizedBox(height: 24),

                        // Banner de Sucesso pós envio
                        if (_controller.isSuccess) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF059669),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'E-mail com instruções de recuperação enviado com sucesso!',
                                    style: TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Botão Principal Escuro com Seta à Direita
                        PrimaryActionButton(
                          label: 'Enviar Instruções de Recuperação',
                          isLoading: _controller.isLoading,
                          onPressed: _handleSubmit,
                        ),
                        const SizedBox(height: 36),

                        // Rodapé com Links de Suporte
                        RecoveryFooterLinks(
                          onSuporteTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Redirecionando para a Secretaria ou Suporte...'),
                              ),
                            );
                          },
                          onHelpCenterTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Abrindo Central de Ajuda...'),
                              ),
                            );
                          },
                          onFaqTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Abrindo Perguntas Frequentes...'),
                              ),
                            );
                          },
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
