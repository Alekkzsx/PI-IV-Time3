// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Container responsivo e padronizado para tabelas de dados institucionais (Aluno, Docente, Admin).
class AcademicDataTableWrapper extends StatelessWidget {
  final Widget child;
  final String? tableTitle;
  final Widget? trailingHeader;
  final int? currentPage;
  final int? totalPages;
  final int? totalItems;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final EdgeInsetsGeometry padding;

  const AcademicDataTableWrapper({
    super.key,
    required this.child,
    this.tableTitle,
    this.trailingHeader,
    this.currentPage,
    this.totalPages,
    this.totalItems,
    this.onPreviousPage,
    this.onNextPage,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tableTitle != null || trailingHeader != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tableTitle != null)
                    Text(
                      tableTitle!,
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (trailingHeader != null) trailingHeader!,
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ],

          // Tabela com rolagem horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: child,
            ),
          ),

          // Rodapé opcional de paginação
          if (currentPage != null && totalPages != null) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalItems != null
                        ? 'Total de $totalItems registros'
                        : 'Página $currentPage de $totalPages',
                    style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: (currentPage! > 1) ? onPreviousPage : null,
                        color: const Color(0xFF3F3F46),
                        disabledColor: const Color(0xFFD4D4D8),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$currentPage / $totalPages',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: (currentPage! < totalPages!) ? onNextPage : null,
                        color: const Color(0xFF3F3F46),
                        disabledColor: const Color(0xFFD4D4D8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
