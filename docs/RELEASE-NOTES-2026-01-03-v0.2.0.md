# Release Notes — 2026-01-03 (v0.2.0)

## Overview
Added strict drift detection and enforcement workflow for dev/test environments while keeping Marketplace deployments clean and Bicep-first.

## Highlights
- New RG-scope entrypoint (`iac/main.rg.bicep`) for dev/test deployments using the same RFC-64 parameters.
- Strict enforcement scripts (Complete mode) for CI/CD:
  - `scripts/deploy/what_if_rg.sh` for what-if drift detection.
  - `scripts/deploy/apply_rg.sh` for apply in CD/manual workflows.
- README updated with dev/test strict enforcement instructions.

## Testing
- `az bicep build -f iac/main.bicep --outdir /tmp/bicep`
- `az bicep build -f iac/main.rg.bicep --outdir /tmp/bicep`

## Notes
- Strict enforcement uses Complete mode at RG scope; ensure the RG contains only managed resources to avoid accidental deletions.

