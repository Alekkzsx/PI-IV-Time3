// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';

/// Card individual para exibição de comunicado institucional com indicador de ciência.
class DocenteNoticeCard extends StatelessWidget {
  final AcademicNotice notice;
  final VoidCallback onTrackScience;

  const DocenteNoticeCard({
    super.key,
    required this.notice,
    required this.onTrackScience,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;
    Color badgeBorder;
    String classLabel;

    switch (notice.classification) {
      case NoticeClassification.informativo:
        badgeBg = const Color(0xFFEFF6FF);
        badgeFg = const Color(0xFF2563EB);
        badgeBorder = const Color(0xFFBFDBFE);
        classLabel = 'Informativo';
        break;
      case NoticeClassification.urgencia:
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFD97706);
        badgeBorder = const Color(0xFFFDE68A);
        classLabel = 'Urgência';
        break;
      case NoticeClassification.convocacao:
        badgeBg = const Color(0xFFFEF2F2);
        badgeFg = const Color(0xFFDC2626);
        badgeBorder = const Color(0xFFFECACA);
        classLabel = 'Convocação';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Badges & Turma
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      classLabel,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: badgeFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${notice.author} • ${notice.publishedAt}',
                    style: jakarta(
                      size: 11.5,
                      color: const Color(0xFF71717A),
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  'Turma: ${notice.targetCourse} • ${notice.targetAudience}',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF27272A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            notice.title,
            style: jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            notice.message,
            style: jakarta(
              size: 12.5,
              color: const Color(0xFF52525B),
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          // Science read receipt row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${notice.readCount} de ${notice.totalRecipients} estudantes confirmaram ciência',
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: const Color(0xFF52525B),
                          ),
                        ),
                        Text(
                          '${(notice.sciencePercentage * 100).toInt()}% de ciência',
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: notice.sciencePercentage,
                        backgroundColor: const Color(0xFFE4E4E7),
                        color: const Color(0xFF16A34A),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              OutlinedButton.icon(
                onPressed: onTrackScience,
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 14,
                  color: Color(0xFF18181B),
                ),
                label: Text(
                  'Rastrear Ciência',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF18181B),
                  side: const BorderSide(color: Color(0xFFD4D4D8)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
