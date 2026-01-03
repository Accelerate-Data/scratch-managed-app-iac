#!/usr/bin/env bash
set -euo pipefail

# Strict drift detection for dev/test (RG scope).
# Usage: ./scripts/deploy/what_if_rg.sh <resource_group> <location> [params_file] [out_file]

RG="${1:?resource_group required}"
LOCATION="${2:?location required}"
PARAMS_FILE="${3:-iac/params.dev.json}"
OUT_FILE="${4:-tests/state_check/what-if.json}"

echo "Running what-if (Complete mode) for iac/main.rg.bicep in $RG ($LOCATION) using $PARAMS_FILE"
az deployment group what-if \
  -g "$RG" \
  -l "$LOCATION" \
  -f iac/main.rg.bicep \
  -p "@${PARAMS_FILE}" \
  --mode Complete \
  --result-format Full \
  --no-pretty-print \
  > "$OUT_FILE"

echo "What-if result saved to $OUT_FILE"
