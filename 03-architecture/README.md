# Section 03: Software Architecture Standards & Complexity Fit Matrix

> **Tier 1: Universal Engineering Core**  
> **Level 1 AI Instruction Baseline**

---

## Overview

Software architecture defines how a system is divided into components, how responsibilities are assigned, and how data and control flow between them. 

The most common trap for an intermediate developer—and for careless AI coding agents—is **premature overengineering**: forcing an enterprise Clean Architecture with 15 interfaces, 4 mapper classes, and 3 build modules onto a simple utility app that only needs 300 lines of code.

This section provides actionable architectural guidance, contrasting the trade-offs of major patterns, and establishing an objective **Architecture Fit Matrix** to select the right pattern for the right problem scale across any software stack.

---

## The Three-Layer Architectural Mental Model

To keep Tier 1 universal while maintaining clear pedagogy:
1.  **Universal Architecture Pattern**: The structural pattern and its mathematical/topological invariants (Layered, Clean, MVVM, Repository, DI).
2.  **Illustrative Technology Implementation**: How the pattern is realized in modern mobile (Kotlin, Compose, Room, StateFlow) or backend/web systems.
3.  **Contextual Fit (When to Use vs. Overkill)**: Explicit trigger conditions determining whether the pattern pays dividends or introduces harmful overhead.

---

## The Architecture Complexity Fit Matrix

```mermaid
flowchart LR
    subgraph Tier1["Tier 1: Small App / Prototype"]
        P1["Direct Layered / MVC<br/>Single Module, direct parameter passing, minimal abstractions"]
    end

    subgraph Tier2["Tier 2: Standard Production App"]
        P2["MVVM / Reactive State + Repository<br/>Unidirectional Data Flow, Observable State, Isolated Persistence, Lightweight DI"]
    end

    subgraph Tier3["Tier 3: Large / Enterprise / Multi-Team"]
        P3["Clean Architecture + Multi-Module<br/>Strict Domain/Data/Presentation boundaries, independent build modules"]
    end

    Tier1 -->|Scale / Longevity Trigger| Tier2
    Tier2 -->|Build Time / Multi-Feature Trigger| Tier3
```

| Project Scale | Recommended Architecture | When It's Overengineering |
| :--- | :--- | :--- |
| **Small / Prototype / Tool**<br/>($< 5$ screens, single developer, rapid validation) | **Layered Architecture or MVC**<br/>Direct UI $\rightarrow$ Storage calls, single build module. | Forcing Domain use-cases, repository interfaces, and complex DI frameworks. |
| **Standard Production App**<br/>(5–25 screens, production lifecycle, local DB + API) | **MVVM / Reactive State + Repository**<br/>UI $\rightarrow$ State Coordinator (StateFlow) $\rightarrow$ Repository $\rightarrow$ Data Sources. | Creating separate Domain modules with boilerplate `GetUsersUseCase` that simply forwards calls to `UserRepository.getUsers()`. |
| **Large / Multi-Feature / Enterprise**<br/>($> 25$ screens, multi-team, mission-critical) | **Clean Architecture + Multi-Module**<br/>Independent feature and core modules, strict dependency inversion. | Applying this to personal side projects or small utility apps where build overhead outweighs modularity benefits. |

---

## Directory Catalog

| File | Pattern / Topic | Best Fit |
| :--- | :--- | :--- |
| [01-layered-architecture.md](01-layered-architecture.md) | Layered Architecture | Small to mid-size apps, standard separation |
| [02-clean-architecture.md](02-clean-architecture.md) | Clean Architecture | Enterprise, long-lived apps with rich domain rules |
| [03-mvc-pattern.md](03-mvc-pattern.md) | MVC Pattern | Small utilities, web controllers, legacy systems |
| [04-mvvm-pattern.md](04-mvvm-pattern.md) | MVVM Pattern | Modern Android (Jetpack Compose + ViewModel) |
| [05-repository-pattern.md](05-repository-pattern.md) | Repository Pattern | Mediating between UI state and multiple data sources |
| [06-dependency-injection.md](06-dependency-injection.md) | Dependency Injection | Decoupling object creation from business usage |
| [07-modular-architecture.md](07-modular-architecture.md) | Modular Architecture | Scaling large applications via subproject boundaries |
| [08-ui-business-logic-separation.md](08-ui-business-logic-separation.md) | UI & Logic Separation | Keeping UI pure and logic unit-testable |
| [09-state-management.md](09-state-management.md) | State Management & UDF | Unidirectional Data Flow, immutable UI state |
| [10-api-communication.md](10-api-communication.md) | API Communication | Robust REST client patterns, error serialization |
| [11-database-integration.md](11-database-integration.md) | Database Integration | Safe offline-first persistence, reactive queries |
