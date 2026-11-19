---
name: testing-and-qa
sidebarTitle: "Testing & QA"
description: Design, implement, and execute automated unit tests, integration tests, UI smoke checks, and boundary tests under the Risk-Based Testing (RBT) doctrine. Use when writing test suites, verifying acceptance criteria, or validating quality gates.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: quality-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Testing and Quality Assurance Skill (Risk-Based Testing)

## 1. Overview & Capability
The **Testing and QA Skill** guides the systematic verification of software systems. Rejecting arbitrary numerical coverage quotas (like "mandatory 70%"), it enforces the **Risk-Based Testing (RBT)** doctrine: focusing high-density automated unit testing on complex business logic, calculations, and security boundaries, while verifying declarative UI through smoke tests and critical user journeys.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Writing automated unit tests for ViewModels, Repositories, Domain models, and calculations.
*   Writing integration tests for Room database queries and Retrofit network clients.
*   Designing test plans and test case specifications for a release milestone.
*   Verifying that acceptance criteria from user stories have been satisfied.

### When NOT to Use
*   Debugging an active crash or reproducing an isolated bug (use `debugging`).
*   Auditing code style or linter formatting (use `code-review`).
*   Unit-testing static, declarative UI layouts (e.g. Compose padding or CSS button color).

---

## 3. Required Inputs & Prerequisites
*   Source code files under test.
*   User stories with Gherkin acceptance criteria from `requirement-engineering`.
*   Testing libraries configured in project dependencies (e.g. JUnit 4/5, MockK, Turbine for Android/Kotlin; Jest/Vitest for Web; pytest for Python). Refer to [`06-technologies/README.md`](../../06-technologies/README.md).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Risk Tier Analysis ──> 2. Test Plan & Matrix ──> 3. Unit Test Domain Logic ──> 4. Boundary & Edge Testing ──> 5. Honest Verification
```

### Step 1: Risk Tier Analysis (Prioritize by Business Impact)
Classify components into verification tiers:
*   **Tier 1: High Risk (Mandatory Deep Unit Tests)**: Core calculations, financial math, authentication tokens, state machine transitions, access control. Target: exhaustive branch coverage.
*   **Tier 2: Medium Risk (Integration Tests)**: Room DAO queries, JSON serialization, offline caching sync, repository coordination. Target: verify data contracts with in-memory DB or MockWebServer.
*   **Tier 3: Low Risk (Smoke Checks)**: Declarative Compose UI layouts, static informational screens, animations. Target: manual smoke test or basic end-to-end journey check; zero unit tests required.

### Step 2: Test Case Specification (Arrange-Act-Assert)
Structure all test methods using the **AAA (Arrange, Act, Assert)** pattern with expressive naming:
$$\text{fun } [\text{methodUnderTesting}]\_[\text{condition}]\_[\text{expectedBehavior}]()$$
Example: `fun calculateDiscount_withExpiredCoupon_returnsZeroDiscount()`

### Step 3: Implement Unit Tests with Deterministic Time & Isolation
1.  **Isolate Async Operations**: Use virtual time controllers (e.g., `StandardTestDispatcher` in Kotlin Coroutines, `jest.useFakeTimers()` in JS) rather than real wall-clock sleeps (`Thread.sleep()`).
2.  **Test Reactive State Streams**: Use stream testing tools (e.g. Turbine for Kotlin `StateFlow`, reactive observers in web):
    ```kotlin
    // Illustrative Kotlin example with Turbine:
    viewModel.uiState.test {
        assertEquals(SearchUiState.Idle, awaitItem())
        viewModel.onQueryChanged("Android")
        assertEquals("Android", awaitItem().query)
    }
    ```
3.  **Inject Test Doubles**: Use fakes or mocks for external repositories, network clients, and databases.

### Step 4: Boundary & Adversarial Edge Testing
Explicitly test adversarial and extreme conditions:
*   Numeric boundaries: `0`, `-1`, `MAX_VALUE`, fractional pennies.
*   Collection boundaries: empty list, single item, 10,000 items (pagination limits).
*   String boundaries: empty string, whitespace only, strings with emojis or special characters (`<script>`, SQL quotes).
*   Temporal boundaries: network timeout, response out of order.

### Step 5: Honest Empirical Verification (The Honesty Clause)
1.  Execute the project's test command via shell (e.g., `./gradlew testDebugUnitTest`, `npm test`, `pytest`).
2.  Inspect raw output logs: confirm passes, failures, and execution times.
3.  **Strict Rule**: Never claim tests passed without empirical logs. If test tools are unavailable in the environment, state: *"Tests authored; verification not executed due to environment constraints. Manual testing required."*

---

## 5. Expected Outputs & Artifact Formats
*   `09-test-plan.md` & `10-test-case-specification.md`.
*   Executable test files in `src/test/` (Unit) and `src/androidTest/` (Instrumentation).
*   Empirical test execution logs and results.

---

## 6. Quality & Verification Checklist
- [ ] Are high-risk business logic components thoroughly tested with unit tests?
- [ ] Are test names descriptive and following the `method_condition_result` convention?
- [ ] Are edge cases (`null`, empty lists, `0`, timeouts) explicitly covered?
- [ ] Are coroutines tested deterministically using `runTest` and test dispatchers?
- [ ] Are test results reported with 100% honesty from actual tool execution?

---

## 7. Common Mistakes & Pitfalls
*   **Testing Trivial Framework Wrappers**: Writing unit tests that test whether Android's `TextView.setText()` sets text, wasting time on Google's code rather than your own logic.
*   **Thread.sleep in Tests**: Using real clock delays (`Thread.sleep(1000)`) instead of virtual time advances (`advanceUntilIdle()`), causing slow and flaky tests.
*   **Testing Implementation Details**: Testing private helper methods directly instead of testing the public observable behavior of the class.

---

## 8. Real-World Example Walkthrough
**Scenario**: Testing `CartViewModel` discount logic.
*   *Arrange*: Initialize `CartViewModel` with `FakeCartRepository`.
*   *Act*: Add 3 items totalling $120; apply coupon code "SAVE20".
*   *Assert*: Using Turbine, assert that emitted `CartUiState` contains `subtotal = 120.0`, `discount = 24.0`, and `finalTotal = 96.0`.
*   *Edge Case*: Apply coupon code with cart total $< $50 (minimum spend). Assert error message "Minimum spend of $50 required" is emitted.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `code-review` to inspect test quality and coverage.
*   $\rightarrow$ Hands off to `debugging` if tests reveal unexpected defects.

---

## 10. Tool Compatibility & Limitations
*   Antigravity can run `./gradlew testDebugUnitTest` and parse outputs directly.
*   In environments without Gradle CLI execution, agents must draft test suites and instruct the user to run the tests locally.
