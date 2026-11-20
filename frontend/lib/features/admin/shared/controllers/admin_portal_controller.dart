// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/academic/grade_calculator.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/role_permission_policy.dart';
import '../data/admin_remote_data_source.dart';
import '../data/admin_academic_data_source.dart';
import '../models/admin_models.dart';
import '../../../../core/network/authenticated_api_client.dart';

/// Controlador reativo unificado em memória para o Portal do Administrador.
class AdminPortalController extends ChangeNotifier {
  final AdminRemoteDataSource remote;
  final AdminAcademicRemoteDataSource academicRemote;
  bool isLoadingRemote = false;
  bool isSavingRemote = false;
  bool isLoadingSupervision = false;
  String? remoteError;
  String? supervisionError;
  Map<String, dynamic> dashboard = {};
  Map<String, dynamic> institutionalSettings = {};
  List<AdminCalendarMilestone> calendarEvents = [];
  List<Map<String, dynamic>> announcements = [];
  List<AdminGradeAuditRow> supervisedGrades = [];
  List<AdminEnrolledStudent> supervisedEnrollments = [];
  List<AdminGradeRectificationModel> rectifications = [];
  List<AdminCourseModel> courses = [];
  bool get usesRemote => true;

  AcademicThresholds get academicThresholds =>
      AcademicThresholds.fromJson(institutionalSettings);

  List<AdminGradeRectificationModel> get pendingRectifications =>
      rectifications.where((r) => r.isPending).toList();

  List<Map<String, dynamic>> get institutionalNotifications {
    final alertsConfig = institutionalSettings['campusAlerts'] is Map
        ? Map<String, dynamic>.from(
            institutionalSettings['campusAlerts'] as Map,
          )
        : <String, dynamic>{};
    final showProtocols = alertsConfig['notifyPendingProtocols'] != false;
    final showRects = alertsConfig['notifyGradeRectifications'] != false;
    final showDeadlines = alertsConfig['notifyRegimentalDeadlines'] != false;

    final items = <Map<String, dynamic>>[];
    if (showProtocols) {
      final pendingProtocols = protocols
          .where((p) => normalizeProtocolStatus(p.status) == 'Aguardando Parecer')
          .length;
      if (pendingProtocols > 0) {
        items.add({
          'type': 'protocol',
          'title': '$pendingProtocols requerimento(s) aguardando parecer',
          'subtitle': 'Secretaria Acadêmica · Despacho pendente',
          'tab': 'secretaria',
        });
      }
    }
    if (showRects) {
      final pendingRectCount = pendingRectifications.length;
      if (pendingRectCount > 0) {
        items.add({
          'type': 'rectification',
          'title': '$pendingRectCount solicitação(ões) de retificação pós-lacração',
          'subtitle': 'Cockpit de Turmas · Revisão de notas pendente',
          'tab': 'turmas',
        });
      }
    }
    if (showDeadlines && isRegimentalLockActive) {
      items.add({
        'type': 'lock',
        'title': 'Trava Regimental Global Ativa',
        'subtitle': 'Edição de notas no Diário Docente bloqueada',
        'tab': 'calendario',
      });
    }
    if (showDeadlines && calendarEvents.isNotEmpty) {
      final now = DateTime.now();
      final upcoming = calendarEvents.where((e) {
        final d = DateTime.tryParse(e.startsAt);
        return d != null &&
            !d.isBefore(DateTime(now.year, now.month, now.day)) &&
            d.difference(now).inDays <= 14;
      }).length;
      if (upcoming > 0) {
        items.add({
          'type': 'calendar',
          'title': '$upcoming marco(s) acadêmico(s) nos próximos 14 dias',
          'subtitle': 'Calendário Acadêmico Institucional',
          'tab': 'calendario',
        });
      }
    }
    return items;
  }

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
      rectifications = [];
      dashboard = {};
      institutionalSettings = {};
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
      rectifications = [];
      dashboard = {};
      institutionalSettings = {};
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
        remote.rectifications().catchError((_) => <AdminGradeRectificationModel>[]),
      ]);
      if (AppUserSession.instance.accessToken != requestedToken) return;
      users = values[0] as List<AdminUserModel>;
      protocols = values[1] as List<AdminProtocolModel>;
      auditLogs = values[2] as List<AdminAuditLogModel>;
      institutionalSettings = Map<String, dynamic>.from(values[3] as Map);
      isRegimentalLockActive =
          institutionalSettings['regimentalLockActive'] == true;
      dashboard = Map<String, dynamic>.from(values[4] as Map);
      courses = values[5] as List<AdminCourseModel>;
      classes = values[6] as List<AdminClassModel>;
      calendarEvents = values[7] as List<AdminCalendarMilestone>;
      announcements = (values[8] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      rectifications = values[9] as List<AdminGradeRectificationModel>;
      _gradeLocksByClass.clear();
      for (final classroom in classes) {
        _gradeLocksByClass[classroom.code.trim().toUpperCase()] =
            classroom.gradeLocked;
      }
      if (activeSupervisedClass != null) {
        final refreshed = classes
            .where((item) => item.code == activeSupervisedClass!.code)
            .firstOrNull;
        if (refreshed != null) {
          activeSupervisedClass = refreshed;
        }
      }
    } catch (error) {
      remoteError = _formatError(
        error,
        fallback: 'Não foi possível carregar o portal administrativo.',
      );
    } finally {
      isLoadingRemote = false;
      notifyListeners();
    }
  }

  String _formatError(Object error, {required String fallback}) {
    if (error is ApiException) return error.message;
    if (error is AdminAcademicApiException) return error.message;
    return fallback;
  }

  void clearRemoteError({bool notify = true}) {
    if (remoteError == null) return;
    remoteError = null;
    if (notify) notifyListeners();
  }

  void clearSupervisionError({bool notify = true}) {
    if (supervisionError == null) return;
    supervisionError = null;
    if (notify) notifyListeners();
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
      remoteError = _formatError(
        error,
        fallback: 'A operação não pôde ser concluída.',
      );
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
    isLoadingSupervision = true;
    supervisionError = null;
    notifyListeners();

    String? gradesError;
    String? enrollmentsError;

    await Future.wait<void>([
      academicRemote
          .classGrades(classCode)
          .then((value) {
            supervisedGrades = value;
          })
          .catchError((Object error) {
            supervisedGrades = [];
            gradesError = _formatError(
              error,
              fallback: 'Não foi possível carregar os registros de notas.',
            );
          }),
      academicRemote
          .getEnrollments(classCode)
          .then((value) {
            supervisedEnrollments = value;
          })
          .catchError((Object error) {
            supervisedEnrollments = [];
            enrollmentsError = _formatError(
              error,
              fallback: 'Não foi possível carregar os discentes da turma.',
            );
          }),
    ]);

    supervisionError = gradesError ?? enrollmentsError;
    isLoadingSupervision = false;
    notifyListeners();
  }
  static final AdminPortalController instance =
      AdminPortalController._internal();
  AdminPortalController._internal({
    AdminRemoteDataSource? remote,
    AdminAcademicRemoteDataSource? academicRemote,
  }) : remote = remote ?? AdminRemoteDataSource(),
       academicRemote = academicRemote ?? AdminAcademicRemoteDataSource();

  /// Isolated instance for unit tests with injected data sources.
  AdminPortalController.forTesting({
    AdminRemoteDataSource? remote,
    AdminAcademicRemoteDataSource? academicRemote,
  }) : remote = remote ?? AdminRemoteDataSource(),
       academicRemote = academicRemote ?? AdminAcademicRemoteDataSource();

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

  Future<bool> deleteAnnouncement(String id) {
    if (!canPerform('publish_announcements') || id.isEmpty) {
      _denyPermission('publish_announcements');
      return Future.value(false);
    }
    return persist(() => remote.deleteAnnouncement(id));
  }

  Future<bool> updateSettings(Map<String, Object?> fields) {
    if (!canPerform('system_settings_2fa') || fields.isEmpty) {
      _denyPermission('system_settings_2fa');
      return Future.value(false);
    }
    return persist(() => remote.patchSettings(fields));
  }

  Future<bool> decideRectification({
    required String id,
    required bool approved,
    required String decisionNote,
  }) async {
    if (!canPerform('manage_classes') || id.isEmpty) {
      _denyPermission('manage_classes');
      return false;
    }
    final ok = await persist(
      () => remote.decideRectification(
        id,
        approved: approved,
        decisionNote: decisionNote,
      ),
    );
    if (ok && activeSupervisedClass != null) {
      await loadClassSupervision(activeSupervisedClass!.code);
    }
    return ok;
  }

  Future<bool> unlockClassPauta(String classCode) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return Future.value(false);
    }
    return persistClass(classCode, {
      'gradeLocked': false,
      'pautaHomologated': false,
    });
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
    supervisionError = null;
    notifyListeners();
  }

  void closeSupervision() {
    if (!AppUserSession.instance.hasRole(RolePermissionPolicy.admin)) return;
    activeSupervisedClass = null;
    supervisionError = null;
    supervisedGrades = [];
    supervisedEnrollments = [];
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

  static String normalizeProtocolStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'aguardando' ||
        normalized == 'aguardando parecer' ||
        normalized == 'pendente') {
      return 'Aguardando Parecer';
    }
    if (normalized == 'deferido') {
      return 'Deferido';
    }
    if (normalized == 'indeferido') {
      return 'Indeferido';
    }
    if (normalized == 'concluido' || normalized == 'concluído') {
      return 'Concluído';
    }
    return status.trim();
  }

  List<AdminProtocolModel> get filteredProtocols {
    if (protocolFilter == 'Todos' || protocolFilter == 'Todos Os Protocolos') {
      return protocols;
    }
    if (protocolFilter == 'Aguardando' ||
        protocolFilter == 'Aguardando Parecer') {
      return protocols
          .where(
            (p) => normalizeProtocolStatus(p.status) == 'Aguardando Parecer',
          )
          .toList();
    }
    if (protocolFilter == 'Deferidos' || protocolFilter == 'Deferido') {
      return protocols
          .where((p) => normalizeProtocolStatus(p.status) == 'Deferido')
          .toList();
    }
    if (protocolFilter == 'Indeferidos' || protocolFilter == 'Indeferido') {
      return protocols
          .where((p) => normalizeProtocolStatus(p.status) == 'Indeferido')
          .toList();
    }
    return protocols
        .where(
          (p) =>
              normalizeProtocolStatus(p.status) ==
              normalizeProtocolStatus(protocolFilter),
        )
        .toList();
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
