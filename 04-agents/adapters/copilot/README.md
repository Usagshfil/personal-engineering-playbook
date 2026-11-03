# Tool Adapter: GitHub Copilot (Priority 4)

> **Adapter Status**: Context Guidance via `.github/copilot-instructions.md`  
> **Target Tool**: GitHub Copilot (Chat & Code Completion in Android Studio / VS Code)

---

## 1. Official Instruction Mechanism
GitHub Copilot reads custom repository-level instructions from:
*   **`.github/copilot-instructions.md`**

This file is automatically appended to Copilot's prompt context when asking questions in Copilot Chat or generating code in the editor.

---

## 2. Supported Capabilities
| Capability | Support Level | Implementation Notes |
| :--- | :---: | :--- |
| **Universal Rules (Level 1)** | **Guidance** | Acts as contextual guidance during inline suggestions and chat. |
| **Technology Rules (Level 2)** | **Guidance** | Enforces Kotlin/Compose idioms and prevents legacy XML suggestions. |
| **Project Rules (Level 3)** | **Guidance** | Informs Copilot of project architecture (e.g. MVVM + Room). |
| **Task Skills (Level 4)** | **Unsupported** | Copilot cannot execute autonomous multi-step workflows or trigger skills automatically. |

---

## 3. Tool Limitations & Practical Guidelines
*   **Not an Autonomous Agent**: GitHub Copilot in standard IDE mode is an assistant, not an autonomous agent. It cannot autonomously create branch plans, execute shell test commands, or manage file lifecycles.
*   **Context Length Sensitivity**: Keep `.github/copilot-instructions.md` concise and directive. Focus on coding idioms, prohibited anti-patterns, and architecture constraints.

---

## 4. Ready-to-Copy Configuration Template

### File: `.github/copilot-instructions.md`
```markdown
# GitHub Copilot Repository Instructions

## Universal Principles (Level 1)
- Write clean, readable, self-documenting code.
- Prefer immutability: use `val` over `var` and immutable collections by default.
- Never hardcode secrets, API keys, or credentials.
- Use early returns (guard clauses) to prevent deep indentation.
- Always provide typed error handling with `Result<T>` or sealed classes.

## Android Development Conventions (Level 2)
- Language: Modern Kotlin (Kotlin 2.0+).
- UI Framework: Jetpack Compose only (do NOT generate XML layouts or ViewBinding unless explicitly asked).
- Architecture: MVVM with `ViewModel` and `StateFlow`.
- Composables: Keep Composables pure; pass state down, hoist events up via lambdas.
- Never pass Android `Context` or View references into a `ViewModel`.
- Never execute database queries or HTTP calls on the Main thread.
- Persistence: Room Database using `suspend` functions and reactive `Flow`.
- Dependency Injection: Hilt constructor injection (`@Inject constructor(...)`).
```
