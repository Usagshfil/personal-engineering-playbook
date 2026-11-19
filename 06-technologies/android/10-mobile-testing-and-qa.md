# 10. Mobile Testing & Quality Assurance: Compose UI Tests, Maestro E2E & Roborazzi Screenshot Regression

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: AndroidX Compose UI Test 1.6+, Maestro 1.35+, Roborazzi 1.10+, Robolectric 4.12+

---

## 1. Definition & Core Concept

**Mobile Quality Assurance** requires a multi-layered verification strategy tailored to mobile application constraints. Unlike web applications where hotfixes can be deployed instantaneously, mobile release cycles are gated by app store review processes. 

This standard establishes the **Pragmatic Mobile Testing Pyramid**, combining fast JVM unit tests, isolated Jetpack Compose UI tests, automated visual screenshot regression tests, and black-box declarative End-to-End (E2E) user journey flows.

```
+---------------------------------------------------------------------------------------------------+
|                                PRAGMATIC MOBILE TESTING PYRAMID                                   |
|                                                                                                   |
|                       / \                                                                         |
|                      /   \       [Tier 4: E2E Flows (~5%)]                                       |
|                     /  ▲  \      Declarative Black-Box User Journeys (Maestro YAML)               |
|                    /───────\                                                                      |
|                   /         \    [Tier 3: Visual Regression (~5%)]                               |
|                  /     ▲     \   JVM Screenshot Diffs (Roborazzi + Robolectric)                   |
|                 /─────────────\                                                                   |
|                /               \ [Tier 2: Component UI Tests (~20%)]                              |
|               /        ▲        \ Jetpack Compose UI Testing (ComposeTestRule & Semantics Tree)   |
|              /───────────────────\                                                                |
|             /                     \ [Tier 1: Domain & Unit Tests (~70%)]                          |
|            /           ▲           \ JUnit 5, Coroutines TestScope, MockK, Turbine (Pure JVM)     |
|           /─────────────────────────\                                                             |
+---------------------------------------------------------------------------------------------------+
```

### The 4 Test Tiers Explained
1.  **Tier 1: Pure JVM Unit Tests ($\sim 70\%$)**: Verifies business rules, ViewModels, Reducers, Repositories, and Room DAOs. Executes in milliseconds on the JVM without launching emulators.
2.  **Tier 2: Compose Component Tests ($\sim 20\%$)**: Verifies isolated UI composables, state hoisting, user interactions (clicks, text input, gestures), and accessibility semantics.
3.  **Tier 3: Visual Screenshot Regression ($\sim 5\%$)**: Verifies visual fidelity across themes (Light/Dark mode), dynamic color palettes, and font scaling ($\times 1.0$ to $\times 1.5$) using Roborazzi running natively on the JVM.
4.  **Tier 4: Black-Box E2E Flows ($\sim 5\%$)**: Verifies multi-screen mission-critical user journeys (e.g. Login $\to$ Cart $\to$ Checkout) using Maestro YAML flows on physical devices or emulators in CI.

---

## 2. Purpose

The purpose of this standard is to guarantee mobile functional correctness, eliminate visual regressions, verify critical user journeys across device densities, and eradicate test flakiness without slowing down developer velocity.

---

## 3. Why It Matters

*   **High Cost of Mobile Defects**: A breaking bug in production cannot be instantly patched. Releasing a hotfix requires rebuilding, re-signing, and waiting 4–48 hours for Google Play review.
*   **The Flakiness Trap of Traditional Espresso**: Traditional Espresso tests that rely on arbitrary timeouts, fragile view matchers, and device hardware timing frequently flake in CI, causing teams to ignore test failures.
*   **Accessibility & Semantics Verification**: Mobile apps must support screen readers (TalkBack) and variable font scaling. Compose semantic trees ensure accessibility is verified programmatically.
*   **Visual Regression Detection**: Code changes in shared themes or spacing tokens can break layouts in distant screens. Roborazzi screenshot comparisons catch visual clipping and overflow before release.

---

## 4. When to Use It

*   **Compose UI Tests**: Use for all complex interactive composables, forms with validation errors, stateful buttons, and animated visibility changes.
*   **Roborazzi Screenshot Tests**: Use for Design System UI components, typography scales, light/dark mode variations, and localized text expansion (e.g. German text length).
*   **Maestro E2E Flows**: Use for core user journeys that determine business viability:
    *   Authentication & Account Creation.
    *   Core CRUD and Offline-First Sync workflows.
    *   Checkout and In-App Purchase flows.
    *   Deep linking and notification tap handling.

---

## 5. When NOT to Use It

*   **Do NOT write UI or E2E tests for pure business logic**: Validating tax calculations, date formatting, or coupon discount percentages belongs in Tier 1 unit tests (100x faster execution).
*   **Do NOT screenshot volatile, dynamic data**: Avoid screenshot testing live feeds with unpredictable image downloads or dynamic current timestamps. Mock all data sources to fixed, deterministic values.
*   **Do NOT write Maestro flows for edge-case validation**: Checking if an email field rejects 15 different invalid email formats should be tested via unit tests on the Validator class, not through 15 separate E2E UI runs.

---

## 6. Advantages & Disadvantages

| Framework | Execution Target | Speed | Flakiness Risk | Primary Strength |
| :--- | :--- | :--- | :--- | :--- |
| **JUnit 5 + MockK + Turbine** | JVM | **Instantaneous** ($<1\text{s}$) | **Zero** | Verifies coroutines, state machines, and business logic. |
| **Compose UI Test** | JVM (Robolectric) or Device | Fast ($1\text{s} - 3\text{s}$) | Low | Verifies user interactions and Compose semantics. |
| **Roborazzi Screenshot** | JVM (Robolectric Native Graphics) | Fast ($2\text{s} - 5\text{s}$) | Low | Detects pixel-level layout shifts and font scaling clips. |
| **Maestro E2E** | Emulator / Device | Moderate ($15\text{s} - 60\text{s}$) | Very Low | Readable YAML; black-box user journey verification. |

---

## 7. Practical Examples

### 7.1 Jetpack Compose Component Test with Semantic Tags

```kotlin
// ui/component/LoginFormTest.kt
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class LoginFormTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun loginForm_invalidEmail_displaysErrorMessage() {
        var submittedEmail: String? = null

        composeTestRule.setContent {
            LoginForm(
                onLoginSubmitted = { email, _ -> submittedEmail = email }
            )
        }

        // 1. Target UI elements using testTag instead of brittle string literals
        composeTestRule.onNodeWithTag("email_input")
            .performTextInput("invalid-email-format")

        composeTestRule.onNodeWithTag("password_input")
            .performTextInput("SecurePassword123!")

        composeTestRule.onNodeWithTag("login_button")
            .performClick()

        // 2. Assert error message is displayed
        composeTestRule.onNodeWithText("Please enter a valid email address")
            .assertIsDisplayed()

        // 3. Verify submission callback was NOT triggered
        assert(submittedEmail == null)
    }
}
```

### 7.2 Roborazzi Visual Regression Test (JVM-based)

```kotlin
// ui/component/TaskItemScreenshotTest.kt
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import com.github.takahirom.roborazzi.RoborazziRule
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE) // Enables pixel-accurate native graphics on JVM
class TaskItemScreenshotTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @get:Rule
    val roborazziRule = RoborazziRule(
        options = RoborazziRule.Options(
            outputDirectoryPath = "src/test/snapshots/images"
        )
    )

    @Test
    fun taskItem_completed_lightTheme() {
        composeTestRule.setContent {
            AppTheme(darkTheme = false) {
                TaskItem(
                    task = Task(id = "1", title = "Write Android Standards", isCompleted = true),
                    onToggle = {}
                )
            }
        }

        // Captures pixel snapshot and compares against baseline golden image
        composeTestRule.onRoot().captureRoboImage()
    }
}
```

### 7.3 Maestro Declarative End-to-End Flow (YAML)

```yaml
# .maestro/flows/login_and_create_task.yaml
appId: com.personal.playbook.app
tags:
  - smoke
  - critical_path
---
- launchApp:
    clearState: true

- assertVisible: "Welcome Back"

# Type credentials using semantic test tags
- tapOn:
    id: "email_input"
- inputText: "engineer@playbook.internal"

- tapOn:
    id: "password_input"
- inputText: "SuperSecret123!"

- tapOn:
    id: "login_button"

# Assert successful navigation to Dashboard
- assertVisible:
    text: "My Tasks"
    timeout: 5000

# Perform CRUD action
- tapOn:
    id: "fab_add_task"

- tapOn:
    id: "task_title_input"
- inputText: "Verify Maestro in CI"

- tapOn:
    id: "save_task_button"

# Verify task appears in the list
- assertVisible: "Verify Maestro in CI"
```

---

## 8. Common Mistakes & Pitfalls

1.  **Using `Thread.sleep()` to Handle Async Operations**:
    *   *Problem*: Adding `Thread.sleep(3000)` introduces massive CI slowdowns and still flakes if the CI server is under heavy CPU load.
    *   *Remedy*: Rely on Compose UI Test auto-synchronization (`composeTestRule.waitUntil()`) or Maestro's built-in `timeout` parameters that poll reactively.
2.  **Matching Views by Raw Localized Text**:
    *   *Problem*: Asserting `.onNodeWithText("Submit")` breaks when running tests against localized device configurations (e.g. Spanish, German, Vietnamese).
    *   *Remedy*: Use `Modifier.testTag("submit_button")` and `.onNodeWithTag("submit_button")` for all functional test assertions.
3.  **Executing E2E Tests Against Live Production Backends**:
    *   *Problem*: Running E2E tests against live cloud databases causes data pollution, triggers real SMS/Email costs, and flakes when the network drops.
    *   *Remedy*: Use MockWebServer or pre-configured staging mock backends with deterministic responses for CI testing.
4.  **Screenshot Test Flakiness Caused by Dynamic Elements**:
    *   *Problem*: Blinking cursor focus, animated loading bars, or dynamic timestamps (`"3 minutes ago"`) cause Roborazzi screenshot comparisons to fail falsely.
    *   *Remedy*: Disable cursor blinking in tests, mock clock timestamps to fixed ISO instants, and disable window animations in test configurations.

---

## 9. Verification Checklist

- [ ] Are business logic, ViewModels, and repositories covered by fast pure JVM unit tests ($\ge 70\%$ of test pyramid)?
- [ ] Do Compose UI tests use `Modifier.testTag(...)` instead of hardcoded strings for target identification?
- [ ] Are all `Thread.sleep()` calls banned from UI test code?
- [ ] Are critical user journeys (Auth, Checkout, Core CRUD) automated using declarative Maestro YAML flows?
- [ ] Are visual regressions guarded by Roborazzi screenshot tests running natively on JVM?
- [ ] Are animated spinners and dynamic clock timestamps frozen/mocked during screenshot capture?
- [ ] Does the CI pipeline execute JVM tests and screenshot comparisons on every Pull Request?
