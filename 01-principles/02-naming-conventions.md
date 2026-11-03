# 02. Naming Conventions & Self-Documenting Code

---

## 1. Definition
**Naming Conventions** represent a standardized, predictable system for assigning names to variables, functions, classes, files, packages, and constants. **Self-Documenting Code** means code whose intent, behavior, and types are immediately obvious from its names alone, without needing explanatory inline comments.

---

## 2. Purpose
The purpose of disciplined naming is to eliminate ambiguity. A developer or AI coding agent should instantly know what a variable stores, what a function does, and what a class represents simply by reading its identifier.

---

## 3. Why It Matters
Poor names are the primary source of subtle bugs and wasted cognitive energy.
*   Cryptic abbreviations (`val usrDtls = ...`) force developers to stop and decode symbols.
*   Misleading names (`fun getUser()` which secretly deletes expired tokens and mutates database state) cause dangerous side effects.
*   Consistent names create subconscious familiarity: you can predict method names across an entire codebase without looking at documentation.

---

## 4. When to Use It
*   **Always**: Every identifier created in production code must adhere to deliberate naming conventions.
*   **Scope-Dependent Length**: 
    *   Variables with broad scope (class fields, global constants) need longer, highly descriptive names (e.g. `maximumRetryAttempts`).
    *   Variables with tiny scope (e.g. a 2-line lambda or loop counter) can be concise (e.g. `items.map { it.id }` or `for (i in 0 until count)`).

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Hyper-Verbose Redundancy**: Avoid repeating context needlessly. If a class is named `UserProfile`, its property should be `name`, not `userProfileName`.
*   **Obsolete Hungarian Notation**: Do not prefix variables with type abbreviations (e.g., `strUserName`, `iCount`, `m_pData`) in modern statically-typed languages like Kotlin or TypeScript. Let the compiler and IDE handle types.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **Self-Explanatory**: Drastically reduces the need for comments. | **Requires Thinking Time**: Choosing precise, accurate names takes mental effort upfront. |
| **Searchability**: Full, unambiguous words make finding references trivial via `grep` or IDE search. | **Longer Line Lengths**: Expressive names take more horizontal space. |
| **AI Agent Accuracy**: AI coding agents understand codebase intent much better with precise identifiers. | **Renaming Friction**: Refactoring poorly named legacy code requires care. |

---

## 7. Practical Examples

### Universal Casing Standards
*   **Classes & Interfaces**: `PascalCase` (e.g., `PaymentProcessor`, `NetworkResponse`)
*   **Functions & Variables**: `camelCase` (e.g., `calculateMonthlyTotal()`, `userSessionToken`)
*   **Constants**: `UPPER_SNAKE_CASE` (e.g., `DEFAULT_TIMEOUT_MILLIS`, `MAX_CACHE_SIZE`)
*   **Packages / Directories**: `lowercase` with no underscores or dashes (e.g., `com.playbook.feature.auth`)

### Bad vs. Good Identifier Naming (Kotlin)

```kotlin
// BAD: Cryptic, abbreviated, misleading intent
val d: Int = 86400 // What is d?
val usrLst = fetch() // What does fetch do? Fetch what?
fun chk(u: User): Boolean // What does chk check?

fun processUserData(u: User) {
    // Hidden side effect: name says "process", but it deletes records!
    db.deleteUser(u.id)
}
```

```kotlin
// GOOD: Clear, intention-revealing, side-effect free
val secondsInOneDay: Int = 86400
val activeUsers: List<User> = fetchActiveSubscribers()

fun isAccountEligibleForDiscount(user: User): Boolean {
    return user.isSubscriptionActive && user.tenureMonths >= 12
}

fun deactivateAccount(user: User) {
    // Explicit name matches the destructive action
    database.markUserInactive(user.id)
}
```

### Boolean Naming Guidelines
Boolean variables and functions returning booleans should always read like yes/no questions:
*   `isActive`, `hasPermission`, `canEdit`, `shouldRetry`, `isVerified`
*   *Avoid negative booleans*: Prefer `isEnabled` over `isNotDisabled` (double negatives like `!isNotDisabled` confuse readers).

---

## 8. Common Mistakes
1.  **Vague Verbs**: Using `handle()`, `process()`, or `doStuff()` instead of precise verbs like `parse()`, `validate()`, `persist()`, or `render()`.
2.  **Lying Names**: A function named `getUserProfile()` that silently makes network calls, refreshes tokens, and updates database records without documenting or signaling those side effects.
3.  **Abbreviations**: Using `btnSub`, `reqDto`, `mgr` instead of `submitButton`, `registrationRequest`, `manager`.

---

## 9. Verification Checklist

- [ ] Do variable names state *what* they hold, not just *how* they are implemented?
- [ ] Do function names start with an active verb describing the action (`calculate`, `fetch`, `validate`)?
- [ ] Are boolean names prefixed with `is`, `has`, `can`, or `should`?
- [ ] Are cryptic or non-standard abbreviations eliminated?
- [ ] Is context avoided in property names (e.g., `User.email` instead of `User.userEmail`)?
