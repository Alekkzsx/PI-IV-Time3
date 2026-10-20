// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/presentation/controllers/student_portal_controller.dart';

/// Cockpit do Ambiente Virtual de Aprendizagem (AVA) do discente para a disciplina selecionada.
/// Implementa as 12 seções pedagógicas com suporte a chat, fórum, notas, sala virtual e entregas.
class StudentAvaCockpitPage extends StatefulWidget {
  final StudentDisciplineModel discipline;
  final VoidCallback onBack;

  const StudentAvaCockpitPage({
    super.key,
    required this.discipline,
    required this.onBack,
  });

  @override
  State<StudentAvaCockpitPage> createState() => _StudentAvaCockpitPageState();
}

class _StudentAvaCockpitPageState extends State<StudentAvaCockpitPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  final List<String> _tabs = [
    'Módulos & Conteúdos',
    'Tarefas e Atividades',
    'Sala Virtual (Ao Vivo)',
    'Fórum de Dúvidas',
    'Notas & Boletim',
    'Pessoas & Turma',
    'Arquivos & Materiais',
    'Programa (Syllabus)',
    'Colaborações (Equipe)',
    'Caderno Pessoal',
    'Chat da Turma',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCockpitHeader(),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 24),
          _buildActiveTabContent(),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO DA DISCIPLINA NO AVA
  // ==========================================
  Widget _buildCockpitHeader() {
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
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Voltar para Minhas Disciplinas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF18181B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('SALA VIRTUAL DISPONÍVEL', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(widget.discipline.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.discipline.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
                    const SizedBox(height: 4),
                    Text('${widget.discipline.professor} • ${widget.discipline.location} • 2026/2', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat('Progresso Geral', '${(widget.discipline.progress * 100).toInt()}%', true),
              const SizedBox(width: 32),
              _buildHeaderStat('Frequência Homologada', '${widget.discipline.attendancePercentage}% (${widget.discipline.absences} faltas)', false),
              const SizedBox(width: 32),
              _buildHeaderStat('Média Ponderada Parcial', widget.discipline.partialAverage.toStringAsFixed(2), false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, bool isProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
      ],
    );
  }

  // ==========================================
  // BARRA DE ABAS DO AVA (12 ABAS)
  // ==========================================
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _controller.activeAvaTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) => _controller.setAvaTab(index),
              selectedColor: const Color(0xFF18181B),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DA ABA SELECIONADA
  // ==========================================
  Widget _buildActiveTabContent() {
    switch (_controller.activeAvaTabIndex) {
      case 0:
        return _buildModulesTab();
      case 1:
        return _buildTasksTab();
      case 2:
        return _buildLiveClassroomTab();
      case 3:
        return _buildForumsTab();
      case 4:
        return _buildGradesTab();
      case 5:
        return _buildPeopleTab();
      case 6:
        return _buildFilesTab();
      case 7:
        return _buildSyllabusTab();
      case 8:
        return _buildCollaborationsTab();
      case 9:
        return _buildNotebookTab();
      case 10:
        return _buildClassChatTab();
      default:
        return _buildModulesTab();
    }
  }

  // --- ABA 1: Módulos & Conteúdos (Print 10) ---
  Widget _buildModulesTab() {
    final modules = [
      {'semana': 'Semana 1 a 4', 'titulo': 'Unidade 1: Arquitetura de Software e Padrões GoF', 'status': 'Concluído', 'aulas': 8},
      {'semana': 'Semana 5 a 9', 'titulo': 'Unidade 2: Padrões Estruturais e Comportamentais', 'status': 'Em Andamento', 'aulas': 10},
      {'semana': 'Semana 10 a 14', 'titulo': 'Unidade 3: Clean Architecture e Microsserviços', 'status': 'Não Iniciado', 'aulas': 8},
      {'semana': 'Semana 15 a 18', 'titulo': 'Unidade 4: Avaliação Prática e Apresentação de Bancas', 'status': 'Não Iniciado', 'aulas': 6},
    ];

    return Column(
      children: modules.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: ExpansionTile(
            title: Text(m['titulo'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${m['semana']} • ${m['aulas']} aulas gravadas e materiais em PDF', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: Chip(
              label: Text(m['status'] as String, style: TextStyle(fontSize: 11, color: m['status'] == 'Concluído' ? const Color(0xFF16A34A) : const Color(0xFF18181B))),
              backgroundColor: m['status'] == 'Concluído' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: const Text('Slides da Aula: Padrão Adapter e Facade.pdf'),
                      subtitle: const Text('Material teórico oficial • 4.2 MB'),
                      trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code, color: Colors.blue),
                      title: const Text('Código-Fonte de Exemplo: AdapterPattern.zip'),
                      subtitle: const Text('Projeto Dart com testes unitários • 1.1 MB'),
                      trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- ABA 2: Tarefas e Atividades (Print 11) ---
  Widget _buildTasksTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Atividades Avaliativas da Disciplina', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showSubmissionModal(context),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Enviar Atividade'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildTaskItem(
            'Implementação dos Padrões Adapter e Facade',
            'Prazo: Hoje às 23:59 • Peso 3.0',
            'Pendente de Envio',
            const Color(0xFFFEF3C7),
            const Color(0xFFD97706),
          ),
          const SizedBox(height: 12),
          _buildTaskItem(
            'Modelagem Arquitetural no PlantUML',
            'Enviado em 12/09/2026 • Nota: 9.5 / 10.0',
            'Avaliado pelo Professor',
            const Color(0xFFDCFCE7),
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String subtitle, String statusText, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Chip(label: Text(statusText, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: bg),
        ],
      ),
    );
  }

  // --- ABA 3: Sala Virtual Ao Vivo (Prints 13, 14, 15) ---
  Widget _buildLiveClassroomTab() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header da Sala Virtual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('AULA AO VIVO: Padrões de Projeto Estruturais', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/video-call'),
                icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                label: const Text('Abrir Sala Completa WebRTC', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Área Central do Slide
          Container(
            height: 380,
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.slideshow, size: 64, color: Colors.white54),
                      const SizedBox(height: 12),
                      Text('Slide ${_controller.currentSlideIndex} de ${_controller.totalSlides}: Padrão Adapter em Arquitetura Limpa', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Profa. Dra. Helena Bittencourt compartilhando tela', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('CC (Legenda Automática): "...o padrão adapter permite que interfaces incompatíveis colaborem sem refatorar o código existente..."', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Controles de Transmissão
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_controller.isMicMuted ? Icons.mic_off : Icons.mic, color: _controller.isMicMuted ? Colors.redAccent : Colors.white),
                onPressed: _controller.toggleMic,
                tooltip: 'Microfone',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(_controller.isCameraOff ? Icons.videocam_off : Icons.videocam, color: _controller.isCameraOff ? Colors.redAccent : Colors.white),
                onPressed: _controller.toggleCamera,
                tooltip: 'Câmera',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.pan_tool, color: _controller.isHandRaised ? Colors.amberAccent : Colors.white),
                onPressed: _controller.toggleHandRaise,
                tooltip: 'Levantar a Mão',
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _controller.prevSlide,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                label: const Text('Anterior', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _controller.nextSlide,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                label: const Text('Próximo', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ABA 4: Fórum de Dúvidas (Prints 16, 17) ---
  Widget _buildForumsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fórum de Dúvidas & Discussões Acadêmicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showNewTopicDialog(context),
                icon: const Icon(Icons.add_comment, size: 16),
                label: const Text('Publicar Nova Dúvida'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ..._controller.forumTopics.map((topic) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(topic['autor']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF18181B))),
                      Text(topic['tempo']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(topic['titulo']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(topic['respostas']!, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- ABA 5: Notas & Boletim (Print 18) ---
  Widget _buildGradesTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Boletim de Avaliações Contínuas (PPC)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Fórmula de Homologação: Média = (N1 x 0.4) + (N2 x 0.6) • Presença Mínima: 75%', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(color: const Color(0xFFE5E7EB)),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('AVALIAÇÃO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('PESO REGIMENTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('NOTA LANÇADA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              _buildGradeRow('Prova Teórica N1 (P1)', '40% da N1', '8.5 / 10.0', 'Consolidado'),
              _buildGradeRow('Trabalho Prático N1 (TRAB)', '60% da N1', '9.5 / 10.0', 'Consolidado'),
              _buildGradeRow('Prova Teórica N2 (P2)', '50% da N2', '9.0 / 10.0', 'Consolidado'),
              _buildGradeRow('Projeto Final Integrador (N2)', '50% da N2', 'Aguardando', 'Em Andamento'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Média Parcial Consolidada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${widget.discipline.partialAverage.toStringAsFixed(2)} / 10.0 (Situação: Regular)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildGradeRow(String name, String weight, String score, String status) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(name, style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.all(12), child: Text(weight, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
        Padding(padding: const EdgeInsets.all(12), child: Text(score, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Padding(padding: const EdgeInsets.all(12), child: Text(status, style: TextStyle(color: status == 'Consolidado' ? const Color(0xFF16A34A) : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }

  // --- ABA 6: Pessoas & Turma (Print 19) ---
  Widget _buildPeopleTab() {
    final people = [
      {'nome': 'Profa. Dra. Helena Bittencourt', 'papel': 'Docente Titular', 'status': 'Online na Sala', 'isTeacher': true},
      {'nome': 'Victor Hugo Mendonça', 'papel': 'Monitor de Ensino', 'status': 'Online', 'isTeacher': false},
      {'nome': 'Gabriel Soares de Oliveira (Você)', 'papel': 'Discente', 'status': 'Online', 'isTeacher': false},
      {'nome': 'Mariana Rios Costa', 'papel': 'Discente', 'status': 'Online', 'isTeacher': false},
      {'nome': 'Lucas Silva Santos', 'papel': 'Discente', 'status': 'Offline', 'isTeacher': false},
      {'nome': 'Beatriz Castro Lima', 'papel': 'Discente', 'status': 'Online', 'isTeacher': false},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Participantes da Disciplina (34 Discentes Matriculados)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...people.map((p) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (p['isTeacher'] as bool) ? const Color(0xFF18181B) : const Color(0xFFE2E8F0),
                foregroundColor: (p['isTeacher'] as bool) ? Colors.white : const Color(0xFF18181B),
                child: Text((p['nome'] as String)[0]),
              ),
              title: Text(p['nome'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(p['papel'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: Chip(
                label: Text(p['status'] as String, style: TextStyle(fontSize: 11, color: p['status'] == 'Offline' ? Colors.grey : const Color(0xFF16A34A))),
                backgroundColor: p['status'] == 'Offline' ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- ABA 7: Arquivos & Materiais (Print 20) ---
  Widget _buildFilesTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Repositório Institucional de Arquivos e Slides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _buildFileRow('Plano_de_Ensino_APS_II_2026_2.pdf', 'Documento Institucional homologado', '540 KB'),
          _buildFileRow('Apostila_Padroes_GoF_Estruturais.pdf', 'Material de apoio didático', '8.4 MB'),
          _buildFileRow('Gabarito_Comentado_P1.pdf', 'Resolução da primeira prova teórica', '1.2 MB'),
        ],
      ),
    );
  }

  Widget _buildFileRow(String name, String desc, String size) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file, color: Color(0xFF18181B)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('$desc • $size', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () {}),
    );
  }

  // --- ABA 8: Programa / Syllabus (Print 21) ---
  Widget _buildSyllabusTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Programa da Disciplina (Syllabus Homologado MEC)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('EMENTA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF18181B))),
          SizedBox(height: 4),
          Text('Padrões de projeto de software (GoF: Criacionais, Estruturais e Comportamentais). Arquiteturas em camadas, Clean Architecture e princípios SOLID. Modelagem em UML e desenvolvimento orientado a testes.', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
          SizedBox(height: 16),
          Text('BIBLIOGRAFIA BÁSICA (ABNT):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF18181B))),
          SizedBox(height: 4),
          Text('1. GAMMA, Erich et al. Padrões de Projeto: Soluções Reutilizáveis de Software Orientado a Objetos. Porto Alegre: Bookman, 2000.\n2. MARTIN, Robert C. Clean Architecture: A Craftsman\'s Guide to Software Structure and Design. Prentice Hall, 2017.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // --- ABA 9: Colaborações (Print 22) ---
  Widget _buildCollaborationsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grupo de Trabalho: Equipe 04 (Projeto Integrador)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tema: Sistema Acadêmico Distribuído com Padrão Adapter e WebRTC', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Integrantes: Gabriel Soares, Mariana Rios, Lucas Silva e Beatriz Castro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Repositório: github.com/institucional/pi-iv-time3 (Branch: develop)', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: 0.75, backgroundColor: const Color(0xFFE2E8F0), valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A))),
          const SizedBox(height: 8),
          const Text('Status dos Marcos: 3 de 4 entregas validadas', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // --- ABA 10: Caderno Pessoal (Print 23) ---
  Widget _buildNotebookTab() {
    final textController = TextEditingController(text: _controller.studentPersonalNotes);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Caderno Pessoal de Anotações (Markdown)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  _controller.updatePersonalNotes(textController.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anotações salvas com sucesso!')));
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Salvar Anotações'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            maxLines: 12,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              hintText: 'Escreva suas anotações aqui em formato Markdown...',
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 11: Chat da Turma (Print 24) ---
  Widget _buildClassChatTab() {
    final chatInput = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Chat da Turma (APS-II 2026/2)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Chip(label: Text('18 alunos conectados', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))), backgroundColor: Color(0xFFDCFCE7)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: ListView(
              children: const [
                Text('Profa. Dra. Helena Bittencourt: Pessoal, iniciamos a aula ao vivo na Sala Virtual!'),
                SizedBox(height: 8),
                Text('Mariana Rios Costa: Professora, o link do GitHub da entrega já está liberado?'),
                SizedBox(height: 8),
                Text('Profa. Dra. Helena Bittencourt: Sim, na aba Tarefas você pode anexar o zip ou informar o repositório.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatInput,
                  decoration: const InputDecoration(hintText: 'Digite uma mensagem para a turma...', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF18181B)),
                onPressed: () {
                  chatInput.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensagem enviada no chat!')));
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // MODAIS ESPECÍFICOS DO AVA
  // ==========================================
  void _showSubmissionModal(BuildContext context) {
    final gitController = TextEditingController();
    final obsController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Submeter Atividade no AVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Anexar Arquivo da Entrega (PDF, ZIP até 25MB):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: const [
                    Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF64748B)),
                    SizedBox(height: 6),
                    Text('Arraste o arquivo ou clique para selecionar', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Link do Repositório Git (Opcional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: gitController, decoration: const InputDecoration(hintText: 'https://github.com/...', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Text('Observações para o Docente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: obsController, maxLines: 2, decoration: const InputDecoration(hintText: 'Observações sobre a implementação...', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              _controller.submitDelivery(
                deliveryId: 'DEL-01',
                fileName: 'entrega_padroes_adapter.zip',
                gitUrl: gitController.text,
                comments: obsController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atividade submetida com sucesso! Protocolo gerado.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
            child: const Text('Confirmar Submissão'),
          ),
        ],
      ),
    );
  }

  void _showNewTopicDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Publicar Nova Dúvida no Fórum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título da Dúvida', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descController, maxLines: 4, decoration: const InputDecoration(labelText: 'Descrição detalhada do problema', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _controller.postForumTopic(titleController.text, descController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dúvida publicada no fórum da disciplina!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}
