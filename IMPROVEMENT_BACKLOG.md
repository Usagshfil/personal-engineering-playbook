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
- [ ] **Tier 2 Cross-Domain Consistency Review**: Post-Milestone 4 audit aligning transaction, validation, auth, error handling, logging, and retry rules across Android, Web, Backend, and Database domains.
- [ ] **Priority 4 Database & Persistence 7-Guide Expansion**: Comprehensive 7-guide catalog covering governance, schema design, indexing, safe migrations, transactions/concurrency, connection pooling, and data security/backup/recovery with executable SQL migration tests.
