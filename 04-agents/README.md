# Section 04: AI Agent Rules, Roles & Tool Adapters

> **Tier 1: Universal Engineering Core**  
> **Level 1 AI Instruction Baseline**

---

## Overview

Modern AI coding agents (such as Google Antigravity, Cursor, Claude Code, and GitHub Copilot) are powerful force multipliers, but without strict engineering guardrails, they quickly generate unmaintainable code, hallucinate test results, introduce bloated dependencies, and overwrite working files.

This section establishes the **AI Agent Governance System**:
1. **Canonical Universal Rules (`AGENTS.md`)**: The non-negotiable Level 1 baseline governing all agents.
2. **The 4-Level Instruction Hierarchy**: The precedence framework that prevents contradictory behavior across tools.
3. **Specialized Agent Roles (`roles/`)**: Role-specific directives for Planning, Scrum Master, Architecture, Coding, Debugging, Testing, Code Review, and Documentation.
4. **Tool Adapters (`adapters/`)**: Practical configuration templates and honest capability/limitation documentation for Google Antigravity, Cursor, Claude Code, and GitHub Copilot.
5. **Tool Interoperability Matrix (`adapters/INTEROPERABILITY_MATRIX.md`)**: Empirical breakdown of what each tool natively supports vs. what requires manual developer execution.

---

## The 4-Level Instruction Precedence Model

```
Level 1: Universal Engineering Rules (Core Playbook: AGENTS.md, Principles, Security, Verification)
   │
   ▼ Inherited by
Level 2: Technology-Specific Rules (Domain: Android, Web, Backend, Database)
   │
   ▼ Configured in
Level 3: Project-Specific Rules (Target Repo: .agent/PROJECT.md, CLAUDE.md, .cursorrules)
   │
   ▼ Triggers on-demand
Level 4: Task-Specific Skills & Roles (Execution: 05-skills/*/SKILL.md & 04-agents/roles/*.md)
```

$$\text{Project-Specific Rules (Level 3)} \succ \text{Technology-Specific Rules (Level 2)} \succ \text{Universal Engineering Rules (Level 1)}$$

> [!CAUTION]
> **The Iron Safety Gate**: Level 1 Safety, Security, and Verification rules are **invariant**. Level 3 project rules may override coding patterns (e.g., choosing Koin over Hilt), but can never override security hygiene, regression testing requirements, or truthfulness standards.

---

## Directory Catalog

### Specialized Roles (`roles/`)
*   [planning-agent.md](roles/planning-agent.md): Deconstructs requirements, produces WBS, scopes milestones, creates implementation plans.
*   [scrum-master-agent.md](roles/scrum-master-agent.md): Facilitates Scrum ceremonies, enforces DoR/DoD, removes delivery blockers, tracks sprint health.
*   [architecture-agent.md](roles/architecture-agent.md): Selects patterns from the Complexity Fit Matrix, guards against overengineering, drafts SADs/TDRs.
*   [coding-agent.md](roles/coding-agent.md): Writes clean, idiomatic, immutable code in small vertical slices.
*   [debugging-agent.md](roles/debugging-agent.md): Root-cause analysis, reproduction, hypothesis testing, regression verification.
*   [testing-agent.md](roles/testing-agent.md): Implements Risk-Based Testing (RBT), unit tests domain logic, mocks system boundaries.
*   [review-agent.md](roles/review-agent.md): Evaluates code quality, security risks, performance bottlenecks, and consistency.
*   [documentation-agent.md](roles/documentation-agent.md): Maintains SRS, SAD, API docs, changelogs, and `PROJECT_PROGRESS.md`.

### Tool Adapters & Interoperability (`adapters/`)
*   [INTEROPERABILITY_MATRIX.md](adapters/INTEROPERABILITY_MATRIX.md): Empirical cross-tool capability and limitations matrix.
*   [antigravity/README.md](adapters/antigravity/README.md): Priority 1 — Google Antigravity integration and workspace rules.
*   [cursor/README.md](adapters/cursor/README.md): Priority 2 — Cursor `.cursorrules` and `.cursor/rules/*.mdc` rules.
*   [claude-code/README.md](adapters/claude-code/README.md): Priority 3 — Claude Code `CLAUDE.md` repository configuration.
*   [copilot/README.md](adapters/copilot/README.md): Priority 4 — GitHub Copilot `.github/copilot-instructions.md` configuration.
