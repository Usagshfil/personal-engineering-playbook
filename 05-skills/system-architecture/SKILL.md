---
name: system-architecture
sidebarTitle: "System Architecture"
description: Design software architecture, component boundaries, layers, modules, unidirectional data flows, and technical decision records (TDRs). Use when establishing or refactoring high-level system structures.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: architecture-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# System Architecture Skill

## 1. Overview & Capability
The **System Architecture Skill** guides the architectural design of a software application. It evaluates requirements against the **Architecture Complexity Fit Matrix**, defines subsystem boundaries, establishes Unidirectional Data Flow (UDF), and authors formal Technical Decision Records (TDRs/ADRs).

---

## 2. When to Use & When NOT to Use

### When to Use
*   Designing a new software application from scratch.
*   Selecting or evaluating architectural patterns (MVVM, Clean Architecture, Layered).
*   Refactoring a monolithic or tightly coupled codebase.
*   Making major technical decisions (e.g. choosing Room vs. raw SQL, Hilt vs. Koin, Compose vs. XML).

### When NOT to Use
*   Implementing small features within an already established architecture (use `coding-and-implementation`).
*   Database schema normalization and index design (use `database-engineering`).
*   Simple cosmetic UI styling (use `ui-ux-engineering`).

---

## 3. Required Inputs & Prerequisites
*   SRS document and Non-Functional Requirements from `requirement-engineering`.
*   Architecture Standards reference (`03-architecture/`).
*   Target tech stack capabilities (e.g., Kotlin, Android SDK, Compose).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Complexity Tier Selection ──> 2. Layer & Boundary Definition ──> 3. Data Flow Modeling ──> 4. Component Diagramming ──> 5. TDR Authoring
```

### Step 1: Complexity Tier Selection
Evaluate the project against the **Complexity Fit Matrix**:
*   *Tier 1 (Simple / Prototype)*: Layered architecture, single Gradle module, direct state management.
*   *Tier 2 (Standard App / Mid-Scale)*: MVVM + Repository Pattern, StateFlow UDF, Room Database, Hilt/Koin DI.
*   *Tier 3 (Enterprise / Multi-Team)*: Clean Architecture with Domain Use Cases, Multi-module Gradle subprojects.
*   *Anti-Overengineering Rule*: Never select a higher tier than the project requirements and team size justify.

### Step 2: Layer & Boundary Definition
1.  Define the **Presentation Layer**: Pure Composables observing `StateFlow`, hoisting user events.
2.  Define the **Domain Layer** (if Tier 3): Pure Kotlin entities and Use Cases with zero Android dependencies.
3.  Define the **Data Layer**: Repositories mediating local Room DB and remote Retrofit APIs.
4.  Establish dependency direction: Dependencies point **inward** or **downward** only.

### Step 3: Data Flow & State Management Modeling
1.  Define how state flows from Data Layer to UI via Unidirectional Data Flow (UDF).
2.  Specify error handling contracts using `Result<T>` or sealed state classes.
3.  Design coroutine threading boundaries (`Dispatchers.IO` for disk/network, `viewModelScope` for coordinators).

### Step 4: Component Diagramming
Produce a Mermaid flowchart visualizing components and communication pathways.

### Step 5: Technical Decision Record (TDR) Authoring
For every major pattern or framework selection, document:
*   Context and problem statement.
*   Decision made.
*   Alternatives considered and why they were rejected.
*   Consequences and trade-offs.

---

## 5. Expected Outputs & Artifact Formats
*   `04-software-architecture-document.md` (SAD).
*   `docs/decisions/TDR-xxx-[title].md` (Architecture Decision Records).
*   Mermaid component and container diagrams.

---

## 6. Quality & Verification Checklist
- [ ] Is the architectural pattern justified by the Complexity Fit Matrix (avoiding premature overengineering)?
- [ ] Does communication flow unidirectionally (State down, Events up)?
- [ ] Are presentation components completely isolated from raw SQL and HTTP clients?
- [ ] Are domain entities (if present) 100% free of Android SDK imports?
- [ ] Is every major library or architectural choice documented via a formal TDR?

---

## 7. Common Mistakes & Pitfalls
*   **Premature Clean Architecture**: Forcing 15 layers of mappers and use cases onto a simple 3-screen app.
*   **Circular Dependencies**: Module or package A importing B while B imports A.
*   **Hidden State Mutation**: Allowing multiple classes to hold mutable references to the same shared object instead of observing an immutable `StateFlow`.

---

## 8. Real-World Example Walkthrough
**Scenario**: Architecting a Fitness Tracking Android App.
*   *Decision*: Tier 2 MVVM + Repository Pattern.
*   *Presentation*: Compose screens observing `WorkoutUiState` from `WorkoutViewModel`.
*   *Data Layer*: `WorkoutRepository` coordinating `WorkoutDao` (Room) and GPS Location Service.
*   *TDR*: TDR-001 documents why MVVM was chosen over Clean Architecture (avoids pass-through Use Case boilerplate while keeping 100% of logic testable on local JVM).

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `database-engineering` to design the persistent data model.
*   $\rightarrow$ Hands off to `coding-and-implementation` to build vertical feature slices.

---

## 10. Tool Compatibility & Limitations
*   Antigravity, Cursor, and Claude Code can generate Mermaid diagrams and TDR documents effectively.
*   Always inspect existing dependencies (`build.gradle.kts`) before proposing architectural changes.
