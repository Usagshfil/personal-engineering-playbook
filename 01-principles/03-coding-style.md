# 03. Coding Style, Formatting & Visual Hierarchy

---

## 1. Definition
**Coding Style** encompasses the visual presentation, formatting rules, indentation, bracket placement, line wrapping, and syntax patterns across a codebase. It is typically enforced via automated tools (linters and formatters like `ktlint`, `spotless`, `detekt`, or `prettier`).

---

## 2. Purpose
The purpose of a unified coding style is to eliminate visual friction. When all files in a repository share the same rhythm and formatting, your brain focuses entirely on the **logic and architecture**, rather than stumbling over inconsistent whitespace, weird line breaks, or personal styling quirks.

---

## 3. Why It Matters
*   **Git Diffs Stay Clean**: Inconsistent indentation or trailing spaces cause massive merge conflicts and pollute pull request reviews with irrelevant formatting noise.
*   **Faster Scanning**: Consistent visual layout allows senior developers and AI agents to quickly identify control flow and logical groupings.
*   **Automated Harmony**: Code style debates waste engineering hours; an automated formatter makes styling decisions objective and instant.

---

## 4. When to Use It
*   **Universal Enforcement**: Apply automated formatting to all source code before committing (via pre-commit hooks or CI checks).
*   **Visual Grouping**: Use blank lines deliberately to separate logical blocks (input validation, calculation, response preparation).

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Manual Bickering in PRs**: Never debate stylistic trivia (spaces vs. tabs, trailing commas) manually during code reviews. If a rule matters, configure an automated tool to enforce or fix it. If the tool can't enforce it, it usually doesn't matter enough to hold up code.
*   **Excessive Vertical Spacing**: Do not put 3 or 4 empty lines between methods. One empty line between functions is clean and sufficient.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **Painless Reviews**: Code reviews focus 100% on correctness, performance, and architecture. | **Initial Tool Setup**: Requires configuring linter plugins in Gradle/IDE. |
| **Clean Version Control**: Every line changed in Git represents a real logical change. | **Strictness Fatigue**: Strict linters can occasionally feel pedantic during rapid prototyping. |
| **Team/Agent Alignment**: AI coding agents conform seamlessly to codebase norms. | **Format Churn**: Reformatting legacy codebases all at once requires a dedicated commit. |

---

## 7. Practical Examples

### Visual Hierarchy & Guard Clauses (Kotlin)

```kotlin
// BAD: Inconsistent formatting, deep nesting, no clear visual hierarchy
fun registerUser(user: User?, isPromo: Boolean): Boolean {
if(user!=null){
    if(user.email.isNotEmpty()){
            if(user.age>=18){
                // Registration
                val registered = db.insert(user)
                    if(registered){
                        if(isPromo){
                            mailer.sendPromo(user)
                        }
                        return true
                    } else {
                        return false
                    }
            }else{return false}
    }else{return false}
}else{return false}
}
```

```kotlin
// GOOD: Clean formatting, guard clauses (early returns), distinct logical steps
fun registerUser(user: User?, isPromo: Boolean): Boolean {
    // 1. Guard clauses (Fail fast)
    if (user == null || user.email.isBlank()) return false
    if (user.age < 18) return false

    // 2. Core action
    val isRegistered = database.insert(user)
    if (!isRegistered) return false

    // 3. Conditional side effects
    if (isPromo) {
        mailer.sendPromo(user)
    }

    return true
}
```

---

## 8. Common Mistakes
1.  **Deep Arrow Anti-Pattern**: Allowing nested `if`/`else`/`try` blocks to push code 50 columns to the right. Use early returns (`if (!valid) return`) instead.
2.  **Long Unwrapped Lines**: Writing single lines exceeding 120 characters with nested function calls. Break arguments onto separate lines with trailing commas.
3.  **Missing Automated Formatters**: Relying on human discipline rather than automated scripts (`./gradlew ktlintFormat` or `spotlessApply`).

---

## 9. Verification Checklist

- [ ] Is an automated linter/formatter configured for the project (`ktlint`, `detekt`, or `spotless`)?
- [ ] Are line lengths bounded within a readable width (100–120 characters)?
- [ ] Are early returns used to keep indentation depth at $\le 2$ levels?
- [ ] Are chained operations (e.g. Rx/Flow/Streams `.map().filter()`) formatted with each operator on a new line?
- [ ] Are imports organized cleanly with unused imports deleted?
