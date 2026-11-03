# Tool Adapter: Google Antigravity (Priority 1)

> **Adapter Status**: Native Full Compatibility (Levels 1–4)  
> **Target Tool**: Google Antigravity (AGY) Agent System & IDE

---

## 1. Official Instruction Mechanism
Google Antigravity natively integrates repository-level instructions, skills, rules, and subagents:
*   **Level 1 (Universal)**: Loaded via canonical `AGENTS.md` and workspace system instructions.
*   **Level 2 & 3 (Tech & Project)**: Injected via `.agent/PROJECT.md` or `.gemini/` workspace rules.
*   **Level 4 (Skills & Roles)**: Natively discovered and executed from `05-skills/*/SKILL.md` via the [Agent Skills standard](https://agentskills.io/). Subagents can be invoked via `invoke_subagent` and configured via `define_subagent`.

---

## 2. Supported Capabilities
| Capability | Support Level | Implementation Notes |
| :--- | :---: | :--- |
| **Universal Rules (`AGENTS.md`)** | **Native** | Read automatically on workspace initialization. |
| **4-Level Hierarchy** | **Native** | Invariant Level 1 safety rules enforced. |
| **On-Demand Skills (`SKILL.md`)** | **Native** | Automatically indexed and triggered by semantic task matching. |
| **Specialized Subagent Roles** | **Native** | Roles map directly to `invoke_subagent` configurations. |
| **Planning & Verification Phase Gates** | **Native** | Integrated with planning mode and execution artifacts. |

---

## 3. Tool Limitations & Practical Guidelines
*   **Context Window Economy**: While Antigravity handles large context windows smoothly, avoid forcing all 12 skills into the prompt at once. Allow Antigravity's on-demand skill matcher to load skills only when the active task requires them.
*   **Terminal Execution on Windows**: Antigravity runs in PowerShell on Windows. Ensure shell commands use PowerShell syntax (e.g., `./gradlew` instead of `gradlew.bat` or bash syntax).

---

## 4. Setup in a Target Project

To adopt the playbook into a project using Antigravity:
1.  Copy `AGENTS.md` to the target project root.
2.  Copy `05-skills/` to the project root or configure Antigravity's skill path to point to this playbook.
3.  Create `.agent/PROJECT.md` specifying the active tech stack:
    ```markdown
    # Project Configuration
    - Stack: Android (Kotlin 2.0, Jetpack Compose, Room, MVVM, Hilt)
    - Playbook Reference: Level 2 -> 06-technologies/android/
    - Coverage Target: High-risk domain logic >= 80%; UI verified via smoke tests
    ```
