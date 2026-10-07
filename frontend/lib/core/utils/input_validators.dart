// Desenvolvido por Marcelo Zarpelon - RA: 25015323

/// Conjunto de validadores utilitários para campos de entrada e formulários institucionais.
class InputValidators {
  InputValidators._();

  /// Expressão regular para validação sintática de endereços de e-mail institucionais.
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Valida a identidade acadêmica ou corporativa informada (R.A., Matrícula ou E-mail Institucional).
  ///
  /// Regras de negócio:
  /// - Campo de preenchimento obrigatório (não nulo e não em branco).
  /// - Se o valor contiver o caractere '@', deve seguir formato sintático válido de e-mail.
  /// - Se for identificador numérico/alfanumérico (R.A. ou Matrícula), requer no mínimo 3 caracteres.
  ///
  /// Retorna `null` quando o valor é válido ou uma [String] com a mensagem de erro correspondente.
  static String? validateIdentity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu R.A., Matrícula ou E-mail Institucional.';
    }

    final trimmed = value.trim();

    // Validação sintática de formato de e-mail (caso contenha @)
    if (trimmed.contains('@')) {
      if (!_emailRegex.hasMatch(trimmed)) {
        return 'Insira um endereço de e-mail válido.';
      }
      return null;
    }

    // Tamanho mínimo para R.A. ou Matrícula
    if (trimmed.length < 3) {
      return 'O identificador informado deve conter pelo menos 3 caracteres.';
    }

    return null;
  }
}

