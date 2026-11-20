// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'security_constants.dart';

/// Política que rege o feedback sanitizado e opaco ao usuário nos fluxos de autenticação
/// e recuperação de credenciais para eliminar enumeração de usuários, canais laterais
/// de temporização e vazamento de informações.
abstract final class GenericFeedbackPolicy {
  GenericFeedbackPolicy._();

  // ─── MENSAGENS ESTÁTICAS OPACAS PADRONIZADAS ───

  /// Erro genérico padronizado retornado em falha de autenticação.
  /// Garante indistinguibilidade entre contas inexistentes e senhas incorretas.
  static const String authFailureMessage =
      'Credenciais inválidas. Verifique seu identificador e senha.';

  /// Feedback genérico de sucesso padronizado retornado na solicitação de recuperação de senha.
  /// Garante indistinguibilidade entre identificadores acadêmicos válidos e inexistentes/não mapeados.
  static const String passwordResetRequestedMessage =
      'Se o identificador informado estiver cadastrado em nosso sistema, as instruções de recuperação foram enviadas.';

  /// Mensagem padronizada de sucesso na solicitação de recuperação (formato institucional).
  static const String recoveryRequestSuccessMessage =
      'Se o identificador informado estiver cadastrado no sistema, as instruções e o código de verificação foram enviados para o e-mail institucional.';

  /// Erro padronizado retornado quando um token de verificação efêmero expirou.
  static const String expiredTokenMessage =
      'Código de verificação expirado. Solicite um novo código.';

  /// Mensagem padronizada de token expirado (redação alternativa).
  static const String tokenExpiredMessage =
      'O código de verificação expirou. Solicite um novo código para continuar.';

  /// Erro padronizado retornado quando o limite de tentativas de OTP (3 tentativas) foi excedido e a sessão é revogada.
  static const String revokedSessionMessage =
      'Sessão de recuperação revogada por excesso de tentativas. Solicite um novo código.';

  /// Mensagem padronizada de token revogado (redação alternativa).
  static const String tokenRevokedMessage =
      'Número máximo de tentativas incorretas excedido. Por segurança, a sessão foi cancelada. Solicite uma nova recuperação.';

  /// Erro padronizado retornado quando a força da senha não atinge a pontuação mínima.
  static const String weakPasswordMessage =
      'A nova senha não atende aos requisitos mínimos de segurança (mínimo 8 caracteres, maiúsculas, minúsculas, números e caracteres especiais).';

  /// Erro padronizado de senha fraca com referência explícita à pontuação.
  static const String passwordTooWeakMessage =
      'A senha não atende aos requisitos mínimos de segurança (pontuação mínima: ${SecurityConstants.minRequiredEntropyScore}/4).';

  /// Mensagem padronizada de sucesso ao concluir a redefinição de senha.
  static const String passwordResetSuccessMessage =
      'Senha redefinida com sucesso. Faça login com a nova senha.';

  /// Mensagem padronizada de erro na validação do payload do cliente.
  static const String badRequestPayloadMessage =
      'Dados da requisição inválidos.';

  /// Mensagem padronizada de payload inválido (redação alternativa).
  static const String invalidPayloadMessage =
      'Dados de requisição inválidos ou fora do formato permitido.';

  /// Mensagem padronizada de erro de payload muito grande (limite de 64 KB).
  static const String payloadTooLargeMessage =
      'Tamanho da requisição excede o limite permitido de 64 KB.';

  /// Mensagem genérica padronizada de erro do servidor suprimindo stack traces internos.
  static const String internalErrorMessage =
      'Ocorreu um erro interno ao processar a solicitação. Tente novamente mais tarde.';

  /// Mensagem genérica padronizada de erro do servidor (redação alternativa).
  static const String internalServerErrorMessage =
      'Ocorreu um erro no processamento da solicitação. Tente novamente mais tarde.';

  // ─── AUXILIARES DE ESTRUTURAÇÃO DE RESPOSTA ───

  /// Cria um mapa de resposta padronizado de falha de autenticação com status 401 e mensagem genérica.
  static Map<String, dynamic> createAuthFailureResponse() {
    return <String, dynamic>{
      'statusCode': 401,
      'error': 'Unauthorized',
      'message': authFailureMessage,
    };
  }

  /// Erro genérico padronizado retornado após bloqueio de conta / período de espera de limitação de taxa.
  static const String accountLockedMessage =
      'Acesso temporariamente bloqueado por excesso de tentativas.';

  // ─── MENSAGENS DINÂMICAS FORMATADAS ───

  /// Retorna a mensagem de bloqueio padronizada com os segundos restantes exatos.
  static String lockoutMessage(int remainingSeconds) {
    final sanitizedSeconds = remainingSeconds > 0 ? remainingSeconds : 0;
    final unit = sanitizedSeconds == 1 ? 'segundo' : 'segundos';
    return 'Muitas tentativas incorretas. Tente novamente em $sanitizedSeconds $unit.';
  }

  /// Retorna a mensagem de contagem regressiva padronizada exibida no banner de bloqueio ativo.
  static String lockoutCountdownMessage(int remainingSeconds) {
    final clamped = remainingSeconds > 0 ? remainingSeconds : 0;
    return 'Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde $clamped segundos.';
  }

  /// Retorna a mensagem padronizada de código OTP inválido com as tentativas restantes.
  static String invalidOtpCodeMessage(int remainingAttempts) {
    final sanitizedAttempts = remainingAttempts > 0 ? remainingAttempts : 0;
    return 'Código de verificação incorreto. Tentativas restantes: $sanitizedAttempts.';
  }

  /// Sanitiza um objeto de erro ou exceção recebido para evitar o vazamento de
  /// erros internos de banco de dados, exceções de usuário ausente ou stack traces da JVM/Dart para a interface.
  /// Padroniza a saída em categorias opacas e anti-enumeração.
  static String sanitizeErrorMessage(dynamic error) {
    if (error == null) return authFailureMessage;
    final raw = error.toString().trim();
    if (raw.isEmpty) return authFailureMessage;
    final message = raw.toLowerCase();

    // 1. Bloqueio de Conta e Limitação de Taxa de Login (Contexto de Autenticação)
    if (message.contains('bloque') ||
        message.contains('lockout') ||
        message.contains('temporariamente') ||
        message.contains('cooldown') ||
        message.contains('limite de tentativas de login') ||
        message.contains('excesso de tentativas de login') ||
        ((message.contains('login') || message.contains('autentica')) &&
            (message.contains('excesso') || message.contains('limite')))) {
      return accountLockedMessage;
    }

    // 2. Expiração de Token Efêmero (Contexto de Recuperação)
    if (message.contains('expir')) {
      return tokenExpiredMessage;
    }

    // 3. Tentativas de Código de Verificação / OTP e Revogação de Sessão (Contexto de Recuperação)
    // Escopo de contexto: exige palavras-chave de verificação/OTP junto com palavras-chave de tentativa/esgotamento,
    // ou termos explícitos de revogação. Nunca vaza para fluxos puros de autenticação/login.
    final hasOtpContext = message.contains('codigo') ||
        message.contains('código') ||
        message.contains('otp') ||
        message.contains('verificacao') ||
        message.contains('verificação');
    final hasAttemptContext = message.contains('tentativa') ||
        message.contains('exced') ||
        message.contains('limite') ||
        message.contains('esgotad');

    if (message.contains('revog') || (hasOtpContext && hasAttemptContext)) {
      return tokenRevokedMessage;
    }

    // 4. Entropia de Senha e Complexidade Mínima (Contexto de Senha)
    if (message.contains('senha') &&
        (message.contains('fraca') ||
            message.contains('fraco') ||
            message.contains('entropia') ||
            message.contains('weak') ||
            message.contains('requisito') ||
            message.contains('complexidade'))) {
      return passwordTooWeakMessage;
    }

    // 5. Limites de Payload e Tamanho (Contexto de Transporte / Middleware)
    if (message.contains('tamanho') ||
        message.contains('payload') ||
        message.contains('64') ||
        message.contains('413') ||
        message.contains('corpo da requisi')) {
      return invalidPayloadMessage;
    }

    // 6. Fallback padrão genérico anti-enumeração
    // Absorve com segurança consultas SQL brutas, stack traces, exceções de conta ausente,
    // falhas de conexão com o banco de dados e erros internos de decremento de tentativas.
    return authFailureMessage;
  }
}
