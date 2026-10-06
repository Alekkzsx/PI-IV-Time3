// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginController extends ChangeNotifier {
  final LoginUseCase loginUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  LoginController({
    required this.loginUseCase,
  });

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

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

