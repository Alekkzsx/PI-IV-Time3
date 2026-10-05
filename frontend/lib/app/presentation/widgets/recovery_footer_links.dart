// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RecoveryFooterLinks extends StatelessWidget {
  final VoidCallback? onSuporteTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onFaqTap;

  const RecoveryFooterLinks({
    super.key,
    this.onSuporteTap,
    this.onHelpCenterTap,
    this.onFaqTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Linha 1: Não lembra suas credenciais...? Fale com a Secretaria ou Suporte
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Não lembra seu R.A. ou perdeu o acesso ao e-mail? ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
            ),
            InkWell(
              onTap: onSuporteTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Text(
                  'Fale com a Secretaria Acadêmica',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Linha 2: Central de Ajuda · Perguntas Frequentes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onHelpCenterTap,
              child: Text(
                'Central de Ajuda',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '·',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            InkWell(
              onTap: onFaqTap,
              child: Text(
                'Perguntas Frequentes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
