#!/usr/bin/env bash
set -euo pipefail

# Strict drift enforcement for dev/test (RG scope).
# Usage: ./scripts/deploy/apply_rg.sh <resource_group> <location> [params_file]

RG="${1:?resource_group required}"
LOCATION="${2:?location required}"
PARAMS_FILE="${3:-iac/params.dev.json}"

# Guardrail: require RG tag IAC=true (prevents accidental Complete-mode deletes)
IAC_TAG=$(az group show -n "$RG" --query "tags.IAC" -o tsv 2>/dev/null || true)
if [ "$IAC_TAG" != "true" ]; then
  echo "ERROR: Resource group '$RG' must be tagged IAC=true before running Complete-mode apply." >&2
  exit 1
fi

echo "Applying deployment (Complete mode) for iac/main.rg.bicep in $RG ($LOCATION) using $PARAMS_FILE"
az deployment group create \
  -g "$RG" \
  -l "$LOCATION" \
  -f iac/main.rg.bicep \
  -p "@${PARAMS_FILE}" \
  --mode Complete
