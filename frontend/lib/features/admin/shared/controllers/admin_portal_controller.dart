// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/role_permission_policy.dart';
import '../data/admin_remote_data_source.dart';
import '../data/admin_academic_data_source.dart';
import '../models/admin_models.dart';
import '../../../../core/network/authenticated_api_client.dart';

/// Controlador reativo unificado em memória para o Portal do Administrador.
class AdminPortalController extends ChangeNotifier {
  final AdminRemoteDataSource remote = AdminRemoteDataSource();
  final AdminAcademicRemoteDataSource academicRemote =
      AdminAcademicRemoteDataSource();
  bool isLoadingRemote = false;
  bool isSavingRemote = false;
  String? remoteError;
  Map<String, dynamic> dashboard = {};
  List<AdminCalendarMilestone> calendarEvents = [];
  List<Map<String, dynamic>> announcements = [];
  List<AdminGradeAuditRow> supervisedGrades = [];
  List<AdminEnrolledStudent> supervisedEnrollments = [];
  List<AdminCourseModel> courses = [];
  bool get usesRemote => true;

  Future<void> loadRemote({bool clear = false}) async {
    final requestedToken = AppUserSession.instance.accessToken;
    if (requestedToken == null || requestedToken.isEmpty) {
      users = [];
      classes = [];
      protocols = [];
      auditLogs = [];
      courses = [];
      calendarEvents = [];
      announcements = [];
      dashboard = {};
      remoteError = 'Entre como administrador para carregar os dados.';
      notifyListeners();
      return;
    }
    if (clear) {
      users = [];
      classes = [];
      protocols = [];
      auditLogs = [];
      courses = [];
      dashboard = {};
    }
    isLoadingRemote = true;
    remoteError = null;
    notifyListeners();
    try {
      final values = await Future.wait<dynamic>([
        remote.users(),
        remote.protocols(),
        remote.auditLogs(),
        remote.request('GET', '/settings'),
        remote.request('GET', '/dashboard'),
        academicRemote.getCourses(),
        academicRemote.getClasses(),
        remote.calendar(),
        remote.request('GET', '/announcements'),
      ]);
      if (AppUserSession.instance.accessToken != requestedToken) return;
      users = values[0] as List<AdminUserModel>;
      protocols = values[1] as List<AdminProtocolModel>;
      auditLogs = values[2] as List<AdminAuditLogModel>;
      isRegimentalLockActive =
          (values[3] as Map)['regimentalLockActive'] == true;
      dashboard = Map<String, dynamic>.from(values[4] as Map);
      courses = values[5] as List<AdminCourseModel>;
      classes = values[6] as List<AdminClassModel>;
      calendarEvents = values[7] as List<AdminCalendarMilestone>;
      announcements = (values[8] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _gradeLocksByClass.clear();
      for (final classroom in classes) {
        _gradeLocksByClass[classroom.code.trim().toUpperCase()] =
            classroom.gradeLocked;
      }
    } catch (error) {
      remoteError = error is ApiException
          ? error.message
          : error is AdminAcademicApiException
          ? error.message
          : 'Não foi possível carregar o portal administrativo.';
    } finally {
      isLoadingRemote = false;
      notifyListeners();
    }
  }

  Future<bool> persist(
    Future<dynamic> Function() operation, {
    VoidCallback? onSuccess,
  }) async {
    if (isSavingRemote) return false;
    isSavingRemote = true;
    remoteError = null;
    notifyListeners();
    try {
      await operation();
      onSuccess?.call();
      await loadRemote();
      return true;
    } catch (error) {
      remoteError = error is ApiException
          ? error.message
          : 'A operação não pôde ser concluída.';
      return false;
    } finally {
      isSavingRemote = false;
      notifyListeners();
    }
  }

  Future<bool> persistUserStatus(
    String id, {
    required bool active,
    String? reason,
  }) => persist(
    () => remote.request('PATCH', '/users/$id/status', {
      'active': active,
      if (reason != null) 'reason': reason,
    }),
  );
  Future<bool> persistRevokeSessions(String id) =>
      persist(() => remote.request('POST', '/users/$id/revoke-sessions', {}));
  Future<bool> persistResetPassword(String id) =>
      persist(() => remote.request('POST', '/users/$id/reset-password', {}));
  Future<bool> persistClass(String code, Map<String, Object?> fields) =>
      persist(
        () => remote.request(
          'PATCH',
          '/classes/${Uri.encodeComponent(code)}',
          fields,
        ),
      );
  Future<bool> persistProtocol(String id, bool approved, String note) =>
      persist(
        () => remote.request('PATCH', '/protocols/$id/decision', {
          'approved': approved,
          'decisionNote': note,
        }),
      );
  Future<bool> persistRegimentalLock() => persist(
    () => remote.request('PATCH', '/settings', {
      'regimentalLockActive': !isRegimentalLockActive,
    }),
  );

  Future<bool> createCalendarEvent(Map<String, Object?> values) =>
      persist(() => remote.createCalendarEvent(values));

  Future<bool> updateCalendarEvent(String id, Map<String, Object?> values) =>
      persist(() => remote.updateCalendarEvent(id, values));

  Future<bool> deleteCalendarEvent(String id) =>
      persist(() => remote.deleteCalendarEvent(id));

  Future<void> loadClassSupervision(String classCode) async {
    try {
      final values = await Future.wait<dynamic>([
        academicRemote.classGrades(classCode),
        academicRemote.getEnrollments(classCode),
      ]);
      supervisedGrades = values[0] as List<AdminGradeAuditRow>;
      supervisedEnrollments = values[1] as List<AdminEnrolledStudent>;
      remoteError = null;
    } catch (error) {
      remoteError = error is ApiException
          ? error.message
          : error is AdminAcademicApiException
          ? error.message
          : 'Não foi possível carregar os dados de supervisão.';
      supervisedGrades = [];
      supervisedEnrollments = [];
    }
    notifyListeners();
  }
  static final AdminPortalController instance =
      AdminPortalController._internal();
  AdminPortalController._internal();
  factory AdminPortalController() => instance;

  // Usuários
  List<AdminUserModel> users = [];
  String userFilter = 'Todos';
  String userSearchQuery = '';

  // Turmas e Supervisão
  List<AdminClassModel> classes = [];
  AdminClassModel? activeSupervisedClass;
  int supervisionTabIndex = 0;
  final Map<String, bool> _gradeLocksByClass = {};
  bool get isGradeLocked =>
      _gradeLocksByClass.values.any((isLocked) => isLocked);

  bool isGradeLockedFor(String classCode) =>
      _gradeLocksByClass[classCode.trim().toUpperCase()] ?? false;
  String selectedEvaluationFormula = 'Ponderada (N1 40% / N2 60%)';
  String get currentOperatorRole =>
      AppUserSession.instance.role ?? 'não autenticado';

  bool hasPermission(String role, String permission) =>
      RolePermissionPolicy.hasPermission(role, permission);

  bool canPerform(String permission) =>
      AppUserSession.instance.hasPermission(permission) &&
      AppUserSession.instance.hasRole(RolePermissionPolicy.admin);

  void _denyPermission(String permission) {
    debugPrint(
      '[AdminPortal] Ação "$permission" negada para $currentOperatorRole.',
    );
  }

  // Protocolos de Secretaria
  List<AdminProtocolModel> protocols = [];
  String protocolFilter = 'Aguardando Parecer';

  // Calendário Oficial & Travas CONSEPE
  bool isRegimentalLockActive = false;

  // Auditoria
  List<AdminAuditLogModel> auditLogs = [];
  String auditSearchQuery = '';

  // --- MÉTODOS DE GESTÃO DE USUÁRIOS ---

  void setUserFilter(String filter) {
    userFilter = filter;
    notifyListeners();
  }

  void setUserSearchQuery(String query) {
    userSearchQuery = query;
    notifyListeners();
  }

  List<AdminUserModel> get filteredUsers {
    return users.where((u) {
      final matchesFilter =
          userFilter == 'Todos' ||
          u.profile == userFilter ||
          (userFilter == 'Alunos' &&
              u.profile == RolePermissionPolicy.student) ||
          (userFilter == 'Docentes' &&
              u.profile == RolePermissionPolicy.teacher) ||
          (userFilter == 'Administradores' &&
              u.profile == RolePermissionPolicy.admin);
      final matchesSearch =
          u.name.toLowerCase().contains(userSearchQuery.toLowerCase()) ||
          u.identity.toLowerCase().contains(userSearchQuery.toLowerCase()) ||
          u.id.toLowerCase().contains(userSearchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(userSearchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<bool> toggleUserStatus(String id) {
    if (!canPerform('manage_users')) {
      _denyPermission('manage_users');
      return Future.value(false);
    }
    final user = users.where((item) => item.id == id).firstOrNull;
    if (user == null) return Future.value(false);
    return persistUserStatus(id, active: user.status != 'Ativo');
  }

  // --- MÉTODOS DE COMUNICADOS ---

  Future<bool> broadcastAnnouncement({
    required String title,
    required String audience,
    required String category,
    required String body,
  }) {
    if (!canPerform('publish_announcements')) {
      _denyPermission('publish_announcements');
      return Future.value(false);
    }
    return persist(
      () => remote.createAnnouncement({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience,
        'category': category,
      }),
    );
  }

  Future<bool> updateAnnouncement(String id, Map<String, Object?> fields) {
    if (!canPerform('publish_announcements') || id.isEmpty || fields.isEmpty) {
      _denyPermission('publish_announcements');
      return Future.value(false);
    }
    return persist(
      () => remote.request(
        'PATCH',
        '/announcements/${Uri.encodeComponent(id)}',
        fields,
      ),
    );
  }

  // --- MÉTODOS DE GESTÃO DE TURMAS & SUPERVISÃO ---

  void openSupervision(AdminClassModel classModel) {
    if (!canPerform('view_class_grades') ||
        !classes.any((item) => item.code == classModel.code)) {
      _denyPermission('view_class_grades');
      return;
    }
    activeSupervisedClass = classModel;
    supervisionTabIndex = 0;
    notifyListeners();
  }

  void closeSupervision() {
    if (!AppUserSession.instance.hasRole(RolePermissionPolicy.admin)) return;
    activeSupervisedClass = null;
    notifyListeners();
  }

  void setSupervisionTab(int index) {
    if (!canPerform('view_class_grades') || index < 0 || index > 4) {
      _denyPermission('view_class_grades');
      return;
    }
    supervisionTabIndex = index;
    notifyListeners();
  }

  Future<bool> updateFormulaRegime(String classCode, String newRegime) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return Future.value(false);
    }
    return persistClass(classCode, {
      'formulaRegime': newRegime == 'Impor pelo Admin'
          ? 'admin'
          : 'autonomia_docente',
    });
  }

  Future<bool> reallocateProfessor(String classCode, String newProfessor) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return Future.value(false);
    }
    return persist(
      () => academicRemote.assignTeacherToClass(
        classCode: classCode,
        professorIdentity: newProfessor,
      ),
    );
  }

  Future<bool> lockAndHomologateClassPauta(String classCode) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return Future.value(false);
    }
    return persistClass(classCode, {
      'gradeLocked': true,
      'pautaHomologated': true,
    });
  }

  // --- MÉTODOS DE SECRETARIA ACADÊMICA ---

  void setProtocolFilter(String filter) {
    protocolFilter = filter;
    notifyListeners();
  }

  List<AdminProtocolModel> get filteredProtocols {
    if (protocolFilter == 'Todos' || protocolFilter == 'Todos Os Protocolos') {
      return protocols;
    }
    if (protocolFilter == 'Aguardando' ||
        protocolFilter == 'Aguardando Parecer') {
      return protocols
          .where(
            (p) => p.status == 'Aguardando' || p.status == 'Aguardando Parecer',
          )
          .toList();
    }
    if (protocolFilter == 'Deferidos' || protocolFilter == 'Deferido') {
      return protocols.where((p) => p.status == 'Deferido').toList();
    }
    if (protocolFilter == 'Indeferidos' || protocolFilter == 'Indeferido') {
      return protocols.where((p) => p.status == 'Indeferido').toList();
    }
    return protocols.where((p) => p.status == protocolFilter).toList();
  }

  Future<bool> decideProtocol({
    required String protocolId,
    required bool defer,
    required String parecerNote,
  }) {
    if (!canPerform('dispatch_protocols')) {
      _denyPermission('dispatch_protocols');
      return Future.value(false);
    }
    return persistProtocol(protocolId, defer, parecerNote);
  }

  Map<String, Map<String, bool>> get rbacMatrix =>
      RolePermissionPolicy.permissions;

  List<AdminAuditLogModel> getUserAuditLogs(String userId) {
    return auditLogs
        .where((l) => l.targetUserId == userId || l.actor.contains(userId))
        .toList();
  }

  // --- MÉTODOS DA MATRIZ RBAC ---

  // --- MÉTODOS DE CALENDÁRIO & AUDITORIA ---

  Future<bool> toggleRegimentalLock() {
    if (!canPerform('system_settings_2fa')) {
      _denyPermission('system_settings_2fa');
      return Future.value(false);
    }
    return persistRegimentalLock();
  }
}
