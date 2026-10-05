// Desenvolvido por Marcelo Zarpelon. RA 25015323

class InputValidators {
  static String? validateIdentity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu R.A., Matrícula ou E-mail Institucional.';
    }

    final trimmed = value.trim();

    // Validação sintática de formato de e-mail (caso contenha @)
    if (trimmed.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(trimmed)) {
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
