// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SecurityAlertBanner extends StatelessWidget {
  const SecurityAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.alertBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: AppColors.alertIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      color: AppColors.alertText,
                      height: 1.45,
                    ),
                children: const [
                  TextSpan(
                    text: 'O token de redefinição enviado tem ',
                  ),
                  TextSpan(
                    text: 'validade de 5 minutos',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' por conformidade de segurança da instituição.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
