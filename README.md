# Personal Software Engineering Playbook

> **A permanent, educational, technology-agnostic engineering framework with specialized extensions for modern software development.**

Welcome to your **Personal Software Engineering Playbook**. This repository serves as a permanent reference library of software engineering principles, architectural patterns, lifecycle workflows, reusable AI agent skills, technology-specific standards, documentation templates, and quality assurance checkpoints.

It is designed to bridge intermediate programming knowledge (such as Kotlin and Android Studio) with professional software engineering standards, helping you build scalable, maintainable systems while ensuring AI coding agents act systematically, safely, and predictably.

---

## 🏛️ Framework Architecture: The 3-Tier Layering Model

To ensure universal principles are not polluted by framework-specific syntax, the playbook enforces a strict **3-Tier Separation of Concerns**:

```
+-----------------------------------------------------------------------------------+
|                           TIER 1: UNIVERSAL CORE                                  |
|  - Engineering Principles (Clean Code, SOLID, DRY, KISS, YAGNI)                   |
|  - Software Development Lifecycle (SDLC: Discovery to Maintenance)               |
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
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                        TIER 3: PROJECT OVERLAYS                                   |
|  - Active target application repository (e.g., ExpenseTracker, SocialApp)        |
|  - Local project rules (.agent/PROJECT.md, CLAUDE.md, .cursorrules)               |
|  - Specific domain requirements, chosen dependencies, and progress tracking       |
+-----------------------------------------------------------------------------------+
```

---

## 🤖 The 4-Level AI Instruction Hierarchy

AI coding agents must not generate code blindly without planning. The framework organizes instructions into four discrete precedence levels:

```
Level 1: Universal Engineering Rules (AGENTS.md, Principles, Security, Verification)
   ├── Level 2: Technology-Specific Rules (Android, Web, Backend, Database)
   │      ├── Level 3: Project-Specific Rules (Project Requirements, Stack, Decisions)
   │      │      └── Level 4: Task-Specific Skills & Agent Roles (Planning, Coding, Debugging)
```

### Precedence & Conflict Resolution
$$\text{Project Rule (Level 3)} \succ \text{Technology Rule (Level 2)} \succ \text{Universal Rule (Level 1)}$$

> [!IMPORTANT]
> **The Iron Safety Gate**: Universal Safety, Security, and Verification Integrity rules (Level 1) can **never** be overridden by Level 2 or Level 3 rules. A project may choose its preferred libraries or conventions, but it cannot authorize an AI agent to commit unencrypted secrets, skip regression tests for bug fixes, or claim functionality works without verification.

---

## 📂 Repository Organization

```text
personal-engineering-playbook/
├── README.md                           # This guide
├── AGENTS.md                           # Universal root instructions for AI coding agents
├── VERSION.md                          # Framework SemVer definition (v1.0.0-alpha)
├── CHANGELOG.md                        # Version history and migration notes
├── CONTRIBUTING.md                     # Rules for refining and extending the playbook
├── IMPROVEMENT_BACKLOG.md              # Living queue of planned enhancements (iOS, Flutter, ML)
│
├── 01-principles/                      # 12 Core Principles with 9-part pedagogical schema
├── 02-lifecycle/                       # 12 SDLC Stages (Inputs, Activities, Outputs, Gate criteria)
├── 03-architecture/                    # 11 Architecture Patterns & Complexity Fit Matrix
├── 04-agents/                          # Universal Agent Rules, 7 Roles & 4 Tool Adapters
├── 05-skills/                          # 12 Reusable AI Skills (agentskills.io compliant)
├── 06-technologies/                    # Domain Standards: Android (P1), Web (P2), Backend (P3), Database (P4)
├── 07-templates/                       # 17 Standardized Markdown Documentation Templates
├── 08-quality/                         # Risk-Based QA Checklists & 4 Operational Phase Gates
├── 09-project-management/              # 9 PM Workflows & 4 Tracking Templates
├── 10-security-and-privacy/            # 9 Universal Security & Privacy Engineering Guides
└── tools/                              # Automation & Scaffolding Utilities (scaffold-project.ps1)
```

---

## 🎓 The 9-Part Pedagogical Schema

To ensure this playbook helps you continuously grow as an engineer, every major concept in `01-principles/`, `03-architecture/`, and `10-security-and-privacy/` follows an educational structure:
1. **Definition**: Plain-English explanation.
2. **Purpose**: The specific failure mode this concept eliminates.
3. **Why It Matters**: The fundamental mental model and engineering value.
4. **When to Use It**: Concrete scenarios and trigger conditions.
5. **When NOT to Use It**: Anti-complexity limits to prevent over-engineering.
6. **Advantages & Disadvantages**: Honest trade-off analysis.
7. **Practical Examples**: Side-by-side **Good** vs. **Bad** code snippets.
8. **Common Mistakes**: Traps and anti-patterns intermediate developers make.
9. **Verification Checklist**: A fast 5-point sanity checklist.

---

## 🚀 How to Adopt in a Project

1. **Standalone Knowledge Base**: Keep this repository open while studying, coding, or designing systems.
2. **AI Agent Integration**: Point your AI assistant (Google Antigravity, Cursor, Claude Code, GitHub Copilot) to `AGENTS.md` and the relevant `05-skills/` or `06-technologies/` directories.
3. **Project Scaffolding**: Use the guidance in `04-agents/adapters/` (or the `tools/scaffold-project.ps1` utility) to bootstrap Level 1–3 rules into a new or existing project repository.

---

## 📜 Version & Governance

* **Current Version**: `1.0.0-alpha`
* **Governed by**: Semantic Versioning (SemVer 2.0.0)
* **Changelog**: See [CHANGELOG.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/CHANGELOG.md)
* **Contributions**: See [CONTRIBUTING.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/CONTRIBUTING.md)
