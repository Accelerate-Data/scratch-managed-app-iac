# RFC-45: Managed Application Registry

## Decision:
Registry single source of truth for all components and configuration for the managed application.

## Summary
Registry is the source of truth for the following
- Azure resources deployed from the marketplace
- Vibedata application artifacts - container apps, app services, function apps, agents, automation runbooks etc.
- Data Domains artifacts
  - Fabric resources - Tenant, Workspace, Lakehouse
  - Github resources - Repo, branches

Registry is stored in Postgres database.

## Context
- We need a consistent mechanism to get all the deployed components for tasks such as upgrade, health check and monitoring.
- Vibedata registry is used to capture this information.

## Proposal
Registry is the source of truth for the components deployed in the managed app and maps expected components to runtime targets.

**Technology:** PostgreSQL Flexible Server

**Bootstrapping:** See Section 5 (Bootstrap Flow).

**Backup:** Covered by PostgreSQL automated backups (Section 7.1)

**Access Pattern:**
- Bulk operations (bootstrap, health checks): Direct SQL queries
- Single resource updates: Single resource updates: JSONB field updates using optimistic concurrency control (CAS)
- API layer: PostgreSQL -> REST API -> Consumers

**Concurrency Control (Optimistic / CAS):**
- All registry updates MUST use optimistic concurrency control to prevent lost updates when multiple workflows (e.g. streaming updates, health checks) write to the registry.
- registryVersion (etag) is a monotonically increasing integer that is incremented on every successful registry write and used for optimistic concurrency (CAS).
- Writers MUST:
  - Read the current registryVersion
  - Apply a JSONB patch/update
  - Write back using compare-and-set: update succeeds only if registryVersion matches the expected value, and MUST increment registryVersion on success
  - If the update affects 0 rows (etag mismatch), the writer MUST reload the latest registry state, re-evaluate intent (do not replay stale transitions), and then retry or no-op based on the latest state.
  - Bootstrap Exception: Bootstrap is the only operation that creates the registry without CAS validation. It initializes registryVersion to 1. All subsequent updates use CAS.

- Function Apps: query deployed container image tags
- Database schemas: query PostgreSQL for deployed schemas and migrations
- Automation Runbooks: query Automation Account for deployed runbooks
- Logic Apps: query deployed workflow definitions
- AKS workloads: query deployed Helm releases and pods
- AI Foundry: query deployed projects and agents

### 5.3 Validation
**Infrastructure Validation:**
- Compares manifest infrastructure components against discovered Azure resources
- Match criteria: resource exists, resource type matches, resource is accessible

**Application Artifact Validation:**
- Compares manifest application components against deployed artifacts
- Match criteria: artifact deployed, version matches manifest (using `latest` tag)

**Mismatch Handling:**

| Condition | Result |
| --- | --- |
| Infrastructure resource in manifest but not deployed | Deployment fails |
| Infrastructure resource deployed but not in manifest | Deployment fails |
| Application artifact in manifest but not deployed | Deployment fails |
| Application artifact deployed but not in manifest | Deployment fails |
| Version mismatch | Deployment fails |

### 5.4 Registration
**Instance Initialization:**
- Generate unique instanceId (nanoid) for the instance
- Set fqdn to `{instanceId}.vibedata.ai`
- Store instanceId and fqdn in registry
- Set schemaVersion to current schema version
- Set registryVersion to 1
- Initialize healthPolicy with platform defaults
- Initialize updatePolicy with platform defaults
- Initialize networkRetryPolicies with platform defaults
- Initialize instanceLock as empty (no active lock)

**Infrastructure Component Registration:**
For each matched infrastructure resource:
- Generate instance-scoped componentId
- Map manifest component name to componentId
- Record resource ID, resource type
- Record private FQDN, endpoints
- Set component version from manifest

**Application Artifact Registration:**
For each matched application artifact:
- Generate instance-scoped componentId
- Map manifest component name to componentId
- Record deployment target (App Service name, Function App name, AKS namespace, etc.)
- Record artifact reference (container image, runbook name, schema version, etc.)
- Set component version from manifest

**Health Initialization:**
- Execute health check for each component per Section 3
- Set component health status based on result
- Aggregate component health to instance health per Section 3.1

### 5.5 Failure Behavior

| Condition | Result |
| --- | --- |
| Runbook not found in Automation Account | Deployment fails |
| Resource in manifest but not deployed | Deployment fails |
| Resource deployed but not in manifest | Deployment fails |
| Health check fails for any component | Deployment fails |
| Partial registration (some succeed, some fail) | Deployment fails |

- All failures surface to ARM as deployment failure
- Customer sees failure in Azure portal
- No partial success or degraded state allowed
- Recovery: delete managed app and redeploy

### 5.6 Idempotency
- Bootstrap does not support re-run
- Failed deployment requires delete and redeploy
- No registry cleanup or rollback mechanism

## Impact
- None

## Open Questions
