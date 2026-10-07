// Desenvolvido por Marcelo Zarpelon - RA: 25015323

/// Representação base abstrata para tratamento de falhas e erros de domínio no padrão Clean Architecture.
abstract class Failure {
  /// Mensagem descritiva da falha para consumo na camada de apresentação ou registro em log.
  final String message;

  /// Cria uma instância imutável de [Failure] contendo uma [message] descritiva.
  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Falha disparada durante a validação de regras de entrada ou formato de dados em formulários.
class ValidationFailure extends Failure {
  /// Cria uma falha de validação com a [message] correspondente.
  const ValidationFailure(super.message);
}

/// Falha originada de erros de comunicação com serviços remotos, APIs ou servidor de backend.
class ServerFailure extends Failure {
  /// Cria uma falha de servidor remoto com a [message] correspondente.
  const ServerFailure(super.message);
}

