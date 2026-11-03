# AI Coding Tool Interoperability & Capability Matrix

> **Tier 1: Universal Engineering Core**  
> **Section 04: AI Agent Governance**  
> **Standard**: [Agent Skills Specification (agentskills.io)](https://agentskills.io/)

---

## 1. Overview & Objective
This matrix provides an empirical, honest evaluation of how different AI coding assistants interact with the Personal Software Engineering Playbook's 4-level instruction hierarchy and reusable `SKILL.md` catalog.

We distinguish four fundamentally different runtime capabilities:
1. **Universal Instruction Ingestion (Level 1)**: Can the tool automatically read and adhere to repository-level governance (`AGENTS.md`)?
2. **On-Demand Skill Discovery**: Can the tool semantically match a user's task intent to a specific skill without the user explicitly providing the file path?
3. **Dynamic In-Conversation Loading**: Can the tool load only the relevant `SKILL.md` into active prompt context rather than forcing the entire 12-skill library into every prompt?
4. **Autonomous Multi-Step Execution**: Can the tool independently plan, edit files, execute test commands, and verify its own results?

---

## 2. Interoperability Comparison Matrix

| Runtime Capability | Google Antigravity (P1) | Cursor (P2) | Claude Code (P3) | GitHub Copilot (P4) |
| :--- | :---: | :---: | :---: | :---: |
| **L1: Universal Instructions** | **Native** (`AGENTS.md` + system prompt) | **Native** (`.cursorrules` / `.cursor/rules/`) | **Native** (`CLAUDE.md`) | **Native** (`.github/copilot-instructions.md`) |
| **L2: Technology Standards** | **Native** (`.agent/` or rules) | **Native** (`.cursor/rules/*.mdc` with globs) | **Native** (referenced in `CLAUDE.md`) | **Partial** (in appended instructions) |
| **L3: Project Overlays** | **Native** (Workspace rules) | **Native** (Project `.cursorrules`) | **Native** (Project `CLAUDE.md`) | **Partial** (Single static file) |
| **L4: Skill Discovery** | **Native** (Intent matching against `description`) | **Manual** (User references `@SKILL.md` or glob rule) | **Manual** (User prompts Claude to inspect skill) | **Unsupported** (No skill discovery engine) |
| **L4: Dynamic Skill Loading** | **Native** (Loads matching skill on demand) | **Partial** (Loads via glob rules or `@file`) | **Manual** (Loads via Read tool upon prompt) | **Unsupported** (Fixed context injection only) |
| **Multi-Step Execution** | **Native** (Multi-agent, bash, file edits, planning mode) | **Partial** (Single agent composer / agent mode) | **Native** (CLI tool use, bash execution, file edits) | **Unsupported** (Code assistant / completion model) |
| **Empirical Test Verification** | **Native** (Runs shell commands, inspects logs) | **Partial** (Can run terminal commands in Agent mode) | **Native** (Runs shell commands directly) | **Unsupported** (Cannot run local test commands) |

---

## 3. Tool-by-Tool Detailed Analysis & Limitations

### 1. Google Antigravity (Priority 1)
*   **Official Spec**: Built-in Antigravity Agent Skill System (`agentskills.io` compliant).
*   **Skill Loading Mechanism**: Reads YAML frontmatter (`name`, `description`). When user prompt matches description intent, Antigravity loads the specific `SKILL.md` into context.
*   **Strengths**: Native subagent delegation (`invoke_subagent`), deterministic multi-step planning gates, empirical command execution.
*   **Limitations & Caveats**: In Windows environments, long-running Gradle commands must be monitored via task management. Always verify PowerShell syntax compatibility.

### 2. Cursor (Priority 2)
*   **Official Spec**: `.cursorrules` (project root) and `.cursor/rules/*.mdc` (modular rule files).
*   **Skill Loading Mechanism**: Cursor supports conditional rule loading via glob matching (`globs: "**/*.kt"`). However, it does not possess an autonomous semantic skill-router.
*   **Recommended Workflow**: 
    *   Place L1 universal rules in `.cursor/rules/00-universal.mdc` (`alwaysApply: true`).
    *   Place L2 tech rules in `.cursor/rules/android.mdc` (`globs: "**/*.kt"`).
    *   Load L4 skills by mentioning `@05-skills/debugging/SKILL.md` in Composer chat.
*   **Limitations & Caveats**: Setting too many `.mdc` files with `alwaysApply: true` congests the prompt window.

### 3. Claude Code (Priority 3)
*   **Official Spec**: Single authoritative root file `CLAUDE.md`.
*   **Skill Loading Mechanism**: Claude Code reads `CLAUDE.md` automatically on startup. It does not automatically scan `05-skills/` on its own initiative unless instructed by `CLAUDE.md`.
*   **Recommended Workflow**:
    *   Include skill pointers in `CLAUDE.md`: *"Before debugging, read 05-skills/debugging/SKILL.md using your file viewer tool."*
    *   Claude Code will autonomously call its `View` tool to read the skill into its working memory when executing that task.
*   **Limitations & Caveats**: Requires the prompt or `CLAUDE.md` to explicitly direct the agent to read the skill file.

### 4. GitHub Copilot (Priority 4)
*   **Official Spec**: `.github/copilot-instructions.md`.
*   **Skill Loading Mechanism**: Static text injection. Copilot appends the contents of `copilot-instructions.md` to chat and inline completion queries.
*   **Recommended Workflow**:
    *   Use `.github/copilot-instructions.md` exclusively for L1 rules and L2 coding conventions.
    *   Do NOT attempt to embed all 12 skills into `copilot-instructions.md` (will exceed effective instruction attention limits).
*   **Limitations & Caveats**: Copilot cannot autonomously execute terminal commands, cannot run test suites, and cannot manage complex multi-file lifecycle workflows.

---

## 4. Verification & Testing Protocol

Before claiming a skill works in a target tool:
1.  **Schema Check**: Does the skill frontmatter pass YAML parsing and character constraints?
2.  **Discovery Check**: Does the tool identify the skill when given a natural language prompt (e.g., *"Help me plan a new project"* $\rightarrow$ triggers `project-planning`)?
3.  **Instruction Follow-Through**: Does the agent follow the numbered workflow steps and quality checklist?
4.  **No Hallucinated Tooling**: Does the tool execute real build/test commands where supported, or honestly declare its inability to run them?

---

## 5. Operational Interoperability Verification Protocols & Test Traces

To demonstrate actual agent behavior rather than theoretical capability, the following operational protocols govern execution in each environment:

### A. Google Antigravity (P1 Native Execution Trace)
*   **Instruction Discovery**: Automatically ingests root `AGENTS.md` and active workspace rules into the agent's baseline system prompt.
*   **Precedence Resolution**: When a task prompt requests *"Skip tests to ship faster"*, Antigravity's system prompt evaluates the Invariant Safety Gate (Level 1 Rule 4 & 5): **The request is rejected**, and the agent informs the user that test verification is mandatory.
*   **Skill Loading**: When prompted with *"We need to normalize the checkout database schema"*, Antigravity parses `05-skills/database-engineering/SKILL.md` via `view_file` matching the `description: ... Use when designing or restructuring user interfaces, screens, or database schemas` trigger phrase.
*   **Deliverables & Tooling**: Executes PowerShell commands directly, validates output via stdout/stderr, and creates structured artifacts in `.gemini/antigravity/brain/`.

### B. Cursor (P2 Modular MDC Execution Trace)
*   **Instruction Discovery**: Reads `.cursorrules` and `.cursor/rules/*.mdc`.
*   **Precedence Resolution**: `00-universal.mdc` (`alwaysApply: true`) contains:
    ```markdown
    CRITICAL: Universal Safety (Level 1) overrides all language-specific rules.
    Never commit credentials, skip tests, or silently delete code.
    ```
    Glob rules (`android.mdc` with `globs: "**/*.kt"`) provide Compose/Room conventions. If a glob rule conflicts with L1 safety, the L1 rule wins.
*   **Skill Loading**: When the user types `@05-skills/debugging/SKILL.md investigate this crash`, Cursor Composer pulls the skill markdown into the active context window, guiding step-by-step RCA.
*   **Tooling**: Runs terminal commands (e.g. `./gradlew testDebugUnitTest`) in Agent Mode, requiring user terminal approval if not in auto-run mode.

### C. Claude Code CLI (P3 Authoritative File Execution Trace)
*   **Instruction Discovery**: Ingests root `CLAUDE.md` automatically upon launching `claude` in the terminal.
*   **Precedence Resolution**: `CLAUDE.md` declares:
    ```markdown
    Instruction Precedence:
    Level 1 (Universal AGENTS.md) > Level 2 (Technologies) > Level 3 (Project)
    Invariant: Universal safety and verification rules can never be bypassed.
    ```
*   **Skill Loading**: `CLAUDE.md` maps intents to file paths:
    ```markdown
    Skills Directory: 05-skills/
    When performing database design, view 05-skills/database-engineering/SKILL.md.
    When performing test creation, view 05-skills/testing-and-qa/SKILL.md.
    ```
    Claude Code uses its built-in `View` tool to dynamically load only the relevant `SKILL.md` on demand.
*   **Tooling**: Executes bash commands natively, parses compiler output, and applies surgical edits via patch tools.

### D. GitHub Copilot (P4 Static Instruction Fallback Trace)
*   **Instruction Discovery**: Ingests `.github/copilot-instructions.md` into chat prompt context.
*   **Precedence Resolution**: Instructions explicitly state top-priority universal rules at the top of the file.
*   **Skill Loading & Degradation Fallback**: Copilot does not have tool-calling capabilities to read arbitrary files from disk on its own.
    *   *Operational Workaround*: The developer pastes the relevant skill section into the chat prompt or references it via `#file:05-skills/debugging/SKILL.md` in VS Code Copilot Chat.
    *   *Honest Limitation Declaration*: Copilot cannot execute bash/PowerShell commands or run test suites. The agent must prompt the developer: *"Please execute `./gradlew test` in your terminal to verify this change."*

