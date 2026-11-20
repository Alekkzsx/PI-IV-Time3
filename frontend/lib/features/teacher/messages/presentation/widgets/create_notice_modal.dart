// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';
import 'components/notice_audience_selector.dart';
import 'components/notice_urgency_chip_group.dart';

/// Modal dialog for authoring and broadcasting official academic notices to students.
class CreateNoticeModal extends StatefulWidget {
  /// Reactive controller for dispatching notices.
  final DocenteController controller;

  const CreateNoticeModal({super.key, required this.controller});

  @override
  State<CreateNoticeModal> createState() => _CreateNoticeModalState();
}

class _CreateNoticeModalState extends State<CreateNoticeModal> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCourse;
  String _selectedAudience = 'Todos os Alunos Matriculados';
  NoticeClassification _selectedClassification =
      NoticeClassification.informativo;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<String> _audiences = [
    'Todos os Alunos Matriculados',
    'Alunos com Frequência Crítica (< 75%)',
    'Alunos em Recuperação / Exame',
    'Líderes e Representantes de Turma',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.controller.selectedCourse.code;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    final published = await widget.controller.publishNotice(
      targetCourse: _selectedCourse,
      targetAudience: _selectedAudience,
      classification: _selectedClassification,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (!mounted) return;

    if (!published) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível publicar o comunicado para esta turma.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Comunicado institucional transmitido aos estudantes com sucesso!',
        ),
        backgroundColor: DocenteColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          color: DocenteColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DocenteColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NoticeUrgencyChipGroup(
                        selectedClassification: _selectedClassification,
                        onClassificationChanged: (c) =>
                            setState(() => _selectedClassification = c),
                      ),
                      const SizedBox(height: 20),
                      NoticeAudienceSelector(
                        courses: widget.controller.courses,
                        selectedCourse: _selectedCourse,
                        onCourseChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCourse = val);
                          }
                        },
                        audiences: _audiences,
                        selectedAudience: _selectedAudience,
                        onAudienceChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAudience = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildMessageField(),
                      const SizedBox(height: 16),
                      _buildBroadcastNoticeBanner(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocenteColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DocenteColors.charcoal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: DocenteColors.charcoal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Novo Comunicado da Disciplina',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
                Text(
                  'Transmissão com rastreamento de ciência obrigatória',
                  style: TextStyle(fontSize: 13, color: DocenteColors.slate),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: DocenteColors.slate),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Título do Comunicado',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: const TextStyle(fontSize: 14, color: DocenteColors.charcoal),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Insira o título do comunicado'
              : null,
          decoration: InputDecoration(
            hintText: 'Ex: Plantão Extra de Dúvidas para o Projeto N1',
            hintStyle: const TextStyle(
              color: DocenteColors.muted,
              fontSize: 13,
            ),
            fillColor: DocenteColors.offWhite,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: DocenteColors.charcoal,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mensagem Institucional',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 5,
          style: const TextStyle(fontSize: 13, color: DocenteColors.charcoal),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Insira o conteúdo do aviso'
              : null,
          decoration: InputDecoration(
            hintText:
                'Descreva os detalhes, orientações pedagógicas ou prazos para a turma...',
            hintStyle: const TextStyle(
              color: DocenteColors.muted,
              fontSize: 13,
            ),
            fillColor: DocenteColors.offWhite,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: DocenteColors.charcoal,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBroadcastNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DocenteColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DocenteColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: DocenteColors.slate),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este comunicado será enviado para o painel do discente e exigirá confirmação de ciência ao acessar o AVA.',
              style: TextStyle(fontSize: 12, color: DocenteColors.slate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: DocenteColors.offWhite,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: DocenteColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: DocenteColors.charcoal,
              side: const BorderSide(color: DocenteColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _submitNotice,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text(
              'Publicar Comunicado',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocenteColors.charcoal,
              foregroundColor: DocenteColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
