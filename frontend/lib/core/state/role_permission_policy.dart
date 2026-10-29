/// Central authorization policy for the three user profiles in the application.
class RolePermissionPolicy {
  RolePermissionPolicy._();

  static const String student = 'aluno';
  static const String teacher = 'docente';
  static const String admin = 'admin';

  static const Map<String, Map<String, bool>> permissions = {
    'view_own_grades': {student: true, teacher: false, admin: false},
    'view_class_grades': {student: false, teacher: true, admin: true},
    'edit_grades': {student: false, teacher: true, admin: false},
    'submit_assignments': {student: true, teacher: false, admin: false},
    'manage_assignments': {student: false, teacher: true, admin: false},
    'manage_course_content': {student: false, teacher: true, admin: false},
    'manage_attendance': {student: false, teacher: true, admin: false},
    'manage_materials': {student: false, teacher: true, admin: false},
    'publish_course_announcements': {
      student: false,
      teacher: true,
      admin: false,
    },
    'publish_announcements': {student: false, teacher: false, admin: true},
    'manage_personal_calendar': {student: true, teacher: false, admin: false},
    'participate_course_forum': {student: true, teacher: false, admin: false},
    'manage_course_calendar': {student: false, teacher: true, admin: false},
    'submit_protocols': {student: true, teacher: false, admin: false},
    'manage_users': {student: false, teacher: false, admin: true},
    'reset_passwords': {student: false, teacher: false, admin: true},
    'impersonate_support': {student: false, teacher: false, admin: true},
    'audit_diff_inspect': {student: false, teacher: false, admin: true},
    'system_settings_2fa': {student: false, teacher: false, admin: true},
    'dispatch_protocols': {student: false, teacher: false, admin: true},
    'manage_classes': {student: false, teacher: false, admin: true},
    'manage_video_calls': {student: false, teacher: true, admin: true},
  };

  static const List<String> roles = [student, teacher, admin];

  static bool hasPermission(String? role, String permission) {
    if (role == null || !roles.contains(role)) return false;
    return permissions[permission]?[role] ?? false;
  }
}
