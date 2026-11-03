# Section 05: Reusable AI Agent Skills

> **Tier 1: Universal Engineering Core**  
> **Level 4 Task-Specific Execution Skills**  
> **Specification**: [Agent Skills Standard (agentskills.io)](https://agentskills.io/)

---

## Overview

This directory contains the canonical collection of **12 reusable AI agent skills**. Each skill represents an isolated, deterministic execution workflow designed to guide AI coding agents (or human developers) through a specific software engineering activity.

In accordance with the [agentskills.io](https://agentskills.io/) standard, each skill is packaged in its own directory with a standardized `SKILL.md` file featuring YAML frontmatter metadata. Skills are **loaded on demand** based on semantic trigger matching, preventing prompt context bloat and contradictory instructions.

---

## The Boundary Between Reusable Skills & Technology Standards

To ensure long-term maintainability and multi-technology scalability, the playbook maintains an explicit separation between **Skills** (procedures) and **Technology Standards** (syntax and platform libraries):

```
┌────────────────────────────────────────────────────────────────────────┐
│ Level 4: Reusable Skill (e.g. database-engineering)                   │
│ - Repeatable, technology-agnostic engineering procedure:               │
│   1. ER Modeling -> 2. Normalization -> 3. Indexing -> 4. Migrations   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Delegates platform idioms to
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Level 2: Technology Standard (e.g. 06-technologies/android/ or db/)    │
│ - Platform-specific syntax, libraries, and compiler details:          │
│   Room @Entity, @Dao, SupportSQLiteDatabase, SQLCipher, Postgres DDL   │
└────────────────────────────────────────────────────────────────────────┘
```

*   **Skills (`05-skills/`)**: Define *how to systematically execute an engineering activity* (inputs, sequential steps, verification gates, failure modes).
*   **Technology Standards (`06-technologies/`)**: Define *concrete framework and language conventions* (Room annotations, Compose lifecycle, Retrofit interceptors).
*   **Boundary Rule**: A skill must never hardcode platform-exclusive assumptions into its universal workflow. It references technology standards for platform-specific syntax while keeping the execution workflow portable.

---

## The 12 Skills Catalog

| Skill Directory | Skill Name | Primary Activity & Objective |
| :--- | :--- | :--- |
| [`project-planning/`](project-planning/SKILL.md) | `project-planning` | Scope boundaries, WBS decomposition, milestones, dependencies |
| [`requirement-engineering/`](requirement-engineering/SKILL.md) | `requirement-engineering` | Functional & Non-functional specs, user stories, Gherkin criteria |
| [`system-architecture/`](system-architecture/SKILL.md) | `system-architecture` | Subsystem design, layer boundaries, UDF, TDR authoring |
| [`database-engineering/`](database-engineering/SKILL.md) | `database-engineering` | Relational modeling, 3NF, query indexing, schema migrations |
| [`ui-ux-engineering/`](ui-ux-engineering/SKILL.md) | `ui-ux-engineering` | Navigation graphs, wireframes, 4 UI states, accessibility (a11y) |
| [`coding-and-implementation/`](coding-and-implementation/SKILL.md) | `coding-and-implementation` | Vertical slice delivery, immutability, clean code, typed results |
| [`debugging/`](debugging/SKILL.md) | `debugging` | Root-cause analysis, reproduction, mandatory regression tests |
| [`testing-and-qa/`](testing-and-qa/SKILL.md) | `testing-and-qa` | Risk-Based Testing, unit/integration suites, boundary validation |
| [`code-review/`](code-review/SKILL.md) | `code-review` | Code quality audit, security analysis, categorized feedback |
| [`technical-documentation/`](technical-documentation/SKILL.md) | `technical-documentation` | Living documentation synchronization, API docs, changelog |
| [`git-and-version-control/`](git-and-version-control/SKILL.md) | `git-and-version-control` | Conventional Commits, trunk-based feature branching, release tags |
| [`deployment-and-release/`](deployment-and-release/SKILL.md) | `deployment-and-release` | Production build hardening, code shrinking, signing, release gate |

> [!TIP]
> **Multi-Skill Lifecycle Integration**: For end-to-end multi-skill execution traces across three representative scenarios (Simple App, Production Bug Triage, Complex Feature), see [INTEGRATION_SCENARIOS.md](INTEGRATION_SCENARIOS.md).

---

## Standard `SKILL.md` Schema

Every `SKILL.md` in this directory adheres strictly to this structure:
1. **YAML Frontmatter (`agentskills.io` standard)**:
   * `name`: Lowercase, hyphen-delimited matching directory name.
   * `description`: Concise summary with clear **when-to-use** trigger keywords.
   * `license`, `compatibility`, and `metadata` mapping.
2. **When to Use & When NOT to Use**: Clear operational triggers and anti-complexity limits.
3. **Required Inputs & Context**: Prerequisites needed before execution.
4. **Step-by-Step Deterministic Workflow**: Sequential, actionable stages.
5. **Expected Outputs & Artifact Formats**: Specific deliverables produced.
6. **Quality Checklist**: 5-point verification gate.
7. **Common Mistakes & Pitfalls**: Traps to avoid.
8. **Real-World Example Walkthrough**: Concrete practical scenario.
9. **Related Skills & Next Steps**: Hand-offs to upstream/downstream skills.
10. **Tool Compatibility & Limitations**: Execution nuances across Antigravity, Cursor, Claude Code, and Copilot.
