// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import '../../domain/usecases/login_usecase.dart';

/// Controlador reativo de estado da interface de login baseado em [ChangeNotifier].
///
/// Gerencia o ciclo de vida da autenticação, controlando os estados de
/// carregamento ([isLoading]), erro ([errorMessage]) e sucesso ([isSuccess]).
class LoginController extends ChangeNotifier {
  /// Caso de uso que encapsula as regras de validação e autenticação do login.
  final LoginUseCase loginUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  /// Cria uma nova instância de [LoginController] injetando [loginUseCase].
  LoginController({
    required this.loginUseCase,
  });

  /// Indica se uma operação de autenticação está em andamento.
  bool get isLoading => _isLoading;

  /// Mensagem de erro amigável caso a autenticação ou validação tenha falhado.
  String? get errorMessage => _errorMessage;

  /// Indica se a última operação de login foi concluída com sucesso.
  bool get isSuccess => _isSuccess;

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
  /// Em caso de falha, sanitiza a mensagem de exceção e a expõe em [errorMessage].
  ///
  /// Retorna `true` se autenticado com sucesso ou `false` se houver falha.
  Future<bool> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      await loginUseCase(
        identity: identity,
        password: password,
        profile: profile,
      );
      _isSuccess = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSuccess = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

