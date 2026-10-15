// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Master E2E Security Test Suite Runner
/// Orchestrates execution across all Dart and Java test tiers and validates Feature 25.

import 'dart:io';
import 'rate_limiter_test.dart' as rate_limiter;
import 'token_lifecycle_test.dart' as token_lifecycle;
import 'input_sanitizer_test.dart' as input_sanitizer;
import 'password_entropy_test.dart' as password_entropy;
import 'timing_attack_test.dart' as timing_attack;
import 'CrossFeatureSecurityTest.dart' as cross_feature;
import 'RealWorldAttackWorkloadTest.dart' as workload;

void main() async {
  print('╔══════════════════════════════════════════════════════════════════════════╗');
  print('║ AGMRM Educational Platform — Unified E2E Security Test Suite Runner       ║');
  print('║ Author: Alex Gabriel Soares Sousa — RA: 24802449                         ║');
  print('║ Target Module: security/tests/                                           ║');
  print('╚══════════════════════════════════════════════════════════════════════════╝');
  print('');

  final stopwatch = Stopwatch()..start();
  final List<String> passedSuites = [];
  final List<String> failedSuites = [];

  Future<void> runSuite(String suiteName, Future<void> Function() runner) async {
    print('>>> Executing Suite: $suiteName');
    try {
      await runner();
      passedSuites.add(suiteName);
      print('>>> SUITE PASSED: $suiteName\n');
    } catch (e, stack) {
      failedSuites.add(suiteName);
      print('>>> SUITE FAILED: $suiteName');
      print('Error: $e\n$stack\n');
    }
  }

  // Tier 1 & 2: Rate Limiting
  await runSuite('Rate Limiter & Brute-Force Suite (Features 12-15)', () async {
    rate_limiter.main();
  });

  // Tier 1 & 2: Token Lifecycle
  await runSuite('Token Lifecycle & OTP Revocation Suite (Features 19-21)', () async {
    token_lifecycle.main();
  });

  // Tier 1 & 2: Input Sanitization
  await runSuite('Input Sanitization & Attack Neutralization Suite (Features 6-9)', () async {
    input_sanitizer.main();
  });

  // Tier 1 & 2: Password Entropy
  await runSuite('Password Entropy & Complexity Suite (Features 10-11)', () async {
    password_entropy.main();
  });

  // Tier 1 & 2: Side-Channel Timing Defense
  await runSuite('Side-Channel Timing Mitigation Suite (Feature 17)', () async {
    await timing_attack.main();
  });

  // Tier 1 & 2: Anti-Enumeration & Generic Feedback (Flutter Test Runner)
  await runSuite('Anti-Enumeration & Generic Feedback Suite (Features 16, 18)', () async {
    final res = await Process.run(
      'flutter',
      ['test', 'tests/generic_feedback_test.dart'],
      workingDirectory: '/home/alekkzsx/Documents/Github/PI-IV-Time3/security',
    );
    stdout.write(res.stdout);
    if (res.exitCode != 0) {
      throw Exception('Flutter test failed with exit code ${res.exitCode}:\n${res.stderr}');
    }
  });

  // Tier 1 & 2: Institutional Security Constants (Flutter Test Runner)
  await runSuite('Security Constants & Invariants Suite (Features 1-3)', () async {
    final res = await Process.run(
      'flutter',
      ['test', 'tests/security_constants_test.dart'],
      workingDirectory: '/home/alekkzsx/Documents/Github/PI-IV-Time3/security',
    );
    stdout.write(res.stdout);
    if (res.exitCode != 0) {
      throw Exception('Flutter test failed with exit code ${res.exitCode}:\n${res.stderr}');
    }
  });

  // Tier 3: Pairwise Combinations
  await runSuite('Cross-Feature Pairwise Security Suite (Tier 3)', () async {
    await cross_feature.main();
  });

  // Tier 4: Real-World Workloads & Governance
  await runSuite('Real-World Adversarial Attack Workloads & Governance Suite (Tier 4)', () async {
    workload.main();
  });

  // Server Middleware & Java Security Suite
  await runSuite('Java Server Security Middleware & Governance Suite (Features 22-24, 3, 4)', () async {
    final tempDir = Directory.systemTemp.createTempSync('sectest');
    try {
      final javac = await Process.run('javac', [
        '-d',
        tempDir.path,
        'security/tests/SecurityServerTestSuite.java',
      ]);
      if (javac.exitCode != 0) {
        throw Exception('javac compilation failed:\n${javac.stderr}');
      }
      final java = await Process.run('java', [
        '-cp',
        tempDir.path,
        'security.tests.SecurityServerTestSuite',
      ]);
      stdout.write(java.stdout);
      if (java.exitCode != 0) {
        throw Exception('Java suite failed with exit code ${java.exitCode}:\n${java.stderr}');
      }
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  });

  stopwatch.stop();

  print('==========================================================================');
  print('E2E TEST EXECUTION SUMMARY');
  print('==========================================================================');
  print('Total Suites Executed: ${passedSuites.length + failedSuites.length}');
  print('Suites Passed:         ${passedSuites.length}');
  print('Suites Failed:         ${failedSuites.length}');
  print('Elapsed Execution Time: ${stopwatch.elapsedMilliseconds} ms');
  print('==========================================================================');

  if (failedSuites.isNotEmpty) {
    print('CRITICAL: The following test suites failed:');
    for (final s in failedSuites) {
      print('  - $s');
    }
    exit(1);
  } else {
    print('ALL E2E TEST SUITES PASSED WITH 100% SUCCESS RATE.');
    exit(0);
  }
}
