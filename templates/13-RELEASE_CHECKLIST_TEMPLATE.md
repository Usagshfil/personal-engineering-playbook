# Production Release Checklist: [Version / Release Name]

> **Target Release Date**: [YYYY-MM-DD]  
> **Release Coordinator**: [Lead Engineer]  
> **Target Version**: [e.g. v1.2.0]  
> **Release Status**: Ready for Deployment / Deployed / Rolled Back  

---

## 1. Pre-Deployment Quality Gates

- [ ] **Clean-Clone Test Suite**: All unit, integration, and contract tests pass on a fresh clone with exit code 0.
- [ ] **Static Code Analysis & Linting**: Linter passes with zero errors and zero warnings.
- [ ] **Security Audit**: Dependency vulnerability scan reports zero high/critical CVEs; zero committed secrets.
- [ ] **Database Migrations Verified**:
  - [ ] Expand-and-contract migration tested against staging clone.
  - [ ] Lock timeout (`SET lock_timeout = '2s'`) verified.
  - [ ] Rollback script verified and ready.
- [ ] **Documentation & Governance**:
  - [ ] `VERSION.md` bumped according to Semantic Versioning.
  - [ ] `CHANGELOG.md` updated with user-facing highlights and breaking changes.
  - [ ] `PROJECT_PROGRESS.md` status updated.

---

## 2. Deployment Execution Protocol

1. **Notify Stakeholders**: Post deployment announcement in `#releases` channel.
2. **Execute Database Migrations**: Run migration container/runner with `migration_runner` credentials.
3. **Deploy Service / Application Pods**: Deploy new container image / Android APK build via blue-green or rolling update.
4. **Verify Health Probes**:
   - [ ] `/startupz` probe passes.
   - [ ] `/readyz` probe passes.
   - [ ] `/healthz` probe returns HTTP 200 OK.

---

## 3. Post-Deployment Smoke Verification

- [ ] **Authentication Flow**: Login, token refresh, and logout verified on production.
- [ ] **Core Business Transaction**: Happy path order placement / mutation executed and verified.
- [ ] **Telemetry & Error Logging**: Verify Datadog / Sentry / CloudWatch receiving clean logs with zero error spikes.
- [ ] **Latency & Resource Monitoring**: CPU, memory, and database connection pool saturation remain within normal baselines.

---

## 4. Rollback Strategy & Emergency Plan

* **Rollback Trigger Criteria**: Error rate $> 1.0\%$ over 5 minutes, or database lock saturation $> 80\%$.
* **Rollback Command Sequence**:
  ```bash
  # Step 1: Rollback application deployment to previous stable image tag
  kubectl rollout undo deployment/api-service
  
  # Step 2: If migration was non-breaking (Phase 1 Expand), no immediate DDL rollback needed
  # If emergency schema rollback required:
  psql -h $PGHOST -U migration_runner -d $PGDATABASE -f migrations/rollback_v1.2.0.sql
  ```
* **Incident Commander**: [Name / Contact]
