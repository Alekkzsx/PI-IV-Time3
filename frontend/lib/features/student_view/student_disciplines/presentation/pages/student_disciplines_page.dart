import 'package:flutter/material.dart';

class StudentDisciplinesPage extends StatelessWidget {
  const StudentDisciplinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retorna o conteúdo diretamente para encaixar no Shell, sem Scaffold.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGeneralStats(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 24),
          _buildDisciplinesGrid(),
          const SizedBox(height: 32),
          _buildBottomLayout(),
        ],
      ),
    );
  }

  // ==========================================
  // BLOCO 1: CABEÇALHO
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Minhas Disciplinas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ambiente Virtual de Aprendizagem (AVA), cronograma de aulas, tarefas ativas e boletim oficial.',
              style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: Color(0xFF18181B),
          ),
          label: const Text(
            'Boletim & Histórico Oficial',
            style: TextStyle(color: Color(0xFF18181B)),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BLOCO 2: ESTATÍSTICAS GERAIS (BARRA CINZA)
  // ==========================================
  Widget _buildGeneralStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatColumn(
            'CARGA HORÁRIA TOTAL',
            '190h',
            'de 280h (68%)',
            showProgress: true,
          ),
          _buildStatColumn(
            'MÉDIA PONDERADA PARCIAL',
            '8.63',
            'Mínimo regimental: 6.0',
            badgeText: 'Aprovado em todas',
          ),
          _buildStatColumn(
            'FREQUÊNCIA GLOBAL CONSOLIDADA',
            '95.7%',
            'Excelente assiduidade presencial',
            badgeSubtitle: '(12 faltas)',
            isGreenSubtitle: true,
          ),
          _buildStatColumn(
            'SITUAÇÃO CURRICULAR 2026/2',
            'Regular & Apto',
            '4 disciplinas em andamento',
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String title,
    String value,
    String subtitle, {
    bool showProgress = false,
    String? badgeText,
    String? badgeSubtitle,
    bool isGreenSubtitle = false,
    IconData? icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF71717A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              if (badgeSubtitle != null) ...[
                const SizedBox(width: 4),
                Text(
                  badgeSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ],
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (showProgress) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isGreenSubtitle
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BLOCO 3: FILTROS E BUSCA
  // ==========================================
  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildFilterChip('Todas as Disciplinas (4)', isSelected: true),
            const SizedBox(width: 8),
            _buildFilterChip('Com Tarefas Pendentes (3)'),
            const SizedBox(width: 8),
            _buildFilterChip('Aulas em Laboratório (2)'),
          ],
        ),
        SizedBox(
          width: 300,
          height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Filtrar por nome, código ou docente...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFA1A1AA),
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFFA1A1AA),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF18181B)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF52525B),
        ),
      ),
    );
  }

  // ==========================================
  // BLOCO 4: GRID DE DISCIPLINAS
  // ==========================================
  Widget _buildDisciplinesGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDisciplineCard(
                '218131 - APS-II',
                'Análise e Projeto de Sistemas II',
                'Profa. Dra. Helena Bittencourt',
                'Lab 04 - Bloco C (Noturno) • Segundas-feiras, 19:00 às 22:30',
                '54h de 80h (68%)',
                '8.5',
                '9.0',
                '8.8',
                '1 tarefa pendente',
                'Freq. 97.5%',
                '2 faltas (limite: 20h)',
                0.68,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDisciplineCard(
                '218131 - BD-II',
                'Estudos de Banco de Dados II',
                'Profa. Dra. Helena Bittencourt',
                'Lab 02 - Bloco B (Noturno) • Terças-feiras, 19:00 às 22:30',
                '60h de 80h (75%)',
                '9.0',
                '8.5',
                '8.7',
                '1 tarefa pendente',
                'Freq. 95.0%',
                '4 faltas (limite: 20h)',
                0.75,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildDisciplineCard(
                '218131 - FIS',
                'Filosofia, Informação e Sociedade',
                'Prof. Dr. Marcos Vinícius Ferreira',
                'Sala 204 - Bloco A (Noturno) • Quartas-feiras, 19:00 às 21:00',
                '32h de 40h (80%)',
                '9.5',
                '9.0',
                '9.2',
                '1 tarefa pendente',
                'Freq. 100.0%',
                '0 faltas (limite: 10h)',
                0.8,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDisciplineCard(
                '218131 - FSO',
                'Fundamentos de Sistemas Operacionais',
                'Prof. Esp. André Luiz Silveira',
                'Anfiteatro 101 - Bloco Central (Noturno) • Quintas-feiras, 19:00 às 22:30',
                '44h de 80h (55%)',
                '7.5',
                '8.0',
                '7.8',
                null,
                'Freq. 92.5%',
                '6 faltas (limite: 20h)',
                0.55,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisciplineCard(
    String code,
    String title,
    String teacher,
    String info,
    String progressText,
    String n1,
    String n2,
    String media,
    String? pendingTask,
    String freq,
    String faltas,
    double progressRatio,
  ) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF52525B),
                  ),
                ),
              ),
              Row(
                children: [
                  if (pendingTask != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pendingTask,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      freq,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teacher,
            style: const TextStyle(fontSize: 12, color: Color(0xFF52525B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFFA1A1AA),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  info,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso dos Módulos',
                style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressRatio,
            backgroundColor: const Color(0xFFE5E7EB),
            color: const Color(0xFF18181B),
            minHeight: 4,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGradeCol('Avaliação N1', n1),
                _buildGradeCol('Avaliação N2', n2),
                _buildGradeCol('Média Parcial', media, isGreen: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.menu_book,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Entrar na Disciplina (AVA)',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.videocam_outlined,
                    size: 16,
                    color: Color(0xFF16A34A),
                  ),
                  label: const Text(
                    'Sala Virtual',
                    style: TextStyle(color: Color(0xFF16A34A)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    backgroundColor: const Color(0xFFDCFCE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ver Plano de Ensino & Ementa',
                style: TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  color: Color(0xFF52525B),
                ),
              ),
              Text(
                faltas,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCol(String label, String value, {bool isGreen = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFFA1A1AA)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF18181B),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BLOCO 5: LAYOUT INFERIOR (TABELAS E AVISOS)
  // ==========================================
  Widget _buildBottomLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna da Esquerda (Maior)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildScheduleBoard(),
              const SizedBox(height: 32),
              _buildTeacherNotices(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Coluna da Direita (Menor)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildUpcomingTasks(),
              const SizedBox(height: 32),
              _buildOfficialResources(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleBoard() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Quadro Semanal de Horários & Laboratórios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Grade de encontros presenciais das 4 disciplinas no Bloco Central e Labs.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Semestre 2026/2',
                  style: TextStyle(fontSize: 11, color: Color(0xFF52525B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildScheduleItem(
            'Segunda-feira',
            '19:00 - 22:30',
            'Análise e Projeto de Sistemas II',
            'APS-II',
            'Lab 04 - Bloco C • Profa. Helena Bittencourt',
            'Laboratório Prático',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildScheduleItem(
            'Terça-feira',
            '19:00 - 22:30',
            'Estudos de Banco de Dados II',
            'BD-II',
            'Lab 02 - Bloco B • Profa. Helena Bittencourt',
            'Laboratório Prático',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildScheduleItem(
            'Quarta-feira',
            '19:00 - 21:00',
            'Filosofia, Informação e Sociedade',
            'FIS',
            'Sala 204 - Bloco A • Prof. Marcos Vinícius',
            'Teórica & Debates',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildScheduleItem(
            'Quinta-feira',
            '19:00 - 22:30',
            'Fundamentos de Sistemas Operacionais',
            'FSO',
            'Anfiteatro 101 - Bloco Central • Prof. André Luiz Silveira',
            'Teórica & Demonstração',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildScheduleItem(
            'Sexta-feira',
            '18:30 - 20:30',
            'Plantão Orientado de Dúvidas & Monitoria',
            'MONITORIA',
            'Lab 04 & Microsoft Teams • Monitores Discentes',
            'Atendimento Orientado',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String day,
    String time,
    String title,
    String code,
    String subtitle,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(fontSize: 10, color: Color(0xFF52525B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherNotices() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mural de Avisos & Comunicados Docentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Orientações recentes publicadas pelos professores das suas disciplinas.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                  ),
                ],
              ),
              const Text(
                '3 avisos',
                style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNoticeItem(
            'APS-II',
            'Profa. Dra. Helena Bittencourt',
            'Há 2 horas',
            'Orientações para o Sprint 1 e Modelagem de Domínio',
            'Lembrem-se de que os diagramas de classes devem contemplar todas as multiplicidades e a rastreabilidade com os casos de uso do Projeto Integrador. Gabarito conceitual disponível na aba de...',
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          _buildNoticeItem(
            'BD-II',
            'Profa. Dra. Helena Bittencourt',
            'Ontem',
            'Scripts de Carga e EXPLAIN ANALYZE no PostgreSQL',
            'Os scripts de povoamento da base de testes para a prática de planos de execução já estão disponíveis no repositório da disciplina. Usem o ambiente Docker homologado.',
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          _buildNoticeItem(
            'FSO',
            'Prof. Esp. André Luiz Silveira',
            '2 dias atrás',
            'Instalação das Máquinas Virtuais para Prática de Semáforos',
            'Todos os alunos devem conferir o acesso à imagem Linux do laboratório para o exercício de sincronização entre processos na próxima quinta-feira.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(
    String code,
    String teacher,
    String time,
    String title,
    String preview,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  teacher,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ],
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          preview,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF52525B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Próximas Avaliações & Entregas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              Text(
                'Ver Calendário →',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF52525B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Prazos e entregas acadêmicas das 4 disciplinas.',
            style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTaskItem(
            'APS-II',
            '25% da N2',
            'Sprint 1: Diagramas de Classes e Sequência do AVA',
            'Hoje às 23:59',
            isUrgent: true,
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTaskItem(
            'BD-II',
            '20% da N2',
            'Lista Prática 02: Normalização Formal e BCNF',
            'Amanhã às 23:59',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTaskItem(
            'FIS',
            '30% da N2',
            'Seminário: Soberania de Dados e LGPD na IA',
            '08 Out às 19:00',
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTaskItem(
            'FSO',
            '20% da N2',
            'Relatório: Simulação de Escalonamento Round-Robin',
            '15 Out às 23:59',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    String code,
    String weight,
    String title,
    String time, {
    bool isUrgent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      weight,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isUrgent
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Acessar',
              style: TextStyle(fontSize: 12, color: Color(0xFF18181B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialResources() {
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
            'Apoio Acadêmico & Recursos Oficiais',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Serviços integrados de suporte ao aprendizado e pesquisa.',
            style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
          ),
          const SizedBox(height: 24),
          _buildResourceBtn(
            Icons.menu_book,
            'Biblioteca Virtual Universitária',
            'Mais de 15.000 títulos técnicos Pearson & Minha Biblioteca',
            isExternal: true,
          ),
          const SizedBox(height: 12),
          _buildResourceBtn(
            Icons.computer,
            'Laboratórios Virtuais & Docker',
            'Ambientes conteinerizados de PostgreSQL e Linux',
            isExternal: true,
          ),
          const SizedBox(height: 12),
          _buildResourceBtn(
            Icons.school_outlined,
            'Monitoria & Nivelamento',
            'Plantões com discentes bolsistas de Seg a Sex',
            isExternal: true,
          ),
          const SizedBox(height: 12),
          _buildResourceBtn(
            Icons.description_outlined,
            'Templates Oficiais ABNT & TCC',
            'Modelos LaTeX e Word aprovados pelo Colegiado',
            isExternal: false,
            isDownload: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceBtn(
    IconData icon,
    String title,
    String subtitle, {
    bool isExternal = false,
    bool isDownload = false,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF52525B)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ),
            if (isExternal)
              const Icon(Icons.open_in_new, size: 16, color: Color(0xFFA1A1AA)),
            if (isDownload)
              const Icon(
                Icons.download_outlined,
                size: 16,
                color: Color(0xFFA1A1AA),
              ),
          ],
        ),
      ),
    );
  }
}
