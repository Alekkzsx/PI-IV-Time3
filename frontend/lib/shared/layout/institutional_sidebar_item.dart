// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Modelo desacoplado e reutilizável de item da Sidebar Institucional

import 'package:flutter/widgets.dart';

/// Assinatura da função construtora do vetor SVG para o item de menu.
typedef SvgIconBuilder = String Function(Color color);

/// Representa um item configurável na barra lateral institucional.
class InstitutionalSidebarItem<T> {
  /// Identificador exclusivo do item (geralmente um enum de rotas/abas).
  final T id;

  /// Rótulo de exibição textual (ex: "Painel Geral", "Disciplinas").
  final String label;

  /// Função geradora do vetor SVG correspondente com a cor de estado aplicada.
  final SvgIconBuilder iconSvgBuilder;

  /// Indica se a ação possui variante de perigo (ex: botão Sair em hover vermelho #b91c1c).
  final bool isDanger;

  /// Indica se deve renderizar uma linha divisória horizontal abaixo deste item.
  final bool showDividerAfter;

  /// Chave de teste ou identificador de widget no Flutter.
  final Key? key;

  const InstitutionalSidebarItem({
    required this.id,
    required this.label,
    required this.iconSvgBuilder,
    this.isDanger = false,
    this.showDividerAfter = false,
    this.key,
  });
}

