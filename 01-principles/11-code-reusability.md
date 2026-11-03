# 11. Pragmatic Code Reusability: DRY, Composition & The Rule of Three

---

## 1. Definition
**Code Reusability** is the design practice that enables software components, algorithms, and models to be reused across different parts of an application without copy-pasting. It is governed by **DRY (Don't Repeat Yourself)**, **The Rule of Three** (wait until code is duplicated three times before abstracting), and **Composition over Inheritance**.

---

## 2. Purpose
Copy-pasting logic leads to "shotgun surgery": when a bug is found in one copy, you must remember to find and update all five other copies across the codebase. Reusability centralizes truth, ensuring that a fix or improvement immediately benefits all consumers.

---

## 3. Why It Matters
*   **The Wrong Abstraction Danger**: Applying DRY prematurely by merging two pieces of code that look identical today—but evolve for different business reasons tomorrow—creates a monstrous, heavily flag-riddled function. Sandi Metz's law states: *"Duplication is far cheaper than the wrong abstraction."*
*   **Composition Over Inheritance**: Deep class inheritance hierarchies (`BaseActivity` $\rightarrow$ `NetworkActivity` $\rightarrow$ `AuthActivity` $\rightarrow$ `MainActivity`) create brittle, tightly coupled code where changing a base class breaks everything. Composition allows assembling behaviors dynamically.

---

## 4. When to Use It
*   **The Rule of Three**: When you write similar code the first time, write it simply. When you write it a second time, tolerate the duplication. When you write it a third time, extract a clean, reusable abstraction.
*   **Domain Calculations**: Universal business rules (e.g. currency conversion, tax calculation, password validation) should always have a single canonical source of truth.
*   **Design System UI**: Common atomic UI components (primary buttons, error banners, input fields) should be extracted into reusable Compose components.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Accidental Duplication**: Two functions that look the same today but belong to completely unrelated business domains (e.g. formatting an order date vs. formatting a blog post date) should not be merged into a single generic function if their requirements may diverge next month.
*   **Test Code (DAMP over DRY)**: Unit test code should be **DAMP (Descriptive And Meaningful Phrases)** rather than strictly DRY. Test clarity and independence matter more than abstracting every test setup step into a complex helper hierarchy.

---

## 6. Advantages & Disadvantages

| Well-Timed Abstraction (Rule of Three) | Premature Abstraction (Forced DRY) |
| :--- | :--- |
| **High Modularity**: Single place to fix bugs. | **High Coupling**: Two unrelated features become tangled. |
| **Clear Business Rules**: Consistent behavior everywhere. | **Parameter Explosion**: Shared method needs 10 boolean flags. |
| **Composability**: Small building blocks easily combined. | **Fragile Changes**: Fixing Feature A breaks Feature B. |

---

## 7. Practical Examples

### Bad Example: Premature DRY Creating a Flag Monster
```kotlin
// BAD: Forced DRY between Admin and Customer flows forces messy boolean flags
fun renderUserHeader(
    name: String,
    role: String,
    isAdmin: Boolean,
    showDeleteButton: Boolean,
    allowImpersonation: Boolean,
    themeColor: Color
) {
    // 50 lines of complex conditionals trying to satisfy two totally different screens
    if (isAdmin) {
        if (allowImpersonation) { /* render special button */ }
        if (showDeleteButton) { /* render danger button */ }
    } else {
        /* render customer loyalty points */
    }
}
```

### Good Example: Composition Over Inheritance (Kotlin Extensions & Delegation)
```kotlin
// GOOD: Composition of focused, reusable validation utilities
interface PasswordValidator {
    fun validate(password: String): ValidationResult
}

class StandardPasswordValidator : PasswordValidator {
    override fun validate(password: String): ValidationResult {
        return when {
            password.length < 8 -> ValidationResult.Invalid("Must be at least 8 characters")
            !password.any { it.isDigit() } -> ValidationResult.Invalid("Must contain at least 1 digit")
            !password.any { it.isUpperCase() } -> ValidationResult.Invalid("Must contain at least 1 uppercase letter")
            else -> ValidationResult.Valid
        }
    }
}

// Composed cleanly into different ViewModels without inheritance
class RegistrationViewModel(
    private val passwordValidator: PasswordValidator
) : ViewModel() {
    fun onPasswordChanged(password: String) {
        val result = passwordValidator.validate(password)
        // handle UI state
    }
}
```

---

## 8. Common Mistakes
1.  **Deep Inheritance Trees**: Subclassing 5 levels deep instead of using interface composition or Kotlin extension functions.
2.  **Premature Generalization**: Building an elaborate generic framework for a feature that only has one single concrete use case.
3.  **Shared Mutable State**: Creating a shared singleton "utility" class that holds mutable state, causing race conditions across callers.

---

## 9. Verification Checklist

- [ ] Was the abstraction created after observing at least three genuine duplicate occurrences (Rule of Three)?
- [ ] Is the shared function free of domain-specific boolean flags used to switch behaviors for different callers?
- [ ] Is composition preferred over class inheritance for sharing behavior?
- [ ] Are test cases readable and descriptive without being obscured by over-abstracted test helpers?
- [ ] Can a bug fix in the reusable component be safely deployed without unintended side effects on other consumers?
