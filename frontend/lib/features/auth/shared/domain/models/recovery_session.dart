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
  final String? resetToken;

  const RecoverySession({
    required this.profile,
    required this.identity,
    required this.displayName,
    required this.institutionalEmail,
    required this.departmentOrCourse,
    required this.roleBadge,
    this.resetToken,
  });

  RecoverySession withResetToken(String token) => copyWith(resetToken: token);

  RecoverySession copyWith({
    UserProfile? profile,
    String? identity,
    String? displayName,
    String? institutionalEmail,
    String? departmentOrCourse,
    String? roleBadge,
    String? resetToken,
  }) => RecoverySession(
    profile: profile ?? this.profile,
    identity: identity ?? this.identity,
    displayName: displayName ?? this.displayName,
    institutionalEmail: institutionalEmail ?? this.institutionalEmail,
    departmentOrCourse: departmentOrCourse ?? this.departmentOrCourse,
    roleBadge: roleBadge ?? this.roleBadge,
    resetToken: resetToken ?? this.resetToken,
  );

  /// Constrói a sessão com dados reais retornados pelo servidor Java / MongoDB.
  factory RecoverySession.fromServerData({
    required UserProfile fallbackProfile,
    required String fallbackIdentity,
    required Map<String, dynamic> data,
    String? resetToken,
  }) {
    final profileStr = data['profile']?.toString() ?? fallbackProfile.name;
    final profile = switch (profileStr.toLowerCase()) {
      'admin' => UserProfile.admin,
      'docente' => UserProfile.docente,
      _ => UserProfile.aluno,
    };
    final identity = data['identity']?.toString() ?? fallbackIdentity;
    final displayName = data['displayName']?.toString() ??
        data['nome']?.toString() ??
        'Usuário';
    final email = data['email']?.toString() ??
        data['maskedEmail']?.toString() ??
        (identity.contains('@') ? identity : 'e-mail cadastrado');
    final departmentOrCourse = data['departmentOrCourse']?.toString() ??
        data['department']?.toString() ??
        '';
    final token = resetToken ??
        data['resetToken']?.toString() ??
        data['recoveryToken']?.toString();

    return RecoverySession(
      profile: profile,
      identity: identity,
      displayName: displayName,
      institutionalEmail: email,
      departmentOrCourse: departmentOrCourse,
      roleBadge: profile == UserProfile.admin
          ? 'Administrador'
          : profile == UserProfile.docente
          ? 'Docente'
          : 'Aluno',
      resetToken: token,
    );
  }

  /// Constrói a sessão de recuperação com os dados institucionais oficiais padronizados
  /// de acordo com o perfil e o identificador fornecido.
  factory RecoverySession.fromProfileAndIdentity({
    required UserProfile profile,
    required String identity,
    String? displayName,
    String? institutionalEmail,
    String? departmentOrCourse,
  }) {
    final cleanIdentity = identity.trim();
    if (cleanIdentity.isEmpty) throw ArgumentError('Identidade obrigatória.');
    return RecoverySession(
      profile: profile,
      identity: cleanIdentity,
      displayName: displayName != null && displayName.trim().isNotEmpty
          ? displayName.trim()
          : (cleanIdentity.contains('@') ? cleanIdentity.split('@').first : 'Usuário'),
      institutionalEmail: institutionalEmail != null && institutionalEmail.trim().isNotEmpty
          ? institutionalEmail.trim()
          : (cleanIdentity.contains('@') ? cleanIdentity : 'e-mail cadastrado'),
      departmentOrCourse: departmentOrCourse ?? '',
      roleBadge: profile == UserProfile.admin
          ? 'Administrador'
          : profile == UserProfile.docente
          ? 'Docente'
          : 'Aluno',
    );
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
