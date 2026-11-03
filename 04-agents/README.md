# Section 04: AI Agent Rules, Roles & Tool Adapters

> **Tier 1: Universal Engineering Core**  
> **Level 1 AI Instruction Baseline**

---

## Overview

Modern AI coding agents (such as Google Antigravity, Cursor, Claude Code, and GitHub Copilot) are powerful force multipliers, but without strict engineering guardrails, they quickly generate unmaintainable code, hallucinate test results, introduce bloated dependencies, and overwrite working files.

This section establishes the **AI Agent Governance System**:
1. **Canonical Universal Rules (`AGENTS.md`)**: The non-negotiable Level 1 baseline governing all agents.
2. **The 4-Level Instruction Hierarchy**: The precedence framework that prevents contradictory behavior across tools.
3. **Specialized Agent Roles (`roles/`)**: Role-specific directives for Planning, Architecture, Coding, Debugging, Testing, Code Review, and Documentation.
4. **Tool Adapters (`adapters/`)**: Practical configuration templates and honest capability/limitation documentation for Google Antigravity, Cursor, Claude Code, and GitHub Copilot.

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
*   [planning-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/planning-agent.md): Deconstructs requirements, produces WBS, scopes milestones, creates implementation plans.
*   [architecture-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/architecture-agent.md): Selects patterns from the Complexity Fit Matrix, guards against overengineering, drafts SADs/TDRs.
*   [coding-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/coding-agent.md): Writes clean, idiomatic, immutable code in small vertical slices.
*   [debugging-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/debugging-agent.md): Root-cause analysis, reproduction, hypothesis testing, regression verification.
*   [testing-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/testing-agent.md): Implements Risk-Based Testing (RBT), unit tests domain logic, mocks system boundaries.
*   [review-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/review-agent.md): Evaluates code quality, security risks, performance bottlenecks, and consistency.
*   [documentation-agent.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/roles/documentation-agent.md): Maintains SRS, SAD, API docs, changelogs, and `PROJECT_PROGRESS.md`.

### Tool Adapters (`adapters/`)
*   [antigravity/README.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/adapters/antigravity/README.md): Priority 1 — Google Antigravity integration and workspace rules.
*   [cursor/README.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/adapters/cursor/README.md): Priority 2 — Cursor `.cursorrules` and `.cursor/rules/*.mdc` rules.
*   [claude-code/README.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/adapters/claude-code/README.md): Priority 3 — Claude Code `CLAUDE.md` repository configuration.
*   [copilot/README.md](file:///c:/Users/datnt249/AndroidStudioProjects/personal-engineering-playbook/04-agents/adapters/copilot/README.md): Priority 4 — GitHub Copilot `.github/copilot-instructions.md` configuration.
