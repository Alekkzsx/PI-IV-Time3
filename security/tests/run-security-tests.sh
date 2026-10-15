// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
#!/usr/bin/env bash

# =============================================================================
# Autonomous Security Test Runner Script (spec_report.md reference)
# Author: Alex Gabriel Soares Sousa - RA: 24802449
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec dart "$SCRIPT_DIR/e2e_test_runner.dart" "$@"
