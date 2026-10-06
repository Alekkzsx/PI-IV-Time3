// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Card informativo que atesta a identidade acadêmica confirmada do discente.
///
/// Exibe um distintivo circular de capelo universitário, o nome do aluno,
/// o número de registro acadêmico (R.A.), o e-mail institucional e um
/// selo circular de verificação verde (`Icons.check`).
class AcademicIdentityCard extends StatelessWidget {
  /// Nome completo do discente verificado.
  final String studentName;

  /// Número de registro acadêmico formatado (ex: `R.A. 2024.1.00892`).
  final String academicRegistration;

  /// E-mail institucional do discente associado à credencial.
  final String studentEmail;

  /// Cria uma nova instância de [AcademicIdentityCard].
  ///
  /// Parâmetros:
  /// - [studentName]: Nome do aluno (padrão: `'Gabriel Martins'`).
  /// - [academicRegistration]: Registro acadêmico (padrão: `'R.A. 2024.1.00892'`).
  /// - [studentEmail]: E-mail acadêmico (padrão: `'gabriel.martins@aluno.universidade.edu.br'`).
  const AcademicIdentityCard({
    super.key,
    this.studentName = 'Gabriel Martins',
    this.academicRegistration = 'R.A. 2024.1.00892',
    this.studentEmail = 'gabriel.martins@aluno.universidade.edu.br',
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone do Capelo Acadêmico
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // slate-100
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          // Dados do Aluno (Nome, RA, Email)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' • $academicRegistration',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  studentEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Checkmark de Confirmação da Identidade
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // green-100
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: Color(0xFF16A34A), // green-600
            ),
          ),
        ],
      ),
    );
  }
}

