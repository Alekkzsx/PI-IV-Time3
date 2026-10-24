// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../domain/entities/academic_message.dart';

/// Cartão de apresentação individual de um comunicado na Central de Mensagens.
class AcademicMessageCard extends StatelessWidget {
  /// Dados do comunicado a ser exibido.
  final AcademicMessage message;

  /// Callback opcional ao clicar no cartão do comunicado.
  final VoidCallback? onTap;

  /// Cria uma instância de [AcademicMessageCard].
  const AcademicMessageCard({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInstitutional =
        message.category == MessageCategory.institutional;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFFAFAFA),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha superior: Remetente, Badges e Data
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Icon(
                            isInstitutional
                                ? Icons.verified_user_outlined
                                : Icons.menu_book_outlined,
                            size: 16,
                            color: isInstitutional
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF52525B),
                          ),
                          Text(
                            message.sender,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF18181B),
                            ),
                          ),
                          _buildCategoryBadge(isInstitutional),
                          if (message.isNew) _buildNewBadge(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      message.dateLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Título do Comunicado
                Text(
                  message.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 6),
                // Corpo Descritivo
                Text(
                  message.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF52525B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(bool isInstitutional) {
    final bgColor =
        isInstitutional ? const Color(0xFFECFDF5) : const Color(0xFFF4F4F5);
    final borderColor =
        isInstitutional ? const Color(0xFFA7F3D0) : const Color(0xFFE4E4E7);
    final textColor =
        isInstitutional ? const Color(0xFF059669) : const Color(0xFF52525B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        isInstitutional ? 'INSTITUCIONAL' : 'DISCIPLINA',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Novo',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
