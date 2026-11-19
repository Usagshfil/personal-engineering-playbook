---
name: project-planning
sidebarTitle: "Project Planning"
description: Analyze project ideas, objectives, scope boundaries, technical constraints, feasibility, work breakdown structure (WBS), and phased delivery milestones. Use when starting a new project, scoping a major initiative, or breaking down a complex multi-stage deliverable.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: project-management
  version: "1.0.0"
  playbook-level: "4"
---

# Project Planning Skill

## 1. Overview & Capability
The **Project Planning Skill** guides an engineer or AI agent through deconstructing high-level project goals into realistic, prioritized, and phased engineering plans. It transforms ambiguous ideas into an executable roadmap with clear milestone gates, dependency graphs, and resource estimates.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Starting a greenfield software project or major feature initiative.
*   Scoping multi-week deliverables with multiple technical moving parts.
*   When a project is experiencing scope creep, missed deadlines, or unclear priorities.

### When NOT to Use
*   Trivial single-file bug fixes or minor cosmetic UI adjustments.
*   Daily bug triage (use `05-skills/debugging/SKILL.md` instead).
*   During active code execution when an approved plan already exists.

---

## 3. Required Inputs & Prerequisites
*   Raw project concept, problem statement, or stakeholder pitch.
*   Target delivery constraints (timeline, available developer hours, budget).
*   Technical platform baseline (e.g., Android, Web, or Full-Stack).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Problem & Vision Framing ──> 2. Scope Boundaries ──> 3. WBS Decomposition ──> 4. Dependency & Milestone Mapping ──> 5. Tracking Init
```

### Step 1: Problem & Vision Framing
1.  Define the core problem statement in a single sentence: *Who has what problem, and what is the consequence?*
2.  Identify the target user personas and primary value proposition.
3.  Establish 2–3 quantitative success metrics (e.g. daily active users, response time $< 200$ms).

### Step 2: Define Scope Boundaries (In-Scope vs. Out-of-Scope)
1.  List all candidate features.
2.  Apply **MoSCoW Prioritization**:
    *   **Must-Have**: The core MVP cannot function without these.
    *   **Should-Have**: Important features targeted for immediate fast-follows.
    *   **Could-Have**: Desirable enhancements if time permits.
    *   **Won't-Have**: Explicitly excluded from the current milestone to prevent scope creep.

### Step 3: Work Breakdown Structure (WBS)
1.  Break down each "Must-Have" feature into independent, verifiable tasks.
2.  Enforce the **Task Sizing Rule**: Each task must take between 2 and 8 hours. If a task exceeds 8 hours, decompose it further.

### Step 4: Dependency Mapping & Milestone Phasing
1.  Identify blocking relationships (e.g., Database schema must precede Repository; Repository must precede ViewModel).
2.  Group tasks into sequential milestones (e.g., M1: Data Layer, M2: Core Feature UI, M3: Polish & Beta).
3.  Add a 20% contingency buffer for unforeseen technical hurdles.

### Step 5: Initialize Tracking Dashboard
1.  Initialize `PROJECT_PROGRESS.md` using the standard operational status taxonomy (`Not Started`, `In Progress`, `Blocked`, `In Review`, `Completed`).
2.  Present the completed roadmap to the user for sign-off.

---

## 5. Expected Outputs & Artifact Formats
*   `ROADMAP.md` (sequenced milestones with target deliverables).
*   `PROJECT_PROGRESS.md` (living task backlog with status tracking).
*   `implementation_plan.md` (if immediately transitioning into active execution).

---

## 6. Quality & Verification Checklist
- [ ] Is the primary user problem articulated in a single sentence?
- [ ] Are explicit "Won't-Have" scope boundaries documented for the current milestone?
- [ ] Are all individual tasks estimated at $\le 8$ hours of effort?
- [ ] Are task dependencies clearly mapped with zero circular dependencies?
- [ ] Is `PROJECT_PROGRESS.md` initialized with tasks categorized using the standard status taxonomy?

---

## 7. Common Mistakes & Pitfalls
*   **The "Everything is Must-Have" Trap**: Failing to prioritize, leading to an overwhelming initial milestone that never ships.
*   **Vague Task Descriptions**: Writing tasks like "Build backend" instead of "Implement Room NoteEntity and NoteDao with insert/query tests".
*   **Ignoring Non-Functional Requirements**: Forgetting to schedule tasks for database migrations, offline caching, and release keystore signing.

---

## 8. Real-World Example Walkthrough
**Scenario**: Planning an Offline-First Personal Expense Tracker Android App.
*   *Problem*: Users lose track of cash spending when traveling without reliable cellular internet.
*   *Must-Have (M1)*: Room database setup, Transaction creation screen, Local monthly total calculation.
*   *Won't-Have (v1)*: Cloud sync, multi-currency live exchange rates, PDF export.
*   *Deliverable*: `ROADMAP.md` dividing work into M1 (Local Storage & Model), M2 (Compose UI & StateFlow), M3 (Category Charts & Release).

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `requirement-engineering` to write formal user stories and acceptance criteria.
*   $\rightarrow$ Hands off to `system-architecture` to design layer boundaries.

---

## 10. Tool Compatibility & Limitations
*   **Antigravity**: Full native execution; updates `implementation_plan.md` directly.
*   **Cursor / Claude Code**: Can generate roadmap markdown files upon prompt instruction; requires user to manually confirm milestone transitions.
*   **Copilot**: Contextual guidance only; cannot autonomously track long-term milestones.
