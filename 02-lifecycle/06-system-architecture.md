# Phase 06: System Architecture & Component Design

---

## 1. Phase Overview
System Architecture establishes the high-level structural blueprint of the application. It selects the overarching architectural pattern (e.g., MVVM, Clean Architecture, Layered), defines subsystem boundaries, specifies data flow, and documents major trade-offs in Technical Decision Records (TDRs).

---

## 2. Inputs
*   SRS Document and Non-Functional Requirements from Phase 03.
*   Feasibility Report from Phase 04.
*   Engineering Principles (`01-principles/`) and Architecture Standards (`03-architecture/`).

---

## 3. Activities
1.  **Architecture Pattern Selection**: Select the appropriate pattern based on the Complexity Fit Matrix (avoiding premature overengineering).
2.  **Layer & Module Boundary Definition**: Establish clean separation between UI (Presentation), Business Logic (Domain), and Data (Repository/Network/Database).
3.  **Data Flow & State Management Design**: Define how state flows through the system (e.g. Unidirectional Data Flow via Kotlin `StateFlow`).
4.  **External Integration Contracts**: Define API protocols, payload schemas, and serialization methods (Retrofit, REST, JSON).
5.  **Technical Decision Records (TDRs)**: Write formal records for major architectural decisions (e.g. why Room was chosen over raw SQLite, why Hilt was chosen for DI).

---

## 4. Expected Outputs
*   Component and container diagrams (C4 model or Mermaid flowcharts).
*   Defined package and module boundaries.
*   Documented rationale for architectural trade-offs.

---

## 5. Deliverables
*   `04-software-architecture-document.md` (SAD, using template `07-templates/04-software-architecture-document.md`).
*   Architecture Decision Records in `docs/decisions/` (using template `07-templates/12-technical-decision-record.md`).

---

## 6. Completion Criteria (Exit Gate)

- [ ] Does the architecture respect KISS/YAGNI principles without unnecessary enterprise bloat?
- [ ] Is data flow strictly unidirectional (e.g. State flows down, Events flow up)?
- [ ] Are boundaries between UI, business logic, and data storage explicitly enforced?
- [ ] Are all major library and framework decisions documented via TDRs?
- [ ] Has the SAD document been reviewed and approved?
