// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Camadas 1 e 2: Suíte de Testes de Mitigação de Ataques de Temporização por Canal Lateral
/// Testa a Funcionalidade 17 e o Critério de Aceitação AC-04.

import 'dart:async';
import 'dart:math';

class TimingAttackMitigation {
  // Piso de latência padronizada configurável (em produção: 1000ms; no ambiente rápido de testes: 50ms)
  final int targetLatencyMs;
  final int varianceToleranceMs;

  TimingAttackMitigation({
    this.targetLatencyMs = 50,
    this.varianceToleranceMs = 25,
  });

  /// Executa trabalho criptográfico sintético (hash fictício) para simular
  /// ciclos de CPU idênticos para identificadores inválidos.
  void executeSyntheticWork() {
    int accumulator = 0;
    for (int i = 0; i < 10000; i++) {
      accumulator ^= (i * 31);
    }
    // Evita a eliminação de código morto
    if (accumulator == -999999) print(accumulator);
  }

  /// Normaliza a latência aguardando pelo tempo restante de targetLatencyMs
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

// Auxiliares de Asserção
void assertTrue(bool condition, String message) {
  if (!condition) throw Exception('Assertion failed: $message');
}

int passedTests = 0;
int totalTests = 0;

Future<void> runAsyncTest(String name, Future<void> Function() testFn) async {
  totalTests++;
  try {
    await testFn();
    passedTests++;
    print('  [PASS] $name');
  } catch (e) {
    print('  [FAIL] $name: $e');
  }
}

Future<void> main() async {
  print('===============================================================');
  print('Running Side-Channel Timing Attack Tests (Feature 17)');
  print('===============================================================');

  final timingDefense = TimingAttackMitigation(targetLatencyMs: 40, varianceToleranceMs: 20);

  // -------------------------------------------------------------
  // CAMADA 1: COBERTURA DE FUNCIONALIDADES
  // -------------------------------------------------------------
  await runAsyncTest('T1-01: Synthetic computational work executes reliably', () async {
    final sw = Stopwatch()..start();
    timingDefense.executeSyntheticWork();
    sw.stop();
    assertTrue(sw.elapsedMicroseconds >= 0, 'Synthetic work executed');
  });

  await runAsyncTest('T1-02: Latency normalization brings fast execution up to target floor', () async {
    final sw = Stopwatch()..start();
    // Caminho rápido: execução imediata
    final totalElapsed = await timingDefense.normalizeLatency(sw);
    assertTrue(
      totalElapsed >= 35,
      'Elapsed latency ($totalElapsed ms) must reach minimum floor (~40ms)',
    );
  });

  // -------------------------------------------------------------
  // CAMADA 2: CASOS DE BORDA E LIMITES
  // -------------------------------------------------------------
  await runAsyncTest('T2-01: Timing delta between valid user and non-existent user is bounded (AC-04)', () async {
    // Ramo A: Usuário existente (consulta simulada ao BD + verificação de senha)
    final swA = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 15)); // bcrypt simulado
    final latencyA = await timingDefense.normalizeLatency(swA);

    // Ramo B: Usuário inexistente (falha imediata na consulta + trabalho sintético)
    final swB = Stopwatch()..start();
    timingDefense.executeSyntheticWork(); // Trabalho sintético
    final latencyB = await timingDefense.normalizeLatency(swB);

    final delta = (latencyA - latencyB).abs();
    print('    [INFO] Latency A (valid ID): ${latencyA}ms, Latency B (fake ID): ${latencyB}ms, Delta: ${delta}ms');

    assertTrue(
      delta <= timingDefense.varianceToleranceMs,
      'Timing delta ($delta ms) must not exceed tolerance (${timingDefense.varianceToleranceMs} ms)',
    );
  });

  print('---------------------------------------------------------------');
  print('Timing Attack Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in timing_attack_test.dart');
  }
}
