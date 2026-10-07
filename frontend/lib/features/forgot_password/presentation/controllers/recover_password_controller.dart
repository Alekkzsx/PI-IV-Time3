// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/foundation.dart';
import '../../../../core/utils/input_validators.dart';
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

  /// Retorna o valor atual da credencial ou e-mail digitado pelo usuário.
  String get identity => _identity;

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
    _identity = value;
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Valida o identificador e submete a solicitação de recuperação de credencial.
  ///
  /// Executa:
  /// 1. Validação de formato via [InputValidators.validateIdentity].
  /// 2. Atualização reativa de [isLoading] e limpeza de mensagens de erro.
  /// 3. Invocação assíncrona de [recoverPasswordUseCase] com sanitização de espaços em branco.
  /// 4. Captura e tratamento amigável de exceções (removendo prefixo `Exception: `).
  ///
  /// Retorna `true` caso a operação seja concluída com sucesso ou `false` em caso de falha.
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

  /// Restaura todas as variáveis de estado do controller para suas condições
  /// iniciais padrão e notifica os ouvintes da tela.
  void reset() {
    _identity = '';
    _errorMessage = null;
    _isSuccess = false;
    _isLoading = false;
    notifyListeners();
  }
}

