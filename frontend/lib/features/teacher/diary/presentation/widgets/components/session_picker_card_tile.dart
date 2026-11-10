// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/attendance_record.dart';

/// Card molecular que representa uma sessão de aula na listagem do seletor.
class SessionPickerCardTile extends StatelessWidget {
  final ClassSession session;
  final bool isSelected;
  final VoidCallback onTap;

  const SessionPickerCardTile({
    super.key,
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBFBFC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFE4E4E7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Círculo com o número da aula
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${session.sessionNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Informações da Aula
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        session.dateFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EM EXIBIÇÃO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    session.contentProgram,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF71717A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: session.isHomologated
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: session.isHomologated
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                session.isHomologated ? 'Homologada' : 'Aguardando',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: session.isHomologated
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
