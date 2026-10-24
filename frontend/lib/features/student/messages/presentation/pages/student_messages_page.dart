// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/widgets/student_sidebar.dart';
import '../../domain/entities/academic_message.dart';
import '../controllers/student_messages_controller.dart';
import '../widgets/academic_message_card.dart';
import '../widgets/message_filter_bar.dart';

/// Página da Central de Mensagens & Comunicados (Visão do Aluno).
///
/// Apresenta os avisos oficiais da Secretaria Acadêmica, Reitoria e
/// comunicados dos docentes das disciplinas com suporte a filtragem e busca.
class StudentMessagesPage extends StatefulWidget {
  /// Controlador reativo opcional da página de mensagens.
  final StudentMessagesController? controller;

  /// Callback opcional para navegação customizada na barra lateral.
  final ValueChanged<StudentNavItem>? onNavItemSelected;

  /// Cria uma instância de [StudentMessagesPage].
  const StudentMessagesPage({
    super.key,
    this.controller,
    this.onNavItemSelected,
  });

  @override
  State<StudentMessagesPage> createState() => _StudentMessagesPageState();
}

class _StudentMessagesPageState extends State<StudentMessagesPage> {
  late final StudentMessagesController _controller;
  late final bool _ownsController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? StudentMessagesController();
    _controller.addListener(_onControllerUpdated);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdated);
    if (_ownsController) {
      _controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showMessageDetailModal(AcademicMessage message) {
    _controller.markAsRead(message.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          message.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${message.sender} • ${message.dateLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message.body,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF3F3F46),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(
                color: Color(0xFF18181B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _controller.filteredMessages;

    // Removemos o StudentPortalShell e agora retornamos apenas a Column principal!
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da Seção
        const Text(
          'Central de Mensagens & Comunicados',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Avisos oficiais da Secretaria Acadêmica, Reitoria e comunicados dos docentes das disciplinas.',
          style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
        ),
        const SizedBox(height: 24),
        // Barra de Filtros e Pesquisa
        MessageFilterBar(
          activeFilter: _controller.activeFilter,
          onFilterChanged: _controller.setFilter,
          onSearchChanged: _controller.setSearchQuery,
          searchController: _searchController,
        ),
        const SizedBox(height: 22),
        // Lista de Comunicados
        if (messages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 32,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(height: 12),
                Text(
                  'Nenhum comunicado encontrado para o filtro selecionado.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF71717A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...messages.map(
            (msg) => AcademicMessageCard(
              key: Key('message_card_${msg.id}'),
              message: msg,
              onTap: () => _showMessageDetailModal(msg),
            ),
          ),
      ],
    );
  }
}
