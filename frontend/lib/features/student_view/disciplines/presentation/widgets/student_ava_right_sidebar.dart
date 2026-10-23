// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'student_disciplines_modals.dart';

/// Barra lateral direita do AVA da disciplina contendo metadados institucionais:
/// - Dados da Matrícula Discente
/// - Frequência & Rendimento
/// - Atendimento com Docente
/// - Plano de Ensino
class StudentAvaRightSidebar extends StatelessWidget {
  final StudentDisciplineModel discipline;

  const StudentAvaRightSidebar({
    super.key,
    required this.discipline,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMatriculaCard(),
          const SizedBox(height: 16),
          _buildFrequenciaCard(),
          const SizedBox(height: 16),
          _buildAtendimentoCard(context),
          const SizedBox(height: 16),
          _buildPlanoEnsinoCard(context),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 1: DADOS DA MATRÍCULA DISCENTE
  // ==========================================
  Widget _buildMatriculaCard() {
    final credits = (discipline.totalHours / 10).toInt();
    final cleanLocation = discipline.location.replaceAll(' (Noturno)', '');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              const Icon(Icons.school_outlined, size: 16, color: Color(0xFF18181B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DADOS DA MATRÍCULA DISCENTE',
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Turma/Oferta:', discipline.fullCode ?? '218131 - ${discipline.code}'),
          const SizedBox(height: 8),
          _buildInfoRow('Carga Horária:', '${discipline.totalHours}h ($credits créditos)'),
          const SizedBox(height: 8),
          _buildInfoRow('Docente Titular:', discipline.professor),
          const SizedBox(height: 8),
          _buildInfoRow('Turno / Sala:', 'Noturno (19:10 - 22:40) • $cleanLocation'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: jakarta(
              size: 11.5,
              color: const Color(0xFF71717A),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: jakarta(
              size: 11.5,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 2: FREQUÊNCIA & RENDIMENTO
  // ==========================================
  Widget _buildFrequenciaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF18181B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'FREQUÊNCIA & RENDIMENTO',
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Regular',
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Assiduidade Presencial',
                  style: jakarta(
                    size: 11.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${discipline.attendancePercentage.toStringAsFixed(0)}%',
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (discipline.attendancePercentage / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Faltas apuradas:',
                  style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${discipline.absences} de ${discipline.maxAbsenceHours} max',
                style: jakarta(size: 11.5, weight: FontWeight.w700, color: const Color(0xFF18181B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Horas concluídas:',
                  style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${discipline.completedHours}h de ${discipline.totalHours}h',
                style: jakarta(size: 11.5, weight: FontWeight.w700, color: const Color(0xFF18181B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 3: ATENDIMENTO COM DOCENTE
  // ==========================================
  Widget _buildAtendimentoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF18181B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ATENDIMENTO COM DOCENTE',
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Plantão semanal síncrono e presencial para orientação de projetos e dúvidas técnicas.',
            style: jakarta(
              size: 11.5,
              color: const Color(0xFF71717A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF18181B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Terças-feiras • 18:00 às 19:00',
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Local: Sala dos Professores (Bloco C) ou Sala Virtual Teams',
                  style: jakarta(
                    size: 11,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('btn_contatar_docente_email'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Abrindo canal direto com ${discipline.professor}...'),
                ),
              );
            },
            icon: const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF18181B)),
            label: Text(
              'Contatar Docente via E-mail',
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 4: PLANO DE ENSINO
  // ==========================================
  Widget _buildPlanoEnsinoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFF18181B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PLANO DE ENSINO',
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.tag_rounded, size: 16, color: Color(0xFFA1A1AA)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Consulte os objetivos pedagógicos, metodologia, critérios de avaliação e bibliografia.',
            style: jakarta(
              size: 11.5,
              color: const Color(0xFF71717A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const Key('btn_ver_ementa_metodologia'),
            onPressed: () => StudentDisciplinesModals.showPlanoEnsinoModal(context),
            icon: const Icon(Icons.menu_book_outlined, size: 14, color: Colors.white),
            label: Text(
              'Ver Ementa e Metodologia',
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
