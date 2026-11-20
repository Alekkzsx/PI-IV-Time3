// Desenvolvido por Murillo Caravita - RA: 25014012
// Componente atômico para exibição padronizada de status de submissão discente

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/assignment_model.dart';
import '../../../../../../shared/widgets/academic_status_badge.dart';

class SubmissionStatusBadge extends StatelessWidget {
  final SubmissionStatus status;

  const SubmissionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SubmissionStatus.corrigido:
        return const AcademicStatusBadge(
          label: 'Corrigido',
          type: AcademicStatusType.aprovado,
        );
      case SubmissionStatus.aguardandoCorrecao:
        return const AcademicStatusBadge(
          label: 'Aguardando Correção',
          type: AcademicStatusType.pendente,
        );
      case SubmissionStatus.entregue:
        return const AcademicStatusBadge(
          label: 'Entregue',
          type: AcademicStatusType.aberto,
        );
      case SubmissionStatus.atrasado:
        return const AcademicStatusBadge(
          label: 'Atrasado',
          type: AcademicStatusType.reprovado,
        );
      case SubmissionStatus.naoEntregue:
        return const AcademicStatusBadge(
          label: 'Não Entregue',
          type: AcademicStatusType.custom,
        );
    }
  }
}
