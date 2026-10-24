// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';

/// Aba de Módulos & Conteúdos de Aprendizagem do curso no Portal Docente.
class CourseHubModulesTab extends StatelessWidget {
  final VoidCallback onNewUnit;
  final VoidCallback onUploadSlides;
  final VoidCallback onPublishAssignment;
  final VoidCallback onQuickNotice;
  final VoidCallback onReviewSyllabus;
  final VoidCallback onNavigateToAssignments;

  const CourseHubModulesTab({
    super.key,
    required this.onNewUnit,
    required this.onUploadSlides,
    required this.onPublishAssignment,
    required this.onQuickNotice,
    required this.onReviewSyllabus,
    required this.onNavigateToAssignments,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna Principal de Unidades Didáticas
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Módulos & Conteúdos de Aprendizagem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Unidades ativas e materiais didáticos disponibilizados para a turma.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: onNewUnit,
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text(
                      'Nova Unidade',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Unidade 1
              _buildDocenteUnitCard(
                tag: 'UNIDADE 1 • SEMANAS 1 A 4 • 20 HORAS LETIVAS',
                title:
                    'Unidade 1: Engenharia de Requisitos & Processos Ágeis de Software',
                items: [
                  'Plano de Ensino & Contrato Pedagógico da Disciplina (Pdf • 420 KB)',
                  'Slides da Aula 01: Processo Unificado e Engenharia de Software Moderna (Pdf • 3.8 MB)',
                  'Gravação da Aula Síncrona: Elicitação de Requisitos e Casos de Uso (Vídeo • 1h 35min)',
                  'Exercício 01: Mapeamento de Requisitos e Especificação de Casos de Uso (Tarefa • Prazo 05 Set)',
                ],
              ),
              const SizedBox(height: 20),

              // Unidade 2
              _buildDocenteUnitCard(
                tag:
                    'UNIDADE 2 • SEMANAS 5 A 9 • 24 HORAS LETIVAS • EM ANDAMENTO',
                title:
                    'Unidade 2: Modelagem Orientada a Objetos com Notação UML 2.5',
                items: [
                  'Slides da Aula 03: Diagrama de Classes, Multiplicidades e Visibilidade (Pdf • 4.2 MB)',
                  'Template Oficial de Diagramação (.drawio e .uml) (Arquivo • 180 KB)',
                  'Slides da Aula 04: Diagrama de Sequência e Interações Temporais (Pdf • 2.9 MB)',
                  'Entrega da Sprint 1: Diagrama de Classes e Sequência do AVA (Tarefa • Prazo Hoje)',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Coluna Lateral: Gestão Pedagógica Docente
        SizedBox(
          width: 310,
          child: Column(
            children: [
              // Card 1: Controle Docente da Turma
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CONTROLE DA TURMA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Em Andamento',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMetaRow('Carga Horária:', '80h (4 créditos)'),
                    const SizedBox(height: 8),
                    _buildMetaRow('Cumprimento:', '54h concluídas (67.5%)'),
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      'Regime Semestral:',
                      '100 Dias Letivos (Semana 10)',
                    ),
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      'Pauta / Fechamento:',
                      'Diário Aberto para Lançamentos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Ações Rápidas de Gestão Pedagógica
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AÇÕES DOCENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionDocenteButton(
                      Icons.upload_file,
                      'Upload de Slides ou Apostila',
                      onTap: onUploadSlides,
                    ),
                    const SizedBox(height: 8),
                    _buildActionDocenteButton(
                      Icons.add_task,
                      'Publicar Nova Tarefa',
                      onTap: onPublishAssignment,
                    ),
                    const SizedBox(height: 8),
                    _buildActionDocenteButton(
                      Icons.announcement_outlined,
                      'Disparar Comunicado à Turma',
                      onTap: onQuickNotice,
                    ),
                    const SizedBox(height: 8),
                    _buildActionDocenteButton(
                      Icons.menu_book,
                      'Revisar Ementa / PPC',
                      onTap: onReviewSyllabus,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: Correções Pendentes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CORREÇÕES PENDENTES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '6 envios',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Entrega da Sprint 1: 28 submetidos de 34 alunos.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onNavigateToAssignments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        minimumSize: const Size(double.infinity, 34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Corrigir Submissões',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildDocenteUnitCard({
    required String tag,
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF71717A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 12),
                  label: const Text(
                    'Adicionar Item',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
          ...items.map((item) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.drag_indicator,
                            size: 16,
                            color: Color(0xFFA1A1AA),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF09090B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Color(0xFF71717A),
                            ),
                            onPressed: () {},
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: Color(0xFF71717A),
                            ),
                            onPressed: () {},
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF4F4F5),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildActionDocenteButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF09090B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF09090B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF09090B),
            ),
          ),
        ),
      ],
    );
  }
}
