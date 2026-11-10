// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Componente atômico para edição de conteúdo e metodologia do plano de aula MEC.
class LessonPlanContentEditor extends StatelessWidget {
  final TextEditingController contentController;
  final TextEditingController methodologyController;
  final TextEditingController locationController;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<String> onMethodologyChanged;
  final ValueChanged<String> onLocationChanged;

  const LessonPlanContentEditor({
    super.key,
    required this.contentController,
    required this.methodologyController,
    required this.locationController,
    required this.onContentChanged,
    required this.onMethodologyChanged,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Conteúdo Programático Específico Ministrado
        const Text(
          'Conteúdo Programático Específico Ministrado (Exigência Regimental MEC)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: contentController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, color: Color(0xFF18181B)),
          onChanged: onContentChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF18181B),
                width: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Metodologia e Recursos Aplicados + Local Real de Realização (2 Colunas Responsivas)
        LayoutBuilder(
          builder: (context, c) {
            final isNarrow = c.maxWidth < 650;

            final methodologyField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Metodologia e Recursos Aplicados',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: methodologyController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF18181B),
                  ),
                  onChanged: onMethodologyChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                      borderSide: const BorderSide(
                        color: Color(0xFF18181B),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            );

            final locationField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local Real de Realização',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: locationController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF18181B),
                  ),
                  onChanged: onLocationChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                      borderSide: const BorderSide(
                        color: Color(0xFF18181B),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                children: [
                  methodologyField,
                  const SizedBox(height: 14),
                  locationField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: methodologyField),
                const SizedBox(width: 16),
                Expanded(child: locationField),
              ],
            );
          },
        ),
      ],
    );
  }
}
