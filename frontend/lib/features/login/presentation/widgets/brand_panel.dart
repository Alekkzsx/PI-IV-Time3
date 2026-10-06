// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Painel institucional Hero exibido ao lado ou no topo do formulário de autenticação.
/// Apresenta a marca do portal AGMRM, arte cósmica com gradientes de contraste e descrição.
class BrandPanel extends StatelessWidget {
  /// Define se o layout é compacto (para telas menores/mobile) ou expandido (desktop).
  final bool compact;

  /// Cria uma instância de [BrandPanel].
  const BrandPanel({
    super.key,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.heroBackground, // #05070B
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de Fundo Estrelado
          Positioned.fill(
            child: SvgPicture.asset(
              'images/cosmic-stars-bg.svg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // 2. Gradiente vertical para contraste (from-[#030509]/75 via-[#030509]/35 to-[#030509]/85)
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xBF030509), // 75%
                    Color(0x59030509), // 35%
                    Color(0xD9030509), // 85%
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Gradiente horizontal suave (from-[#030509]/60 via-transparent to-[#030509]/40)
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x99030509), // 60%
                    Colors.transparent,
                    Color(0x66030509), // 40%
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 4. Conteúdo: Topo (Logo) e Centro (Headline + Descrição)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 28 : 48,
              vertical: compact ? 32 : 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PortalLogo(compact: compact),
                const Spacer(flex: 2),
                _brandDescription(context),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o bloco de headline e texto institucional descritivo com tipografia escalável.
  Widget _brandDescription(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 512), // max-w-lg
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua jornada\nuniversitária, interativa\ne sem limites.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: compact ? 28 : 42, // text-3xl sm:text-4xl lg:text-[44px]
              height: 1.16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
              shadows: const [
                Shadow(
                  color: Color(0xD9000000), // drop-shadow-[0_2px_12px_rgba(0,0,0,0.85)]
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 14 : 24),
          Text(
            'Aulas síncronas, biblioteca digital com mais de 80 mil títulos, '
            'acompanhamento contínuo de notas e entregas de atividades com '
            'inteligência acadêmica integrada.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xE6E2E8F0), // text-slate-200/90
              fontSize: compact ? 13 : 15, // text-sm sm:text-[15px]
              height: 1.6, // leading-relaxed
              fontWeight: FontWeight.normal,
              shadows: const [
                Shadow(
                  color: Color(0xD9000000), // drop-shadow-[0_1px_8px_rgba(0,0,0,0.85)]
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Logotipo institucional do portal AGMRM.
///
/// Exibe a marca textual do portal com variações para modo compacto ou expandido.
class PortalLogo extends StatelessWidget {
  /// Define se o logotipo é exibido em tamanho compacto.
  final bool compact;

  /// Cria uma instância de [PortalLogo].
  const PortalLogo({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AGMRM',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: compact ? 20 : 24, // text-xl sm:text-2xl
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            shadows: const [
              Shadow(
                color: Color(0xCC000000), // drop-shadow-[0_2px_8px_rgba(0,0,0,0.8)]
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Portal Acadêmico Integrado',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.slate300, // text-slate-300
            fontSize: compact ? 11 : 13, // text-xs sm:text-[13px]
            fontWeight: FontWeight.normal,
            letterSpacing: 0.2,
            shadows: const [
              Shadow(
                color: Color(0xCC000000), // drop-shadow-[0_1px_4px_rgba(0,0,0,0.8)]
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

