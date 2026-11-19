# Personal Software Engineering Playbook

> **A permanent, educational, technology-agnostic engineering framework with specialized extensions for modern software development.**  
> **Status**: Verified Production-Ready Reference System (`v1.0.0-rc.1`)  
> **Target Audience**: Intermediate Developers & AI Coding Agents (Google Antigravity, Cursor, Claude Code, GitHub Copilot).

---

## ⚡ 30-Second Quick Start: Using This Playbook for a New Project

Starting a new project? Follow these 3 simple steps:

1. **Copy the Universal Agent Governance**:
   Copy [`AGENTS.md`](AGENTS.md) into the root of your new project repository to establish non-negotiable engineering safety, inspection gates, and verification rules.
2. **Follow the Reusable 8-Stage Bootstrap Workflow**:
   Open [`docs/guides/PROJECT_BOOTSTRAP_WORKFLOW.md`](docs/guides/PROJECT_BOOTSTRAP_WORKFLOW.md) for step-by-step guidance from problem discovery and project classification to CI setup and production release.
3. **Select Your Project Templates**:
   Visit the [`templates/`](templates/README.md) catalog to copy production-ready templates for your Project Brief, Architecture Design, API Specs, and Test Plans.

> [!TIP]
> **Interactive Documentation Site**: You can browse the entire playbook locally with full-text search, dark/light themes, and interactive components by running `mint dev` (hosted on [Mintlify](https://mintlify.com)).

---

## 🧭 The 5 Core Engineering Questions Answered

This playbook is organized around answering five fundamental questions for any software initiative:

```
+---------------------------------------------------------------------------------------------------------------+
|                                    THE 5 CORE ENGINEERING PILLARS                                             |
|                                                                                                               |
|  1. WHAT should I do?     ===> Core Principles, 12-Stage SDLC, Architecture Fit Matrix                        |
|  2. HOW should I do it?   ===> Tier 2 Tech Standards (Android, Web, Backend, Database) & Cross-Domain     |
|  3. WHO should do it?     ===> AI Agent Roles, Tool Adapters, 4-Level Instruction Hierarchy                   |
|  4. HOW do I know it works? => Risk-Based Testing, Quality Gates, 5-Suite Automated Verifiers, CI           |
|  5. HOW do I bootstrap?   ===> 8-Stage Lifecycle Guide, 15 Standalone Templates, Scenarios Evaluation        |
+---------------------------------------------------------------------------------------------------------------+
```

---

### 1. What Should I Do? (Principles, Lifecycle & Architecture)
* **Timeless Engineering Principles**: Master Clean Code, Modularity, Performance, and Simplicity in [`01-principles/`](01-principles/README.md). Every principle follows a 9-part pedagogical schema with Good/Bad code examples.
* **12-Stage Software Development Lifecycle (SDLC)**: Explore strict Phase Gates (Discovery $\to$ Architecture $\to$ Implementation $\to$ QA $\to$ Release $\to$ Maintenance) in [`02-lifecycle/`](02-lifecycle/README.md).
* **Agile Engineering & Scrum Delivery**: Master iterative 2-week sprint cadences, ceremony timeboxes, INVEST story criteria, Definition of Ready/Done, and SDLC phase reconciliation in [`docs/guides/AGILE_SCRUM_GUIDE.md`](docs/guides/AGILE_SCRUM_GUIDE.md).
* **Architecture Pattern Fit Matrix**: Select the right architecture (Layered, Clean, Event-Driven, Modular) based on project complexity in [`03-architecture/`](03-architecture/README.md).
* **Security & Privacy Baseline**: Enforce STRIDE threat modeling, least privilege, zero hardcoded secrets, and PII protection in [`10-security-and-privacy/`](10-security-and-privacy/README.md).

### 2. How Should I Do It? (Technology Standards & Cross-Domain Harmonization)
* **Android Development (Priority 1)**: 11 comprehensive guides covering Modern Kotlin 2.0, Jetpack Compose, Coroutines/StateFlow, Room persistence, Dagger Hilt, Retrofit API design, Gradle Version Catalogs, Offline-First Sync Engines (WorkManager & tombstones), Mobile UI/E2E Testing (Compose Test, Roborazzi, Maestro), and Release Engineering (AAB, R8 Full Mode, Keystore security, Fastlane) in [`06-technologies/android/`](06-technologies/android/README.md).
* **Web Frontend (Priority 2)**: Strict TypeScript 5.5+, React 19, Tailwind CSS, TanStack Query, and WCAG 2.1 AA accessibility in [`06-technologies/web/`](06-technologies/web/README.md).
* **Backend & APIs (Priority 3)**: RESTful API design, Zod boundary validation, RFC 9457 Problem Details, Unit of Work, and idempotency in [`06-technologies/backend/`](06-technologies/backend/README.md).
* **Database & Persistence (Priority 4)**: PostgreSQL 16+ schemas, 3NF normalization, composite indexing, expand-and-contract migrations, and concurrency in [`06-technologies/database/`](06-technologies/database/README.md).
* **Cross-Domain Consistency Layer**: Harmonize timeouts, token family rotation state machines, domain rounding, and the Transactional Outbox in [`06-technologies/CROSS_DOMAIN_CONSISTENCY.md`](06-technologies/CROSS_DOMAIN_CONSISTENCY.md).

### 3. Who Should Do It? (AI Agent Roles, Skills & Instruction Hierarchy)
* **Universal Agent Rules (`AGENTS.md`)**: The root contract mandating *Inspect Before Modifying*, *Plan Before Substantial Implementation*, *Zero Silent Overwrites*, and *Verification Integrity*.
* **4-Level Instruction Precedence**:
  $$\text{Project Rules (Level 3)} \succ \text{Technology Rules (Level 2)} \succ \text{Universal Rules (Level 1)}$$
  *(The Iron Safety Gate: Universal safety, security, and verification rules can NEVER be overridden).*
* **Specialized Agent Roles**: Planning, Scrum Master, Architecture, Coding, Debugging, Testing, Review, and Documentation personas in [`04-agents/roles/`](04-agents/roles/).
* **Tool-Specific Adapters**: Dedicated adapters for Google Antigravity, Cursor, Claude Code, and GitHub Copilot in [`04-agents/adapters/`](04-agents/adapters/).
* **12 Reusable Agent Skills**: Standards-compliant skills following the [Agent Skills Specification](https://agentskills.io) in [`05-skills/`](05-skills/README.md), including Gitflow & Trunk-Based branching workflows in [`05-skills/git-and-version-control/SKILL.md`](05-skills/git-and-version-control/SKILL.md).

### 4. How Do I Know It Works? (Testing Doctrine, Validation & Quality Gates)
* **Risk-Based Testing (RBT)**: Pragmatic verification focused on core domain logic, race conditions, edge cases, and regression proofs in [`02-lifecycle/10-testing.md`](02-lifecycle/10-testing.md) and [`05-skills/testing-and-qa/SKILL.md`](05-skills/testing-and-qa/SKILL.md).
* **Automated Verification Harnesses**:
  * `tools/validate-playbook.ps1`: Full link integrity, absolute path hygiene, and technology schema validator.
  * `tools/test-validator-positive.ps1` & `test-validator-negative.ps1`: Skill schema test suites.
  * `tools/test-backend-example.ps1`: Clean architecture and idempotency contract verifier.
  * `tools/test-database-example.ps1`: PostgreSQL 16+ structural and migration verifier.
  * `tools/test-clean-clone.ps1`: End-to-end reproducibility harness executing all suites from an isolated clone.
* **CI/CD Pipeline**: Upgraded GitHub Actions workflow ([`.github/workflows/validate-playbook.yml`](.github/workflows/validate-playbook.yml)) running on Ubuntu and Windows with Node 20, automated secret scanning, and live PostgreSQL 16 container testing.

### 5. How Do I Bootstrap a New Project? (Workflow, Templates & Scenarios)
* **The 8-Stage Operating Manual**: Follow [`docs/guides/PROJECT_BOOTSTRAP_WORKFLOW.md`](docs/guides/PROJECT_BOOTSTRAP_WORKFLOW.md) from Initialization to Release.
* **Reusable Project Templates**: 15 standalone templates ready to copy into new repositories in [`templates/`](templates/README.md).
* **Real-World Project Evaluations**: Detailed walkthroughs across Small Android, Medium Web, and Complex Distributed platforms in [`docs/reports/PROJECT_SCENARIOS_EVALUATION.md`](docs/reports/PROJECT_SCENARIOS_EVALUATION.md).

---

## 🏛️ Framework Layering Architecture: The 3-Tier Model

```
+-----------------------------------------------------------------------------------+
|                           TIER 1: UNIVERSAL CORE                                  |
|  - Engineering Principles (Clean Code, SOLID, DRY, KISS, YAGNI)                   |
|  - Software Development Lifecycle (12 SDLC Stages: Discovery to Maintenance)      |
|  - Universal Architecture Patterns & Fit Matrix                                   |
|  - Universal AI Agent Governance (AGENTS.md & 4-Level Instruction Hierarchy)      |
|  - Universal Security & Privacy Engineering (Defense-in-Depth, STRIDE)            |
|  - Standardized Documentation Templates & Risk-Based Quality Assurance           |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                      TIER 2: TECHNOLOGY EXTENSIONS                                |
|  - Android (Modern Kotlin, Jetpack Compose, Room, MVVM, Coroutines/StateFlow)    |
|  - Web (Modern TypeScript, React Component Architecture, State, Accessibility)    |
|  - Backend (REST API Design, Service Layer Architecture, Validation, Auth)       |
|  - Database (Relational Modeling, Indexing, Transactions, Migrations, Integrity)  |
|  - Cross-Domain Consistency & Harmonization Specification                         |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                        TIER 3: PROJECT OVERLAYS                                   |
|  - Active target application repository (e.g., ExpenseTracker, CheckoutPlatform)  |
|  - Local project rules (.agent/PROJECT.md, CLAUDE.md, .cursorrules)               |
|  - Specific domain requirements, chosen dependencies, and progress tracking       |
+-----------------------------------------------------------------------------------+
```

---

## 📂 Repository Organization

```text
personal-engineering-playbook/
├── README.md                           # Master entry point & 5-question guide
├── AGENTS.md                           # Universal root instructions for AI coding agents
├── VERSION.md                          # Framework SemVer specification (v1.0.0-rc.1)
├── CHANGELOG.md                        # Version history and milestone change logs
├── CONTRIBUTING.md                     # Engineering standards for contributing
├── IMPROVEMENT_BACKLOG.md              # Roadmap and future technology extensions
│
├── docs/                               # Engineering guides and authoritative reports
│   ├── guides/                         # PROJECT_BOOTSTRAP_WORKFLOW.md, AGILE_SCRUM_GUIDE.md
│   └── reports/                        # FINALIZATION_BASELINE.md, PROJECT_SCENARIOS_EVALUATION.md, etc.
│
├── templates/                          # 15 Reusable, decoupled project templates + Catalog Index
│   ├── 01-PROJECT_BRIEF_TEMPLATE.md
│   ├── 02-REQUIREMENTS_SPEC_TEMPLATE.md
│   ├── ...
│   └── README.md                       # Master Template Index & Selector
│
├── 01-principles/                      # 12 Core Principles with 9-part pedagogical schema
├── 02-lifecycle/                       # 12 SDLC Stages (Inputs, Activities, Outputs, Gate Criteria)
├── 03-architecture/                    # 11 Architecture Patterns & Complexity Fit Matrix
├── 04-agents/                          # Universal Agent Rules, 8 Roles & 4 Tool Adapters
├── 05-skills/                          # 12 Reusable AI Skills (agentskills.io compliant)
├── 06-technologies/                    # Domain Standards: Android, Web, Backend, Database & Cross-Domain
├── 07-templates/                       # Playbook internal documentation templates
├── 08-quality/                         # Risk-Based QA Checklists & 4 Operational Phase Gates
├── 09-project-management/              # 9 PM Workflows & Progress Tracking
├── 10-security-and-privacy/            # 9 Universal Security & Privacy Engineering Guides
└── tools/                              # Automation, validation suites & clean-clone harnesses
```

---

## 📜 Version & Governance

* **Current Version**: `1.0.0-rc.1`
* **Governed by**: Semantic Versioning (SemVer 2.0.0)
* **Changelog**: See [CHANGELOG.md](CHANGELOG.md)
* **Contributions**: See [CONTRIBUTING.md](CONTRIBUTING.md)
