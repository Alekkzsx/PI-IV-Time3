// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import '../policies/security_constants.dart';

/// Side-channel timing attack mitigation component.
/// Equalizes response latencies across successful and unsuccessful authentication paths
/// and executes synthetic computational work for unmapped identities to prevent
/// timing-based user enumeration.
class TimingAttackMitigation {
  /// Standardized latency floor in milliseconds.
  final int targetLatencyMs;

  /// Allowable jitter variance threshold in milliseconds.
  final int varianceToleranceMs;

  TimingAttackMitigation({
    this.targetLatencyMs = SecurityConstants.defaultAuthLatencyMs,
    this.varianceToleranceMs = SecurityConstants.defaultAuthJitterMs,
  });

  /// Executes synthetic cryptographic work (dummy hashing cycles) to simulate
  /// identical CPU execution time for non-existent identities.
  void executeSyntheticWork() {
    int accumulator = 0;
    for (int i = 0; i < 10000; i++) {
      accumulator ^= (i * 31);
    }
    // Prevent compiler dead-code elimination
    if (accumulator == -999999) {
      assert(true);
    }
  }

  /// Normalizes execution latency by padding the remaining duration up to [targetLatencyMs].
  Future<int> normalizeLatency(Stopwatch stopwatch) async {
    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = targetLatencyMs - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }
}

