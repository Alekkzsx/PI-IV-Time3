import 'package:flutter/material.dart';

class StudentSettingsPage extends StatelessWidget {
  const StudentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna Esquerda: Menu interno de configurações
              SizedBox(width: 280, child: _buildInnerSidebar()),
              const SizedBox(width: 32),
              // Coluna Direita: Conteúdo do Perfil
              Expanded(child: _buildProfileContent()),
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
        SizedBox(height: 8),
        Text(
          'Gerencie sua identidade estudantil, camadas de proteção de acesso, preferências de alerta e direitos de privacidade.',
          style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
        ),
      ],
    );
  }

  // ==========================================
  // MENU LATERAL INTERNO
  // ==========================================
  Widget _buildInnerSidebar() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                Icons.person_outline,
                'Perfil & Identidade',
                'Foto, nome de exibição e dados acadêmi...',
                isSelected: true,
              ),
              _buildMenuItem(
                Icons.shield_outlined,
                'Segurança & Acesso',
                'Senha, 2FA e sessões ativas',
                badgeText: '2FA ATIVO',
              ),
              _buildMenuItem(
                Icons.notifications_none,
                'Central de Notificações',
                'Alertas no portal e e-mails de prazos',
              ),
              _buildMenuItem(
                Icons.tune,
                'Preferências do Sistema',
                'Aparência, fonte e calendário',
              ),
              _buildMenuItem(
                Icons.lock_outline,
                'Privacidade & Dados',
                'Visibilidade para turmas e LGPD',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF18181B),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gabriel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  Text(
                    'AGM-2024-0891',
                    style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    bool isSelected = false,
    bool isLast = false,
    String? badgeText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isSelected ? 11 : 0),
          bottom: Radius.circular((isSelected && isLast) ? 11 : 0),
        ),
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFE5E7EB),
                ),
              ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF4F4F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF18181B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // CORREÇÃO: O Flexible impede que o título empurre a seta para fora da tela
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF18181B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? const Color(0xFFA1A1AA)
                        : const Color(0xFF71717A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ), // Adicionado um pequeno espaçamento de segurança
          Icon(
            Icons.chevron_right,
            size: 16,
            color: isSelected
                ? const Color(0xFFA1A1AA)
                : const Color(0xFFD4D4D8),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DIREITO (CARTÕES)
  // ==========================================
  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.end, // Para alinhar o botão inferior à direita
      children: [
        _buildIdentityPhotoCard(),
        const SizedBox(height: 24),
        _buildIdentificationCard(),
        const SizedBox(height: 24),
        _buildAcademicInfoCard(),
        const SizedBox(height: 24),
        _buildContactsCard(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Salvar Alterações de Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildIdentityPhotoCard() {
    return _buildCardWrapper(
      title: 'Identidade Visual & Foto',
      subtitle:
          'Sua foto será exibida para professores e colegas nos fóruns, salas virtuais e trabalhos em grupo.',
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Carregar Nova Imagem',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Formatos recomendados: JPG, PNG ou WebP. Tamanho máximo: 5 MB.',
                style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationCard() {
    return _buildCardWrapper(
      title: 'Identificação & Nome de Exibição',
      subtitle:
          'Configure como seu nome deve ser chamado nas comunicações cotidianas da instituição.',
      child: Row(
        children: [
          Expanded(
            child: _buildInputField(
              label: 'Nome de Registro Civil',
              value: 'Gabriel Soares de Oliveira',
              isDisabled: true,
              badgeLabel: 'Oficial',
              badgeIcon: Icons.lock_outline,
              helperText:
                  'Registro civil emitido no ato da matrícula acadêmica.',
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildInputField(
              label: 'Nome Social / Preferido',
              value: 'Gabriel',
              badgeLabel: 'Editável',
              helperText:
                  'Nome utilizado em chamadas, listas públicas e fóruns de disciplina.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard() {
    return _buildCardWrapper(
      title: 'Informações Acadêmicas Oficiais',
      subtitle:
          'Dados vinculados ao seu registro perante o Ministério da Educação e Secretaria Acadêmica.',
      headerBadge: 'MATRÍCULA REGULAR',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoBox('MATRÍCULA / RA', 'AGM - 2024 - 0891'),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildInfoBox(
                  'CURSO VINCULADO',
                  'Bacharelado em Engenharia ...',
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBox('PERÍODO LETIVO', '4º Semestre (2026/2)'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'POLO / UNIDADE',
            'Campus Central - Polo Tecnológico Asa Norte',
            icon: Icons.domain,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF52525B)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Para solicitar alterações nos dados de matrícula, trancamento, transferência de polo ou correção de registro civil, abra um protocolo pelo menu de Protocolos da Secretaria Virtual.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF52525B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return _buildCardWrapper(
      title: 'Contatos & E-mails',
      subtitle:
          'E-mails utilizados para comunicação institucional, alertas do AVA e recuperação de acesso.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInputField(
              label: 'E-mail Institucional (Login Principal)',
              value: '123456@aluno.instituicao.edu.br',
              isDisabled: true,
              labelIcon: Icons.email_outlined,
              badgeLabel: 'Fixo',
              badgeIcon: Icons.lock_outline,
              helperText:
                  'Conta acadêmica oficial associada aos serviços educacionais.',
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: Color(0xFF18181B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'E-mail Pessoal de Recuperação',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Verificado',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'gabriel.martins.dev@g...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Utilizado para redefinição de senha e alertas críticos de segurança.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFF18181B),
                        ),
                        label: const Text(
                          'Alterar E-mail',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A alteração exige validação de senha e confirmação com código de 6 dígitos enviado ao novo endereço.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================
  Widget _buildCardWrapper({
    required String title,
    required String subtitle,
    String? headerBadge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              if (headerBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Color(0xFF52525B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        headerBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String value,
    bool isDisabled = false,
    IconData? labelIcon,
    String? badgeLabel,
    IconData? badgeIcon,
    required String helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (labelIcon != null) ...[
                  Icon(labelIcon, size: 14, color: const Color(0xFF18181B)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                ),
              ],
            ),
            if (badgeLabel != null)
              Row(
                children: [
                  if (badgeIcon != null) ...[
                    Icon(badgeIcon, size: 12, color: const Color(0xFFA1A1AA)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    badgeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled ? const Color(0xFFFAFAFA) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDisabled
                  ? const Color(0xFFA1A1AA)
                  : const Color(0xFF18181B),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helperText,
          style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFF71717A)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }
}
