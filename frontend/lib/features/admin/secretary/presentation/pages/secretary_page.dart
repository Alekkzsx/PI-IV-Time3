// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/secretary/presentation/widgets/secretary_filter_bar.dart';
import 'package:pi_iv_time3/features/admin/secretary/presentation/widgets/secretary_protocols_table.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';

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
                        SecretaryFilterBar(controller: _controller),
                        const SizedBox(height: 24),
                        SecretaryProtocolsTable(
                          protocols: filteredProtocols,
                          controller: _controller,
                        ),
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
}
