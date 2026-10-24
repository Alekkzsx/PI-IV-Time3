// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../shared/domain/models/recovery_session.dart';

/// Card informativo que atesta a identidade institucional confirmada do usuário.
///
/// Exibe um distintivo dinâmico correspondente ao perfil (capelo universitário,
/// crachá docente ou escudo administrativo), nome oficial, número de registro acadêmico/matrícula,
/// e-mail institucional e um selo circular de verificação verde (`Icons.check`).
class AcademicIdentityCard extends StatelessWidget {
  /// Sessão de recuperação opcional contendo todos os dados já validados.
  final RecoverySession? session;

  /// Nome completo verificado.
  final String studentName;

  /// Registro formatado (ex: `R.A. 2024.1.00892`).
  final String academicRegistration;

  /// E-mail institucional do usuário.
  final String studentEmail;

  /// Curso ou departamento acadêmico.
  final String? department;

  /// Cria uma nova instância de [AcademicIdentityCard].
  const AcademicIdentityCard({
    super.key,
    this.session,
    this.studentName = 'Gabriel Soares de Oliveira',
    this.academicRegistration = 'R.A. 2024.1.00892',
    this.studentEmail = 'gabriel.oliveira@aluno.universidade.edu.br',
    this.department,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveName = session?.displayName ?? studentName;
    final effectiveRegistration =
        session?.formattedIdentityLabel ?? academicRegistration;
    final effectiveEmail = session?.institutionalEmail ?? studentEmail;
    final effectiveDepartment =
        session?.departmentOrCourse ?? department ?? 'Engenharia de Software';
    final effectiveIcon = session?.profileIcon ?? Icons.school_outlined;
    final effectiveBadge = session?.roleBadge ?? 'Identidade Confirmada';

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
          // Ícone do Perfil
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), // slate-100
              shape: BoxShape.circle,
            ),
            child: Icon(effectiveIcon, size: 22, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 14),
          // Dados Oficiais do Usuário (Nome, RA/Matrícula, Curso/Depto e Email)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        effectiveName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $effectiveRegistration',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  effectiveDepartment,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  effectiveEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Checkmark de Confirmação da Identidade com Tooltip
          Tooltip(
            message: effectiveBadge,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7), // green-100
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF16A34A), // green-600
              ),
            ),
          ),
        ],
      ),
    );
  }
}
