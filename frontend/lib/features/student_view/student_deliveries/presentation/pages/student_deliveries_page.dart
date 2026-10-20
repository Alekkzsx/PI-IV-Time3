import 'package:flutter/material.dart';

class StudentDeliveriesPage extends StatelessWidget {
  const StudentDeliveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 32),
          _buildTabsAndFilters(),
          const SizedBox(height: 24),
          _buildDeliveriesList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Central de Entregas & Atividades',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gerencie prazos acadêmicos, envie seus trabalhos e acompanhe pareceres e notas oficiais.',
              style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Text(
                'Semestre Letivo:',
                style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
              SizedBox(width: 4),
              Text(
                '2026/2',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ESTATÍSTICAS SUPERIORES
  // ==========================================
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'PENDENTES',
            value: '4',
            subtitle: 'atividades',
            description: 'Há entregas com prazo fatal nos próximos 2 dias.',
            topRightWidget: const Icon(
              Icons.access_time,
              size: 18,
              color: Color(0xFF18181B),
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.info_outline, size: 10, color: Color(0xFFDC2626)),
                  SizedBox(width: 4),
                  Text(
                    '1 urgente',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'EM ANÁLISE',
            value: '2',
            subtitle: 'aguardando correção',
            description: 'Submissões com protocolo emitido aguardando parecer.',
            topRightWidget: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.send_outlined,
                size: 14,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'AVALIADAS',
            value: '3',
            subtitle: 'concluídas no semestre',
            description: 'Com notas consolidadas e devolutiva do docente.',
            topRightWidget: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.bookmark_outline,
                size: 14,
                color: Color(0xFF18181B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'MÉDIA PONDERADA',
            value: '9.7',
            subtitle: '/ 10.0',
            description:
                'Média das notas de trabalhos entregues até o momento.',
            topRightWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                border: Border.all(color: const Color(0xFF86EFAC)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Excelente',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required String description,
    Widget? topRightWidget,
    Widget? badgeWidget,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (topRightWidget != null) topRightWidget,
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
              if (badgeWidget != null) ...[const Spacer(), badgeWidget],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFA1A1AA),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TABS, BUSCA E FILTROS
  // ==========================================
  Widget _buildTabsAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            _buildTabItem('Todas as Atividades', '9', isActive: true),
            _buildTabItem('Pendentes', '4'),
            _buildTabItem('Em Análise / Enviadas', '2'),
            _buildTabItem('Avaliadas com Nota', '3'),
          ],
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFE5E7EB),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 400,
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por título, código ou palavra-chave...',
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
            Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disciplina:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Todas as disciplinas',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      SizedBox(width: 32),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Color(0xFF18181B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabItem(String title, String count, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, right: 24, left: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? const Color(0xFF18181B) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? const Color(0xFF18181B)
                  : const Color(0xFF71717A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF18181B)
                  : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF71717A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LISTA DE ENTREGAS
  // ==========================================
  Widget _buildDeliveriesList() {
    return Column(
      children: [
        // Exemplo 1: Tarefa Pendente e Urgente
        _buildTaskCard(
          code: 'APS-ATV-04',
          discipline: 'Análise e Projeto de Sistemas II',
          title:
              'Modelagem de Domínio e Diagramas de Casos de Uso com Padrões GoF',
          description:
              'Elaboração de documento técnico contendo a especificação detalhada de 3 casos de uso do sistema acadêmico, o diagrama de classes de domínio com cardinalidades e justificativa técnica da aplicação de pelo menos dois padrões de projeto GoF (Factory Method e Strategy).',
          dataLimite: '02 de Outubro, 23:59',
          docente: 'Profa. Dra. Helena Bittencourt',
          criterio: 'Peso 2.5 • Nota Máx: 10.0',
          topRightBadge: _buildUrgentBadge('Prazo fatal: em 2 dias'),
          bottomLeftWidget: const Text(
            'Formatos aceitos: .pdf, .zip • Max: 25MB',
            style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
          actionButton: _buildActionButton(
            'Realizar Entrega',
            Icons.upload,
            isDark: true,
          ),
        ),
        const SizedBox(height: 16),
        // Exemplo 2: Tarefa Pendente Normal
        _buildTaskCard(
          code: 'BD2-LAB-03',
          discipline: 'Banco de Dados II',
          title:
              'Otimização de Índices B-Tree, Explain Plan e Triggers no PostgreSQL',
          description:
              'Prática de laboratório com execução de planos de consulta (EXPLAIN ANALYZE) sobre dataset com 1 milhão de tuplas, criação de índices parciais e implementação de trigger para auditoria de alterações sensíveis.',
          dataLimite: '05 de Outubro, 23:59',
          docente: 'Prof. Me. Carlos Eduardo Silva',
          criterio: 'Peso 2.0 • Nota Máx: 10.0',
          topRightBadge: _buildNormalBadge(
            'Prazo em 5 dias',
            Icons.access_time,
          ),
          bottomLeftWidget: const Text(
            'Formatos aceitos: .sql, .pdf, .zip • Max: 30MB',
            style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
          actionButton: _buildActionButton(
            'Realizar Entrega',
            Icons.upload,
            isDark: true,
          ),
        ),
        const SizedBox(height: 16),
        // Exemplo 3: Tarefa Enviada / Em Análise
        _buildTaskCard(
          code: 'APS-ATV-03',
          discipline: 'Análise e Projeto de Sistemas II',
          title: 'Documento de Visão e Requisitos de Software v1.2',
          description:
              'Revisão completa do documento de requisitos incorporando as regras de negócio de fechamento contábil e autenticação federada com OAuth 2.0 / SAML.',
          dataLimite: '28 de Setembro, 23:59',
          docente: 'Profa. Dra. Helena Bittencourt',
          criterio: 'Peso 2.0 • Nota Máx: 10.0',
          topRightBadge: _buildBlueBadge(
            'Enviada em 28/09/2026',
            Icons.send_outlined,
          ),
          bottomLeftWidget: Row(
            children: const [
              Icon(
                Icons.verified_user_outlined,
                size: 14,
                color: Color(0xFF16A34A),
              ),
              SizedBox(width: 4),
              Text(
                'Protocolo: ',
                style: TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
              ),
              Text(
                'AGR-2026-0928-8472 (1 anexo)',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
          actionButton: _buildActionButton(
            'Ver Comprovante',
            Icons.insert_drive_file_outlined,
            isGreen: true,
          ),
        ),
        const SizedBox(height: 16),
        // Exemplo 4: Tarefa Avaliada
        _buildTaskCard(
          code: 'APS-ATV-01',
          discipline: 'Análise e Projeto de Sistemas II',
          title:
              'Estudo de Caso 01: Análise de Viabilidade Técnica e Econômica',
          description:
              'Elaboração de parecer técnico sobre a substituição de sistema legado monolítico por arquitetura distribuída, com cálculo de TCO (Total Cost of Ownership), ROI estimado e análise de riscos.',
          dataLimite: '14 de Setembro, 23:59',
          docente: 'Profa. Dra. Helena Bittencourt',
          criterio: 'Peso 2.0 • Nota Máx: 10.0',
          topRightBadge: _buildOutlineGreenBadge(
            'Nota: 9.8 / 10.0',
            Icons.check_circle_outline,
          ),
          bottomLeftWidget: const Text(
            'Parecer emitido em 17/09/2026',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          actionButton: _buildActionButton(
            'Ver Devolutiva & Nota',
            Icons.check_circle_outline,
            isGreen: true,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CONSTRUTOR GENÉRICO DO CARTÃO DE TAREFA
  // ==========================================
  Widget _buildTaskCard({
    required String code,
    required String discipline,
    required String title,
    required String description,
    required String dataLimite,
    required String docente,
    required String criterio,
    required Widget topRightBadge,
    required Widget bottomLeftWidget,
    required Widget actionButton,
  }) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  const SizedBox(width: 12),
                  Text(
                    discipline,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
              topRightBadge,
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
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF71717A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn(
                  'DATA LIMITE',
                  dataLimite,
                  icon: Icons.access_time,
                ),
              ),
              Expanded(child: _buildInfoColumn('DOCENTE RESPONSÁVEL', docente)),
              Expanded(child: _buildInfoColumn('CRITÉRIO E PESO', criterio)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              bottomLeftWidget,
              Row(
                children: [
                  actionButton,
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFFA1A1AA),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA1A1AA),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFFA1A1AA)),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF18181B)),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // BADGES E BOTÕES DE ESTADO
  // ==========================================
  Widget _buildUrgentBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 12, color: Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF71717A)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF52525B)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineGreenBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    bool isDark = false,
    bool isGreen = false,
  }) {
    Color bgColor = Colors.white;
    if (isDark) bgColor = const Color(0xFF18181B);
    if (isGreen)
      bgColor = const Color(0xFF14532D); // Verde bem escuro conforme o layout

    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}
