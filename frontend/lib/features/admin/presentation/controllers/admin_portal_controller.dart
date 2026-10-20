// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../data/admin_mock_data.dart';

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
      final matchesFilter = userFilter == 'Todos' || u.profile == userFilter;
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
    if (protocolFilter == 'Todos') return protocols;
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

  // --- MÉTODOS DE CALENDÁRIO & AUDITORIA ---

  void toggleRegimentalLock() {
    isRegimentalLockActive = !isRegimentalLockActive;
    _logAudit('Carlos Eduardo Mendes', 'TRAVA REGIMENTAL', 'Status da trava CONSEPE alterado para: $isRegimentalLockActive');
    notifyListeners();
  }

  void _logAudit(String actor, String action, String desc) {
    auditLogs.insert(
      0,
      AdminAuditLogModel(
        id: 'LOG-${1000 + auditLogs.length}',
        timestamp: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        actor: actor,
        actionType: action,
        description: desc,
        ipAddress: '192.168.10.45',
        severity: 'INFO',
      ),
    );
  }
}

