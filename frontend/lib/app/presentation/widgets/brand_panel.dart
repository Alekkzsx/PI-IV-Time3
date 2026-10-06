// Desenvolvido por Murilo (Murillo Caravita)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Painel institucional exibido ao lado ou no topo do formulário de autenticação.
/// Apresenta a marca do portal AGMRM, arte de fundo cósmica e descrição institucional.
class BrandPanel extends StatelessWidget {
  final bool compact;

  const BrandPanel({
    super.key,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF020305),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'images/cosmic-stars-bg.svg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Positioned(
            top: compact ? 28 : 48,
            left: compact ? 28 : 48,
            child: const PortalLogo(),
          ),
          Positioned(
            left: compact ? 28 : 48,
            right: compact ? 28 : 48,
            bottom: compact ? 28 : 72,
            child: _brandDescription(context),
          ),
        ],
      ),
    );
  }

  Widget _brandDescription(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sua jornada\nuniversitária, interativa\ne sem limites.',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontSize: compact ? 26 : 36,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: compact ? 12 : 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Aulas síncronas, biblioteca digital com mais de 80 mil títulos, '
            'acompanhamento contínuo de notas e entregas de atividades com '
            'inteligência acadêmica integrada.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCBD5E1),
                  fontSize: compact ? 11 : 12.5,
                  height: 1.55,
                ),
          ),
        ),
      ],
    );
  }
}

/// Logotipo institucional do portal AGMRM.
class PortalLogo extends StatelessWidget {
  const PortalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AGMRM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Portal Acadêmico Integrado',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

