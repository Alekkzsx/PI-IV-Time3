// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin_view/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_footer.dart';

/// Tela da Secretaria Acadêmica Geral & Mesa de Protocolos da Visão do Administrador.
/// Permite filtrar protocolos por status, inspecionar documentos digitalizados
/// anexados e emitir deferimento ou indeferimento oficial com despacho formal.
class SecretaryPage extends StatefulWidget {
  const SecretaryPage({super.key});

  @override
  State<SecretaryPage> createState() => _SecretaryPageState();
}

class _SecretaryPageState extends State<SecretaryPage> {
  final AdminPortalController _controller = AdminPortalController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredProtocols = _controller.filteredProtocols;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 20.0,
                      vertical: 36.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: 24),
                        _buildFilterPills(),
                        const SizedBox(height: 24),
                        _buildProtocolsTableCard(context, filteredProtocols),
                      ],
                    ),
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // CABEÇALHO DA PÁGINA
  // ==========================================
  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Secretaria Acadêmica Geral & Protocolos',
          style: jakarta(
            size: isDesktop ? 26 : 22,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mesa de análise de atestados médicos, pedidos de segunda chamada, trancamentos e validação de horas complementares',
          style: jakarta(
            size: 14,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FILTROS DE STATUS (PILLS)
  // ==========================================
  Widget _buildFilterPills() {
    final filters = [
      'Todos Os Protocolos',
      'Aguardando Parecer',
      'Deferidos',
      'Indeferidos',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((f) {
        final isSelected = _controller.protocolFilter == f ||
            (_controller.protocolFilter == 'Todos' &&
                f == 'Todos Os Protocolos') ||
            (_controller.protocolFilter == 'Aguardando' &&
                f == 'Aguardando Parecer') ||
            (_controller.protocolFilter == 'Deferido' && f == 'Deferidos') ||
            (_controller.protocolFilter == 'Indeferido' && f == 'Indeferidos');

        return InkWell(
          onTap: () => _controller.setProtocolFilter(f),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              f,
              style: jakarta(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF525252),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // TABELA PRINCIPAL DE PROTOCOLOS
  // ==========================================
  Widget _buildProtocolsTableCard(
    BuildContext context,
    List<AdminProtocolModel> protocols,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 1100.0;
          final tableWidth =
              constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(),
                  for (int i = 0; i < protocols.length; i++)
                    _buildTableRow(context, protocols[i]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    final headerStyle = jakarta(
      size: 11,
      weight: FontWeight.w700,
      color: const Color(0xFF737373),
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 16,
            child: Text('PROTOCOLO', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 22,
            child: Text('DISCENTE / R.A.', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: Text('TIPO DE REQUERIMENTO', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 26,
            child: Text('OBJETO / COMPONENTE', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 14,
            child: Text('STATUS', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('AÇÃO', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AdminProtocolModel p) {
    final isDeferido = p.status == 'Deferido';
    final isAguardando =
        p.status == 'Aguardando' || p.status == 'Aguardando Parecer';

    Color statusBg;
    Color statusBorder;
    Color statusText;

    if (isDeferido) {
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
    } else if (isAguardando) {
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusText = const Color(0xFFD97706);
    } else {
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusText = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Protocolo
          Expanded(
            flex: 16,
            child: Text(
              p.id,
              style: jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Discente / R.A.
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.studentName,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.studentRa,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Tipo de Requerimento
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  p.requestType,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF52525B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Objeto / Componente
          Expanded(
            flex: 26,
            child: Text(
              p.targetComponent,
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF525252),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  p.status,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: statusText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Ação
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _showAnalisarRequerimentoModal(context, p),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    'Analisar Requerimento',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL ANALISAR REQUERIMENTO (Imagem 2)
  // ==========================================
  void _showAnalisarRequerimentoModal(
    BuildContext context,
    AdminProtocolModel p,
  ) {
    final parecerController = TextEditingController(
      text: p.decisionNote ??
          'Documentação idônea conferida perante os critérios da Resolução CONSEPE. Deferimento concedido com reflexo no diário.',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: SizedBox(
          width: 660,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo com identificação e botão fechar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.id,
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF737373),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'RA: ${p.studentRa}',
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF737373),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF737373),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Nome do Discente e Metadados
                Text(
                  p.studentName,
                  style: jakarta(
                    size: 20,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${p.requestType} • Submetido em ${p.date}',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 22),

                // Justificativa / Objeto do Requerimento
                Text(
                  'Justificativa / Objeto do Requerimento',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    p.justification,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Documento Anexo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.attachmentName,
                              style: jakarta(
                                size: 13,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Documento oficial digitalizado',
                              style: jakarta(
                                size: 11.5,
                                color: const Color(0xFF737373),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 14,
                          color: Color(0xFF18181B),
                        ),
                        label: Text(
                          'Conferir Anexo',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Parecer Conclusivo da Secretaria Geral
                Text(
                  'Parecer Conclusivo da Secretaria Geral (Registrado no Prontuário)',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: parecerController,
                  maxLines: 3,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Escreva a fundamentação legal da decisão...',
                    hintStyle: jakarta(size: 13, color: const Color(0xFFA3A3A3)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF18181B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Callout de Impacto Imediato
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Impacto Imediato: ',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        TextSpan(
                          text: p.immediateImpact ??
                              'Ao deferir a solicitação, a decisão da Secretaria Geral surtirá efeitos imediatos no histórico e diário acadêmico do aluno.',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Rodapé com Ações
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF525252),
                        ),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        _controller.decideProtocol(
                          protocolId: p.id,
                          defer: false,
                          parecerNote: parecerController.text,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Requerimento indeferido.',
                              style: jakarta(size: 13, color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.highlight_off_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      label: Text(
                        'Indeferir',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _controller.decideProtocol(
                          protocolId: p.id,
                          defer: true,
                          parecerNote: parecerController.text,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Requerimento deferido! Lançamento homologado com sucesso.',
                              style: jakarta(size: 13, color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF18181B),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Deferir Requerimento',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
