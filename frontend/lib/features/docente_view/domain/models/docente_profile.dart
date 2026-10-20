// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// An active login session on a user's device.
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

/// A security audit entry for login attempts.
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
}

/// Represents the professor's account and security profile.
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
