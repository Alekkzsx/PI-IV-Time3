// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 2>/dev/null || :
#!/usr/bin/env bash
set -e

# =============================================================================
# Enterprise Defense-in-Depth Security Test Suite Master Runner
# Author: Alex Gabriel Soares Sousa - RA: 24802449
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "================================================================================"
echo "Starting Enterprise Security Architecture End-to-End Verification"
echo "Author: Alex Gabriel Soares Sousa - RA: 24802449"
echo "Target: $SCRIPT_DIR"
echo "================================================================================"

# Execute unified Dart E2E Test Suite Runner (which orchestrates both Dart & Java suites)
dart "$SCRIPT_DIR/e2e_test_runner.dart"

echo ""
echo "================================================================================"
echo "End-to-End Verification Completed Successfully with 100% Pass Rate."
echo "================================================================================"
