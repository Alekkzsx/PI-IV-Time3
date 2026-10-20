// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Modal dialog for authoring and broadcasting official academic notices to students.
class CreateNoticeModal extends StatefulWidget {
  /// Reactive controller for dispatching notices.
  final DocenteController controller;

  const CreateNoticeModal({
    super.key,
    required this.controller,
  });

  @override
  State<CreateNoticeModal> createState() => _CreateNoticeModalState();
}

class _CreateNoticeModalState extends State<CreateNoticeModal> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCourse;
  String _selectedAudience = 'Todos os Alunos Matriculados';
  NoticeClassification _selectedClassification = NoticeClassification.informativo;

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

  void _submitNotice() {
    if (!_formKey.currentState!.validate()) return;

    widget.controller.publishNotice(
      targetCourse: _selectedCourse,
      targetAudience: _selectedAudience,
      classification: _selectedClassification,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comunicado institucional transmitido aos estudantes com sucesso!'),
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
              color: Colors.black.withOpacity(0.08),
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
                      _buildClassificationSelector(),
                      const SizedBox(height: 20),
                      _buildCourseAndAudiencePickers(),
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
              color: DocenteColors.charcoal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_outlined, color: DocenteColors.charcoal, size: 22),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: DocenteColors.slate,
                  ),
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

  Widget _buildClassificationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classificação do Comunicado',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: NoticeClassification.values.map((classification) {
            final isSelected = _selectedClassification == classification;
            Color activeColor;
            String label;

            switch (classification) {
              case NoticeClassification.informativo:
                activeColor = const Color(0xFF2563EB); // Blue
                label = 'Informativo';
                break;
              case NoticeClassification.urgencia:
                activeColor = DocenteColors.amber;
                label = 'Urgência';
                break;
              case NoticeClassification.convocacao:
                activeColor = DocenteColors.crimson;
                label = 'Convocação';
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedClassification = classification;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor.withOpacity(0.12) : DocenteColors.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? activeColor : DocenteColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeColor : DocenteColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCourseAndAudiencePickers() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turma / Disciplina',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DocenteColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCourse,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: DocenteColors.charcoal),
                    items: [
                      ...widget.controller.courses.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.code,
                          child: Text('${c.code} - ${c.name}'),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: 'TODAS',
                        child: Text('Todas as Turmas do Semestre'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCourse = val;
                        });
                      }
                    },
                  ),
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
              const Text(
                'Público-Alvo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DocenteColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAudience,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: DocenteColors.charcoal),
                    items: _audiences.map((aud) {
                      return DropdownMenuItem<String>(
                        value: aud,
                        child: Text(aud),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedAudience = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          validator: (val) => val == null || val.trim().isEmpty ? 'Insira o título do comunicado' : null,
          decoration: InputDecoration(
            hintText: 'Ex: Plantão Extra de Dúvidas para o Projeto N1',
            hintStyle: const TextStyle(color: DocenteColors.muted, fontSize: 13),
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
              borderSide: const BorderSide(color: DocenteColors.charcoal, width: 1.5),
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
          validator: (val) => val == null || val.trim().isEmpty ? 'Insira o conteúdo do aviso' : null,
          decoration: InputDecoration(
            hintText: 'Descreva os detalhes, orientações pedagógicas ou prazos para a turma...',
            hintStyle: const TextStyle(color: DocenteColors.muted, fontSize: 13),
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
              borderSide: const BorderSide(color: DocenteColors.charcoal, width: 1.5),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

