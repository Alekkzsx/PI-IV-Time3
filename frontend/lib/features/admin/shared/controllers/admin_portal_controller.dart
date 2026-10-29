// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/role_permission_policy.dart';
import '../data/admin_mock_data.dart';

/// Controlador reativo unificado em memória para o Portal do Administrador.
class AdminPortalController extends ChangeNotifier {
  static final AdminPortalController instance =
      AdminPortalController._internal();
  AdminPortalController._internal() {
    _initAcademicBridge();
  }
  factory AdminPortalController() => instance;

  void _initAcademicBridge() {
    AcademicBridgeService.instance.onAdminProtocolReceived = (newProtocol) {
      protocols.insert(0, newProtocol);
      notifyListeners();
    };
  }

  // Usuários
  late List<AdminUserModel> users = List.from(AdminMockData.users);
  String userFilter = 'Todos';
  String userSearchQuery = '';

  // Turmas e Supervisão
  late List<AdminClassModel> classes = List.from(AdminMockData.classes);
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
  late List<AdminProtocolModel> protocols = List.from(AdminMockData.protocols);
  String protocolFilter = 'Aguardando Parecer';

  // Calendário Oficial & Travas CONSEPE
  bool isRegimentalLockActive = true;

  // Auditoria
  late List<AdminAuditLogModel> auditLogs = List.from(AdminMockData.auditLogs);
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
          u.id.toLowerCase().contains(userSearchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(userSearchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  bool toggleUserStatus(String id) {
    if (!canPerform('manage_users')) {
      _denyPermission('manage_users');
      return false;
    }
    final index = users.indexWhere((u) => u.id == id);
    if (index != -1) {
      users[index].status = users[index].status == 'Ativo'
          ? 'Suspenso'
          : 'Ativo';
      _logAudit(
        'Carlos Eduardo Mendes',
        'ALTERAÇÃO STATUS',
        'Status do usuário $id alterado para ${users[index].status}',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  bool addUser({
    required String name,
    required String email,
    required String profile,
    required String department,
    required bool require2FA,
  }) {
    if (!canPerform('manage_users')) {
      _denyPermission('manage_users');
      return false;
    }
    if (!RolePermissionPolicy.roles.contains(profile)) {
      debugPrint(
        '[AdminPortal] Cadastro recusado: perfil inválido "$profile".',
      );
      return false;
    }
    final newId = profile == RolePermissionPolicy.student
        ? '2024.2.0${1040 + users.length}'
        : profile == RolePermissionPolicy.teacher
        ? 'DOC-${88420 + users.length}'
        : 'ADM-${10000 + users.length}';
    users.insert(
      0,
      AdminUserModel(
        id: newId,
        name: name,
        email: email,
        profile: profile,
        departmentOrCourse: department,
        status: 'Ativo',
        twoFactorRequired: require2FA,
      ),
    );
    _logAudit(
      'Carlos Eduardo Mendes',
      'NOVO CADASTRO',
      'Criação de credencial institucional para $name ($newId)',
    );
    notifyListeners();
    return true;
  }

  // --- MÉTODOS DE COMUNICADOS ---

  bool broadcastAnnouncement({
    required String title,
    required String audience,
    required String category,
    required String body,
  }) {
    if (!canPerform('publish_announcements')) {
      _denyPermission('publish_announcements');
      return false;
    }
    _logAudit(
      'Carlos Eduardo Mendes',
      'COMUNICADO CAMPUS',
      'Disparo de comunicado: "$title" para $audience ($category)',
    );

    // Dispara institucionalmente para os murais discentes
    AcademicBridgeService.instance.broadcastNotice(
      title: title.trim(),
      content: body.trim(),
      senderRole: 'admin',
      senderName: 'Administrador institucional ($audience)',
      targetCourse: 'Institucional',
    );

    notifyListeners();
    return true;
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
    if (!canPerform('view_class_grades') ||
        activeSupervisedClass == null ||
        index < 0 ||
        index > 4) {
      _denyPermission('view_class_grades');
      return;
    }
    supervisionTabIndex = index;
    notifyListeners();
  }

  bool updateFormulaRegime(String classCode, String newRegime) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return false;
    }
    final index = classes.indexWhere((c) => c.code == classCode);
    if (index != -1) {
      classes[index].formulaRegime = newRegime;
      _logAudit(
        'Carlos Eduardo Mendes',
        'REGIME AVALIAÇÃO',
        'Regime de notas da turma $classCode alterado para $newRegime',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  bool reallocateProfessor(String classCode, String newProfessor) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return false;
    }
    final index = classes.indexWhere((c) => c.code == classCode);
    if (index != -1) {
      final oldProfessor = classes[index].professor;
      classes[index].professor = newProfessor;
      _logAudit(
        'Carlos Eduardo Mendes',
        'ATRIBUIÇÃO DOCENTE',
        'Substituição na turma $classCode: $oldProfessor -> $newProfessor',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  bool lockAndHomologateClassPauta(String classCode) {
    if (!canPerform('manage_classes')) {
      _denyPermission('manage_classes');
      return false;
    }
    final normalizedClassCode = classCode.trim().toUpperCase();
    if (!classes.any(
      (classModel) => classModel.code.toUpperCase() == normalizedClassCode,
    )) {
      return false;
    }
    _gradeLocksByClass[normalizedClassCode] = true;
    _logAudit(
      'Carlos Eduardo Mendes',
      'FECHAMENTO ATA',
      'Pauta oficial e notas da turma $classCode homologadas e lacradas.',
    );
    notifyListeners();
    return true;
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

  bool decideProtocol({
    required String protocolId,
    required bool defer,
    required String parecerNote,
  }) {
    if (!canPerform('dispatch_protocols')) {
      _denyPermission('dispatch_protocols');
      return false;
    }
    final index = protocols.indexWhere((p) => p.id == protocolId);
    if (index != -1) {
      protocols[index].status = defer ? 'Deferido' : 'Indeferido';
      protocols[index].decisionNote = parecerNote;
      protocols[index].signedBy = 'Administrador institucional';
      _logAudit(
        'Carlos Eduardo Mendes',
        defer ? 'DEFERIMENTO PROTOCOLO' : 'INDEFERIMENTO PROTOCOLO',
        'Protocolo $protocolId decidido: ${protocols[index].status}',
      );

      // Transmite a decisão homologada com parecer oficial para o Portal do Aluno
      AcademicBridgeService.instance.dispatchProtocolDecision(
        protocolCode: protocolId,
        isApproved: defer,
        decisionNote: parecerNote,
        approverName: 'Administrador institucional',
      );

      notifyListeners();
      return true;
    }
    return false;
  }

  // Suporte & Impersonation
  AdminUserModel? activeImpersonatedUser;

  Map<String, Map<String, bool>> get rbacMatrix =>
      RolePermissionPolicy.permissions;

  // --- MÉTODOS DE GOVERNANÇA AVANÇADA DE USUÁRIOS ---

  void terminateUserSessions(String userId) {
    if (!canPerform('reset_passwords')) {
      _denyPermission('reset_passwords');
      return;
    }
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      final previousCount = user.activeSessionsCount;
      user.activeSessionsCount = 0;

      _logAudit(
        'Carlos Eduardo Mendes',
        'ENCERRAMENTO DE SESSÕES',
        'Revogação imediata de todas as sessões ativas do usuário ${user.name} (${user.id}). Dispositivos desconectados.',
        targetUserId: user.id,
        targetUserName: user.name,
        diffBefore: {
          'sessoesAtivas': previousCount,
          'estadoSessao': previousCount > 0
              ? 'Conectado em dispositivos'
              : 'Sem sessões ativas',
        },
        diffAfter: {
          'sessoesAtivas': 0,
          'estadoSessao': 'Todas as sessões encerradas (Logout forçado)',
          'exigirNovaAutenticacao': true,
        },
        severity: 'ATENCAO',
      );
      notifyListeners();
    }
  }

  void suspendUserWithReason(
    String userId, {
    required String reason,
    required bool suspend,
  }) {
    if (!canPerform('manage_users')) {
      _denyPermission('manage_users');
      return;
    }
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      final previousStatus = user.status;
      final previousReason = user.suspensionReason;

      user.status = suspend ? 'Suspenso' : 'Ativo';
      user.suspensionReason = suspend ? reason : null;
      if (suspend) {
        user.activeSessionsCount = 0;
      }

      _logAudit(
        'Carlos Eduardo Mendes',
        suspend ? 'BLOQUEIO ADMINISTRATIVO' : 'REATIVAÇÃO DE CONTA',
        suspend
            ? 'Usuário ${user.name} (${user.id}) foi suspenso. Motivo: $reason'
            : 'Usuário ${user.name} (${user.id}) foi reativado para acesso regular.',
        targetUserId: user.id,
        targetUserName: user.name,
        diffBefore: {
          'status': previousStatus,
          'motivoSuspensao': previousReason ?? 'Nenhum',
          'sessoesPermitidas': previousStatus == 'Ativo',
        },
        diffAfter: {
          'status': user.status,
          'motivoSuspensao': user.suspensionReason ?? 'Nenhum (Liberado)',
          'sessoesPermitidas': !suspend,
        },
        severity: suspend ? 'CRITICO' : 'INFO',
      );
      notifyListeners();
    }
  }

  void impersonateUser(AdminUserModel user) {
    if (!canPerform('impersonate_support')) {
      _denyPermission('impersonate_support');
      return;
    }
    activeImpersonatedUser = user;
    _logAudit(
      'Carlos Eduardo Mendes',
      'MODO SUPORTE (IMPERSONATION)',
      'Abertura de visualização espelho como ${user.name} (${user.id}) para diagnóstico de atendimento.',
      targetUserId: user.id,
      targetUserName: user.name,
      diffBefore: {
        'contextoVisualizacao': 'Painel Administrativo Pleno',
        'perfilOperador': 'Administrador institucional',
      },
      diffAfter: {
        'contextoVisualizacao': 'Espelho Diagnóstico: ${user.profile}',
        'usuarioDiagnosticado': '${user.name} (${user.id})',
        'permissaoModo': 'Somente Leitura (Auditada LGPD)',
      },
      severity: 'ATENCAO',
    );
    notifyListeners();
  }

  void exitImpersonation() {
    if (!canPerform('impersonate_support')) {
      _denyPermission('impersonate_support');
      return;
    }
    if (activeImpersonatedUser != null) {
      final user = activeImpersonatedUser!;
      _logAudit(
        'Carlos Eduardo Mendes',
        'ENCERRAMENTO MODO SUPORTE',
        'Encerramento do modo espelho de suporte para o usuário ${user.name} (${user.id}).',
        targetUserId: user.id,
        targetUserName: user.name,
      );
      activeImpersonatedUser = null;
      notifyListeners();
    }
  }

  void resetUserPasswordAdvanced(
    String userId, {
    required bool forceNextLogin,
    required bool sendRecoveryEmail,
    required bool revokeActiveSessions,
  }) {
    if (!canPerform('reset_passwords')) {
      _denyPermission('reset_passwords');
      return;
    }
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      final previousSessions = user.activeSessionsCount;
      if (revokeActiveSessions) {
        user.activeSessionsCount = 0;
      }

      _logAudit(
        'Carlos Eduardo Mendes',
        'RESET AVANÇADO DE CREDENCIAIS',
        'Redefinição de senha institucional para ${user.name} (${user.id}). E-mail enviado: $sendRecoveryEmail | Forçar troca: $forceNextLogin | Revogar sessões: $revokeActiveSessions',
        targetUserId: user.id,
        targetUserName: user.name,
        diffBefore: {
          'senhaTemporaria': false,
          'forcarTrocaNoProximoLogin': false,
          'sessoesAtivas': previousSessions,
        },
        diffAfter: {
          'senhaTemporaria': true,
          'forcarTrocaNoProximoLogin': forceNextLogin,
          'emailRecuperacaoEnviado': sendRecoveryEmail,
          'sessoesAtivas': user.activeSessionsCount,
        },
        severity: 'ATENCAO',
      );
      notifyListeners();
    }
  }

  List<AdminAuditLogModel> getUserAuditLogs(String userId) {
    return auditLogs
        .where((l) => l.targetUserId == userId || l.actor.contains(userId))
        .toList();
  }

  // --- MÉTODOS DA MATRIZ RBAC ---

  // --- MÉTODOS DE CALENDÁRIO & AUDITORIA ---

  void toggleRegimentalLock() {
    if (!canPerform('system_settings_2fa')) {
      _denyPermission('system_settings_2fa');
      return;
    }
    isRegimentalLockActive = !isRegimentalLockActive;
    _logAudit(
      'Carlos Eduardo Mendes',
      'TRAVA REGIMENTAL',
      'Status da trava CONSEPE alterado para: $isRegimentalLockActive',
      diffBefore: {'travaConsepeAtiva': !isRegimentalLockActive},
      diffAfter: {'travaConsepeAtiva': isRegimentalLockActive},
      severity: 'ATENCAO',
    );
    notifyListeners();
  }

  void _logAudit(
    String actor,
    String action,
    String desc, {
    String? targetUserId,
    String? targetUserName,
    Map<String, dynamic>? diffBefore,
    Map<String, dynamic>? diffAfter,
    String severity = 'INFO',
  }) {
    auditLogs.insert(
      0,
      AdminAuditLogModel(
        id: 'LOG-${1000 + auditLogs.length}',
        timestamp:
            '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        actor: actor,
        actionType: action,
        description: desc,
        ipAddress: '192.168.10.45',
        severity: severity,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        diffBefore: diffBefore,
        diffAfter: diffAfter,
      ),
    );
  }
}
