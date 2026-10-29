// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/login/domain/usecases/login_usecase.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';

/// Dublê de teste (Mock/Spy) para [AuthRepository].
///
/// Registra os parâmetros recebidos e permite simular falhas controladas de autenticação.
class MockAuthRepository implements AuthRepository {
  /// Último identificador repassado na chamada de login.
  String? lastIdentity;

  /// Última senha repassada na chamada de login.
  String? lastPassword;

  /// Último perfil repassado na chamada de login.
  String? lastProfile;

  /// Flag de controle para simular rejeição de credenciais no repositório.
  bool shouldFail = false;

  @override
  Future<void> recoverPassword({required String identity}) async {}

  @override
  Future<String> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    if (shouldFail) {
      throw Exception('Credenciais inválidas.');
    }
    lastIdentity = identity;
    lastPassword = password;
    lastProfile = profile;
    return 'test-access-token';
  }

  @override
  Future<bool> verifyOtpToken({
    required String identity,
    required String code,
  }) async => true;

  @override
  Future<String> verifyPasswordRecoveryCode({
    required String identity,
    required String code,
  }) async => 'test-reset-token';

  @override
  Future<void> resetPassword({
    required String identity,
    required String newPassword,
    String? resetToken,
  }) async {}

  @override
  Future<bool> isTwoFactorRequired({
    required String identity,
    required String profile,
  }) async => false;
}

void main() {
  late MockAuthRepository mockRepository;
  late LoginUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test(
    'Deve executar login com sucesso e repassar dados ao repositório',
    () async {
      // Arrange & Act
      await useCase(
        identity: 'ADM-00123',
        password: 'password123',
        profile: 'admin',
      );

      // Assert
      expect(mockRepository.lastIdentity, 'ADM-00123');
      expect(mockRepository.lastPassword, 'password123');
      expect(mockRepository.lastProfile, 'admin');
    },
  );

  test('Deve lançar erro quando o identificador for vazio', () async {
    // Act & Assert
    expect(
      () => useCase(identity: '   ', password: 'password123', profile: 'admin'),
      throwsA(isA<Exception>()),
    );
  });

  test('Deve lançar erro quando a senha for menor que 8 caracteres', () async {
    // Act & Assert
    expect(
      () => useCase(identity: 'ADM-00123', password: '123', profile: 'admin'),
      throwsA(isA<Exception>()),
    );
  });

  test('Deve propagar erro do repositório em falha de autenticação', () async {
    // Arrange
    mockRepository.shouldFail = true;

    // Act & Assert
    expect(
      () => useCase(
        identity: 'ADM-00123',
        password: 'password123',
        profile: 'admin',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
