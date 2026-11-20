// Desenvolvido por Marcelo Zarpelon - RA: 25015323

/// Uma sessão de login ativa no dispositivo do usuário.
class ActiveSession {
  final String id;
  final String device;
  final String location;
  final String ip;
  final String lastActive;
  final bool isCurrent;

  const ActiveSession({
    required this.id,
    required this.device,
    required this.location,
    required this.ip,
    required this.lastActive,
    this.isCurrent = false,
  });
}

/// Um registro de auditoria de segurança para tentativas de login.
class LoginAudit {
  final String date;
  final String time;
  final String device;
  final String location;
  final String ip;
  final String status; // 'Autorizado', 'Bloqueado'

  const LoginAudit({
    required this.date,
    required this.time,
    required this.device,
    required this.location,
    required this.ip,
    required this.status,
  });

  /// Data e hora formatadas.
  String get timestamp => '$date às $time';

  /// Indica se a autenticação foi concedida.
  bool get success =>
      status.toLowerCase().contains('autorizado') ||
      status.toLowerCase().contains('sucesso');
}

/// Representa a conta e o perfil de segurança do docente.
class DocenteProfile {
  final String fullName;
  final String socialName;
  final String registrationId;
  final String department;
  final String semester;
  final String campus;
  final String status;
  final String academicEmail;
  final String personalEmail;
  final bool twoFactorEnabled;
  final List<ActiveSession> activeSessions;
  final List<LoginAudit> loginAudits;

  static const DocenteProfile empty = DocenteProfile(
    fullName: '',
    socialName: '',
    registrationId: '',
    department: '',
    semester: '',
    campus: '',
    status: '',
    academicEmail: '',
    personalEmail: '',
    twoFactorEnabled: false,
    activeSessions: [],
    loginAudits: [],
  );

  const DocenteProfile({
    required this.fullName,
    required this.socialName,
    required this.registrationId,
    required this.department,
    required this.semester,
    required this.campus,
    required this.status,
    required this.academicEmail,
    required this.personalEmail,
    required this.twoFactorEnabled,
    required this.activeSessions,
    required this.loginAudits,
  });

  /// Alias para o número de matrícula institucional.
  String get registrationNumber => registrationId;

  /// Alias para o e-mail institucional.
  String get institutionalEmail => academicEmail;

  /// Titulação / grau institucional.
  String get title => 'Doutorado em Ciência da Computação - USP';

  /// Regime de contrato de trabalho.
  String get workRegime => '40h Dedicação Exclusiva (DE)';

  /// URL do Currículo Lattes.
  String get lattesUrl => 'http://lattes.cnpq.br/4928172938471928';

  DocenteProfile copyWith({
    String? fullName,
    String? socialName,
    String? registrationId,
    String? department,
    String? semester,
    String? campus,
    String? status,
    String? academicEmail,
    String? personalEmail,
    bool? twoFactorEnabled,
    List<ActiveSession>? activeSessions,
    List<LoginAudit>? loginAudits,
  }) {
    return DocenteProfile(
      fullName: fullName ?? this.fullName,
      socialName: socialName ?? this.socialName,
      registrationId: registrationId ?? this.registrationId,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      campus: campus ?? this.campus,
      status: status ?? this.status,
      academicEmail: academicEmail ?? this.academicEmail,
      personalEmail: personalEmail ?? this.personalEmail,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      activeSessions: activeSessions ?? this.activeSessions,
      loginAudits: loginAudits ?? this.loginAudits,
    );
  }
}
