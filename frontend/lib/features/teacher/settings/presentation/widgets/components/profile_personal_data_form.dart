// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/domain/models/docente_profile.dart';

/// Formulário molecular com dados cadastrais, e-mails e vínculos acadêmicos do docente.
class ProfilePersonalDataForm extends StatelessWidget {
  final DocenteProfile profile;
  final TextEditingController civilNameController;
  final TextEditingController socialNameController;
  final TextEditingController institutionalEmailController;
  final TextEditingController personalEmailController;
  final FocusNode personalEmailFocusNode;
  final VoidCallback onSave;

  const ProfilePersonalDataForm({
    super.key,
    required this.profile,
    required this.civilNameController,
    required this.socialNameController,
    required this.institutionalEmailController,
    required this.personalEmailController,
    required this.personalEmailFocusNode,
    required this.onSave,
  });

  InputDecoration _inputDecoration({String? hintText, Widget? suffix}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: jakarta(
        size: 13,
        weight: FontWeight.w400,
        color: const Color(0xFFA1A1AA),
      ),
      filled: true,
      fillColor: Colors.white,
      suffix: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(
    String label, {
    String? tagText,
    bool isEditable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w600,
                color: const Color(0xFF3F3F46),
              ),
            ),
          ),
          if (tagText != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEditable)
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Color(0xFF71717A),
                  )
                else
                  const Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: Color(0xFF71717A),
                  ),
                const SizedBox(width: 4),
                Text(
                  tagText,
                  style: jakarta(
                    size: 10.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: jakarta(
              size: 10,
              weight: FontWeight.w600,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: jakarta(
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final emailChangeButton = OutlinedButton.icon(
      onPressed: () =>
          FocusScope.of(context).requestFocus(personalEmailFocusNode),
      icon: const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF18181B)),
      label: Text(
        'Alterar E-mail',
        style: jakarta(
          size: 11,
          weight: FontWeight.w500,
          color: const Color(0xFF18181B),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD4D4D8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        backgroundColor: Colors.white,
      ),
    );
    final saveButton = ElevatedButton(
      onPressed: onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Salvar Alterações de Perfil',
        style: jakarta(
          size: 12.5,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identificação & Nome de Exibição
        Container(
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
              Text(
                'Identificação & Nome de Exibição',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure como seu nome deve ser chamado nas comunicações cotidianas da instituição.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          'Nome de Registro Civil',
                          tagText: 'Oficial',
                        ),
                        TextFormField(
                          controller: civilNameController,
                          readOnly: true,
                          style: jakarta(
                            size: 12.5,
                            color: const Color(0xFF52525B),
                          ),
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registro civil emitido no ato da matrícula acadêmica.',
                          style: jakarta(
                            size: 10.5,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          'Nome Social / Preferido',
                          tagText: 'Editável',
                          isEditable: true,
                        ),
                        TextFormField(
                          controller: socialNameController,
                          style: jakarta(
                            size: 12.5,
                            color: const Color(0xFF18181B),
                          ),
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nome utilizado em chamadas, listas públicas e fóruns de disciplina.',
                          style: jakarta(
                            size: 10.5,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Informações Acadêmicas Oficiais
        Container(
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
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Informações Acadêmicas Oficiais',
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 14,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MATRÍCULA REGULAR',
                        style: jakarta(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Dados vinculados ao seu registro perante o Ministério da Educação e Secretaria Acadêmica.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.31,
                    child: _buildInfoBox('MATRÍCULA / RA', '234324234'),
                  ),
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.31,
                    child: _buildInfoBox(
                      'CURSO VINCULADO',
                      profile.department,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.31,
                    child: _buildInfoBox(
                      'PERÍODO LETIVO',
                      profile.semester,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoBox(
                'POLO / UNIDADE',
                profile.campus,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF4F4F5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Para solicitar alterações nos dados de matrícula, trancamento, transferência de polo ou correção de registro civil, abra um protocolo pelo menu de Protocolos da Secretaria Virtual.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Contatos & E-mails
        Container(
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
              Text(
                'Contatos & E-mails',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'E-mails utilizados para comunicação institucional, alertas do AVA e recuperação de acesso.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel(
                          'E-mail Institucional (Login Principal)',
                          tagText: 'Fixo',
                        ),
                        TextFormField(
                          controller: institutionalEmailController,
                          readOnly: true,
                          style: jakarta(
                            size: 12,
                            color: const Color(0xFF52525B),
                          ),
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Conta acadêmica oficial associada aos serviços educacionais.',
                          style: jakarta(
                            size: 10.5,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: isCompact ? 1 : 0.48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'E-mail Pessoal de Recuperação',
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(
                                  size: 11.5,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF3F3F46),
                                ),
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
                                'Verificado',
                                style: jakarta(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        isCompact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    focusNode: personalEmailFocusNode,
                                    controller: personalEmailController,
                                    style: jakarta(
                                      size: 12,
                                      color: const Color(0xFF18181B),
                                    ),
                                    decoration: _inputDecoration(),
                                  ),
                                  const SizedBox(height: 8),
                                  emailChangeButton,
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      focusNode: personalEmailFocusNode,
                                      controller: personalEmailController,
                                      style: jakarta(
                                        size: 12,
                                        color: const Color(0xFF18181B),
                                      ),
                                      decoration: _inputDecoration(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  emailChangeButton,
                                ],
                              ),
                        const SizedBox(height: 4),
                        Text(
                          'Utilizado para redefinição de senha e alertas críticos de segurança.\nA alteração exige validação de senha e confirmação com código de 6 dígitos enviado ao novo endereço.',
                          style: jakarta(
                            size: 10.5,
                            color: const Color(0xFFA1A1AA),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: isCompact
                    ? SizedBox(width: double.infinity, child: saveButton)
                    : saveButton,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
