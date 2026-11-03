---
name: debugging
description: Analyze errors, inspect crash traces, isolate root causes, formulate hypotheses, write reproducing regression tests, and verify surgical fixes. Use when investigating unexpected runtime bugs, crashes, race conditions, or test failures.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: quality-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Debugging Skill

## 1. Overview & Capability
The **Debugging Skill** guides the systematic, evidence-based diagnosis and remediation of software defects. Rather than guessing or applying random patches ("shotgun debugging"), this skill enforces **Root Cause Analysis (RCA)**, **Hypothesis Testing**, and **Mandatory Reproducing Regression Tests** to guarantee that bugs stay fixed permanently.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Investigating application crashes, ANRs, memory leaks, or unhandled exceptions.
*   Resolving failed automated unit or integration tests.
*   Troubleshooting unexpected state desynchronization, UI glitches, or race conditions.
*   Responding to production crash reports (Crashlytics, Sentry).

### When NOT to Use
*   Writing new features from scratch (use `coding-and-implementation`).
*   Routine code reviews of working features (use `code-review`).
*   Configuring production build signing (use `deployment-release`).

---

## 3. Required Inputs & Prerequisites
*   Bug description, user steps to reproduce, or crash stack trace.
*   Affected source code files and version context.
*   System environment logs (Android logcat, device model, OS version).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Triage & Error Analysis ──> 2. Root Cause Isolation ──> 3. Mandatory Regression Test ──> 4. Surgical Fix ──> 5. Verify & Document
```

### Step 1: Triage & Error Analysis
1.  Read the full error message and stack trace. Identify:
    *   *Exception Type* (e.g., `NullPointerException`, `IllegalStateException`, `SQLiteConstraintException`).
    *   *Exact File and Line Number* where the failure was thrown.
    *   *Triggering State* (e.g., screen rotation, airplane mode toggle, rapid button double-tap).

### Step 2: Root Cause Isolation (The 5 Whys)
Do not fix the symptom; fix the cause:
*   *Symptom*: App crashes on `user.name.length` with `NullPointerException`.
*   *Why 1*: `user.name` is null.
*   *Why 2*: The backend sent `null` when a user has no display name set.
*   *Why 3*: The Kotlin DTO model declared `val name: String` as non-nullable.
*   *Root Cause*: Serialization model does not accurately reflect API nullability contract.

### Step 3: Author Mandatory Reproducing Regression Test
**Rule**: Never write the fix until you have written an automated test that reproduces the bug.
1.  Write a unit or integration test simulating the exact input condition that triggers the bug.
2.  Run the test: **Verify that the test FAILS** (Red phase).
3.  If the test passes before the fix, your test is not reproducing the actual defect.

### Step 4: Apply Surgical Minimal Fix
1.  Apply the minimal, localized code change needed to resolve the root cause.
2.  Avoid broad refactorings or rewriting unrelated functions while fixing a bug.
3.  Rerun the reproducing regression test: **Verify that the test SUCCEEDS** (Green phase).

### Step 5: Full Regression Run & RCA Documentation
1.  Run the full test suite (`./gradlew testDebugUnitTest`) to ensure zero collateral regressions.
2.  Document the Root Cause Analysis in `11-bug-report.md`.

---

## 5. Expected Outputs & Artifact Formats
*   `11-bug-report.md` (updated with Root Cause Analysis).
*   Automated regression test committed to `src/test/`.
*   Surgical code fix resolving the defect.

---

## 6. Quality & Verification Checklist
- [ ] Was the underlying root cause identified rather than merely suppressing the symptom?
- [ ] Was an automated regression test written that failed before the fix was applied?
- [ ] Does the regression test pass after the fix is applied?
- [ ] Did the entire existing test suite pass with zero collateral regressions?
- [ ] Does the bug report document why the bug occurred and how it was permanently resolved?

---

## 7. Common Mistakes & Pitfalls
*   **Shotgun Debugging**: Randomly adding `?.` null-checks or `try/catch` wrappers without understanding why data was null in the first place.
*   **Skipping the Regression Test**: Fixing a bug without a test, allowing a future refactoring to reintroduce the exact same crash next month.
*   **Swallowing the Exception**: Catching the exception and doing nothing, converting an obvious crash into a silent, undetectable data corruption bug.

---

## 8. Real-World Example Walkthrough
**Scenario**: User crashes when rotating screen during checkout.
*   *Log*: `IllegalStateException: ViewModel cannot be accessed after onDestroy`.
*   *Root Cause*: A coroutine in `CheckoutActivity` was launched on `GlobalScope` instead of `lifecycleScope`, attempting to update destroyed UI views.
*   *Regression Test*: Unit test simulating lifecycle cancellation verifies coroutine cancels properly on disposal.
*   *Fix*: Replaced `GlobalScope.launch` with `lifecycleScope.launch` inside activity.
*   *Result*: Test passes; rotation no longer crashes.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `testing-and-qa` to run full integration and regression test suites.
*   $\rightarrow$ Hands off to `code-review` to inspect the surgical patch.

---

## 10. Tool Compatibility & Limitations
*   Antigravity, Cursor, and Claude Code excel at stack trace analysis and writing regression tests.
*   AI agents must execute the test command locally to confirm failure before fix and success after fix.
