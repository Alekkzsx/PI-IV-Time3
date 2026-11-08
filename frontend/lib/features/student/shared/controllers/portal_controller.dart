// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/navigation/nav_item.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../data/portal_remote_data_source.dart';
import '../models/models.dart';

part 'parts/portal_controller_bridge.dart';
part 'parts/portal_controller_calendar.dart';
part 'parts/portal_controller_ava.dart';
part 'parts/portal_controller_deliveries.dart';
part 'parts/portal_controller_settings.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// [_PortalControllerBase]
///
/// Classe base abstrata que armazena o estado reativo compartilhado e o ciclo de vida
/// de sincronização remota do Portal do Aluno, servindo de alicerce para os mixins
/// de domínio (`_PortalBridgeMixin`, `_PortalCalendarMixin`, `_PortalAvaMixin`,
/// `_PortalDeliveriesMixin` e `_PortalSettingsMixin`).
abstract class _PortalControllerBase extends ChangeNotifier {
  final StudentRemoteDataSource _remote;
  final AuthProfileRemoteDataSource _profileRemote =
      AuthProfileRemoteDataSource();

  _PortalControllerBase({StudentRemoteDataSource? remote})
    : _remote = remote ?? StudentRemoteDataSource();

  /// Snapshot agregado com os dados brutos recebidos da API remota do portal.
  StudentDashboardSnapshot? remoteDashboard;

  /// Resposta estruturada da linha do tempo acadêmica.
  StudentTimelineResponse? timeline;

  /// Flag indicativa de requisição de sincronização remota em andamento.
  bool isLoadingRemote = false;

  /// Mensagem descritiva de erro ocorrido na última sincronização remota, se houver.
  String? remoteError;

  String? _loadedForToken;

  /// Lista de disciplinas ativas matriculadas pelo aluno no semestre corrente.
  List<StudentDisciplineModel> disciplines = [];

  /// Destino de navegação ativo atualmente selecionado no shell do discente.
  StudentNavItem activeNavItem = StudentNavItem.painelGeral;

  /// Define se o dashboard principal está no modo de visualização em Grade (`true`) ou Linha do Tempo (`false`).
  bool isGridView = true;

  /// Disciplina acadêmica selecionada para detalhamento no cockpit do AVA.
  StudentDisciplineModel? selectedDiscipline;

  /// Modo de visualização do calendário acadêmico ('Semana', 'Mês' ou 'Agenda').
  String calendarViewMode = 'Mês';

  /// Data focal atualmente selecionada no calendário acadêmico.
  DateTime calendarFocusedDate = _today();

  /// Conjunto de categorias de eventos ativas no filtro do calendário.
  final Set<String> activeEventTypes = {
    'Entrega',
    'Aula',
    'Fórum',
    'Avaliação',
  };

  /// Filtro por códigos de disciplina ativos na visualização de eventos.
  final Set<String> activeDisciplineFilters = {};

  /// Lista total de eventos acadêmicos sincronizados para o calendário.
  List<StudentCalendarEvent> events = [];

  /// Lista de atividades e tarefas acadêmicas com entrega atribuídas ao estudante.
  List<StudentDeliveryItem> deliveries = [];

  /// Filtro de status ativo para as tarefas (ex.: 'Todas', 'Pendentes', 'Enviadas', 'Avaliadas').
  String activeDeliveryFilter = 'Todas';

  /// Índice numérico da aba ativa no módulo de configurações discentes.
  int selectedSettingsTabIndex = 0;

  /// Flag indicativa do status de ativação da autenticação de dois fatores (2FA).
  bool isTwoFactorEnabled = false;

  /// Flag de notificação de avisos acadêmicos por correio eletrônico.
  bool emailNotifications = true;

  /// Flag de notificação de avisos em tempo real via push no dispositivo.
  bool pushNotifications = true;

  /// Flag de notificação de lembretes urgentes por mensagem SMS.
  bool smsNotifications = false;

  /// Aba ativa no cockpit do Ambiente Virtual de Aprendizagem (0 a 10).
  int activeAvaTabIndex = 0;

  /// Texto do bloco de anotações particulares do discente para a disciplina ativa.
  String studentPersonalNotes = '';

  /// Getter dos dados cadastrais do aluno extraídos do snapshot remoto.
  Map<String, dynamic> get studentInfo =>
      remoteDashboard?.studentInfo ?? const {};

  /// Getter dos indicadores de desempenho acadêmico (CR, frequência média).
  Map<String, dynamic> get stats => remoteDashboard?.stats ?? const {};

  /// Getter do resumo estatístico do histórico escolar.
  Map<String, dynamic> get recordSummary =>
      remoteDashboard?.recordSummary ?? const {};

  /// Informações da aula do dia, caso agendada no horário discente.
  Map<String, dynamic>? get todayClass => remoteDashboard?.todayClass;

  /// Lista de mensagens administrativas e comunicados institucionais.
  List<Map<String, dynamic>> get messages =>
      remoteDashboard?.messages ?? const [];

  /// Lista de requerimentos administrativos registrados na secretaria virtual.
  List<Map<String, dynamic>> get protocols =>
      remoteDashboard?.protocols ?? const [];

  /// Atualiza o item de navegação ativo e notifica os ouvintes da interface.
  void setNavItem(StudentNavItem item) {
    if (activeNavItem != item) {
      activeNavItem = item;
      notifyListeners();
    }
  }

  /// Alterna a visualização do painel geral entre Grade e Linha do Tempo.
  void toggleDashboardView(bool grid) {
    if (isGridView != grid) {
      isGridView = grid;
      if (!isGridView && timeline == null) {
        loadTimeline();
      }
      notifyListeners();
    }
  }

  /// Requisita e atualiza os blocos da linha do tempo acadêmica do discente.
  Future<void> loadTimeline() async {
    try {
      final res = await _remote.getTimeline();
      timeline = res;
      notifyListeners();
    } catch (_) {}
  }

  /// Carrega do servidor os dados consolidados do estudante via API.
  Future<void> loadRemote({bool force = false}) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      final hadRemoteState =
          remoteDashboard != null ||
          _loadedForToken != null ||
          disciplines.isNotEmpty ||
          deliveries.isNotEmpty ||
          events.isNotEmpty ||
          remoteError != 'Entre novamente para carregar seus dados acadêmicos.';
      remoteDashboard = null;
      timeline = null;
      _loadedForToken = null;
      remoteError = 'Entre novamente para carregar seus dados acadêmicos.';
      disciplines = [];
      deliveries = [];
      events = [];
      if (hadRemoteState) notifyListeners();
      return;
    }
    if (isLoadingRemote || (!force && _loadedForToken == token)) return;

    isLoadingRemote = true;
    remoteError = null;
    if (_loadedForToken != token) {
      remoteDashboard = null;
      timeline = null;
    }
    notifyListeners();
    try {
      final result = await _remote.getBootstrap();
      StudentTimelineResponse? timelineResult;
      try {
        timelineResult = await _remote.getTimeline();
      } catch (_) {}
      if (AppUserSession.instance.accessToken == token) {
        remoteDashboard = result;
        timeline = timelineResult;
        _loadedForToken = token;
        isTwoFactorEnabled = result.studentInfo['twoFactorRequired'] == true;
        AcademicBridgeService.instance.registerStudentEnrollments(
          result.studentInfo['ra']?.toString() ??
              AppUserSession.instance.identity ??
              '',
          result.disciplines.map((discipline) => discipline.code),
          studentEmail: result.studentInfo['email']?.toString(),
        );
        disciplines = result.disciplines;
        deliveries = result.deliveries;
        events = result.events;
        if (disciplines.isNotEmpty) {
          final firstDiscipline = disciplines.first;
          selectedDiscipline = firstDiscipline;
          studentPersonalNotes =
              result.personalNotes[firstDiscipline.code]?.toString() ?? '';
        } else {
          selectedDiscipline = null;
          studentPersonalNotes = '';
        }
      }
    } on ApiException catch (error) {
      if (AppUserSession.instance.accessToken == token) {
        remoteError = error.message;
      }
    } catch (_) {
      if (AppUserSession.instance.accessToken == token) {
        remoteError = 'Não foi possível carregar os dados acadêmicos.';
      }
    } finally {
      isLoadingRemote = false;
      notifyListeners();
    }
  }
}

/// [PortalController]
///
/// Controlador de estado reativo unificado do Portal do Aluno baseado no padrão Singleton
/// e [ChangeNotifier], modularizado por domínio via `part` e mixins coesos.
class PortalController extends _PortalControllerBase
    with
        _PortalBridgeMixin,
        _PortalCalendarMixin,
        _PortalAvaMixin,
        _PortalDeliveriesMixin,
        _PortalSettingsMixin {
  /// Instância única do controlador (Singleton pattern).
  static final PortalController instance = PortalController._internal();

  PortalController._internal() : super() {
    _initAcademicBridgeListener();
  }

  /// Construtor visível para injeção de dependências durante a execução de testes de unidade.
  @visibleForTesting
  PortalController.withRemoteDataSource(StudentRemoteDataSource remote)
    : super(remote: remote) {
    _initAcademicBridgeListener();
  }

  /// Retorna a instância compartilhada de [PortalController].
  factory PortalController() => instance;
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentPortalController = PortalController;
