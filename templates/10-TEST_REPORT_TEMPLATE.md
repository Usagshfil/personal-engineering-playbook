# Test Execution Report: [Feature / Milestone Name]

> **Execution Date**: [YYYY-MM-DDTHH:mm:ssZ]  
> **Commit SHA**: [Git Commit SHA]  
> **Environment**: [Local Host Workstation / GitHub Actions CI Runner]  
> **Overall Verdict**: **PASS** / **PASS WITH LIMITATIONS** / **FAIL**  

---

## 1. Executive Summary

*Briefly summarize the test execution outcome, number of test suites executed, total tests passed/failed, and any critical defects discovered.*

| Metric | Recorded Value | Target Threshold | Status |
| :--- | :---: | :---: | :---: |
| **Total Test Suites** | [e.g. 5] | All configured | PASS |
| **Total Test Cases** | [e.g. 42] | 100% P0/P1 | PASS |
| **Failed Tests** | [e.g. 0] | 0 | PASS |
| **Flaky Tests** | [e.g. 0] | 0 | PASS |
| **Execution Duration** | [e.g. 14.2s] | $< 60\text{s}$ | PASS |

---

## 2. Test Execution Details by Suite

### Suite 1: [Suite Name, e.g. Domain & Unit Tests]
* **Command Executed**: `npm test` or `./gradlew test`
* **Exit Code**: 0
* **Log Output Excerpt**:
  ```text
  PASS  src/domain/Order.test.ts
    ✓ should create order with pending status (2ms)
    ✓ should confirm order and increment OCC version (1ms)
    ✓ should reject confirmation if already processed (1ms)
  ```

### Suite 2: [Suite Name, e.g. API Boundary & Idempotency Tests]
* **Command Executed**: `powershell -File ./tools/test-backend-example.ps1`
* **Exit Code**: 0
* **Log Output Excerpt**:
  ```text
  PASS: Happy Path Order Creation (201 Created)
  PASS: Cached Idempotency Replay (X-Cache-Replay: true)
  PASS: Concurrent In-Flight Lock Rejection (409 Conflict)
  ```

---

## 3. Regression Testing for Fixed Defects

| Bug / Defect ID | Description | Reproducing Test Name | Pre-Fix Status | Post-Fix Status |
| :---: | :--- | :--- | :---: | :---: |
| **BUG-101** | Concurrent refresh token race condition | `testConcurrentRefreshRotation` | FAILED | **PASSED** |
| **BUG-102** | Decimal rounding bias in VAT calculation | `testTaxHalfUpBoundaryRounding` | FAILED | **PASSED** |

---

## 4. Known Limitations & Environment Constraints

*Document any tests that could not be executed due to environment boundaries (Tier 1 Rule 4: Zero Hallucinated Testing):*
* *Constraint 1*: [e.g. Docker unavailable on local Windows host; containerized PostgreSQL verified in GitHub Actions CI].
* *Constraint 2*: [e.g. End-to-end device push notifications simulated with mock APNs payload].

---

## 5. Sign-Off & Recommendation

* **QA Lead / Developer Sign-Off**: [Name]
* **Recommendation**: Ready for production deployment / Requires hotfix before release.
