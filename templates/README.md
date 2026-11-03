# Standardized Project Templates Catalog

> **Reusable Engineering Deliverables for Real-World Project Initiation, Architecture, Implementation, and Handover**  
> **Applicability**: Decoupled and standalone. Ready to copy into any new or existing software project repository.

---

## 1. Master Template Index

This directory provides 15 production-grade documentation and operational templates organized across the software engineering project lifecycle:

| Template File | Lifecycle Stage | Primary Purpose | Key Audience |
| :--- | :--- | :--- | :--- |
| **[`01-PROJECT_BRIEF_TEMPLATE.md`](01-PROJECT_BRIEF_TEMPLATE.md)** | Discovery / Initialization | Problem statement, target personas, core value proposition, and MoSCoW scope. | Product Owner, Lead Dev |
| **[`02-REQUIREMENTS_SPEC_TEMPLATE.md`](02-REQUIREMENTS_SPEC_TEMPLATE.md)** | Planning & Requirements | Functional user stories (Gherkin syntax), data invariants, and NFR targets. | Engineers, QA |
| **[`03-TECHNICAL_DESIGN_TEMPLATE.md`](03-TECHNICAL_DESIGN_TEMPLATE.md)** | Architecture & Design | System context, C4 diagrams, sequence flows, STRIDE threat models, and trade-offs. | Architects, Lead Devs |
| **[`04-ADR_TEMPLATE.md`](04-ADR_TEMPLATE.md)** | Architectural Decision | Formal decision records documenting context, drivers, options, and trade-offs. | Architecture Team |
| **[`05-API_SPECIFICATION_TEMPLATE.md`](05-API_SPECIFICATION_TEMPLATE.md)** | Interface Design | REST contracts, headers (`Idempotency-Key`), RFC 9457 error models, cursor pagination. | Backend & Client Devs |
| **[`06-DATABASE_DESIGN_TEMPLATE.md`](06-DATABASE_DESIGN_TEMPLATE.md)** | Data Modeling | 3NF normalized schema, exact data types, declarative constraints, and safe migrations. | Database / Backend Devs |
| **[`07-IMPLEMENTATION_PLAN_TEMPLATE.md`](07-IMPLEMENTATION_PLAN_TEMPLATE.md)** | Implementation Planning | Pre-implementation plan: component breakdown, risk analysis, and RBT test strategy. | Developers, AI Agents |
| **[`08-TASK_DEFINITION_TEMPLATE.md`](08-TASK_DEFINITION_TEMPLATE.md)** | Execution & Tracking | Granular subtask definition with clear preconditions and Definition of Done. | Developers, AI Agents |
| **[`09-TEST_PLAN_TEMPLATE.md`](09-TEST_PLAN_TEMPLATE.md)** | Quality Assurance | Risk-Based Testing strategy, test prioritization, and concrete failure scenarios. | QA Lead, Developers |
| **[`10-TEST_REPORT_TEMPLATE.md`](10-TEST_REPORT_TEMPLATE.md)** | Verification & Evidence | Empirical test execution logs, pass/fail counts, regression proofs, and environment limits. | QA, Tech Lead |
| **[`11-CODE_REVIEW_TEMPLATE.md`](11-CODE_REVIEW_TEMPLATE.md)** | Code Review & QA | Systematic checklist covering architecture, idioms, concurrency, security, and tests. | Peer Reviewers, AI |
| **[`12-SECURITY_REVIEW_TEMPLATE.md`](12-SECURITY_REVIEW_TEMPLATE.md)** | Security & Compliance | OWASP Top 10 checklist, BOLA/IDOR verification, PII redaction, and secret scanning. | SecOps, Tech Lead |
| **[`13-RELEASE_CHECKLIST_TEMPLATE.md`](13-RELEASE_CHECKLIST_TEMPLATE.md)** | Deployment & Release | Pre-flight quality gates, migration execution, health probe verification, and rollback. | Release Coordinator |
| **[`14-INCIDENT_REPORT_TEMPLATE.md`](14-INCIDENT_REPORT_TEMPLATE.md)** | Operations & Reliability | Post-mortem root cause analysis (5 Whys), timeline of events, and preventative action items. | SRE, Engineering Team |
| **[`15-RETROSPECTIVE_TEMPLATE.md`](15-RETROSPECTIVE_TEMPLATE.md)** | Continuous Improvement | Milestone evaluation: delivery assessment, friction points, learnings, and next actions. | Entire Team |

---

## 2. Project Profile Template Selector Matrix

Different projects require different levels of documentation rigor. Use this matrix to select the recommended template set based on project complexity:

| Template | Small Project (e.g. Android Utility) | Medium Project (e.g. Web + REST API) | Complex Project (e.g. Distributed Platform) |
| :--- | :---: | :---: | :---: |
| `01-PROJECT_BRIEF` | **Mandatory** | **Mandatory** | **Mandatory** |
| `02-REQUIREMENTS_SPEC` | Recommended (Simplified) | **Mandatory** | **Mandatory** |
| `03-TECHNICAL_DESIGN` | Optional (Combined in Brief) | **Mandatory** | **Mandatory** |
| `04-ADR` | Optional (Only for non-obvious) | **Mandatory** (Key choices) | **Mandatory** (All architecture choices) |
| `05-API_SPECIFICATION` | Not Applicable | **Mandatory** | **Mandatory** |
| `06-DATABASE_DESIGN` | Recommended (Room entities) | **Mandatory** (PostgreSQL) | **Mandatory** (Distributed schemas) |
| `07-IMPLEMENTATION_PLAN` | **Mandatory** (For non-trivial) | **Mandatory** | **Mandatory** |
| `08-TASK_DEFINITION` | Recommended | **Mandatory** | **Mandatory** |
| `09-TEST_PLAN` | Recommended | **Mandatory** | **Mandatory** |
| `10-TEST_REPORT` | **Mandatory** (CI / Verification) | **Mandatory** | **Mandatory** |
| `11-CODE_REVIEW` | **Mandatory** (PR gate) | **Mandatory** | **Mandatory** |
| `12-SECURITY_REVIEW` | Recommended | **Mandatory** | **Mandatory** |
| `13-RELEASE_CHECKLIST` | Recommended | **Mandatory** | **Mandatory** |
| `14-INCIDENT_REPORT` | As needed | As needed | **Mandatory** (Post-outage) |
| `15-RETROSPECTIVE` | Recommended | **Mandatory** | **Mandatory** |

---

## 3. How to Use These Templates in a New Project

1. **Copy the Chosen Templates**: Copy the relevant template files into your project's `docs/` or `templates/` directory.
2. **Fill Placeholders**: Replace bracketed text (e.g. `[Project Name]`, `[YYYY-MM-DD]`) with your project-specific details.
3. **Commit with Project Documentation**: Track filled templates directly in your target repository's version control.
4. **Reference in AI Instructions**: Point AI coding agents (via `CLAUDE.md`, `.cursorrules`, or `AGENTS.md`) to the templates when asking them to plan, implement, or review code.
