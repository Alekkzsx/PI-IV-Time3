// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin_view/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_footer.dart';

/// Tela de Auditoria de Segurança & Trilha Documental (Audit Trail) da Visão do Administrador.
/// Exibe registros imutáveis de transações acadêmicas com rastreabilidade de operadores,
/// endereços IP, eventos de notas, protocolos e severidades.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final logs = _controller.auditLogs.where((l) {
      if (query.isEmpty) return true;
      return l.actor.toLowerCase().contains(query) ||
          (l.actorRole?.toLowerCase().contains(query) ?? false) ||
          l.description.toLowerCase().contains(query) ||
          l.actionType.toLowerCase().contains(query) ||
          l.ipAddress.toLowerCase().contains(query);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho da Página
                      const Text(
                        'Auditoria de Segurança & Trilha Documental (Audit Trail)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Registro irrevogável de lançamentos de notas, deferimentos de protocolos, retificações e tentativas de acesso.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Barra de Filtro / Busca
                      _buildSearchCard(),
                      const SizedBox(height: 20),

                      // Tabela de Logs de Auditoria
                      _buildAuditTableCard(logs),
                    ],
                  ),
                ),

                // Rodapé Institucional
                const AdminFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // CARD DE BUSCA / FILTRO
  // ==========================================
  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 360,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: Color(0xFF09090B)),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar por ator, ação ou descrição nos logs...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA1A1AA)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF71717A)),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CARD DA TABELA DE AUDITORIA
  // ==========================================
  Widget _buildAuditTableCard(List<AdminAuditLogModel> logs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          const double minWidth = 1050.0;
          final double effectiveWidth = box.maxWidth < minWidth ? minWidth : box.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: effectiveWidth,
              child: Column(
                children: [
                  // Cabeçalho da Tabela
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 13,
                          child: Text(
                            'DATA / HORA',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.3),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Text(
                            'AGENTE / RESPONSÁVEL',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.3),
                          ),
                        ),
                        Expanded(
                          flex: 18,
                          child: Text(
                            'TIPO DE EVENTO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.3),
                          ),
                        ),
                        Expanded(
                          flex: 34,
                          child: Text(
                            'DESCRIÇÃO DA OPERAÇÃO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.3),
                          ),
                        ),
                        Expanded(
                          flex: 15,
                          child: Text(
                            'ORIGEM (IP)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.3),
                          ),
                        ),
                        Expanded(
                          flex: 11,
                          child: Text(
                            'SEVERIDADE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.3),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),

                  // Linhas de Registros
                  if (logs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Nenhum registro de auditoria encontrado para o filtro informado.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                        ),
                      ),
                    )
                  else
                    ...logs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final log = entry.value;
                      final isLast = index == logs.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Data / Hora
                                Expanded(
                                  flex: 13,
                                  child: Text(
                                    log.timestamp,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3F3F46),
                                    ),
                                  ),
                                ),

                                // Agente / Responsável
                                Expanded(
                                  flex: 20,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.actor,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF09090B),
                                        ),
                                      ),
                                      if (log.actorRole != null && log.actorRole!.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          log.actorRole!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF71717A),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Tipo de Evento
                                Expanded(
                                  flex: 18,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F5),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFE4E4E7)),
                                      ),
                                      child: Text(
                                        log.actionType,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3F3F46),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Descrição da Operação
                                Expanded(
                                  flex: 34,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: Text(
                                      log.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3F3F46),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),

                                // Origem (IP)
                                Expanded(
                                  flex: 15,
                                  child: Text(
                                    log.ipAddress,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF52525B),
                                    ),
                                  ),
                                ),

                                // Severidade
                                Expanded(
                                  flex: 11,
                                  child: Center(
                                    child: _buildSeverityBadge(log.severity),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                        ],
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color bg;
    Color textColor;
    String label = severity;

    switch (severity.toUpperCase()) {
      case 'ATENCAO':
      case 'ATENÇÃO':
        bg = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'ATENCAO';
        break;
      case 'CRITICO':
      case 'CRÍTICO':
        bg = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'CRÍTICO';
        break;
      case 'INFO':
      default:
        bg = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        label = 'INFO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
