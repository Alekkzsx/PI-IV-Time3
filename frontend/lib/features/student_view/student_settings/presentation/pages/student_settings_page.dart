// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/presentation/controllers/student_portal_controller.dart';

/// Tela de Configurações da Conta Discente.
/// Implementa as 5 seções de governança: Perfil, Segurança com 2FA,
/// Central de Notificações, Preferências de Interface e Privacidade LGPD.
class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna Esquerda: Menu interno de configurações (280px)
              SizedBox(width: 280, child: _buildInnerSidebar()),
              const SizedBox(width: 24),
              // Coluna Direita: Conteúdo dinâmico da subaba selecionada
              Expanded(child: _buildSelectedTabContent()),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO
  // ==========================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Configurações da Conta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18181B),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Gerencie sua identidade estudantil, camadas de proteção de acesso, preferências de alerta e direitos de privacidade.',
          style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
        ),
      ],
    );
  }

  // ==========================================
  // MENU LATERAL INTERNO (5 SUBABAS)
  // ==========================================
  Widget _buildInnerSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            0,
            Icons.person_outline,
            'Perfil & Identidade',
            'Foto, nome social e dados acadêmicos',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildMenuItem(
            1,
            Icons.shield_outlined,
            'Segurança & Acesso',
            'Senha, 2FA e sessões ativas',
            badgeText: _controller.isTwoFactorEnabled ? '2FA ATIVO' : 'DESATIVADO',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildMenuItem(
            2,
            Icons.notifications_none,
            'Central de Notificações',
            'Alertas no portal e e-mails de prazos',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildMenuItem(
            3,
            Icons.tune,
            'Preferências do Sistema',
            'Aparência, densidade e formato de data',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildMenuItem(
            4,
            Icons.lock_outline,
            'Privacidade & LGPD',
            'Visibilidade para turmas e termos',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title, String subtitle, {String? badgeText}) {
    final isSelected = _controller.selectedSettingsTabIndex == index;
    return InkWell(
      onTap: () => _controller.setSettingsTab(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
          border: isSelected ? const Border(left: BorderSide(color: Color(0xFF0F172A), width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _controller.isTwoFactorEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badgeText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _controller.isTwoFactorEnabled ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DINÂMICO DA SUBABA SELECIONADA
  // ==========================================
  Widget _buildSelectedTabContent() {
    switch (_controller.selectedSettingsTabIndex) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildSecurityTab();
      case 2:
        return _buildNotificationsTab();
      case 3:
        return _buildPreferencesTab();
      case 4:
        return _buildPrivacyTab();
      default:
        return _buildProfileTab();
    }
  }

  // Subaba 1: Perfil & Identidade (Print 35)
  Widget _buildProfileTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identidade Estudantil & Cadastro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(radius: 36, backgroundColor: Color(0xFF0F172A), child: Text('G', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(StudentMockData.studentName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('R.A.: ${StudentMockData.studentRa} • Registro Homologado DTI', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          _buildSettingField('Nome Civil Completo', StudentMockData.studentName),
          const SizedBox(height: 16),
          _buildSettingField('Nome Social / Exibição', 'Gabriel Soares'),
          const SizedBox(height: 16),
          _buildSettingField('E-mail Institucional', 'gabriel.oliveira@aluno.universidade.edu.br'),
          const SizedBox(height: 16),
          _buildSettingField('Curso e Período', StudentMockData.studentCourse),
        ],
      ),
    );
  }

  // Subaba 2: Segurança & Acesso (Print 36)
  Widget _buildSecurityTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Segurança, Credenciais & 2FA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Autenticação em Dois Fatores (2FA)'),
            subtitle: const Text('Exige código de verificação enviado via App Autenticador ou SMS em novos acessos.'),
            trailing: Switch(
              value: _controller.isTwoFactorEnabled,
              onChanged: (_) => _controller.toggleTwoFactor(),
              activeThumbColor: const Color(0xFF16A34A),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Senha de Acesso ao Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Última alteração realizada há 42 dias.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link de redefinição de senha enviado para o e-mail institucional.'))),
                child: const Text('Redefinir Senha'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Sessões Ativas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.computer, color: Color(0xFF0F172A)),
            title: Text('Google Chrome no Windows 11 (Esta sessão)'),
            subtitle: Text('IP: 177.136.24.10 • Curitiba, Brasil • Ativo agora'),
          ),
        ],
      ),
    );
  }

  // Subaba 3: Central de Notificações (Print 37)
  Widget _buildNotificationsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Canais e Frequência de Notificações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Notificações no Portal AVA'),
            subtitle: const Text('Alertas visuais de novos comunicados, notas lançadas e prazos.'),
            value: _controller.pushNotifications,
            onChanged: (val) => setState(() => _controller.pushNotifications = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('E-mails de Prazos e Entregas'),
            subtitle: const Text('Resumo diário enviado para seu e-mail institucional com 48h de antecedência.'),
            value: _controller.emailNotifications,
            onChanged: (val) => setState(() => _controller.emailNotifications = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Alertas Urgentes via SMS'),
            subtitle: const Text('Avisos de alterações emergenciais de sala ou suspensões de aula.'),
            value: _controller.smsNotifications,
            onChanged: (val) => setState(() => _controller.smsNotifications = val),
          ),
        ],
      ),
    );
  }

  // Subaba 4: Preferências do Sistema (Print 38)
  Widget _buildPreferencesTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Preferências de Interface & Acessibilidade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ListTile(
            title: Text('Tema da Interface'),
            subtitle: Text('Modo Claro Oficial (Padrão AGMRM)'),
            trailing: Icon(Icons.light_mode, color: Colors.orange),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Formato de Data e Horário'),
            subtitle: Text('DD/MM/AAAA • 24 Horas (Horário de Brasília)'),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Idioma Oficial'),
            subtitle: Text('Português (Brasil) - Resolução CONSEPE'),
          ),
        ],
      ),
    );
  }

  // Subaba 5: Privacidade & LGPD (Print 39)
  Widget _buildPrivacyTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Direitos de Privacidade & Governança LGPD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Em conformidade com a Lei Geral de Proteção de Dados (Lei 13.709/2018), seus registros acadêmicos, históricos de notas, frequências e interações na plataforma são custodiados exclusivamente para fins pedagógicos institucionais.',
            style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Exportar Meus Dados Pessoais e Acadêmicos (LGPD)', style: TextStyle(fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dossiê LGPD exportado com sucesso (JSON).'))),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar Dossiê'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ),
      ],
    );
  }
}
