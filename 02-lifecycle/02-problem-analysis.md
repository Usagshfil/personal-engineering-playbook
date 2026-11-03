# Phase 02: Problem Analysis

---

## 1. Phase Overview
Problem Analysis is the deep deconstruction of the user's pain points and operational environment. It bridges high-level vision with factual domain reality, ensuring that the software team solves the *root cause* rather than superficial symptoms.

---

## 2. Inputs
*   `01-project-proposal.md` from Phase 01.
*   User interviews, surveys, or workflow observations.
*   Existing system logs, manual spreadsheets, or paper forms being replaced.

---

## 3. Activities
1.  **Root Cause Analysis (5 Whys)**: Drill down into user complaints to understand why existing tools fail.
2.  **Current-State Workflow Mapping**: Diagram the user's existing workflow step-by-step, highlighting friction, delays, and errors.
3.  **Future-State Workflow Modeling**: Design the idealized workflow once the new software is operational.
4.  **Domain Concept Modeling**: Identify the core real-world entities (e.g. `Order`, `Invoice`, `Vehicle`, `Route`) and their relationships before designing databases.
5.  **Constraint Identification**: Catalogue business constraints (regulations, budget, hardware access, offline usage).

---

## 4. Expected Outputs
*   Unambiguous Problem Statement.
*   Current vs. Future state workflow comparisons.
*   Domain entity glossary with definitions agreed upon by all parties.

---

## 5. Deliverables
*   `docs/problem-analysis-report.md`.
*   Current vs. Future State Activity Diagrams (Mermaid format).
*   Domain Glossary & Concept Map.

---

## 6. Completion Criteria (Exit Gate)

- [ ] Has the root cause been validated with real users or domain experts?
- [ ] Are current-state inefficiencies quantitatively or qualitatively documented?
- [ ] Is the future-state workflow mapped and agreed upon?
- [ ] Is a domain glossary established to ensure consistent vocabulary across code and documentation?
- [ ] Are environmental constraints (e.g., offline-first requirement) explicitly confirmed?
