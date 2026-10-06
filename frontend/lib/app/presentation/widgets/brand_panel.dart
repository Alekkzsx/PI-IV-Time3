// Desenvolvido por Murillo Caravita

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Painel institucional exibido ao lado ou no topo do formulário de autenticação.
/// Apresenta a marca do portal AGMRM, gradiente de fundo e descrição institucional.
class BrandPanel extends StatelessWidget {
  final bool compact;

  const BrandPanel({
    super.key,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.buttonDark,
      child: Stack(
        children: [
          _backgroundGradient(),
          _decorations(),
          Positioned(
            top: compact ? 28 : 56,
            left: compact ? 28 : 54,
            child: const PortalLogo(),
          ),
          Positioned(
            left: compact ? 28 : 54,
            right: compact ? 28 : 54,
            bottom: compact ? 32 : 130,
            child: _brandDescription(context),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGradient() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.1, 0.2),
          radius: 1.2,
          colors: [
            Color(0xFF172554),
            Color(0xFF0B132B),
            Color(0xFF050B1D),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }

  Widget _decorations() {
    return Stack(
      children: [
        Positioned(
          top: 22,
          right: 96,
          child: _dot(
            size: 18,
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        Positioned(
          top: 92,
          left: 155,
          child: _dot(
            size: 10,
            color: const Color(0xFFC38A17).withOpacity(0.55),
          ),
        ),
        Positioned(
          top: 155,
          right: 72,
          child: _dot(
            size: 7,
            color: const Color(0xFFEAB308).withOpacity(0.65),
          ),
        ),
        Positioned(
          bottom: 150,
          right: 112,
          child: _dot(
            size: 15,
            color: Colors.white.withOpacity(0.30),
          ),
        ),
        Positioned(
          bottom: 82,
          left: 72,
          child: _dot(
            size: 9,
            color: Colors.white.withOpacity(0.18),
          ),
        ),
      ],
    );
  }

  Widget _dot({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
                fontSize: compact ? 27 : 38,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: compact ? 14 : 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            'Aulas síncronas, biblioteca digital com mais de 80 mil títulos, '
            'acompanhamento contínuo de notas e entregas de atividades com '
            'inteligência acadêmica integrada.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCBD5E1),
                  fontSize: compact ? 11 : 13,
                  height: 1.6,
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

