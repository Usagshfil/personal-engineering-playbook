# Tool Adapter: Claude Code (Priority 3)

> **Adapter Status**: High Compatibility via `CLAUDE.md`  
> **Target Tool**: Anthropic Claude Code CLI

---

## 1. Official Instruction Mechanism
Claude Code relies on a single authoritative **`CLAUDE.md`** file located at the repository root. Claude Code automatically reads this file on every command and uses it as its primary project context and behavioral constraints.

---

## 2. Supported Capabilities
| Capability | Support Level | Implementation Notes |
| :--- | :---: | :--- |
| **Universal Rules (Level 1)** | **Full** | Directly included in `CLAUDE.md`. |
| **Technology Rules (Level 2)** | **Full** | Included as concise bulleted directives in `CLAUDE.md`. |
| **Project Rules (Level 3)** | **Full** | Project-specific build and test commands placed in `CLAUDE.md`. |
| **Task Skills (Level 4)** | **Manual** | Claude Code will read specific `SKILL.md` files upon user prompt (e.g., *"Follow the debugging workflow in 05-skills/debugging/SKILL.md"*). |

---

## 3. Tool Limitations & Practical Guidelines
*   **Single File Focus**: Claude Code reads `CLAUDE.md` exclusively. It does not automatically parse `.cursorrules` or `.agent/`.
*   **Conciseness Requirement**: Anthropic recommends keeping `CLAUDE.md` concise and dense with facts, commands, and constraints rather than long theoretical essays.
*   **Explicit Command Instructions**: Always specify the exact build, test, and lint commands (`./gradlew testDebugUnitTest`, `./gradlew ktlintCheck`) so Claude Code can run them autonomously.

---

## 4. Ready-to-Copy Configuration Template

### Root File: `CLAUDE.md`
```markdown
# Project Engineering Guidelines (Claude Code)

## Build, Test & Lint Commands
- Compile debug: `./gradlew assembleDebug`
- Run unit tests: `./gradlew testDebugUnitTest`
- Run specific test: `./gradlew testDebugUnitTest --tests "com.example.app.UserViewModelTest"`
- Check code style: `./gradlew ktlintCheck`
- Format code: `./gradlew ktlintFormat`

## Core Engineering Rules (Level 1 & 2)
- Refer to canonical playbook standards in `AGENTS.md`.
- Inspect existing files and architecture before proposing changes.
- Never write substantial code without presenting an implementation plan first.
- Zero hardcoded secrets: never commit credentials, tokens, or private keys.
- Never claim tests pass without executing `./gradlew testDebugUnitTest` and viewing real output.
- Every bug fix requires a reproducing regression test.
- Architecture: MVVM with Jetpack Compose + StateFlow + Room Database.
- UI: Composables must remain pure (state down, events up); no database or network calls inside Composables.

## Task Skills (Level 4)
When performing specialized workflows, read the corresponding playbook skill file:
- For debugging: Read `05-skills/debugging/SKILL.md`
- For architecture design: Read `05-skills/system-architecture/SKILL.md`
- For code review: Read `05-skills/code-review/SKILL.md`
```
