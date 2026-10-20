// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/presentation/controllers/admin_portal_controller.dart';

// Tela principal do painel geral da secretaria
class PainelGeralPage extends StatelessWidget {
  const PainelGeralPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Permite rolar a tela quando o conteúdo ultrapassar o espaço disponível
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área principal do painel, localizada à esquerda
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com título, descrição e botão de comunicado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Painel Geral',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bem-vindo, Carlos.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Secretaria Geral Acadêmica • Gestão Integrada do Campus 2026/2',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Botão para emitir comunicados institucionais
                    ElevatedButton.icon(
                      onPressed: () => _showEmitirComunicadoModal(context),
                      icon: const Icon(Icons.campaign, size: 18),
                      label: const Text('Emitir Comunicado Institucional'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Exibe os principais indicadores acadêmicos em cards
                Row(
                  children: [
                    _buildStatCard(
                      'DISCENTES ATIVOS',
                      '1.240',
                      'Matriculados',
                      'Índice de Retenção',
                      '96.4%',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'CORPO DOCENTE',
                      '86',
                      'Professores',
                      'Titulação Doutor/Mestre',
                      '92.0%',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'TURMAS EM ANDAMENTO',
                      '48',
                      'no Semestre 2026/2',
                      'Alocação de Salas',
                      '100% Homologado',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'PROTOCOLOS DE SECRETARIA',
                      '07',
                      'Aguardando Parecer',
                      'Tempo Médio de Resposta',
                      '24 horas',
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Título da seção de alertas e data de referência
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alertas da Secretaria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'HOJE, 20 SET',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Exibe os alertas em dois cards lado a lado
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 4,
                              child: Container(color: Colors.black),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Identifica a categoria e a quantidade de pendências
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Colors.grey[350]!,
                                            ),
                                          ),
                                          child: const Text(
                                            'Mesa de Análise',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          '• 2 PENDENTES',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Título e descrição dos requerimentos pendentes
                                  const Text(
                                    'Requerimentos Discentes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Atestados médicos, 2ª chamada e horas',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Card com o alerta de fechamento do período letivo
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ícone que representa um prazo
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Fechamento do Período',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Trava regimental de diários e atas em 12 dias',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Cabeçalho da seção de cursos e matrizes curriculares
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cursos & Matrizes Ativas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Botão para acessar a lista completa de cursos
                    TextButton(
                      onPressed: () => _showEmitirComunicadoModal(context),
                      child: const Text(
                        'Ver todos os cursos →',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Painel lateral com os prazos acadêmicos importantes
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e quantidade de prazos cadastrados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Prazos Regimentais',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          '03',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),

                  // Primeiro prazo: fechamento das notas N1
                  _buildPrazoItem(
                    'Fechamento de Prazos N1',
                    'Prazo final para digitação de notas e frequências',
                    '30/10 às 23:59',
                    Icons.access_time,
                  ),
                  const Divider(height: 1),

                  // Segundo prazo: validação de horas complementares
                  _buildPrazoItem(
                    'Validação de Horas Complementares',
                    'Período para submissão de certificados externos',
                    'Até 15/11/2026',
                    Icons.access_time,
                  ),
                  const Divider(height: 1),

                  // Terceiro prazo: renovação de matrículas
                  _buildPrazoItem(
                    'Renovação de Matrículas 2027/1',
                    'Abertura da grade horária e pré-matrícula',
                    'Início em 01/12/2026',
                    Icons.access_time,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cria um card reutilizável para apresentar estatísticas
  Widget _buildStatCard(
    String title,
    String mainValue,
    String subValue,
    String footerLabel,
    String footerValue,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do indicador
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // Valor principal e descrição complementar
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  mainValue,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    subValue,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Informações adicionais exibidas no rodapé do card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  footerLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  footerValue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Cria um item reutilizável para apresentar cada prazo
  Widget _buildPrazoItem(
    String title,
    String subtitle,
    String dateInfo,
    IconData icon,
  ) {
    return Padding(
      // Adiciona espaço acima e abaixo de cada prazo
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do prazo
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Descrição do prazo
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          // Ícone e data limite
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                dateInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL EMITIR COMUNICADO GERAL (Print 41)
  // ==========================================
  void _showEmitirComunicadoModal(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedAudience = 'Toda a Comunidade Acadêmica';
    String selectedCategory = 'Institucional';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Emitir Comunicado Institucional Geral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título do Comunicado', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAudience,
                    decoration: const InputDecoration(labelText: 'Público-Alvo Destinatário', border: OutlineInputBorder()),
                    items: ['Toda a Comunidade Acadêmica', 'Somente Discentes', 'Somente Docentes'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setModalState(() => selectedAudience = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Classificação / Severidade', border: OutlineInputBorder()),
                    items: ['Institucional', 'Calendário Acadêmico', 'Urgente / Alerta'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setModalState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: bodyController, maxLines: 4, decoration: const InputDecoration(labelText: 'Corpo do Comunicado', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  AdminPortalController.instance.broadcastAnnouncement(
                    title: titleController.text,
                    audience: selectedAudience,
                    category: selectedCategory,
                    body: bodyController.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comunicado institucional transmitido a todos os usuários!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              child: const Text('Disparar Comunicado'),
            ),
          ],
        ),
      ),
    );
  }
}
