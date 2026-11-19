# Framework Improvement Backlog

This backlog tracks future ideas, planned technology modules, and candidate skills for the Personal Software Engineering Playbook.

---

## 🔮 Future Technology Extensions (Post-v1.0.0)

| Priority | Extension Area | Scope & Objectives | Candidate Trigger |
| :---: | :--- | :--- | :--- |
| **P2** | **iOS & Swift Development** | Swift 6 concurrency, SwiftUI architecture, SwiftData, Clean MVVM, App Store distribution. | When starting native iOS apps. |
| **P2** | **Flutter & Dart** | Cross-platform state management (Bloc / Riverpod), widget tree optimization, platform channels. | When evaluating cross-platform UI. |
| **P3** | **Python Engineering** | Modern typing (`mypy`), FastAPI, Poetry/uv packaging, PyTest fixtures, asynchronous programming. | When building data processing or ML backend tools. |
| **P3** | **DevOps & CI/CD Pipelines** | GitHub Actions workflows, Docker containerization, automated testing gates, automated semantic versioning. | When deploying services to cloud infrastructure. |
| **P4** | **Applied Machine Learning & LLMs** | Prompt engineering standards, RAG architectures, vector database indexing, evaluation pipelines. | When building AI-augmented software. |

---

## 🛠️ Tooling & Framework Enhancements

- [x] **Static Documentation Site (Mintlify)**: Configured full Mintlify static documentation site (`docs.json`, `index.mdx`, `.mintignore`) with 5 tabs, responsive search, KaTeX math rendering, and automated broken-link checking (`mint validate` and `mint broken-links` passing with 0 errors).
- [ ] **Interactive CLI Scaffolder**: Advanced Node.js or Go binary alternative to the PowerShell script for multi-platform developer machines.
- [x] **Automated Rule Linter**: GitHub Actions workflow (`.github/workflows/validate-playbook.yml`) verifying link integrity, absolute path hygiene, and `agentskills.io` JSON schema compliance across Ubuntu and Windows runners.
- [ ] **Obsidian / Logseq Knowledge Graph Config**: Optional `.obsidian` graph configuration for visualizing interconnected software engineering concepts.
- [x] **Backend Reference API Verifier**: Automated verifier (`tools/test-backend-example.ps1`) executing clean-clone contract, schema, idempotency, and test coverage validation.
- [x] **Priority 4 Database & Persistence 7-Guide Expansion**: Comprehensive 7-guide catalog covering governance, schema design, indexing, safe migrations, transactions/concurrency, connection pooling, and data security/backup/recovery with reference PostgreSQL 16+ implementation (`representative-schema-and-migration.sql`) and automated verifier (`tools/test-database-example.ps1`).
- [x] **Tier 2 Cross-Domain Consistency Review (Milestone 4.3)**: Complete cross-domain integration specification in `06-technologies/CROSS_DOMAIN_CONSISTENCY.md` covering:
  - **Authoritative Ownership Matrix**: Clear single-owner allocation across database constraints, request parsing, transaction boundaries, BOLA authorization, session state, audit ledgers, timeouts, and caching.
  - **Cross-Domain Conflict & Harmonization Matrix**: Unified defaults for timeouts, RFC 9457 problem details, token lifespans, minor units money, timestamp semantics, idempotency, and jittered retries.
  - **F11 — Transaction & Unit-of-Work Boundaries**: Service Layer Unit of Work, PostgreSQL ACID/OCC, Room Android transactions, and the **Transactional Outbox Pattern** with idempotent consumers.
  - **F12 — Validation & Error Representation Consistency**: 5-stage validation lifecycle, suppression of raw SQL/schema leakage, and standard RFC 9457 error contracts.
  - **F13 — Authentication, Revocation & Token Family Storage**: End-to-end token family rotation, SHA-256 hashed storage, atomic single-use rotation, 30s concurrent refresh grace, whole-family revocation on reuse, and client storage isolation (HttpOnly cookies vs Android KeyStore).
  - **F14 — Retry, Timeout & Circuit Breaker Budgets**: Unified hierarchical deadline budget ($\text{Client (5s)} > \text{Ingress (4s)} > \text{DB Statement (2s)} > \text{Outbound HTTP (1.5s)}$), full jitter backoff, and circuit breaker tripping.
  - **F15 — PII Redaction & Audit Ledger Schemas**: Four-tier telemetry taxonomy (operational, security, audit ledger, traces) and payload delta capturing rules without credential leakage.
  - **Vertical Slice Walkthrough**: Step-by-step trace of Order Placement and Stock Reservation Flow across client, transport, controller, service, database locks, outbox worker, and audit trail.
- [x] **F21 — PostgreSQL 16+ Container Runtime Verification Test Harness**: Provision a disposable containerized PostgreSQL 16+ test environment (e.g. Testcontainers / GitHub Actions Postgres service) executing the reference SQL (`representative-schema-and-migration.sql`) to verify actual clean DB initialization, sequential migration passes, constraint enforcement, role permission boundaries, OCC conflict handling, and `SKIP LOCKED` worker concurrency.
- [ ] **F22 — Automated Backup Restoration Drill Execution**: Build and execute an automated CI/CD pipeline drill restoring base backups and continuous WAL archives into an isolated sandbox, measuring actual RPO and RTO metrics against production targets.
- [x] **Milestone 5.0: Playbook Finalization for Real-World Project Use**:
  - **F23 (Ownership & Enforcement Boundaries)**: Replaced single-column ownership model with a 4-dimensional matrix (Policy Owner, Source of Truth, Enforcement Layer, Validation Responsibilities across Client, Gateway, Service, and DB Engine).
  - **F24 (Refresh Token Concurrency & Replay State Machine)**: Formally specified token-family state machine (`ISSUED` $\to$ `ACTIVE` $\to$ `CONSUMED` / `REVOKED`) with Mermaid diagram and operational trade-offs of grace periods vs. atomic database advisory locks.
  - **F25 (Financial Rounding Policy & Regulatory Nuance)**: De-dogmatized Banker's Rounding; distinguished `ROUND_HALF_EVEN` for accounting from `ROUND_HALF_UP` for statutory tax compliance (HMRC/IRS/VAT), with strict pipeline boundary rounding.
  - **F26 (Distributed Deadline Propagation & Cancellation)**: Specified standard headers (`X-Request-Deadline`, `X-Request-Timeout-Ms`), context cancellation mechanics (`AbortSignal`, Coroutine cancellation), and downstream DB query cancellation (`pg_cancel_backend`).
  - **F27 (Transactional Outbox Operational Realities)**: Addressed at-least-once duplicates, consumer inbox deduplication, aggregate partition ordering, poison message handling with DLQ, and automated table cleanup/archival.
  - **F28 (Executable Integration Evidence)**: Explicitly distinguished conceptual architectural walkthroughs from executable integration test harnesses (`representative-api.test.ts` and `verify-postgres-runtime.sh`).
  - [x] **Phase 2 & 3**: Runtime verification scripts & GitHub Actions CI upgrades (Node 20 + PostgreSQL 16 service container).
  - [x] **Phase 4**: Reusable Project Bootstrap Workflow (`docs/guides/PROJECT_BOOTSTRAP_WORKFLOW.md`).
  - [x] **Phase 5**: Reusable Project Templates catalog (15 templates in `templates/` + `templates/README.md`).
  - [x] **Phase 6**: Real-world project scenario evaluations (`docs/reports/PROJECT_SCENARIOS_EVALUATION.md`).
  - [x] **Phase 7**: Root `README.md` Quick Start overhaul and Final Readiness Report (`docs/reports/FINAL_READINESS_REPORT.md`).
- [x] **Gitflow Workflow Reference Integration**: Added authoritative [Atlassian Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) to `05-skills/git-and-version-control/SKILL.md` with CLI commands, branching diagram, and decision matrix.
- [x] **Agile Engineering & Scrum Delivery Standards**: Created `docs/guides/AGILE_SCRUM_GUIDE.md` covering 2-week sprint cadences, 5 Scrum ceremonies, INVEST story criteria, BDD Given-When-Then acceptance criteria, Definition of Ready/Done, and 12-stage SDLC phase reconciliation.
- [x] **Scrum Master & Agile Coach Agent Role**: Created `04-agents/roles/scrum-master-agent.md` providing an authoritative persona and operational instructions for sprint facilitation, asynchronous standup synthesis, blocker removal, and DoD enforcement.
- [x] **Tier 2 Android Mobile Engineering Standards Expansion**: Authored 3 comprehensive guides (`09-offline-first-and-sync.md`, `10-mobile-testing-and-qa.md`, `11-release-management-and-cicd.md`) adhering to the 9-part pedagogical schema, establishing standards for Room SSOT + WorkManager sync engines, Compose UI test + Maestro YAML E2E + Roborazzi screenshot testing pyramids, and AAB + R8 Full Mode + Keystore CI signing + Fastlane progressive staged rollouts.
