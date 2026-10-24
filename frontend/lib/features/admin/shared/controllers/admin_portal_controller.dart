// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../data/admin_mock_data.dart';

/// Controlador reativo unificado em memória para o Portal do Administrador.
class AdminPortalController extends ChangeNotifier {
  static final AdminPortalController instance = AdminPortalController._internal();
  AdminPortalController._internal();
  factory AdminPortalController() => instance;

  // Usuários
  late List<AdminUserModel> users = List.from(AdminMockData.users);
  String userFilter = 'Todos';
  String userSearchQuery = '';

  // Turmas e Supervisão
  late List<AdminClassModel> classes = List.from(AdminMockData.classes);
  AdminClassModel? activeSupervisedClass;
  int supervisionTabIndex = 0;
  bool isGradeLocked = false;
  String selectedEvaluationFormula = 'Ponderada (N1 40% / N2 60%)';

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
      final matchesFilter = userFilter == 'Todos' ||
          u.profile == userFilter ||
          (userFilter == 'Discentes' && u.profile == 'Discente') ||
          (userFilter == 'Docentes' && u.profile == 'Docente') ||
          (userFilter == 'Administração' && u.profile == 'Administrador');
      final matchesSearch = u.name.toLowerCase().contains(userSearchQuery.toLowerCase()) ||
          u.id.toLowerCase().contains(userSearchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(userSearchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void toggleUserStatus(String id) {
    final index = users.indexWhere((u) => u.id == id);
    if (index != -1) {
      users[index].status = users[index].status == 'Ativo' ? 'Suspenso' : 'Ativo';
      _logAudit('Carlos Eduardo Mendes', 'ALTERAÇÃO STATUS', 'Status do usuário $id alterado para ${users[index].status}');
      notifyListeners();
    }
  }

  void addUser({
    required String name,
    required String email,
    required String profile,
    required String department,
    required bool require2FA,
  }) {
    final newId = profile == 'Discente' ? '2024.2.0${1040 + users.length}' : 'DOC-${88420 + users.length}';
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
    _logAudit('Carlos Eduardo Mendes', 'NOVO CADASTRO', 'Criação de credencial institucional para $name ($newId)');
    notifyListeners();
  }

  // --- MÉTODOS DE COMUNICADOS ---

  void broadcastAnnouncement({
    required String title,
    required String audience,
    required String category,
    required String body,
  }) {
    _logAudit('Carlos Eduardo Mendes', 'COMUNICADO CAMPUS', 'Disparo de comunicado: "$title" para $audience ($category)');
    notifyListeners();
  }

  // --- MÉTODOS DE GESTÃO DE TURMAS & SUPERVISÃO ---

  void openSupervision(AdminClassModel classModel) {
    activeSupervisedClass = classModel;
    supervisionTabIndex = 0;
    notifyListeners();
  }

  void closeSupervision() {
    activeSupervisedClass = null;
    notifyListeners();
  }

  void setSupervisionTab(int index) {
    supervisionTabIndex = index;
    notifyListeners();
  }

  void updateFormulaRegime(String classCode, String newRegime) {
    final index = classes.indexWhere((c) => c.code == classCode);
    if (index != -1) {
      classes[index].formulaRegime = newRegime;
      _logAudit('Carlos Eduardo Mendes', 'REGIME AVALIAÇÃO', 'Regime de notas da turma $classCode alterado para $newRegime');
      notifyListeners();
    }
  }

  void reallocateProfessor(String classCode, String newProfessor) {
    final index = classes.indexWhere((c) => c.code == classCode);
    if (index != -1) {
      final oldProfessor = classes[index].professor;
      classes[index].professor = newProfessor;
      _logAudit('Carlos Eduardo Mendes', 'ATRIBUIÇÃO DOCENTE', 'Substituição na turma $classCode: $oldProfessor -> $newProfessor');
      notifyListeners();
    }
  }

  void lockAndHomologateClassPauta(String classCode) {
    isGradeLocked = true;
    _logAudit('Carlos Eduardo Mendes', 'FECHAMENTO ATA', 'Pauta oficial e notas da turma $classCode homologadas e lacradas.');
    notifyListeners();
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
    if (protocolFilter == 'Aguardando' || protocolFilter == 'Aguardando Parecer') {
      return protocols.where((p) => p.status == 'Aguardando' || p.status == 'Aguardando Parecer').toList();
    }
    if (protocolFilter == 'Deferidos' || protocolFilter == 'Deferido') {
      return protocols.where((p) => p.status == 'Deferido').toList();
    }
    if (protocolFilter == 'Indeferidos' || protocolFilter == 'Indeferido') {
      return protocols.where((p) => p.status == 'Indeferido').toList();
    }
    return protocols.where((p) => p.status == protocolFilter).toList();
  }

  void decideProtocol({
    required String protocolId,
    required bool defer,
    required String parecerNote,
  }) {
    final index = protocols.indexWhere((p) => p.id == protocolId);
    if (index != -1) {
      protocols[index].status = defer ? 'Deferido' : 'Indeferido';
      protocols[index].decisionNote = parecerNote;
      protocols[index].signedBy = 'Carlos Eduardo Mendes - Secretaria Geral';
      _logAudit(
        'Carlos Eduardo Mendes',
        defer ? 'DEFERIMENTO PROTOCOLO' : 'INDEFERIMENTO PROTOCOLO',
        'Protocolo $protocolId decidido: ${protocols[index].status}',
      );
      notifyListeners();
    }
  }

  // Suporte & Impersonation
  AdminUserModel? activeImpersonatedUser;

  // Matriz de Permissões RBAC (Entidade/Operação x Perfis Institucionais)
  late Map<String, Map<String, bool>> rbacMatrix = _getDefaultRbacMatrix();

  static Map<String, Map<String, bool>> _getDefaultRbacMatrix() {
    return {
      'view_grades': {
        'Discente': true,
        'Docente': true,
        'Coordenador': true,
        'Secretaria': true,
        'Admin Operacional': true,
        'Super Admin': true,
      },
      'edit_grades': {
        'Discente': false,
        'Docente': true,
        'Coordenador': true,
        'Secretaria': false,
        'Admin Operacional': true,
        'Super Admin': true,
      },
      'manage_users': {
        'Discente': false,
        'Docente': false,
        'Coordenador': false,
        'Secretaria': false,
        'Admin Operacional': true,
        'Super Admin': true,
      },
      'reset_passwords': {
        'Discente': false,
        'Docente': false,
        'Coordenador': false,
        'Secretaria': true,
        'Admin Operacional': true,
        'Super Admin': true,
      },
      'impersonate_support': {
        'Discente': false,
        'Docente': false,
        'Coordenador': false,
        'Secretaria': false,
        'Admin Operacional': true,
        'Super Admin': true,
      },
      'audit_diff_inspect': {
        'Discente': false,
        'Docente': false,
        'Coordenador': false,
        'Secretaria': false,
        'Admin Operacional': true,
        'Super Admin': true,
      },
      'system_settings_2fa': {
        'Discente': false,
        'Docente': false,
        'Coordenador': false,
        'Secretaria': false,
        'Admin Operacional': false,
        'Super Admin': true,
      },
      'dispatch_protocols': {
        'Discente': false,
        'Docente': false,
        'Coordenador': true,
        'Secretaria': true,
        'Admin Operacional': true,
        'Super Admin': true,
      },
    };
  }

  // --- MÉTODOS DE GOVERNANÇA AVANÇADA DE USUÁRIOS ---

  void terminateUserSessions(String userId) {
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
          'estadoSessao': previousCount > 0 ? 'Conectado em dispositivos' : 'Sem sessões ativas',
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

  void suspendUserWithReason(String userId, {required String reason, required bool suspend}) {
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
    activeImpersonatedUser = user;
    _logAudit(
      'Carlos Eduardo Mendes',
      'MODO SUPORTE (IMPERSONATION)',
      'Abertura de visualização espelho como ${user.name} (${user.id}) para diagnóstico de atendimento.',
      targetUserId: user.id,
      targetUserName: user.name,
      diffBefore: {
        'contextoVisualizacao': 'Painel Administrativo Pleno',
        'perfilOperador': 'Carlos Eduardo Mendes (Super Admin)',
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
    return auditLogs.where((l) => l.targetUserId == userId || l.actor.contains(userId)).toList();
  }

  // --- MÉTODOS DA MATRIZ RBAC ---

  void toggleRbacPermission(String role, String permKey) {
    if (rbacMatrix.containsKey(permKey) && rbacMatrix[permKey]!.containsKey(role)) {
      final current = rbacMatrix[permKey]![role] ?? false;
      rbacMatrix[permKey]![role] = !current;
      notifyListeners();
    }
  }

  void saveRbacMatrixChanges() {
    _logAudit(
      'Carlos Eduardo Mendes',
      'ATUALIZAÇÃO POLÍTICA RBAC',
      'Alteração manual na matriz institucional de privilégios e permissões de acesso por perfil.',
      diffBefore: {
        'matrizStatus': 'Revisão Anterior Homologada',
      },
      diffAfter: {
        'matrizStatus': 'Nova Política Ativa e Propagada',
        'dataHomologacao': DateTime.now().toIso8601String(),
        'operador': 'Carlos Eduardo Mendes - DTI/Admin',
      },
      severity: 'CRITICO',
    );
    notifyListeners();
  }

  void resetRbacToDefault() {
    rbacMatrix = _getDefaultRbacMatrix();
    _logAudit(
      'Carlos Eduardo Mendes',
      'RESTAURAÇÃO RBAC PADRÃO',
      'Matriz de privilégios redefinida para os padrões institucionais recomendados (MEC/CONSEPE).',
      severity: 'ATENCAO',
    );
    notifyListeners();
  }

  // --- MÉTODOS DE CALENDÁRIO & AUDITORIA ---

  void toggleRegimentalLock() {
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

