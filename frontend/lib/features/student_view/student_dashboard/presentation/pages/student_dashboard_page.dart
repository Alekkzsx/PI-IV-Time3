import 'package:flutter/material.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retornamos uma Column dentro de um SingleChildScrollView.
    // O Scaffold já é provido pelo StudentPortalShell.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 32),
          _buildStatsCards(),
          const SizedBox(height: 32),
          _buildMainContentRow(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Bem-vindo, Gabriel.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Engenharia de Software • 5º Semestre',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF52525B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            title: 'DISCIPLINAS',
            mainValue: '04',
            subValue: 'Ativas no Semestre',
            bottomLabel: 'Frequência Média',
            bottomValue: '94.8%',
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'ENTREGAS DO MÊS',
            mainValue: '04',
            subValue: 'Cadastradas',
            bottomLabel: 'Próximo\nVencimento',
            bottomValue: 'Hoje,\n23:59',
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'COEFICIENTE DE RENDIMENTO\n(CR)',
            mainValue: '8.8',
            subValue: '/10.0',
            bottomLabel: 'Situação Acadêmica',
            bottomValue: 'Regular',
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: 'HORAS COMPLEMENTARES',
            mainValue: '140h',
            subValue: '/ 180h',
            bottomLabel: 'Progresso Total',
            bottomValue: '77.7%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String mainValue,
    required String subValue,
    required String bottomLabel,
    required String bottomValue,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mainValue,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subValue,
                style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bottomLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
              ),
              Text(
                bottomValue,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: double.infinity,
            color: const Color(0xFFE5E7EB),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 2,
              width: 150, // Ajuste estático para visualização
              color: const Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Aula do Dia', 'HOJE, 20 SET'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildLiveClassCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFreeScheduleCard()),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Minhas Disciplinas', 'Ver grade →'),
              const SizedBox(height: 16),
              _buildDisciplinesGrid(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildPendingDeadlinesList(),
              const SizedBox(height: 32),
              _buildNoticeBoard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18181B),
          ),
        ),
        Text(
          actionText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF71717A),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveClassCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '19:00 - 20:40',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF52525B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'AO VIVO AGORA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Análise e Projeto de Sistemas II',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Profa. Dra. Helena Bittencourt',
            style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.videocam_outlined,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sala Virtual AVA •\nTeams Link',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  children: const [
                    Text(
                      'Entrar na\nVideochamada',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreeScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 190, // Altura aproximada para igualar ao card ao vivo
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today_outlined, color: Color(0xFFA1A1AA)),
            SizedBox(height: 12),
            Text(
              'Horário Livre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Reservado para estudos e atividades práticas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDisciplineCard(
          '218131 - APS-II',
          'Análise e Projeto de Sistemas II',
          'Profa. Dra. Helena Bittencourt',
          '68%',
        ),
        _buildDisciplineCard(
          '218131 - BD-II',
          'Estudos de Banco de Dados II',
          'Profa. Dra. Helena Bittencourt',
          '75%',
        ),
        _buildDisciplineCard(
          '218131 - FIS',
          'Filosofia, Informação e Sociedade',
          'Prof. Dr. Marcos Vinícius Ferreira',
          '82%',
        ),
        _buildDisciplineCard(
          '218131 - FSO',
          'Fundamentos de Sistemas Operacionais',
          'Prof. Esp. André Luiz Silveira',
          '54%',
        ),
      ],
    );
  }

  Widget _buildDisciplineCard(
    String code,
    String name,
    String teacher,
    String progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: Color(0xFF52525B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teacher,
            style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso',
                style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
              Text(
                progress,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 4,
              width: 100, // Ajuste estático para visualização
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDeadlinesList() {
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
              const Text(
                'Prazos Pendentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '4',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDeadlineItem(
            'Entrega: Diagrama de Classes e Se...',
            'Análise e Projeto de Sistemas II',
            'Hoje, 20/09 às 23:59',
          ),
          const SizedBox(height: 16),
          _buildDeadlineItem(
            'Fórum Temático: Ética na Inteligên...',
            'Filosofia, Informação e Sociedade',
            'Amanhã, 21/09 às 18:00',
          ),
          const SizedBox(height: 16),
          _buildDeadlineItem(
            'Atividade Prática: Modelagem Rel...',
            'Estudos de Banco de Dados II',
            'Quinta, 24/09 às 23:59',
          ),
          const SizedBox(height: 16),
          _buildDeadlineItem(
            'Avaliação Parcial: Gerenciamento ...',
            'Fundamentos de Sistemas Operacionais',
            'Terça, 29/09 às 20:40',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Abrir Calendário',
                style: TextStyle(
                  color: Color(0xFF18181B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(String title, String subtitle, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 3, height: 40, color: const Color(0xFF18181B)),
        const SizedBox(width: 12),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 12,
                    color: Color(0xFFA1A1AA),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA1A1AA),
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

  Widget _buildNoticeBoard() {
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
            children: const [
              Text(
                'Mural de Avisos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              Text(
                'NÃO LIDOS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNoticeItem(
            'Prof. Carlos Eduardo (APS-II)',
            'Hoje, 14:10',
            'Feedback da Sprint 1 e Orientações para o Diagrama UML',
            'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já...',
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          _buildNoticeItem(
            'Profª. Eliane Ramos (BD-II)',
            'Ontem, 17:45',
            'Material de Apoio: Normalização em 3FN e BCNF',
            'Disponibilizei os slides com os exercícios resolvidos em aula sobre dependências...',
          ),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          _buildNoticeItem(
            'Secretaria Acadêmica AGMRM',
            '18 de set',
            'Prazo para Validação de Atividades Complementares 2026/2',
            'Lembramos a todos os estudantes que o envio de certificados de cursos e palestras...',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(
    String sender,
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
            Text(
              sender,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF52525B),
              ),
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 10, color: Color(0xFFA1A1AA)),
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
          preview,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF71717A),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
