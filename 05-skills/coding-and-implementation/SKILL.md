---
name: coding-and-implementation
description: Implement features, classes, and UI screens using established architecture, clean code principles, immutability, and typed error handling. Use when writing, modifying, or refactoring production application code.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: core-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Coding and Implementation Skill

## 1. Overview & Capability
The **Coding and Implementation Skill** guides the disciplined writing of production source code. It ensures that features are built incrementally in vertical slices, follow established architectural boundaries (MVVM / Clean), enforce immutability, apply typed error handling (`Result<T>`), and conform to automated formatting standards.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Implementing new features, services, repositories, or UI screens.
*   Writing production Kotlin, TypeScript, or backend code.
*   Refactoring existing code to improve readability and maintainability.

### When NOT to Use
*   Investigating unexpected bugs, crashes, or test failures (use `debugging` first).
*   Planning major new multi-week initiatives (use `project-planning` first).
*   Designing high-level system boundaries (use `system-architecture` first).

---

## 3. Required Inputs & Prerequisites
*   Approved `implementation_plan.md` or task description from `PROJECT_PROGRESS.md`.
*   System Architecture Document and database schemas.
*   Existing codebase patterns, dependencies, and version catalog (`libs.versions.toml`).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Inspect Existing Context ──> 2. Vertical Slice Order ──> 3. Write Clean & Immutable Code ──> 4. Typed Error Handling ──> 5. Automated Lint & Format
```

### Step 1: Inspect Existing Context (Read Before Write)
1.  Read existing files in the target package to match style, naming conventions, and dependencies.
2.  Check project dependency manifests (`build.gradle.kts`, `package.json`, etc.) to verify available libraries.
3.  Confirm active architecture (e.g. MVVM, Layered, Clean Architecture) from Level 3 project instructions.

### Step 2: Implement in Vertical Slices (Bottom-Up)
Deliver features end-to-end in cohesive layers rather than writing disconnected UI:
1.  **Data Tier**: Persistent entity and data access contract (e.g., Room DAO on Android, SQL repository on backend).
2.  **Repository Tier**: Repository interface and offline-first implementation mapping raw entities to domain models.
3.  **State / Coordinator Tier**: State holder exposing immutable observable state (e.g., `StateFlow<UiState>` on Android, Zustand/Redux on Web).
4.  **UI Tier**: Pure presentation components with state hoisting and 4 UI states (e.g., Compose, React).
*Delegate platform-specific conventions to the active Technology Standard (`06-technologies/`).*

### Step 3: Write Clean, Immutable Code
1.  Declare variables as `val` by default; use `var` only when local mutation is unavoidable.
2.  Keep functions small ($\le 25$ lines) with $\le 3$ arguments.
3.  Use guard clauses (early returns) to eliminate deep indentation:
    ```kotlin
    if (input.isBlank()) return Result.failure(...)
    ```

### Step 4: Implement Typed Error Handling
1.  Never swallow exceptions with empty catch blocks.
2.  Return typed results (`Result<T>` or sealed domain interfaces).
3.  Dispatch blocking I/O operations to `Dispatchers.IO`.

### Step 5: Format & Lint
1.  Run automated linter (`./gradlew ktlintCheck` or `spotlessCheck`).
2.  Auto-format code (`./gradlew ktlintFormat` or `spotlessApply`).
3.  Eliminate all compiler warnings and unused imports.

---

## 5. Expected Outputs & Artifact Formats
*   Compilable production source files.
*   Companion unit tests covering business logic.
*   Summary of files touched and commands executed.

---

## 6. Quality & Verification Checklist
- [ ] Were existing project patterns and dependencies inspected before editing?
- [ ] Are variables declared immutable (`val`) and collections read-only (`List`)?
- [ ] Are functions short, cohesive, and using early returns to limit nesting?
- [ ] Are exceptions safely handled and returned as typed results (`Result<T>`)?
- [ ] Does the code compile with zero warnings, zero linter errors, and clean formatting?

---

## 7. Common Mistakes & Pitfalls
*   **Blind Code Generation**: Writing code without inspecting existing dependencies or architecture, inventing non-existent libraries or patterns.
*   **Silent Overwrites**: Deleting existing functions, comments, or tests during an edit.
*   **Exposing Mutable State**: Exposing `MutableStateFlow` or `MutableList` outside a ViewModel.

---

## 8. Real-World Example Walkthrough
**Task**: Implement Bookmarking in a News Reader App.
1.  *Data*: Add `isBookmarked` column to `ArticleEntity`; add `upsertBookmark()` to `ArticleDao`.
2.  *Repository*: Add `toggleBookmark(articleId: String): Result<Unit>` to `ArticleRepository`.
3.  *ViewModel*: In `ArticleViewModel`, launch coroutine to call repository and update `ArticleUiState`.
4.  *UI*: In `ArticleScreen`, render filled/outline bookmark icon button calling `viewModel.onBookmarkClicked()`.
5.  *Verification*: `./gradlew ktlintCheck && ./gradlew testDebugUnitTest` pass cleanly.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `testing-and-qa` to execute test suites and verify coverage.
*   $\rightarrow$ Hands off to `code-review` for peer inspection before merging.

---

## 10. Tool Compatibility & Limitations
*   Fully supported across Antigravity, Cursor, Claude Code, and Copilot.
*   Agents must always run build/lint checks using local tools where available.
