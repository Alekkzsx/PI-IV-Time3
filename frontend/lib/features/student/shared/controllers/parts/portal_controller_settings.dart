// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

part of '../portal_controller.dart';

/// [_PortalSettingsMixin]
///
/// Mixin de domínio responsável pelo gerenciamento das abas de configurações
/// do discente e ativação/desativação da autenticação em duas etapas (2FA).
mixin _PortalSettingsMixin on _PortalControllerBase {
  /// Retorna o identificador textual da sub-aba de configurações ativa.
  String get settingsSubtab {
    switch (selectedSettingsTabIndex) {
      case 0:
        return 'perfil';
      case 1:
        return 'seguranca';
      case 2:
        return 'notificacoes';
      case 3:
        return 'preferencias';
      case 4:
        return 'privacidade';
      default:
        return 'perfil';
    }
  }

  /// Define a sub-aba de configurações com base em sua chave textual.
  ///
  /// Parâmetros:
  /// - [key]: Chave representativa da sub-aba ('perfil', 'seguranca', etc.).
  void setSettingsSubtab(String key) {
    switch (key) {
      case 'perfil':
        selectedSettingsTabIndex = 0;
        break;
      case 'seguranca':
        selectedSettingsTabIndex = 1;
        break;
      case 'notificacoes':
        selectedSettingsTabIndex = 2;
        break;
      case 'preferencias':
        selectedSettingsTabIndex = 3;
        break;
      case 'privacidade':
        selectedSettingsTabIndex = 4;
        break;
      default:
        selectedSettingsTabIndex = 0;
    }
    notifyListeners();
  }

  /// Define o índice numérico da aba de configurações ativa.
  ///
  /// Parâmetros:
  /// - [index]: Índice inteiro da aba (0 a 4).
  void setSettingsTab(int index) {
    selectedSettingsTabIndex = index;
    notifyListeners();
  }

  /// Alterna o status de ativação da autenticação em duas etapas (2FA) do discente.
  ///
  /// Parâmetros:
  /// - [password]: Senha atual do usuário para validação de segurança.
  Future<void> toggleTwoFactor(String password) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException(
        'Apenas alunos podem alterar esta configuração.',
      );
    }
    await _profileRemote.toggleTwoFactor(
      password: password,
      enabled: !isTwoFactorEnabled,
    );
    setTwoFactorEnabled(!isTwoFactorEnabled);
  }

  /// Atualiza o indicador reativo de 2FA em memória.
  void setTwoFactorEnabled(bool enabled) {
    if (isTwoFactorEnabled == enabled) return;
    isTwoFactorEnabled = enabled;
    notifyListeners();
  }
}
