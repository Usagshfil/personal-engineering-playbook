---
name: requirement-engineering
description: Generate functional and non-functional requirements, user stories, use cases, and verifiable Gherkin acceptance criteria. Use when converting problem statements into formal, unambiguous technical specifications.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: specification-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Requirement Engineering Skill

## 1. Overview & Capability
The **Requirement Engineering Skill** provides a disciplined procedure for capturing, decomposing, and documenting software requirements. It ensures that every feature has unambiguous behavioral boundaries and verifiable acceptance criteria before coding starts.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Translating a project pitch or feature concept into an actionable specification.
*   Drafting or updating a Software Requirements Specification (SRS).
*   Defining formal acceptance tests before beginning sprint or feature implementation.

### When NOT to Use
*   During emergency hotfixes where reproducing a known bug is the only requirement (use `debugging`).
*   When determining low-level library choices or database indexing (use `system-architecture` or `database-engineering`).

---

## 3. Required Inputs & Prerequisites
*   Project Proposal or high-level scope from `project-planning`.
*   Target user personas and environmental constraints.
*   Domain glossary and business rules.

---

## 4. Step-by-Step Deterministic Workflow

```
1. Functional Decomposition ──> 2. Non-Functional Benchmarks ──> 3. User Story Authoring ──> 4. Gherkin Scenarios ──> 5. SRS Compilation
```

### Step 1: Functional Requirement Decomposition (FRs)
1.  List every distinct user action and system response.
2.  Use explicit modal verbs:
    *   **SHALL**: Mandatory requirement.
    *   **SHOULD**: Highly recommended, but system functions without it.
    *   **MAY**: Truly optional capability.
3.  Assign each requirement a unique traceable ID (e.g., `FR-AUTH-001`, `FR-CART-002`).

### Step 2: Non-Functional Requirement Specification (NFRs)
1.  Specify measurable performance thresholds (e.g. "Cold app launch $< 1.5$s on 4GB RAM devices").
2.  Specify security and privacy requirements (e.g. "All network traffic forced over TLS 1.3").
3.  Specify reliability and offline capabilities (e.g. "App remains fully browsable without network connection").

### Step 3: User Story Authoring
Write stories from the user's perspective:
$$\text{As a } [\text{User Persona}], \text{ I want to } [\text{Perform Action}] \text{ so that } [\text{Achieve Benefit}].$$

### Step 4: Gherkin Acceptance Criteria (Given / When / Then)
Every user story must include at least two Gherkin scenarios (one happy path, one error/boundary path):
```gherkin
Scenario: Submitting an order with valid payment
  Given the user has 3 items in their cart
  And a valid credit card is selected
  When the user taps "Place Order"
  Then the payment is processed successfully
  And an order confirmation screen is displayed
  And the local cart is emptied
```

### Step 5: SRS Compilation
Compile all requirements into `02-software-requirements-specification.md` using template `07-templates/02-software-requirements-specification.md`.

---

## 5. Expected Outputs & Artifact Formats
*   `docs/srs.md` or `02-software-requirements-specification.md`.
*   Traceable requirements matrix with IDs and acceptance criteria.

---

## 6. Quality & Verification Checklist
- [ ] Does every functional requirement have a unique identifier (`FR-xxx`)?
- [ ] Are all requirements written using unambiguous language ("SHALL", avoiding vague words like "intuitive")?
- [ ] Are all Non-Functional Requirements quantitatively measurable with exact numbers/units?
- [ ] Does every user story contain both happy path and edge-case Gherkin acceptance criteria?
- [ ] Have offline and error scenarios been explicitly defined?

---

## 7. Common Mistakes & Pitfalls
*   **Vague Non-Functional Requirements**: Writing "The app should be fast and secure" instead of "Database queries must execute in $< 50$ms; all credentials stored in Android Keystore."
*   **Mixing Architecture with Requirements**: Writing "The app shall use Room and Retrofit" in a requirement. Requirements specify *what* the system does; architecture specifies *how* it is built.
*   **Missing Error Path Specifications**: Specifying what happens when a network call succeeds, but failing to specify what happens when the network times out.

---

## 8. Real-World Example Walkthrough
**Requirement**: *Expense Logging Feature*
*   *ID*: `FR-EXP-001`
*   *Specification*: "The system SHALL allow users to log an expense with amount, currency, category, and date."
*   *Acceptance Criteria*:
    *   *Scenario*: User enters amount $\le 0$. System rejects input with inline message "Amount must be greater than zero."
    *   *Scenario*: User enters valid amount while in Airplane Mode. System saves expense locally to Room and queues it for sync.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `ui-ux-engineering` to design wireframes reflecting the user stories.
*   $\rightarrow$ Hands off to `testing-and-qa` to transform Gherkin scenarios into automated test suites.

---

## 10. Tool Compatibility & Limitations
*   Compatible across all major AI tools (Antigravity, Cursor, Claude Code, Copilot). Any LLM can generate high-quality Gherkin requirements when given this structured workflow.
