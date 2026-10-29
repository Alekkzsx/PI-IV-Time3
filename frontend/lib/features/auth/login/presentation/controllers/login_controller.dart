// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import '../../domain/usecases/login_usecase.dart';

/// Controlador reativo de estado da interface de login baseado em [ChangeNotifier].
///
/// Gerencia o ciclo de vida da autenticação, controlando os estados de
/// carregamento ([isLoading]), erro ([errorMessage]), sucesso ([isSuccess])
/// e prontidão arquitetural para desafio de segundo fator ([requiresTwoFactor]).
class LoginController extends ChangeNotifier {
  /// Caso de uso que encapsula as regras de validação e autenticação do login.
  final LoginUseCase loginUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  // Prontidão arquitetural para 2FA
  bool _requiresTwoFactor = false;
  int _operationId = 0;
  String? _pendingIdentity;
  String? _pendingProfile;

  /// Cria uma nova instância de [LoginController] injetando [loginUseCase].
  LoginController({required this.loginUseCase});

  /// Indica se uma operação de autenticação está em andamento.
  bool get isLoading => _isLoading;

  /// Mensagem de erro amigável caso a autenticação ou validação tenha falhado.
  String? get errorMessage => _errorMessage;

  /// Indica se a última operação de login foi concluída com sucesso.
  bool get isSuccess => _isSuccess;

  /// Indica se a credencial exige o desafio complementar de 2FA.
  bool get requiresTwoFactor => _requiresTwoFactor;

  /// Limpa a mensagem de erro atual e notifica os ouvintes da tela.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Dispara a tentativa de autenticação do usuário.
  ///
  /// Atualiza o estado reativo notificando a interface no início da operação,
  /// delegando a execução ao [loginUseCase]. Em caso de sucesso, marca [isSuccess] como `true`.
  /// Em caso de falha, expõe uma mensagem genérica sem repassar detalhes do servidor.
  ///
  /// Retorna `true` se autenticado com sucesso ou `false` se houver falha.
  Future<bool> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    if (_isLoading) return false;

    final cleanIdentity = identity.trim();
    final operationId = ++_operationId;
    AppUserSession.instance.signOut();
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    _requiresTwoFactor = false;
    _pendingIdentity = cleanIdentity;
    _pendingProfile = profile;
    notifyListeners();

    try {
      await loginUseCase(
        identity: cleanIdentity,
        password: password,
        profile: profile,
      );

      // Verificação de prontidão para 2FA via repositório
      final needs2FA = await loginUseCase.repository.isTwoFactorRequired(
        identity: cleanIdentity,
        profile: profile,
      );

      if (operationId != _operationId) return false;

      if (needs2FA) {
        _requiresTwoFactor = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      AppUserSession.instance.signIn(identity: cleanIdentity, profile: profile);
      _isSuccess = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      if (operationId != _operationId) return false;
      _errorMessage =
          'Não foi possível entrar. Confira seus dados e tente novamente.';
      _isSuccess = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Validação do desafio de 2FA quando ativado no repositório.
  Future<bool> verifyTwoFactorToken({
    required String identity,
    required String code,
  }) async {
    if (_isLoading || !_requiresTwoFactor) return false;

    final operationId = ++_operationId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final valid = await loginUseCase.repository.verifyOtpToken(
        identity: identity,
        code: code,
      );

      if (operationId != _operationId) return false;

      if (valid) {
        final identity = _pendingIdentity;
        final profile = _pendingProfile;
        if (identity == null || profile == null) {
          _errorMessage = 'Sessão de autenticação inválida. Entre novamente.';
          _isLoading = false;
          _requiresTwoFactor = false;
          notifyListeners();
          return false;
        }
        AppUserSession.instance.signIn(identity: identity, profile: profile);
        _isSuccess = true;
        _requiresTwoFactor = false;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Código de segurança de 2 fatores incorreto.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      if (operationId != _operationId) return false;
      _errorMessage = 'Não foi possível validar o código. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _operationId++;
    super.dispose();
  }
}
