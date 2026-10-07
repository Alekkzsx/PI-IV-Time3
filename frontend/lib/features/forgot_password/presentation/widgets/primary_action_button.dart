// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Botão de ação primária com largura total, tipografia padronizada e
/// suporte a feedback visual de progresso assíncrono.
///
/// Adota a identidade visual escura do projeto ([AppColors.buttonDark]),
/// cantos arredondados de 8px e ícone de seta indicativa para frente.
/// Quando [isLoading] é verdadeiro, desabilita interações e exibe um
/// [CircularProgressIndicator] branco e centralizado.
class PrimaryActionButton extends StatelessWidget {
  /// Texto exibido no centro do botão quando não estiver em carregamento.
  final String label;

  /// Ação disparada ao pressionar o botão, ou `null` caso esteja desabilitado.
  final VoidCallback? onPressed;

  /// Indica se o botão está processando uma ação assíncrona, desabilitando toques adicionais.
  final bool isLoading;

  /// Cria uma nova instância de [PrimaryActionButton].
  ///
  /// Parâmetros:
  /// - [label]: Rótulo textual da ação.
  /// - [onPressed]: Callback acionado pelo toque do usuário.
  /// - [isLoading]: Define se o indicador de progresso circular deve ser exibido (padrão: `false`).
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.buttonDark.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }
}
