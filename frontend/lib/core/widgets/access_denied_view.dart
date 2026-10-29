import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Shared visual treatment for access restrictions across all user portals.
class AccessDeniedView extends StatelessWidget {
  final String message;
  final bool fullPage;
  final VoidCallback? onReturn;

  const AccessDeniedView({
    super.key,
    required this.message,
    this.fullPage = false,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    if (!fullPage) {
      return _buildCard(context, embedded: true);
    }

    return Scaffold(
      backgroundColor: InstColors.stone,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: InstColors.headerBg,
        foregroundColor: InstColors.ink,
        elevation: 0,
        title: Text('Acesso restrito', style: InstText.pageTitle()),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: InstColors.border),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildCard(context, embedded: false),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required bool embedded}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(embedded ? 24 : 32),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: InstColors.stoneActive,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 27,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            embedded ? 'Área não disponível' : 'Verifique seu acesso',
            textAlign: TextAlign.center,
            style: jakarta(
              size: embedded ? 17 : 20,
              weight: FontWeight.w700,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: jakarta(size: 13, color: InstColors.muted, height: 1.55),
          ),
          if (!embedded && onReturn != null) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReturn,
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('Voltar ao login'),
                style: FilledButton.styleFrom(
                  backgroundColor: InstColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: jakarta(size: 13, weight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
