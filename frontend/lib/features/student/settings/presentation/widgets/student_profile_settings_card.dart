// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Card de configurações de perfil discente, dados acadêmicos e identificação oficial.
class StudentProfileSettingsCard extends StatefulWidget {
  final StudentPortalController controller;

  const StudentProfileSettingsCard({super.key, required this.controller});

  @override
  State<StudentProfileSettingsCard> createState() =>
      _StudentProfileSettingsCardState();
}

class _StudentProfileSettingsCardState
    extends State<StudentProfileSettingsCard> {
  late TextEditingController _civilNameController;
  late TextEditingController _socialNameController;
  late TextEditingController _institutionalEmailController;
  late TextEditingController _recoveryEmailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _civilNameController = TextEditingController(
      text: StudentMockData.studentName,
    );
    _socialNameController = TextEditingController(text: 'Gabriel Soares');
    _institutionalEmailController = TextEditingController(
      text: 'gabriel.oliveira@aluno.universidade.edu.br',
    );
    _recoveryEmailController = TextEditingController(
      text: 'gabriel.soares.dev@gmail.com',
    );
    _phoneController = TextEditingController(text: '(41) 99876-5432');
  }

  @override
  void dispose() {
    _civilNameController.dispose();
    _socialNameController.dispose();
    _institutionalEmailController.dispose();
    _recoveryEmailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Dados de perfil e preferências de contato atualizados com sucesso!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffix,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: jakarta(
        size: 13,
        weight: FontWeight.w400,
        color: const Color(0xFFA1A1AA),
      ),
      filled: true,
      fillColor: readOnly ? const Color(0xFFFAFAFA) : Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Identidade Visual & Registro Discente
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Discente
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF18181B),
                          border: Border.all(
                            color: const Color(0xFFE4E4E7),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'GO',
                          style: jakarta(
                            size: 24,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                StudentMockData.studentName,
                                style: jakarta(
                                  size: 16.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Text(
                                'Matrícula Ativa',
                                style: jakarta(
                                  size: 10.5,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R.A.: ${StudentMockData.studentRa} • Registro Homologado DTI / MEC',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w400,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 13,
                              color: Color(0xFF71717A),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              StudentMockData.studentCourse,
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w500,
                                color: const Color(0xFF3F3F46),
                              ),
                            ),
                          ],
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

        // 2. Bloco Oficial de Registro Acadêmico (Exibição Institucional)
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
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dados Acadêmicos Oficiais',
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
                'Informações vinculadas à sua matrícula discente sob custódia da Secretaria Geral.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),
              // Grid de 4 KPIs Acadêmicos
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  return isNarrow
                      ? Column(
                          children: [
                            _buildAcademicKpi(
                              'REGISTRO ACADÊMICO (R.A.)',
                              StudentMockData.studentRa,
                              Icons.numbers_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildAcademicKpi(
                              'CURSO DE GRADUAÇÃO',
                              'Engenharia de Software (Bacharelado)',
                              Icons.menu_book_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildAcademicKpi(
                              'SEMESTRE / PERÍODO',
                              '2026/2 • Noturno (7º Semestre)',
                              Icons.calendar_month_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildAcademicKpi(
                              'COEFICIENTE DE RENDIMENTO (CR)',
                              '8.80 / 10.0',
                              Icons.analytics_outlined,
                              highlight: true,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAcademicKpi(
                                    'REGISTRO ACADÊMICO (R.A.)',
                                    StudentMockData.studentRa,
                                    Icons.numbers_rounded,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildAcademicKpi(
                                    'CURSO DE GRADUAÇÃO',
                                    'Engenharia de Software (Bacharelado)',
                                    Icons.menu_book_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAcademicKpi(
                                    'SEMESTRE / PERÍODO',
                                    '2026/2 • Noturno (7º Semestre)',
                                    Icons.calendar_month_rounded,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildAcademicKpi(
                                    'COEFICIENTE DE RENDIMENTO (CR)',
                                    '8.80 / 10.0',
                                    Icons.analytics_outlined,
                                    highlight: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Informações Cadastrais e Contatos
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
                'Identificação & Contatos',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mantenha seus canais de contato atualizados para receber comunicados de estágio e notas.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),

              // Nome Civil
              _buildFieldLabel(
                'Nome Civil Completo',
                tagText: 'Alteração apenas via protocolo',
                isEditable: false,
              ),
              TextField(
                controller: _civilNameController,
                readOnly: true,
                style: jakarta(size: 13, color: const Color(0xFF71717A)),
                decoration: _inputDecoration(
                  readOnly: true,
                  suffix: const Tooltip(
                    message:
                        'Para alteração de nome civil, abra um protocolo na Secretaria com certidão em anexo.',
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Nome Social
              _buildFieldLabel(
                'Nome Social / Exibição',
                tagText: 'Editável • Exibido no AVA',
                isEditable: true,
              ),
              TextField(
                controller: _socialNameController,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: _inputDecoration(
                  hintText: 'Como você deseja ser chamado nas turmas e fóruns',
                ),
              ),
              const SizedBox(height: 18),

              // E-mail Institucional
              _buildFieldLabel(
                'E-mail Institucional',
                tagText: 'Vinculado ao SSO Estudantil',
                isEditable: false,
              ),
              TextField(
                controller: _institutionalEmailController,
                readOnly: true,
                style: jakarta(size: 13, color: const Color(0xFF71717A)),
                decoration: _inputDecoration(
                  readOnly: true,
                  suffix: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
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
                ),
              ),
              const SizedBox(height: 18),

              // E-mail de Recuperação & Telefone
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  return isNarrow
                      ? Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(
                                  'E-mail Pessoal / Recuperação',
                                  tagText: 'Editável',
                                  isEditable: true,
                                ),
                                TextField(
                                  controller: _recoveryEmailController,
                                  style: jakarta(
                                    size: 13,
                                    color: const Color(0xFF18181B),
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: 'exemplo@gmail.com',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(
                                  'Celular / WhatsApp',
                                  tagText: 'Editável',
                                  isEditable: true,
                                ),
                                TextField(
                                  controller: _phoneController,
                                  style: jakarta(
                                    size: 13,
                                    color: const Color(0xFF18181B),
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: '(00) 00000-0000',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    'E-mail Pessoal / Recuperação',
                                    tagText: 'Editável',
                                    isEditable: true,
                                  ),
                                  TextField(
                                    controller: _recoveryEmailController,
                                    style: jakarta(
                                      size: 13,
                                      color: const Color(0xFF18181B),
                                    ),
                                    decoration: _inputDecoration(
                                      hintText: 'exemplo@gmail.com',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(
                                    'Celular / WhatsApp',
                                    tagText: 'Editável',
                                    isEditable: true,
                                  ),
                                  TextField(
                                    controller: _phoneController,
                                    style: jakarta(
                                      size: 13,
                                      color: const Color(0xFF18181B),
                                    ),
                                    decoration: _inputDecoration(
                                      hintText: '(00) 00000-0000',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 24),

              // Botão de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Salvar Alterações de Perfil',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
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
        ),
      ],
    );
  }

  Widget _buildAcademicKpi(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFAFAFA) : const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlight
                  ? const Color(0xFF18181B)
                  : const Color(0xFFF4F4F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: highlight ? Colors.white : const Color(0xFF18181B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
