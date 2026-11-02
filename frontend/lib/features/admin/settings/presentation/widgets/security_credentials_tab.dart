// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import '../../../../../core/network/authenticated_api_client.dart';
import '../../../../../core/state/app_user_session.dart';
import '../../../../auth/shared/presentation/change_password_dialog.dart';

/// Configuration tab for Administrator Security & Credentials.
///
/// Consulta a conta real e permite alterar a senha e o segundo fator por e-mail.
class SecurityCredentialsTab extends StatefulWidget {
  const SecurityCredentialsTab({super.key});

  @override
  State<SecurityCredentialsTab> createState() => _SecurityCredentialsTabState();
}

class _SecurityCredentialsTabState extends State<SecurityCredentialsTab> {
  bool? _twoFactor;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    if (AppUserSession.instance.accessToken == null) return;
    try {
      final user = await AuthenticatedApiClient().request(
        'GET',
        '/api/auth/me',
      );
      if (mounted) {
        setState(() => _twoFactor = (user as Map)['twoFactorRequired'] == true);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _changePassword() async {
    final changed = await showPasswordChangeDialog(context);
    if (changed == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _toggleTwoFactor() async {
    final password = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirme sua senha'),
        content: TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha atual'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, password.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    password.dispose();
    if (entered == null || !mounted) return;
    try {
      await AuthenticatedApiClient().request(
        'POST',
        '/api/auth/two-factor',
        body: {'password': entered, 'enabled': _twoFactor != true},
      );
      AppUserSession.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      _buildSecurityCard(
        icon: Icons.vpn_key_rounded,
        title: 'Credencial de Acesso (Senha)',
        badgeText: 'Hash bcrypt',
        badgeBg: const Color(0xFFECFDF5),
        badgeBorder: const Color(0xFFA7F3D0),
        badgeTextColor: const Color(0xFF059669),
        subtitle: 'Altere sua senha usando a credencial atual.',
        actionButton: FilledButton(
          onPressed: _changePassword,
          child: const Text('Alterar Senha'),
        ),
        child: _buildInfoColumn(
          'Senhas protegidas com bcrypt',
          'A troca da senha encerra as sessões anteriores.',
        ),
      ),
      const SizedBox(height: 20),
      _buildSecurityCard(
        icon: Icons.verified_user_outlined,
        title: 'Autenticação em Duas Etapas (2FA)',
        badgeText: _twoFactor == null
            ? 'Consultar conta'
            : _twoFactor!
            ? 'Ativada'
            : 'Desativada',
        badgeBg: const Color(0xFFEFF6FF),
        badgeBorder: const Color(0xFFBFDBFE),
        badgeTextColor: const Color(0xFF1D4ED8),
        subtitle:
            'Código de acesso enviado ao e-mail cadastrado, após validar a senha.',
        actionButton: OutlinedButton(
          onPressed: _twoFactor == null ? null : _toggleTwoFactor,
          child: Text(_twoFactor == true ? 'Desativar' : 'Ativar'),
        ),
        child: _buildInfoColumn(
          'Código temporário de seis dígitos',
          'Validade de cinco minutos e três tentativas. Requer envio de e-mail configurado.',
        ),
      ),
    ],
  );

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeTextColor,
    required String subtitle,
    required Widget actionButton,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              actionButton,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
    String title,
    String subtitle, {
    bool isHighlightGreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isHighlightGreen
                ? const Color(0xFF059669)
                : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
