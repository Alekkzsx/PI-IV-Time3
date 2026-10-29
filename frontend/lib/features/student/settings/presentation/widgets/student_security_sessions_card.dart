// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Card de configurações de 2FA, gerenciamento de sessões ativas discentes e auditoria de segurança.
class StudentSecuritySessionsCard extends StatefulWidget {
  final StudentPortalController controller;

  const StudentSecuritySessionsCard({super.key, required this.controller});

  @override
  State<StudentSecuritySessionsCard> createState() =>
      _StudentSecuritySessionsCardState();
}

class _StudentSecuritySessionsCardState
    extends State<StudentSecuritySessionsCard> {
  bool _mobileSessionRevoked = false;
  List<String> _backupCodes = [
    '8F2A-91K4',
    '3C9X-41M8',
    '7P2L-09Q3',
    '5V8N-11R6',
    '9T4B-62Z5',
    '2M7K-83W1',
    '4J6H-55D9',
    '1X9Y-74E2',
  ];

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.lock_reset_rounded,
              size: 22,
              color: Color(0xFF18181B),
            ),
            const SizedBox(width: 10),
            Text(
              'Alterar Senha de Acesso',
              style: jakarta(
                size: 16,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sua nova senha deve conter no mínimo 8 caracteres, incluindo letras maiúsculas, minúsculas, números e símbolos.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              _buildModalField(
                'Senha Atual',
                currentPassController,
                isObscure: true,
              ),
              const SizedBox(height: 14),
              _buildModalField(
                'Nova Senha',
                newPassController,
                isObscure: true,
              ),
              const SizedBox(height: 14),
              _buildModalField(
                'Confirmar Nova Senha',
                confirmPassController,
                isObscure: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: jakarta(size: 13, color: const Color(0xFF71717A)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Senha de acesso institucional atualizada com sucesso!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Salvar Nova Senha',
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller, {
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: jakarta(
            size: 11.5,
            weight: FontWeight.w600,
            color: const Color(0xFF3F3F46),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: jakarta(size: 13, color: const Color(0xFF18181B)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFF18181B),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _regenerateBackupCodes() {
    setState(() {
      _backupCodes = List.generate(
        8,
        (i) =>
            '${(1000 + i * 379).toRadixString(36).toUpperCase()}-${(2000 + i * 541).toRadixString(36).toUpperCase()}',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Novos códigos de recuperação gerados. Os anteriores foram invalidados.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF18181B),
      ),
    );
  }

  void _copyBackupCodes() {
    Clipboard.setData(ClipboardData(text: _backupCodes.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '8 códigos de backup copiados para a área de transferência.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _revokeMobileSession() {
    setState(() => _mobileSessionRevoked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessão remota no iPhone 15 Pro encerrada com sucesso.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF18181B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Credencial de Acesso (Senha)
        _buildPasswordCard(),
        const SizedBox(height: 20),

        // 2. Autenticação em Duas Etapas (2FA)
        _buildTwoFactorCard(),
        const SizedBox(height: 20),

        // 3. Códigos de Recuperação (Backup)
        _buildBackupCodesCard(),
        const SizedBox(height: 20),

        // 4. Sessões Ativas & Dispositivos Conectados
        _buildActiveSessionsCard(),
        const SizedBox(height: 20),

        // 5. Histórico Recente de Acesso (Auditoria de Segurança)
        _buildAuditLogsCard(),
      ],
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF18181B),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.key_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        'Credencial de Acesso (Senha)',
                        style: jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          'Protegida',
                          style: jakarta(
                            size: 10,
                            weight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(
                  Icons.lock_reset_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  'Alterar Senha',
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Utilizada para entrar no AVA, Portal Acadêmico e redes Wi-Fi dos campi.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Última alteração de senha: há 42 dias • Expiração automática em 138 dias (Política DTI)',
                    style: jakarta(size: 12, color: const Color(0xFF52525B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoFactorCard() {
    final is2FaEnabled = widget.controller.isTwoFactorEnabled;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: is2FaEnabled
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.security_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        'Autenticação em Duas Etapas (2FA)',
                        style: jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: is2FaEnabled
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: is2FaEnabled
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          is2FaEnabled ? '2FA ATIVO' : 'DESATIVADO',
                          style: jakarta(
                            size: 10,
                            weight: FontWeight.w700,
                            color: is2FaEnabled
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: is2FaEnabled,
                onChanged: (_) {
                  widget.controller.toggleTwoFactor();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.controller.isTwoFactorEnabled
                            ? 'Autenticação em duas etapas ativada com sucesso!'
                            : 'Aviso: Autenticação em duas etapas desativada.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: widget.controller.isTwoFactorEnabled
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  );
                },
                activeTrackColor: const Color(0xFF16A34A),
                activeThumbColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Exige código temporário de 6 dígitos gerado via app autenticador ao conectar em computadores dos laboratórios ou novos navegadores.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phonelink_lock_rounded,
                  size: 18,
                  color: Color(0xFF18181B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aplicativos compatíveis: Google Authenticator, Microsoft Authenticator e Authy.',
                    style: jakarta(size: 12, color: const Color(0xFF52525B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCodesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pin_rounded,
                    size: 20,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Códigos de Recuperação (Backup)',
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _regenerateBackupCodes,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: Color(0xFF18181B),
                    ),
                    label: Text(
                      'Gerar Novos',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _copyBackupCodes,
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Copiar Todos',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cada código pode ser usado uma única vez caso você perca o acesso ao seu dispositivo com autenticador.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 16),
          // Grid de Códigos de Backup
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: _backupCodes.map((code) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: const Color(0xFF18181B),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.devices_rounded,
                size: 20,
                color: Color(0xFF18181B),
              ),
              const SizedBox(width: 8),
              Text(
                'Sessões Ativas & Dispositivos Conectados',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dispositivos atualmente autenticados com sua conta institucional discente.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),

          // Sessão 1: Dispositivo Atual (Web)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.laptop_chromebook_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Google Chrome 126 no Windows 11',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              'Esta sessão (Ativo)',
                              style: jakarta(
                                size: 9.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'IP: 177.136.24.10 • Curitiba, Brasil • Conectado via Wi-Fi Acadêmico',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sessão 2: Mobile App
          if (!_mobileSessionRevoked) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F4F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_iphone_rounded,
                      size: 18,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aplicativo Móvel Universitário no iOS 18 (iPhone 15 Pro)',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'IP: 189.28.14.92 • Curitiba, Brasil • Última atividade: há 3 horas',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _revokeMobileSession,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Desconectar',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditLogsCard() {
    final logs = [
      {
        'data': 'Hoje às 08:30',
        'origem': 'Google Chrome (Windows 11)',
        'ip': '177.136.24.10',
        'status': 'Sucesso (2FA)',
      },
      {
        'data': 'Ontem às 19:15',
        'origem': 'App Mobile (iOS 18)',
        'ip': '189.28.14.92',
        'status': 'Sucesso (Biometria)',
      },
      {
        'data': '21/10/2026 às 14:02',
        'origem': 'Laboratório de Informática 03 (Linux)',
        'ip': '10.20.1.45',
        'status': 'Sucesso (2FA)',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.manage_history_rounded,
                size: 20,
                color: Color(0xFF18181B),
              ),
              const SizedBox(width: 8),
              Text(
                'Histórico Recente de Acesso (Auditoria)',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Registros forenses de login autenticados nos sistemas centrais.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 16),
          Column(
            children: logs.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log['data']!,
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${log['origem']} • IP ${log['ip']}',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    Text(
                      log['status']!,
                      style: jakarta(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
