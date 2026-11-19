// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaPeopleTab]
///
/// Aba 5 do Cockpit AVA: Pessoas e Participantes da Turma.
/// Apresenta o corpo docente em destaque no padrão canônico [AvaBannerSurfaceCard]
/// com canal direto de contato e a relação real de colegas matriculados vindos do MongoDB.
class AvaPeopleTab extends StatefulWidget {
  /// Controlador reativo do portal do estudante.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaPeopleTab].
  const AvaPeopleTab({super.key, required this.controller});

  @override
  State<AvaPeopleTab> createState() => _AvaPeopleTabState();
}

class _AvaPeopleTabState extends State<AvaPeopleTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discipline = widget.controller.selectedDiscipline;
    final professor = discipline?.professor ?? 'Docente Titular';
    final professorEmail = discipline?.professorEmail.isNotEmpty == true
        ? discipline!.professorEmail
        : 'docente@faculdade.edu.br';

    final allParticipants = discipline?.participants ?? const <Map<String, dynamic>>[];

    // Extrai monitores e colegas
    final monitors = allParticipants.where((p) {
      final role = (p['role'] ?? '').toString().toLowerCase();
      return role == 'monitor' || role.contains('monitor');
    }).toList();
    final classmates = allParticipants.where((p) {
      final role = (p['role'] ?? '').toString().toLowerCase();
      return role == 'aluno' || role == 'estudante';
    }).toList();

    // Filtra pela busca
    final filteredClassmates = classmates.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final ra = (c['ra'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || ra.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Pessoas e Participantes da Turma',
          subtitle:
              'Corpo docente responsável, monitores e discentes regularmente matriculados.',
          trailing: AvaSearchPillField(
            controller: _searchController,
            hintText: 'Buscar docente, monitor ou colega...',
            width: 250,
            onChanged: (q) => setState(() => _searchQuery = q.trim()),
          ),
        ),
        const SizedBox(height: 20),

        // Card Docente Responsável
        AvaBannerSurfaceCard(
          overlineTag: 'DOCENTE TITULAR RESPONSÁVEL',
          title: professor,
          subtitle: 'Docente Titular • $professorEmail',
          headerTrailing: AvaActionPillButton(
            label: 'Contatar Docente',
            icon: Icons.mail_outline_rounded,
            variant: AvaButtonVariant.secondary,
            compact: true,
            onPressed: () => _openContactModal(context, professor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF18181B),
                child: Text(
                  professor.isNotEmpty ? professor[0] : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professor,
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plantão de Atendimento: ${discipline?.officeHours ?? "Terças-feiras • 18:00 às 19:00"}',
                      style: jakarta(size: 12, color: const Color(0xFF71717A)),
                    ),
                  ],
                ),
              ),
              const AvaStatusBadge(
                label: 'Professor',
                variant: AvaBadgeVariant.neutral,
                isPill: false,
              ),
            ],
          ),
        ),

        // Monitores (se houver)
        if (monitors.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final mon in monitors)
            AvaSurfaceCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: Text(
                      (mon['name']?.toString() ?? 'M')[0],
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mon['name']?.toString() ?? 'Monitor Acadêmico',
                          style: jakarta(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monitor da Turma • ${mon['email'] ?? "monitor@faculdade.edu.br"}',
                          style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  ),
                  const AvaStatusBadge(
                    label: 'Monitor',
                    variant: AvaBadgeVariant.warning,
                    isPill: false,
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 20),

        // Seção Discentes Matriculados
        Text(
          'Colegas Matriculados (${filteredClassmates.length}):',
          style: jakarta(
            size: 14,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 12),

        if (filteredClassmates.isEmpty)
          const AvaEmptyStateCard(
            icon: Icons.person_search_outlined,
            title: 'Nenhum colega encontrado para este termo de busca.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 700;
              final colWidth = isDesktop ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: filteredClassmates.map((c) {
                  final name = (c['name'] ?? 'Estudante').toString();
                  final ra = (c['ra'] ?? '218131').toString();
                  final peerEmail = c['email']?.toString();
                  final peerStatus = (c['status'] ?? 'Matriculado').toString();
                  final isPrivatePresence =
                      peerStatus.toLowerCase() == 'privado' ||
                      c['showPresenceStatus'] == false;

                  return SizedBox(
                    width: colWidth,
                    child: AvaSurfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFF4F4F5),
                            child: Text(
                              name.isNotEmpty ? name[0] : 'E',
                              style: const TextStyle(
                                color: Color(0xFF18181B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  peerEmail != null && peerEmail.isNotEmpty
                                      ? 'RA: $ra • $peerEmail'
                                      : 'RA: $ra',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 11.5,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AvaStatusBadge(
                            label: isPrivatePresence ? 'Discreto' : 'Matriculado',
                            variant: isPrivatePresence
                                ? AvaBadgeVariant.neutral
                                : AvaBadgeVariant.success,
                            isPill: false,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  void _openContactModal(BuildContext context, String professorName) {
    final discipline = widget.controller.selectedDiscipline;
    if (discipline == null) return;
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    var isSending = false;

    AvaStandardModal.show<void>(
      context: context,
      overlineTag: 'CANAL DIRETO COM DOCENTE',
      title: 'Contatar $professorName',
      subtitle: 'Disciplina: ${discipline.code} — ${discipline.name}',
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envie uma mensagem oficial com protocolo registrado no sistema e notificação por e-mail:',
                  style: jakarta(size: 13, color: const Color(0xFF52525B), height: 1.45),
                ),
                const SizedBox(height: 14),
                Text(
                  'Assunto do Contato',
                  style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectController,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Ex.: Dúvida sobre o projeto prático ou plantão',
                    hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Mensagem Detalhada',
                  style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Escreva sua mensagem com clareza e cordialidade...',
                    hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AvaActionPillButton(
                      label: 'Cancelar',
                      variant: AvaButtonVariant.secondary,
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                    const SizedBox(width: 8),
                    AvaActionPillButton(
                      label: 'Enviar Mensagem',
                      icon: Icons.send_rounded,
                      isLoading: isSending,
                      onPressed: isSending
                          ? null
                          : () async {
                              final subj = subjectController.text.trim();
                              final msg = messageController.text.trim();
                              if (subj.length < 3 || msg.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Preencha assunto e mensagem detalhada.')),
                                );
                                return;
                              }
                              setModalState(() => isSending = true);
                              try {
                                final res = await widget.controller.contactProfessor(
                                  classCode: discipline.code,
                                  subject: subj,
                                  message: msg,
                                );
                                if (!context.mounted) return;
                                Navigator.of(modalCtx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mensagem enviada com sucesso ao docente! Protocolo: ${res['protocolCode'] ?? "AGR-MSG"}'),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isSending = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
