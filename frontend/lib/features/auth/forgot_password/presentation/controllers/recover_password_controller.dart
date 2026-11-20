// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/foundation.dart';
import '../../../../../core/utils/input_validators.dart';
import '../../../shared/external/auth_remote_datasource_impl.dart';
import '../../domain/usecases/recover_password_usecase.dart';

/// Controller de apresentação responsável por gerenciar o estado reativo da tela
/// de recuperação de senha utilizando o padrão [ChangeNotifier].
///
/// Coordena a validação da identidade informada (RA, matrícula ou e-mail),
/// o disparo assíncrono de [RecoverPasswordUseCase], o controle de feedback
/// visual de carregamento ([isLoading]) e o tratamento de erros amigáveis.
class RecoverPasswordController extends ChangeNotifier {
  /// Instância injetada do caso de uso de recuperação de senha.
  final RecoverPasswordUseCase recoverPasswordUseCase;

  /// Cria uma nova instância de [RecoverPasswordController] com o caso de uso obrigatório.
  RecoverPasswordController({required this.recoverPasswordUseCase});

  String _identity = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  int _operationId = 0;
  Map<String, dynamic>? _lastRecoveryResponse;

  /// Retorna o valor atual da credencial ou e-mail digitado pelo usuário.
  String get identity => _identity;

  /// Retorna a resposta com dados reais (como maskedEmail) vinda do servidor Java / MongoDB.
  Map<String, dynamic>? get lastRecoveryResponse => _lastRecoveryResponse;

  /// Indica se a operação de envio de recuperação está em processamento ativo.
  bool get isLoading => _isLoading;

  /// Mensagem de erro de validação local ou falha do repositório, ou `null` quando não houver erro.
  String? get errorMessage => _errorMessage;

  /// Sinaliza se a solicitação de recuperação de senha foi concluída com êxito.
  bool get isSuccess => _isSuccess;

  /// Atualiza o identificador acadêmico digitado e remove mensagens de erro
  /// anteriores caso existam, promovendo reatividade limpa no formulário.
  ///
  /// Parâmetros:
  /// - [value]: Novo valor de texto fornecido pelo campo de entrada.
  void setIdentity(String value) {
    if (_identity == value) return;
    _identity = value;
    _operationId++;
    final wasLoading = _isLoading;
    _isLoading = false;
    final hadFeedback = _errorMessage != null || _isSuccess || wasLoading;
    _isSuccess = false;
    if (hadFeedback) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Limpa qualquer mensagem de erro exibida atualmente (ex.: ao trocar de aba de perfil).
  void clearError() {
    if (_errorMessage != null || _isSuccess) {
      _errorMessage = null;
      _isSuccess = false;
      notifyListeners();
    }
  }

  /// Valida o identificador e submete a solicitação de recuperação de credencial.
  ///
  /// Executa:
  /// 1. Validação de formato via [InputValidators.validateIdentity].
  /// 2. Atualização reativa de [isLoading] e limpeza de mensagens de erro.
  /// 3. Invocação assíncrona de [recoverPasswordUseCase] com sanitização de espaços em branco.
  /// 4. Validação de compatibilidade do tipo de usuário ([profile]) contra o perfil da conta.
  ///
  /// Retorna `true` caso a operação seja concluída com sucesso ou `false` em caso de falha.
  Future<bool> submit({String? profile}) async {
    if (_isLoading) return false;

    final identity = _identity.trim();
    final selectedProfile = profile?.trim().toLowerCase();
    final validationError = InputValidators.validateIdentity(identity);
    if (validationError != null) {
      _errorMessage = validationError;
      _isSuccess = false;
      notifyListeners();
      return false;
    }

    final operationId = ++_operationId;
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final repository = recoverPasswordUseCase.repository;
      final response = await repository.recoverPasswordDetails(
        identity: identity,
        profile: selectedProfile,
      );
      if (operationId != _operationId) return false;

      final responseProfile = _normalizeProfile(response['profile']?.toString());
      if (selectedProfile != null &&
          selectedProfile.isNotEmpty &&
          responseProfile.isNotEmpty &&
          responseProfile != _normalizeProfile(selectedProfile)) {
        _isLoading = false;
        _isSuccess = false;
        _lastRecoveryResponse = null;
        _errorMessage = _buildInvalidUserTypeMessage(
          selectedProfile: selectedProfile,
          actualProfile: responseProfile,
        );
        notifyListeners();
        return false;
      }

      _lastRecoveryResponse = response;
      _isLoading = false;
      _isSuccess = true;
      notifyListeners();
      return true;
    } on AuthApiException catch (error) {
      if (operationId != _operationId) return false;
      _isLoading = false;
      _errorMessage = _resolveApiErrorMessage(error);
      _isSuccess = false;
      notifyListeners();
      return false;
    } catch (_) {
      try {
        await recoverPasswordUseCase(
          identity: identity,
          profile: selectedProfile,
        );
        if (operationId != _operationId) return false;
        _isLoading = false;
        _isSuccess = true;
        notifyListeners();
        return true;
      } on AuthApiException catch (error) {
        if (operationId != _operationId) return false;
        _isLoading = false;
        _errorMessage = _resolveApiErrorMessage(error);
        _isSuccess = false;
        notifyListeners();
        return false;
      } catch (_) {
        if (operationId != _operationId) return false;
        _isLoading = false;
        _errorMessage =
            'Não foi possível solicitar a recuperação agora. Tente novamente.';
        _isSuccess = false;
        notifyListeners();
        return false;
      }
    }
  }

  static const Set<int> _clientVisibleStatuses = {
    400,
    401,
    403,
    404,
    422,
    429,
    503,
    504,
  };

  static String _normalizeProfile(String? raw) {
    if (raw == null) return '';
    final p = raw.trim().toLowerCase();
    if (p == 'student' || p == 'discente') return 'aluno';
    if (p == 'teacher' || p == 'professor') return 'docente';
    if (p == 'administrator' || p == 'administrador') return 'admin';
    return p;
  }

  static String _profileLabel(String raw) {
    final norm = _normalizeProfile(raw);
    if (norm == 'aluno') return 'Aluno';
    if (norm == 'docente') return 'Docente';
    if (norm == 'admin') return 'Admin';
    return raw;
  }

  static String _buildInvalidUserTypeMessage({
    required String selectedProfile,
    required String actualProfile,
  }) {
    return 'Tipo de usuário inválido: esta conta pertence ao perfil de '
        '${_profileLabel(actualProfile)}, não ao perfil selecionado '
        '(${_profileLabel(selectedProfile)}).';
  }

  String _resolveApiErrorMessage(AuthApiException error) {
    final trimmed = error.message.trim();
    if (_clientVisibleStatuses.contains(error.statusCode) && trimmed.isNotEmpty) {
      return trimmed;
    }
    return 'Não foi possível solicitar a recuperação agora. Tente novamente.';
  }

  /// Restaura todas as variáveis de estado do controller para suas condições
  /// iniciais padrão e notifica os ouvintes da tela.
  void reset() {
    _operationId++;
    _identity = '';
    _errorMessage = null;
    _isSuccess = false;
    _isLoading = false;
    _lastRecoveryResponse = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _operationId++;
    super.dispose();
  }
}
