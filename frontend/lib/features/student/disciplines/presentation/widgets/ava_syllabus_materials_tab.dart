// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';

void _handleFileDownload(BuildContext context, String fileName, {bool isNewlyAdded = false}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  if (isNewlyAdded) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF18181B),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Download de "$fileName" concluído com sucesso! Arquivo institucional verificado.',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('O download de "$fileName" ainda não está disponível.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Abas do AVA para Módulos, Arquivos e Materiais, Programa (Syllabus) e Colaborações em Equipe.
class AvaSyllabusMaterialsTab extends StatelessWidget {
  final int activeTabIndex;

  const AvaSyllabusMaterialsTab({super.key, required this.activeTabIndex});

  @override
  Widget build(BuildContext context) {
    switch (activeTabIndex) {
      case 0:
        return _buildModulesTab(context);
      case 6:
        return _buildFilesTab(context);
      case 7:
        return _buildSyllabusTab();
      case 8:
        return _buildCollaborationsTab();
      default:
        return _buildModulesTab(context);
    }
  }

  // --- ABA 1: Módulos & Conteúdos ---
  Widget _buildModulesTab(BuildContext context) {
    final modules = [
      {
        'semana': 'Semana 1 a 4',
        'titulo': 'Unidade 1: Arquitetura de Software e Padrões GoF',
        'status': 'Concluído',
        'aulas': 8,
      },
      {
        'semana': 'Semana 5 a 9',
        'titulo': 'Unidade 2: Padrões Estruturais e Comportamentais',
        'status': 'Em Andamento',
        'aulas': 10,
      },
      {
        'semana': 'Semana 10 a 14',
        'titulo': 'Unidade 3: Clean Architecture e Microsserviços',
        'status': 'Não Iniciado',
        'aulas': 8,
      },
      {
        'semana': 'Semana 15 a 18',
        'titulo': 'Unidade 4: Avaliação Prática e Apresentação de Bancas',
        'status': 'Não Iniciado',
        'aulas': 6,
      },
    ];

    return Column(
      children: modules.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExpansionTile(
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              title: Text(
                m['titulo'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                '${m['semana']} • ${m['aulas']} aulas gravadas e materiais em PDF',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              trailing: Chip(
                label: Text(
                  m['status'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: m['status'] == 'Concluído'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF18181B),
                  ),
                ),
                backgroundColor: m['status'] == 'Concluído'
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Slides da Aula: Padrão Adapter e Facade.pdf',
                        ),
                        subtitle: const Text(
                          'Material teórico oficial • 4.2 MB',
                        ),
                        trailing: IconButton(
                          tooltip: 'Baixar Slides da Aula',
                          icon: const Icon(Icons.download),
                          onPressed: () => _handleFileDownload(
                            context,
                            'Slides da Aula: Padrão Adapter e Facade.pdf',
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code, color: Colors.blue),
                        title: const Text(
                          'Código-Fonte de Exemplo: AdapterPattern.zip',
                        ),
                        subtitle: const Text(
                          'Projeto Dart com testes unitários • 1.1 MB',
                        ),
                        trailing: IconButton(
                          tooltip: 'Baixar Código-Fonte de Exemplo',
                          icon: const Icon(Icons.download),
                          onPressed: () => _handleFileDownload(
                            context,
                            'Código-Fonte de Exemplo: AdapterPattern.zip',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- ABA 7: Arquivos & Materiais ---
  Widget _buildFilesTab(BuildContext context) {
    return AnimatedBuilder(
      animation: AcademicBridgeService.instance,
      builder: (context, _) {
        final liveMaterials = AcademicBridgeService.instance.materials;

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
              const Text(
                'Repositório Institucional de Arquivos e Slides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Materiais publicados pelo docente
              for (final mat in liveMaterials)
                _buildFileRow(
                  context,
                  mat['title'] as String? ?? 'Arquivo.pdf',
                  'Disponibilizado pelo docente • ${mat['courseCode'] ?? 'Turma'}',
                  mat['fileSize'] as String? ?? '1.5 MB',
                  isNewlyAdded: true,
                ),
              _buildFileRow(
                context,
                'Plano_de_Ensino_APS_II_2026_2.pdf',
                'Documento Institucional homologado',
                '540 KB',
              ),
              _buildFileRow(
                context,
                'Apostila_Padroes_GoF_Estruturais.pdf',
                'Material de apoio didático',
                '8.4 MB',
              ),
              _buildFileRow(
                context,
                'Gabarito_Comentado_P1.pdf',
                'Resolução da primeira prova teórica',
                '1.2 MB',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    String name,
    String desc,
    String size, {
    bool isNewlyAdded = false,
  }) {
    return ListTile(
      leading: Icon(
        isNewlyAdded ? Icons.picture_as_pdf : Icons.insert_drive_file,
        color: isNewlyAdded ? const Color(0xFFDC2626) : const Color(0xFF18181B),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (isNewlyAdded)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Novo',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '$desc • $size',
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: IconButton(
        tooltip: 'Baixar $name',
        icon: const Icon(Icons.file_download_outlined),
        onPressed: () => _handleFileDownload(context, name, isNewlyAdded: isNewlyAdded),
      ),
    );
  }

  // --- ABA 8: Programa / Syllabus ---
  Widget _buildSyllabusTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Programa da Disciplina (Syllabus Homologado MEC)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'EMENTA:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF18181B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Padrões de projeto de software (GoF: Criacionais, Estruturais e Comportamentais). Arquiteturas em camadas, Clean Architecture e princípios SOLID. Modelagem em UML e desenvolvimento orientado a testes.',
            style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          SizedBox(height: 16),
          Text(
            'BIBLIOGRAFIA BÁSICA (ABNT):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF18181B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '1. GAMMA, Erich et al. Padrões de Projeto: Soluções Reutilizáveis de Software Orientado a Objetos. Porto Alegre: Bookman, 2000.\n2. MARTIN, Robert C. Clean Architecture: A Craftsman\'s Guide to Software Structure and Design. Prentice Hall, 2017.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // --- ABA 9: Colaborações ---
  Widget _buildCollaborationsTab() {
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
          const Text(
            'Grupo de Trabalho: Equipe 04 (Projeto Integrador)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tema: Sistema Acadêmico Distribuído com Padrão Adapter e WebRTC',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Integrantes: Gabriel Soares, Mariana Rios, Lucas Silva e Beatriz Castro',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Repositório: github.com/institucional/pi-iv-time3 (Branch: develop)',
            style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            value: 0.75,
            backgroundColor: Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(Color(0xFF16A34A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Status dos Marcos: 3 de 4 entregas validadas',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
