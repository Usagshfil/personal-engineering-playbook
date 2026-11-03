# 07. Modular Architecture & Gradle Subprojects

---

## 1. Definition
**Modular Architecture** is the practice of decomposing a single monolithic codebase into multiple independent, isolated compile units (such as Gradle subprojects in Android or npm workspaces in web). Standard modularization patterns divide code into **Feature Modules** (e.g. `:feature:auth`, `:feature:checkout`) and **Core Modules** (e.g. `:core:database`, `:core:network`, `:core:model`, `:core:designsystem`).

---

## 2. Purpose
As a project grows beyond 10,000 lines of code and multiple developers, single-module projects suffer from **skyrocketing Gradle build times**, **accidental code coupling**, and **uncontrolled namespace pollution**. Modularization enforces strict compiler-level boundaries between features.

---

## 3. Why It Matters
*   **Parallel Compilation & Build Caching**: Gradle can compile independent modules in parallel across multiple CPU cores. If you edit code in `:feature:checkout`, Gradle reuses cached binaries for `:core:database` and `:feature:auth`, reducing build times from minutes to seconds.
*   **Enforced Encapsulation**: A feature module cannot accidentally reach into another feature module's private internal classes if Gradle does not declare a dependency between them.
*   **Dynamic Delivery**: On Android, modularization enables Dynamic Feature Modules (Play Feature Delivery), allowing optional features to be downloaded on-demand to shrink initial APK install size.

---

## 4. When to Use It
*   **Growing Production Codebases**: When clean package boundaries start getting violated or when clean build times exceed 2–3 minutes.
*   **Multiple Developers / Teams**: When different engineers own distinct business domains and need to work without stepping on each other's toes.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Small Projects & Intermediate Learning**: **Do not modularize a simple 3-screen app into 10 Gradle modules.** Modularization adds substantial configuration overhead: managing multiple `build.gradle.kts` files, configuring Hilt across module boundaries, handling navigation between modules, and slower initial Gradle sync.
*   **Start with Package-by-Feature First**: Always start with clean packages in a single `:app` module. When package boundaries are clean, extracting a package into a Gradle module later takes less than 30 minutes.

---

## 6. Advantages & Disadvantages

| Modular Multi-Module Architecture | Monolithic Single-Module |
| :--- | :--- |
| **Lightning-Fast Incremental Builds**: Parallel compilation. | **Slow Clean Builds**: Changing one file often triggers full recompilation. |
| **Strict Architectural Boundaries**: Enforced by the compiler. | **Fragile Boundaries**: Developers can accidentally couple everything. |
| **Reusability Across Apps**: Core modules can be shared. | **Single Build File**: Very simple to set up and configure. |
| **Build Configuration Overhead**: Multiple `build.gradle.kts` to maintain. | **Zero Module Overhead**: Ideal for small apps and rapid prototypes. |

---

## 7. Practical Examples

```
                              ┌─────────┐
                              │  :app   │ (Application Orchestrator)
                              └──┬───┬──┘
                  ┌──────────────┘   └──────────────┐
                  ▼                                 ▼
         ┌──────────────────┐             ┌──────────────────┐
         │  :feature:auth   │             │ :feature:cart    │
         └──┬────────────┬──┘             └──┬────────────┬──┘
            │            │                   │            │
            ▼            ▼                   ▼            ▼
     ┌──────────────┐  ┌──────────────────┐  │     ┌──────────────┐
     │ :core:model  │  │ :core:database   │◄─┘     │ :core:network│
     └──────────────┘  └──────────────────┘        └──────────────┘
```

### Module Dependency Rules
1.  **`:app`** depends on all feature modules and orchestrates global navigation.
2.  **`:feature:*`** modules **NEVER** depend on other `:feature:*` modules. They communicate via deep links or `:core:*` shared interfaces.
3.  **`:core:*`** modules provide foundational utilities (database, network, theme) and never depend on feature modules.

---

## 8. Common Mistakes
1.  **Circular Module Dependencies**: Feature A depends on Feature B, which depends on Feature A. Gradle will fail immediately.
2.  **The "Mega-Core" Anti-Pattern**: Putting everything into `:core` so that every module depends on everything, completely defeating the purpose of modularization.
3.  **Premature Splitting**: Creating a separate Gradle module for a 20-line utility class.

---

## 9. Verification Checklist

- [ ] Is modularization justified by project scale ($\ge 10$ screens or multi-developer team)?
- [ ] Do feature modules remain strictly independent of each other (zero cross-feature dependencies)?
- [ ] Are core foundational modules (`:core:model`, `:core:designsystem`) small, cohesive, and reusable?
- [ ] Is visibility scoped properly using Kotlin `internal` keywords to protect module implementations?
- [ ] Does Gradle configuration use shared convention plugins or version catalogs to prevent duplicated build scripts?
