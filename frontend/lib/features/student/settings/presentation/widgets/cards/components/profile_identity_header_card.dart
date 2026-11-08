// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../common/settings_common_widgets.dart';

/// [ProfileIdentityHeaderCard]
///
/// Cartão superior de identificação visual do discente nas Configurações,
/// exibindo avatar com iniciais, selo de matrícula ativa, R.A. e curso.
class ProfileIdentityHeaderCard extends StatelessWidget {
  /// Iniciais do nome do discente.
  final String initials;

  /// Nome de exibição do estudante.
  final String studentName;

  /// Registro Acadêmico (R.A.).
  final String studentRa;

  /// Nome do curso de graduação.
  final String studentCourse;

  /// Cria uma nova instância de [ProfileIdentityHeaderCard].
  const ProfileIdentityHeaderCard({
    super.key,
    required this.initials,
    required this.studentName,
    required this.studentRa,
    required this.studentCourse,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF18181B),
                  border: Border.all(
                    color: const Color(0xFFE4E4E7),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: jakarta(
                    size: 24,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        studentName,
                        style: jakarta(
                          size: 16.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        'Matrícula Ativa',
                        style: jakarta(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'R.A.: $studentRa',
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 13,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        studentCourse,
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF3F3F46),
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
    );
  }
}
