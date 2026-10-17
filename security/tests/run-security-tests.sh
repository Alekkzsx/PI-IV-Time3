// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
#!/usr/bin/env bash
set -eo pipefail

# =============================================================================
# Autonomous Security Test Runner Script (spec_report.md reference)
# Author: Alex Gabriel Soares Sousa - RA: 24802449
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v dart >/dev/null 2>&1; then
  echo "Error: 'dart' executable not found in PATH." >&2
  exit 127
fi

exec dart "$SCRIPT_DIR/e2e_test_runner.dart" "$@"
