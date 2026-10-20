// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Tab page for managing teacher profile, 2FA security, active sessions, audit logs, and LGPD.
class DocenteSettingsTab extends StatefulWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteSettingsTab({
    super.key,
    required this.controller,
  });

  @override
  State<DocenteSettingsTab> createState() => _DocenteSettingsTabState();
}

class _DocenteSettingsTabState extends State<DocenteSettingsTab> {
  late TextEditingController _socialNameController;
  late TextEditingController _personalEmailController;
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _notifySubmissions = true;
  bool _notifyMecDeadlines = true;
  bool _notifyAttendanceRisk = true;
  bool _notifyPush = false;

  @override
  void initState() {
    super.initState();
    _socialNameController = TextEditingController(text: widget.controller.profile.socialName);
    _personalEmailController = TextEditingController(text: widget.controller.profile.personalEmail);
  }

  @override
  void dispose() {
    _socialNameController.dispose();
    _personalEmailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtab = widget.controller.settingsSubtab;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSubtabsBar(subtab),
          const SizedBox(height: 24),
          _buildSubtabContent(subtab),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações Docente & Segurança Institucional',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: DocenteColors.charcoal,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Gestão de perfil, credenciais de acesso, 2FA, sessões ativas e privacidade LGPD',
          style: TextStyle(
            fontSize: 14,
            color: DocenteColors.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtabsBar(String activeSubtab) {
    final tabs = [
      {'key': 'perfil', 'label': 'Perfil Docente'},
      {'key': 'seguranca', 'label': 'Segurança & Acessos'},
      {'key': 'notificacoes', 'label': 'Notificações'},
      {'key': 'preferencias', 'label': 'Preferências'},
      {'key': 'privacidade', 'label': 'Privacidade & LGPD'},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocenteColors.border)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = activeSubtab == tab['key'];
          return InkWell(
            onTap: () => widget.controller.setSettingsSubtab(tab['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? DocenteColors.charcoal : Colors.transparent,
                    width: 2.0,
                  ),
                ),
              ),
              child: Text(
                tab['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? DocenteColors.charcoal : DocenteColors.slate,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubtabContent(String subtab) {
    switch (subtab) {
      case 'perfil':
        return _buildProfileTab();
      case 'seguranca':
        return _buildSecurityTab();
      case 'notificacoes':
        return _buildNotificationsTab();
      case 'preferencias':
        return _buildPreferencesTab();
      case 'privacidade':
        return _buildPrivacyTab();
      default:
        return _buildSecurityTab();
    }
  }

  Widget _buildProfileTab() {
    final profile = widget.controller.profile;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: DocenteColors.charcoal,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'HB',
                  style: TextStyle(color: DocenteColors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                  ),
                  Text(
                    '${profile.title} • Matrícula: ${profile.registrationNumber}',
                    style: const TextStyle(fontSize: 13, color: DocenteColors.slate),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: DocenteColors.border),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField('Nome Completo Institucional', profile.fullName),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField('E-mail Institucional (@universidade.edu.br)', profile.institutionalEmail),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEditableField('Nome Social (Opcional)', _socialNameController),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditableField('E-mail Pessoal para Recuperação', _personalEmailController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField('Regime de Trabalho', profile.workRegime),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField('Currículo Lattes', profile.lattesUrl),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.controller.updateProfile(
                  socialName: _socialNameController.text.trim(),
                  personalEmail: _personalEmailController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados do perfil docente atualizados com sucesso!'),
                    backgroundColor: DocenteColors.emerald,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Salvar Informações do Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    final profile = widget.controller.profile;

    return Column(
      children: [
        // 2FA Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DocenteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (profile.twoFactorEnabled ? DocenteColors.emerald : DocenteColors.crimson).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  profile.twoFactorEnabled ? Icons.security_rounded : Icons.gpp_maybe_rounded,
                  color: profile.twoFactorEnabled ? DocenteColors.emerald : DocenteColors.crimson,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Autenticação em Dois Fatores (2FA)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (profile.twoFactorEnabled ? DocenteColors.emerald : DocenteColors.crimson).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.twoFactorEnabled ? 'Ativo (App Autenticador)' : 'Desativado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: profile.twoFactorEnabled ? DocenteColors.emerald : DocenteColors.crimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A autenticação em dois fatores protege seu lançamento de notas oficiais e dados sensíveis dos discentes exigindo um código TOTP a cada login.',
                      style: TextStyle(fontSize: 13, color: DocenteColors.slate, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  widget.controller.toggleTwoFactor();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.controller.profile.twoFactorEnabled
                            ? 'Autenticação 2FA ativada com sucesso!'
                            : 'Autenticação 2FA desativada temporariamente.',
                      ),
                      backgroundColor: DocenteColors.charcoal,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.charcoal,
                  side: const BorderSide(color: DocenteColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(profile.twoFactorEnabled ? 'Desativar 2FA' : 'Configurar 2FA'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Active Sessions Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DocenteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sessões Ativas Conectadas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dispositivos atualmente autenticados no Portal do Docente',
                style: TextStyle(fontSize: 13, color: DocenteColors.slate),
              ),
              const SizedBox(height: 16),
              ...profile.activeSessions.map((session) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DocenteColors.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DocenteColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        session.device.toLowerCase().contains('phone') ? Icons.phone_iphone : Icons.laptop_mac,
                        color: DocenteColors.charcoal,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  session.device,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                if (session.isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: DocenteColors.emerald.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Esta Sessão (Atual)',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DocenteColors.emerald),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'IP: ${session.ip} • ${session.location} • ${session.lastActive}',
                              style: const TextStyle(fontSize: 11, color: DocenteColors.slate),
                            ),
                          ],
                        ),
                      ),
                      if (!session.isCurrent)
                        TextButton(
                          onPressed: () {
                            widget.controller.disconnectSession(session.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sessão encerrada com sucesso.'),
                                backgroundColor: DocenteColors.charcoal,
                              ),
                            );
                          },
                          child: const Text('Desconectar', style: TextStyle(color: DocenteColors.crimson, fontSize: 12)),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Audit Trail Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DocenteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Histórico de Auditoria & Logins Recentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
              ),
              const SizedBox(height: 4),
              const Text(
                'Registro auditável de tentativas de autenticação para conformidade institucional',
                style: TextStyle(fontSize: 13, color: DocenteColors.slate),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(DocenteColors.offWhite),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Data / Hora', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Dispositivo / Navegador', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Endereço IP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Localização', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    ],
                    rows: profile.loginAudits.map((audit) {
                      return DataRow(
                        cells: [
                          DataCell(Text(audit.timestamp, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(audit.device, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                          DataCell(Text(audit.ip, style: const TextStyle(fontSize: 12, color: DocenteColors.slate))),
                          DataCell(Text(audit.location, style: const TextStyle(fontSize: 12))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (audit.success ? DocenteColors.emerald : DocenteColors.crimson).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                audit.success ? 'Sucesso' : 'Bloqueado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: audit.success ? DocenteColors.emerald : DocenteColors.crimson,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferências de Comunicação & Notificações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Notificações de Novas Entregas de Alunos por E-mail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Receba um aviso assim que um aluno enviar uma atividade ou projeto no AVA', style: TextStyle(fontSize: 12, color: DocenteColors.slate)),
            value: _notifySubmissions,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifySubmissions = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Avisos de Prazo de Homologação de Diário MEC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Lembretes automáticos 48h antes do encerramento quinzenal do lançamento de faltas', style: TextStyle(fontSize: 12, color: DocenteColors.slate)),
            value: _notifyMecDeadlines,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifyMecDeadlines = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Alertas de Discentes em Risco de Frequência (< 75%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Alerta imediato quando um estudante atinge 20% de faltas acumuladas na disciplina', style: TextStyle(fontSize: 12, color: DocenteColors.slate)),
            value: _notifyAttendanceRisk,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifyAttendanceRisk = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Notificações Push no Dispositivo Móvel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Alertas instantâneos de mensagens urgentes da coordenação do curso', style: TextStyle(fontSize: 12, color: DocenteColors.slate)),
            value: _notifyPush,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifyPush = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferências do Sistema & Interface',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField('Densidade Visual das Tabelas', 'Confortável (Padrão Institucional)'),
          const SizedBox(height: 16),
          _buildReadOnlyField('Fuso Horário', 'Horário de Brasília (GMT-3)'),
          const SizedBox(height: 16),
          _buildReadOnlyField('Sincronização de Calendário Padrão', 'Google Workspace for Education'),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacidade & Conformidade LGPD (Lei nº 13.709/2018)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
          ),
          const SizedBox(height: 12),
          const Text(
            'Os dados pessoais coletados neste portal são utilizados exclusivamente para cumprimento de obrigações legais perante o Ministério da Educação (MEC) e gestão acadêmica da instituição. O tratamento de dados sensíveis e registros de presença segue rigorosamente as diretrizes da LGPD.',
            style: TextStyle(fontSize: 13, color: DocenteColors.slate, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relatório LGPD dos seus dados pessoais exportado com sucesso.'),
                  backgroundColor: DocenteColors.charcoal,
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Exportar Meus Dados Pessoais (LGPD)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocenteColors.charcoal,
              foregroundColor: DocenteColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DocenteColors.charcoal)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DocenteColors.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: DocenteColors.slate)),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DocenteColors.charcoal)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: DocenteColors.charcoal),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: DocenteColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
