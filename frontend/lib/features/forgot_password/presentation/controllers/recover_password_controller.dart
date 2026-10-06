// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/foundation.dart';
import '../../../../core/utils/input_validators.dart';
import '../../domain/usecases/recover_password_usecase.dart';

class RecoverPasswordController extends ChangeNotifier {
  final RecoverPasswordUseCase recoverPasswordUseCase;

  RecoverPasswordController({required this.recoverPasswordUseCase});

  String _identity = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  String get identity => _identity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  void setIdentity(String value) {
    _identity = value;
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> submit() async {
    final validationError = InputValidators.validateIdentity(_identity);
    if (validationError != null) {
      _errorMessage = validationError;
      _isSuccess = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      await recoverPasswordUseCase(
        identity: _identity.trim(),
      );
      _isLoading = false;
      _isSuccess = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSuccess = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _identity = '';
    _errorMessage = null;
    _isSuccess = false;
    _isLoading = false;
    notifyListeners();
  }
}
