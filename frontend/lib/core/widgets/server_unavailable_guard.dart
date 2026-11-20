// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/material.dart';
import '../network/server_health_monitor.dart';
import '../state/app_user_session.dart';
import '../theme/institutional_tokens.dart';
import '../theme/jakarta_text.dart';

/// Guarda global Fail-Closed que envolve toda a árvore do aplicativo
/// (tanto deslogado na tela de login quanto logado em qualquer portal).
///
/// Quando o Servidor Java (:8080) ou o Backend Acadêmico (:3001) estiver
/// desligado ou fora do ar, bloqueia 100% da interface e informa exatamente
/// qual serviço está indisponível.
class ServerUnavailableGuard extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final ServerHealthMonitor? monitor;

  const ServerUnavailableGuard({
    super.key,
    required this.child,
    this.enabled = true,
    this.monitor,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final effectiveMonitor = monitor ?? ServerHealthMonitor.instance;
    final listenable = Listenable.merge([
      effectiveMonitor,
      AppUserSession.instance,
    ]);

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final snapshot = effectiveMonitor.snapshot;
        if (!snapshot.isBlocking) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: FocusScope(
                canRequestFocus: false,
                descendantsAreFocusable: false,
                child: IgnorePointer(
                  ignoring: true,
                  child: AbsorbPointer(absorbing: true, child: child),
                ),
              ),
            ),
            PopScope(
              canPop: false,
              child: Material(
                color: InstColors.stone,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: snapshot.state == ServerConnectionState.checking
                            ? _buildCheckingCard()
                            : _buildOfflineCard(
                                snapshot: snapshot,
                                monitor: effectiveMonitor,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verificando conexão com o servidor e o backend...',
            textAlign: TextAlign.center,
            style: jakarta(
              size: 16,
              weight: FontWeight.w700,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aguarde enquanto confirmamos a disponibilidade do Servidor Java (:8080) e do Backend Acadêmico (:3001).',
            textAlign: TextAlign.center,
            style: jakarta(size: 13, color: InstColors.muted, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard({
    required ServerHealthSnapshot snapshot,
    required ServerHealthMonitor monitor,
  }) {
    final reason =
        snapshot.failureReason ??
        ServerHealthMonitor.buildFailureReason(
          authServerOnline: snapshot.authServerOnline,
          academicServerOnline: snapshot.academicServerOnline,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: InstColors.dangerBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: InstColors.danger.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 30,
              color: InstColors.danger,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Serviço fora do ar',
            textAlign: TextAlign.center,
            style: jakarta(
              size: 21,
              weight: FontWeight.w700,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: jakarta(
              size: 13.5,
              weight: FontWeight.w500,
              color: InstColors.body,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: InstColors.stone,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: InstColors.border),
            ),
            child: Column(
              children: [
                _ServiceStatusRow(
                  name: 'Servidor Java (:8080)',
                  online: snapshot.authServerOnline,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: InstColors.border),
                ),
                _ServiceStatusRow(
                  name: 'Backend Acadêmico (:3001)',
                  online: snapshot.academicServerOnline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A operação foi pausada por segurança. Tentando reconectar automaticamente...',
            textAlign: TextAlign.center,
            style: jakarta(size: 12.5, color: InstColors.muted, height: 1.5),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: snapshot.isRechecking
                  ? null
                  : () => unawaited(monitor.checkNow()),
              icon: snapshot.isRechecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                snapshot.isRechecking
                    ? 'Verificando conexão...'
                    : 'Tentar reconectar agora',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: InstColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: jakarta(size: 13.5, weight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          if (AppUserSession.instance.isAuthenticated) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AppUserSession.instance.expire(),
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: const Text('Encerrar sessão local'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: InstColors.ink,
                  side: const BorderSide(color: InstColors.borderStrong),
                  padding: const EdgeInsets.symmetric(vertical: 13),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: InstColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: InstColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

class _ServiceStatusRow extends StatelessWidget {
  final String name;
  final bool online;

  const _ServiceStatusRow({required this.name, required this.online});

  @override
  Widget build(BuildContext context) {
    final badgeBg = online ? InstColors.successBg : InstColors.dangerBg;
    final badgeFg = online ? InstColors.success : InstColors.danger;

    return Row(
      children: [
        Icon(
          online ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: badgeFg,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: jakarta(
              size: 13,
              weight: FontWeight.w600,
              color: InstColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            online ? 'Online' : 'Desligado ou fora do ar',
            style: jakarta(size: 11.5, weight: FontWeight.w600, color: badgeFg),
          ),
        ),
      ],
    );
  }
}
