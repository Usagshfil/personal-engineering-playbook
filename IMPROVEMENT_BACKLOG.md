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

- [ ] **Interactive CLI Scaffolder**: Advanced Node.js or Go binary alternative to the PowerShell script for multi-platform developer machines.
- [x] **Automated Rule Linter**: GitHub Actions workflow (`.github/workflows/validate-playbook.yml`) verifying link integrity, absolute path hygiene, and `agentskills.io` JSON schema compliance across Ubuntu and Windows runners.
- [ ] **Obsidian / Logseq Knowledge Graph Config**: Optional `.obsidian` graph configuration for visualizing interconnected software engineering concepts.
- [x] **Backend Reference API Verifier**: Automated verifier (`tools/test-backend-example.ps1`) executing clean-clone contract, schema, idempotency, and test coverage validation.
- [x] **Priority 4 Database & Persistence 7-Guide Expansion**: Comprehensive 7-guide catalog covering governance, schema design, indexing, safe migrations, transactions/concurrency, connection pooling, and data security/backup/recovery with reference PostgreSQL 16+ implementation (`representative-schema-and-migration.sql`) and automated verifier (`tools/test-database-example.ps1`).
- [ ] **Tier 2 Cross-Domain Consistency Review**: Post-Milestone 4 audit aligning cross-domain patterns across Android, Web, Backend, and Database domains:
  - **F11 — Transaction & Unit-of-Work Boundaries**: Aligning Service Layer Unit of Work (Backend Guide 04), PostgreSQL ACID/OCC (Database Guide 05), and Room Android transactions (Android Guide 04).
  - **F12 — Validation & Error Representation Consistency**: Aligning RFC 9457 Problem Details (Backend Guide 01/04), Zod schema errors (Web Guide 06), and DB check constraint violations (Database Guide 02).
  - **F13 — Authentication, Revocation & Token Family Storage**: Harmonizing OAuth 2.0 / OIDC token rotation (Backend Guide 03), client token storage (Android Guide 06, Web Guide 03), and database token family persistence / revocation blacklists (Database Guide 02/07).
  - **F14 — Retry, Timeout & Circuit Breaker Budgets**: Cross-domain calibration of client timeouts, HTTP retry safety (Backend Guide 05), DB connection checkout / statement timeouts (Database Guide 04/06), and worker queue consumption (`FOR UPDATE SKIP LOCKED`).
  - **F15 — PII Redaction & Audit Ledger Schemas**: Unifying log sanitization filters (Backend Guide 06), database audit ledger schemas (Database Guide 02/07, `audit_ledger`), and client-side privacy boundaries.
