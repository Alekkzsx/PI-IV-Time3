// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

/// [StudentNavItem]
///
/// Enumerador que define os destinos de navegação disponíveis na barra lateral
/// e no shell do Portal do Aluno.
enum StudentNavItem {
  /// Visão geral do discente (painel consolidado com prazos e disciplinas).
  painelGeral,

  /// Catálogo de disciplinas e acesso ao cockpit do Ambiente Virtual de Aprendizagem.
  disciplinas,

  /// Calendário acadêmico interativo de aulas, tarefas e avaliações.
  calendario,

  /// Gestor de tarefas, atividades avaliativas e submissões discentes.
  entregas,

  /// Central de mensagens institucionais e comunicados de professores.
  mensagens,

  /// Secretaria acadêmica virtual para solicitações de protocolos e documentos.
  secretaria,

  /// Preferências de perfil, segurança (2FA) e notificações da conta.
  configuracoes,

  /// Gatilho para encerramento seguro da sessão autenticada.
  sair,
}

/// Alias de compatibilidade para convenção de nomenclatura simplificada.
typedef NavItem = StudentNavItem;
