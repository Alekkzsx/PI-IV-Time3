// Desenvolvido por Rafael Henrique dos Santos Inácio - RA: 25009719

import 'package:flutter/material.dart';

// Enum para mapear os 3 estados que identificamos no protótipo
enum DeliveryStatus { pending, inReview, graded }

class StudentDeliveriesPage extends StatelessWidget {
  const StudentDeliveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Cor de fundo suave do painel
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDashboardCards(),
            const SizedBox(height: 32),
            _buildTabsAndFilters(),
            const SizedBox(height: 24),
            _buildDeliveriesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Central de Entregas & Atividades',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Gerencie prazos acadêmicos, envie seus trabalhos e acompanhe pareceres e notas oficiais.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Semestre Letivo: 2026/2',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCards() {
    // Aqui você pode criar um Row com 4 Expanded contendo os 4 cards brancos
    // (Pendentes, Em Análise, Avaliadas, Média Ponderada)
    return Row(
      children: [
        _buildMetricCard(
          'PENDENTES',
          '4',
          'atividades',
          'Há entregas com prazo fatal nos próximos 2 dias.',
          isUrgent: true,
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          'EM ANÁLISE',
          '2',
          'aguardando correção',
          'Submissões com protocolo emitido aguardando parecer.',
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          'AVALIADAS',
          '3',
          'concluídas no semestre',
          'Com notas consolidadas e devolutiva do docente.',
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          'MÉDIA PONDERADA',
          '9.7',
          '/ 10.0',
          'Média das notas de trabalhos entregues até o momento.',
          isSuccess: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    String desc, {
    bool isUrgent = false,
    bool isSuccess = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green.shade700 : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsAndFilters() {
    // Linha contendo Filtros de Texto e Dropdown
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por título, código ou palavra-chave...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: 'Todas as disciplinas',
                items:
                    [
                          'Todas as disciplinas',
                          'Análise e Projeto de Sistemas II',
                          'Banco de Dados II',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) {},
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveriesList() {
    return Column(
      children: [
        // Exemplo 1: Pendente e Urgente
        DeliveryCardWidget(
          status: DeliveryStatus.pending,
          courseCode: 'APS-ATV-04',
          courseName: 'Análise e Projeto de Sistemas II',
          title:
              'Modelagem de Domínio e Diagramas de Casos de Uso com Padrões GoF',
          description:
              'Elaboração de documento técnico contendo a especificação detalhada de 3 casos de uso do sistema acadêmico...',
          deadline: '02 de Outubro, 23:59',
          professor: 'Profa. Dra. Helena Bittencourt',
          criteria: 'Peso 2.5 • Nota Máx: 10.0',
          statusLabel: 'Prazo fatal: em 2 dias',
          footerInfo: 'Formatos aceitos: .pdf, .zip • Max: 25MB',
          actionText: 'Realizar Entrega',
        ),
        const SizedBox(height: 16),
        // Exemplo 2: Em Análise
        DeliveryCardWidget(
          status: DeliveryStatus.inReview,
          courseCode: 'APS-ATV-03',
          courseName: 'Análise e Projeto de Sistemas II',
          title: 'Documento de Visão e Requisitos de Software v1.2',
          description:
              'Revisão completa do documento de requisitos incorporando as regras de negócio de fechamento contábil...',
          deadline: '28 de Setembro, 23:59',
          professor: 'Profa. Dra. Helena Bittencourt',
          criteria: 'Peso 2.0 • Nota Máx: 10.0',
          statusLabel: 'Enviada em 28/09/2026',
          footerInfo: 'Protocolo: AGR-2026-0928-8472 (1 anexo)',
          actionText: 'Ver Comprovante',
        ),
        const SizedBox(height: 16),
        // Exemplo 3: Avaliada
        DeliveryCardWidget(
          status: DeliveryStatus.graded,
          courseCode: 'APS-ATV-01',
          courseName: 'Análise e Projeto de Sistemas II',
          title:
              'Estudo de Caso 01: Análise de Viabilidade Técnica e Econômica',
          description:
              'Elaboração de parecer técnico sobre a substituição de sistema legado monolítico por arquitetura distribuída...',
          deadline: '14 de Setembro, 23:59',
          professor: 'Profa. Dra. Helena Bittencourt',
          criteria: 'Peso 2.0 • Nota Máx: 10.0',
          statusLabel: 'Nota: 9.8 / 10.0',
          footerInfo: 'Parecer emitido em 17/09/2026',
          actionText: 'Ver Devolutiva & Nota',
        ),
      ],
    );
  }
}

// Widget Reutilizável do Card que se adapta aos estados
class DeliveryCardWidget extends StatelessWidget {
  final DeliveryStatus status;
  final String courseCode;
  final String courseName;
  final String title;
  final String description;
  final String deadline;
  final String professor;
  final String criteria;
  final String statusLabel;
  final String footerInfo;
  final String actionText;

  const DeliveryCardWidget({
    super.key,
    required this.status,
    required this.courseCode,
    required this.courseName,
    required this.title,
    required this.description,
    required this.deadline,
    required this.professor,
    required this.criteria,
    required this.statusLabel,
    required this.footerInfo,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color actionButtonColor;

    switch (status) {
      case DeliveryStatus.pending:
        statusColor = Colors.red.shade700;
        actionButtonColor = const Color(0xFF1E1E1E); // Preto
        break;
      case DeliveryStatus.inReview:
        statusColor = Colors.blue.shade700;
        actionButtonColor = const Color(0xFF1E5B3A); // Verde Escuro
        break;
      case DeliveryStatus.graded:
        statusColor = Colors.green.shade700;
        actionButtonColor = const Color(0xFF1E5B3A); // Verde Escuro
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      courseCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    courseName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status == DeliveryStatus.pending
                      ? Colors.red.shade50
                      : Colors.white,
                  border: Border.all(
                    color: status == DeliveryStatus.graded
                        ? Colors.green
                        : statusColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Corpo do Card
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Metadados
          Row(
            children: [
              _buildMetaColumn('DATA LIMITE', deadline),
              const SizedBox(width: 48),
              _buildMetaColumn('DOCENTE RESPONSÁVEL', professor),
              const SizedBox(width: 48),
              _buildMetaColumn('CRITÉRIO E PESO', criteria),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Footer do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footerInfo,
                style: TextStyle(
                  color: status == DeliveryStatus.pending
                      ? Colors.grey.shade600
                      : Colors.green.shade700,
                  fontSize: 14,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      actionText,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
