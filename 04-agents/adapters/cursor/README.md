# Tool Adapter: Cursor (Priority 2)

> **Adapter Status**: High Compatibility via `.cursorrules` & `.cursor/rules/*.mdc`  
> **Target Tool**: Cursor IDE (v0.40+)

---

## 1. Official Instruction Mechanism
Cursor uses two complementary instruction formats:
1.  **`.cursorrules` (Legacy / Root)**: A single markdown file at the project root loaded into every prompt context.
2.  **`.cursor/rules/*.mdc` (Modern System)**: Modular rule files with glob pattern matching (`globs: "**/*.kt"`) and YAML frontmatter (`alwaysApply: false`). This allows loading technology and task instructions only when specific files are opened.

---

## 2. Supported Capabilities
| Capability | Support Level | Implementation Notes |
| :--- | :---: | :--- |
| **Universal Rules (Level 1)** | **Full** | Placed in `.cursorrules` or `.cursor/rules/00-universal.mdc` (`alwaysApply: true`). |
| **Technology Rules (Level 2)** | **Full** | Placed in `.cursor/rules/android.mdc` with `globs: "**/*.kt, **/*.kts"`. |
| **Project Rules (Level 3)** | **Full** | Included at bottom of `.cursorrules` or in `project.mdc`. |
| **Task Skills (Level 4)** | **Partial** | Cannot automatically invoke multi-step subagents; Cursor can read `SKILL.md` when prompted by the user (e.g. `@SKILL.md`). |

---

## 3. Tool Limitations & Practical Guidelines
*   **No Multi-Agent Orchestration**: Cursor operates as a single conversational agent. It does not spawn independent subagents for planning vs. testing in parallel.
*   **Context Congestion**: If you configure too many `.cursor/rules/*.mdc` files with `alwaysApply: true`, the system prompt becomes overcrowded and Cursor may start ignoring rules. Use globs to conditionally apply rules.

---

## 4. Ready-to-Copy Configuration Templates

### Root File: `.cursorrules` (or `.cursor/rules/00-universal.mdc`)
```markdown
---
description: Universal engineering standards and AI coding rules
globs: *
alwaysApply: true
---

# Universal AI Coding Standards (Level 1)
- Refer to canonical rules in AGENTS.md.
- Inspect files and existing architecture before writing code.
- Never write code blindly: create an implementation plan for non-trivial edits.
- Never fabricate test results: report exact test outputs honestly.
- Zero hardcoded secrets: never place API keys or tokens in source code.
- Zero silent overwrites: preserve existing comments, functions, and working tests.
- Explain non-obvious algorithms and trade-offs at an intermediate developer level.
```

### Technology Rule: `.cursor/rules/android.mdc`
```markdown
---
description: Modern Android and Kotlin development standards
globs: **/*.kt, **/*.kts
alwaysApply: false
---

# Modern Android Standards (Level 2)
- Language: Kotlin 2.0+ with modern idioms.
- UI: Jetpack Compose with pure composables; state flows down, events flow up.
- Architecture: MVVM with StateFlow; collect via collectAsStateWithLifecycle().
- Persistence: Room Database on Dispatchers.IO; expose reactive Flow streams.
- Immutability: Prefer val over var; use immutable data classes.
- Anti-Pattern: Never pass Context into ViewModels; never run DB queries on Main thread.
```
