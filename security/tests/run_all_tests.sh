// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
#!/usr/bin/env bash
set -eo pipefail

# =============================================================================
# Enterprise Defense-in-Depth Security Test Suite Master Runner
# Author: Alex Gabriel Soares Sousa - RA: 24802449
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================================"
echo "Starting Enterprise Security Architecture End-to-End Verification"
echo "Author: Alex Gabriel Soares Sousa - RA: 24802449"
echo "Target: $SCRIPT_DIR"
echo "================================================================================"

# Execute unified Dart E2E Test Suite Runner (which orchestrates both Dart & Java suites)
set +e
dart "$SCRIPT_DIR/e2e_test_runner.dart" "$@"
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "================================================================================"
  echo "CRITICAL: Security Test Suite FAILED with exit code $EXIT_CODE"
  echo "================================================================================"
  exit $EXIT_CODE
fi

echo ""
echo "================================================================================"
echo "End-to-End Verification Completed Successfully with 100% Pass Rate."
echo "================================================================================"
exit 0
