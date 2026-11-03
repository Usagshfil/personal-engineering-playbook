# Phase 10: Testing & Quality Assurance (Risk-Based Testing)

---

## 1. Phase Overview
Testing & Quality Assurance verifies that the software functions correctly, performs reliably under stress, handles unexpected inputs safely, and meets all acceptance criteria defined in Phase 03. Testing follows the **Risk-Based Testing (RBT)** doctrine, targeting verification effort where defects cause high business, data, or operational impact.

---

## 2. Inputs
*   SRS Acceptance Criteria & Gherkin Scenarios from Phase 03.
*   Working source code and unit tests from Phase 09.
*   Risk-Based Testing Guidelines (`08-quality/`).

---

## 3. Activities
1.  **Risk-Based Test Prioritization**:
    *   *High Risk (Critical Domain Logic)*: Exhaustive unit tests and boundary testing (`null`, `0`, overflow, state transitions).
    *   *Medium Risk (Boundaries & Persistence)*: Integration tests for Room DAOs, Retrofit API error parsing, and Repository sync.
    *   *Low Risk (Declarative UI)*: Smoke tests and critical journey end-to-end tests; zero unit tests required for static layouts.
2.  **Regression Testing**: Execute automated regression test suites to guarantee that recent changes did not break existing functionality.
3.  **Mandatory Bug Reproduction Verification**: For every reported defect, write a reproducing test proving the defect exists before fixing it, and proving the fix after.
4.  **Manual Exploratory & Edge-Case Testing**: Test on real physical devices under adversarial conditions (airplane mode, poor network, screen rotation, background killing).
5.  **Performance & Memory Profiling**: Inspect memory allocations, detect memory leaks via Android Studio Profiler/LeakCanary, and ensure smooth UI scrolling ($\ge 60$ fps).

---

## 4. Expected Outputs
*   Test execution pass/fail logs with empirical output (no simulated results).
*   Documented bug reports for any discovered anomalies.
*   Verified regression tests committed to the repository.

---

## 5. Deliverables
*   `09-test-plan.md` (using template `07-templates/09-test-plan.md`).
*   Automated test suites in `src/test/` (Unit) and `src/androidTest/` (Instrumentation).
*   Test Execution Summary Report.

---

## 6. Completion Criteria (Exit Gate)

- [ ] Do 100% of automated unit and integration tests pass without failures or flakiness?
- [ ] Have all high-risk domain logic modules passed edge-case and boundary verification?
- [ ] Has every fixed defect been validated by a permanent regression test?
- [ ] Has the application been manually verified on at least one physical device?
- [ ] Are all Sev-1 (Critical) and Sev-2 (Major) bugs completely resolved?
