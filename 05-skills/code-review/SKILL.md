---
name: code-review
sidebarTitle: "Code Review"
description: Review pull requests, commits, and code diffs for architectural integrity, security flaws, performance bottlenecks, maintainability, and testing adequacy. Use when conducting peer reviews or pre-commit audits.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: quality-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Code Review Skill

## 1. Overview & Capability
The **Code Review Skill** guides the systematic, constructive, and objective peer review of source code changes. It ensures that pull requests uphold architectural boundaries, adhere to clean code principles, introduce zero security vulnerabilities or hardcoded secrets, and provide adequate test coverage under Risk-Based Testing guidelines.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Reviewing a Git pull request or branch diff before merging into main.
*   Auditing recent changes for security, privacy, and performance anti-patterns.
*   Evaluating AI-generated code for hidden assumptions or architectural drift.
*   Performing pre-commit quality gate checks.

### When NOT to Use
*   Writing original production code (use `coding-and-implementation`).
*   Automated formatting (use `ktlint` or `spotless` instead of human review).
*   Writing detailed requirements (use `requirement-engineering`).

---

## 3. Required Inputs & Prerequisites
*   Git diff, pull request patch, or list of modified files.
*   Original issue description or user story acceptance criteria.
*   Project Architecture Standards (`03-architecture/`) and Security Guidelines (`10-security-and-privacy/`).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Scope & Intent Inspection ──> 2. Security & Secrets Audit ──> 3. Architecture & Boundary Check ──> 4. Performance & Test Review ──> 5. Constructive Categorized Feedback
```

### Step 1: Scope & Intent Inspection
1.  Read the PR title and description. Does the change match the requested user story?
2.  Check for **Scope Creep**: Are there unrelated refactorings or file touch-ups bundled into a simple bug fix?
3.  Check diff size: Is the PR focused ($\le 400$ lines)? If massive, request breaking it into smaller PRs.

### Step 2: Security & Secrets Audit (Zero Tolerance)
Inspect the diff for critical security violations:
*   Are there any hardcoded API keys, passwords, private tokens, or URLs?
*   Are database queries parameterized, or is there raw string interpolation?
*   Are user inputs validated at system boundaries?
*   Are passwords or PII logged to logcat?

### Step 3: Architecture & Boundary Check
1.  Does the code respect layer boundaries (e.g. Composable does not touch Room DAO)?
2.  Does the change maintain Unidirectional Data Flow?
3.  Is mutable state kept private (`val uiState: StateFlow` instead of public `var`)?
4.  Were unnecessary third-party dependencies introduced?

### Step 4: Performance & Testing Review
1.  Are heavy operations offloaded to `Dispatchers.IO`?
2.  In Jetpack Compose: Are expensive calculations remembered or hoisted to ViewModel?
3.  **Risk-Based Testing**: Are high-risk domain logic changes accompanied by automated unit tests? If fixing a bug, is there a reproducing regression test?

### Step 5: Deliver Categorized Constructive Feedback
Label every comment with a standard severity tag:
*   `[BLOCKER]`: Critical defect, security flaw, data corruption, or crash. Must be resolved before merge.
*   `[WARNING]`: Architectural drift, missing test, or performance concern. Strongly recommended.
*   `[SUGGESTION]`: Idiomatic Kotlin improvement or readability enhancement. Non-blocking.
*   `[NITPICK]`: Minor stylistic preference. Non-blocking.
*   *Educational Requirement*: Always explain *why* something should be changed and provide a concrete code snippet showing the recommended alternative.

---

## 5. Expected Outputs & Artifact Formats
*   Structured Code Review Report or Pull Request Comments.
*   Pass/Fail decision on Pre-Feature-Complete or Pre-Commit Gate.

---

## 6. Quality & Verification Checklist
- [ ] Are diffs verified to contain zero hardcoded secrets or credentials?
- [ ] Are review comments categorized with severity tags (`[BLOCKER]`, `[WARNING]`, etc.)?
- [ ] Does every suggested change include an explanation of *why* and a concrete code snippet?
- [ ] Did the reviewer avoid manual arguments over issues enforceable by automated linters?
- [ ] Are accompanying unit tests verified to cover new business logic and edge cases?

---

## 7. Common Mistakes & Pitfalls
*   **Bickering Over Styling**: Debating spaces vs. tabs or brace positioning instead of letting `ktlint` enforce it automatically.
*   **Vague Criticisms**: Leaving comments like "This looks messy" without explaining why or providing a cleaner alternative.
*   **Rubber-Stamping (LGTM)**: Approving a 1,000-line PR in 30 seconds without inspecting security boundaries or test adequacy.

---

## 8. Real-World Example Walkthrough
**Reviewing PR #42**: *Add User Discount Calculation*
*   `[BLOCKER]`: `val query = "SELECT * FROM coupons WHERE code = '$code'"` is vulnerable to SQL injection. Please use Room's parameterized query: `@Query("SELECT * FROM coupons WHERE code = :code")`.
*   `[WARNING]`: The discount calculation handles positive values, but does not test what happens when coupon discount exceeds the cart total. Please add a unit test for this boundary condition.
*   `[SUGGESTION]`: In Kotlin, `if (user != null) user.isVip else false` can be written idiomatically as `user?.isVip == true`.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ If blockers are found, hands back to `coding-and-implementation` or `debugging`.
*   $\rightarrow$ If approved, hands off to `git-and-version-control` to merge.

---

## 10. Tool Compatibility & Limitations
*   Antigravity, Cursor, and Claude Code excel at performing automated code reviews over git diffs.
*   Review agents must always verify that tests pass before giving final merge approval.
