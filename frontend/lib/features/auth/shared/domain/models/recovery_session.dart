// Desenvolvido por Alex Gabriel Soares Sousa, Marcelo Zarpelon, Murillo Caravita e Rafael Henrique Inácio

import 'package:flutter/material.dart';

/// Perfis de usuário aceitos no fluxo de autenticação e recuperação do portal.
enum UserProfile {
  /// Perfil discente: autenticação via R.A. ou e-mail de aluno.
  aluno,

  /// Perfil docente: autenticação via Matrícula ou e-mail institucional.
  docente,

  /// Perfil administrativo: autenticação via credencial de administração.
  admin,
}

/// Modelo de domínio que encapsula os metadados da sessão de recuperação de credenciais.
///
/// Propagado de forma tipada entre as rotas:
/// `/recover-password` ➔ `/verify-code` ➔ `/reset-password` ➔ `/` (Login com feedback).
class RecoverySession {
  /// Perfil acadêmico ou corporativo do usuário.
  final UserProfile profile;

  /// R.A., matrícula docente ou login institucional digitado.
  final String identity;

  /// Nome completo oficial registrado no portal.
  final String displayName;

  /// E-mail institucional registrado para envio de credenciais.
  final String institutionalEmail;

  /// Curso, departamento ou lotação administrativa.
  final String departmentOrCourse;

  /// Distintivo do papel institucional.
  final String roleBadge;

  const RecoverySession({
    required this.profile,
    required this.identity,
    required this.displayName,
    required this.institutionalEmail,
    required this.departmentOrCourse,
    required this.roleBadge,
  });

  /// Constrói a sessão de recuperação com os dados institucionais oficiais padronizados
  /// de acordo com o perfil e o identificador fornecido.
  factory RecoverySession.fromProfileAndIdentity({
    required UserProfile profile,
    required String identity,
  }) {
    final cleanIdentity = identity.trim();
    switch (profile) {
      case UserProfile.aluno:
        return RecoverySession(
          profile: profile,
          identity: cleanIdentity.isNotEmpty ? cleanIdentity : '2024.1.00892',
          displayName: 'Gabriel Soares de Oliveira',
          institutionalEmail: 'gabriel.oliveira@aluno.universidade.edu.br',
          departmentOrCourse: 'Engenharia de Software • 5º Semestre',
          roleBadge: 'Discente Regular',
        );
      case UserProfile.docente:
        return RecoverySession(
          profile: profile,
          identity: cleanIdentity.isNotEmpty ? cleanIdentity : 'DOC-40892',
          displayName: 'Profa. Dra. Helena Cristina Santos',
          institutionalEmail: 'helena.santos@docente.universidade.edu.br',
          departmentOrCourse: 'Ciência da Computação & Engenharia',
          roleBadge: 'Corpo Docente',
        );
      case UserProfile.admin:
        return RecoverySession(
          profile: profile,
          identity: cleanIdentity.isNotEmpty ? cleanIdentity : 'ADM-00123',
          displayName: 'Carlos Alberto Silveira',
          institutionalEmail: 'carlos.silveira@admin.universidade.edu.br',
          departmentOrCourse: 'DTI • Secretaria Geral Acadêmica',
          roleBadge: 'Administrador de Sistemas',
        );
    }
  }

  /// Retorna o e-mail mascarado com asteriscos para privacidade e conformidade com a LGPD.
  /// Ex: g***.oliveira@aluno.universidade.edu.br
  String get maskedEmail {
    final parts = institutionalEmail.split('@');
    if (parts.length != 2) return institutionalEmail;
    final user = parts[0];
    final domain = parts[1];
    if (user.length <= 3) {
      return '$user***@$domain';
    }
    final firstChar = user[0];
    final lastChar = user[user.length - 1];
    return '$firstChar***$lastChar@$domain';
  }

  /// Identificador formatado com rótulo institucional de acordo com a categoria.
  String get formattedIdentityLabel {
    switch (profile) {
      case UserProfile.aluno:
        return 'R.A. $identity';
      case UserProfile.docente:
        return 'Matrícula $identity';
      case UserProfile.admin:
        return 'Credencial $identity';
    }
  }

  /// Ícone representativo do perfil institucional.
  IconData get profileIcon {
    switch (profile) {
      case UserProfile.aluno:
        return Icons.school_outlined;
      case UserProfile.docente:
        return Icons.badge_outlined;
      case UserProfile.admin:
        return Icons.shield_outlined;
    }
  }
}
