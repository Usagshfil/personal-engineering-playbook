# 01. Modern Kotlin Idioms: Type Safety, Immutability & Expressiveness

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Kotlin 2.0+ (K2 Compiler)

---

## 1. Definition & Core Concept

**Modern Kotlin Idioms** represent the canonical patterns, language features, and design conventions that maximize Kotlin's expressiveness, compile-time safety, and performance. Rather than writing "Java with Kotlin syntax," idiomatic Kotlin leverages **first-class immutability** (`val`), **sealed hierarchies** for domain modeling, **inline value classes** to eliminate primitive obsession, **property delegation**, and disciplined use of **scope functions** (`let`, `apply`, `run`, `also`).

---

## 2. Purpose

The purpose of this standard is to prevent common concurrency bugs, eliminate null-pointer exceptions, optimize JVM memory allocations, and reduce boilerplate while maintaining readable, maintainable code across all Android modules.

---

## 3. Why It Matters

*   **Null-Safety at Compile Time**: Kotlin's type system distinguishes nullable (`String?`) from non-nullable (`String`) types at compile time, eliminating the historically notorious `NullPointerException`.
*   **Compile-Time Exhaustiveness**: Modeling state with `sealed interface` enables exhaustive `when` expressions. When a new state or event is added, the compiler flags every unhandled branch across the entire project.
*   **Zero-Overhead Abstractions**: Inline value classes (`@JvmInline value class`) provide domain-specific type safety (e.g. distinguishing `UserId` from `OrderId`) without allocating heap objects at runtime.
*   **Thread-Safe Concurrency**: Immutable data models (`val` fields, read-only collections) cannot be corrupted when passed across threads or coroutine dispatchers.

---

## 4. When to Use It

*   **Data Models & DTOs**: Use `data class` with read-only properties (`val`) for entities, network responses, and UI state objects.
*   **Domain States & Results**: Use `sealed interface` to represent discrete application states (`Loading`, `Success`, `Error`), UI events, and navigation destinations.
*   **Preventing Primitive Obsession**: Wrap raw identifiers, currency values, or email strings in `@JvmInline value class` to prevent parameter swap bugs:
    ```kotlin
    @JvmInline value class UserId(val value: String)
    @JvmInline value class Email(val value: String)
    ```
*   **Scope Functions Guidelines**:
    *   `apply`: Use for configuring object instances during construction.
    *   `let`: Use exclusively for executing a code block on a non-null object (`user?.let { ... }`) or scoping local transformations.
    *   `run`: Use when computing an expression or initializing a value that requires temporary local variables.
    *   `also`: Use for side effects that do not alter the object (e.g. logging or telemetry).

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Scope Function Pyramids**: Never chain multiple scope functions together (e.g., `item.let { it.run { it.also { ... } } }`). Chaining obscures variable bindings, confuses readers, and increases cognitive load.
*   **Overuse of Extension Functions**: Do not turn every private helper into a public extension function on core types like `String` or `Context`. Keep extension functions scoped to the package or feature where they are needed.
*   **Mutable Data Classes**: Never declare `var` properties inside a `data class`. Mutating an object that is stored in a `Set` or used as a `Map` key alters its `hashCode`, causing silent lookup failures and data corruption.

---

## 6. Advantages & Disadvantages

| Idiomatic Kotlin Patterns | Legacy / Non-Idiomatic Patterns |
| :--- | :--- |
| **Exhaustive State Handling**: Compiler forces handling of all branches. | **Fragile Switch Statements**: Unhandled states fail silently at runtime. |
| **Type-Safe Domain Identifiers**: Value classes prevent accidental parameter swaps. | **Primitive Obsession**: Passing raw `String` or `Int` leads to subtle bugs. |
| **Immutable Collections**: Read-only interfaces (`List`, `Set`) prevent side-effects. | **Shared Mutable State**: Modifying shared collections causes race conditions. |
| **Clean Property Delegation**: `by lazy`, `by viewModels()` eliminate boilerplate. | **Manual Synchronization**: Boilerplate double-check locking logic. |

---

## 7. Practical Examples

### Bad Example: Java-Style Boilerplate, Primitive Obsession & Mutability
```kotlin
// BAD: Mutable data class, primitive obsession, un-exhaustive if-else chains
data class User(
    var id: String,          // Mutable var!
    var email: String,       // Raw string (easy to swap with name)
    var isVerified: Boolean
)

class UserProfilePresenter {
    fun processUser(user: User?, newEmail: String) {
        // Nested null checks instead of safe calls
        if (user != null) {
            if (newEmail.contains("@")) {
                user.email = newEmail // Mutating shared state directly!
            }
        }
    }
}
```

### Good Example: Idiomatic Kotlin 2.0 with Value Classes & Sealed Result
```kotlin
// GOOD: Value classes, immutable data class, sealed interface domain result
@JvmInline
value class UserId(val value: String)

@JvmInline
value class EmailAddress(val value: String) {
    init {
        require(value.contains("@") && value.contains(".")) { "Invalid email address format: $value" }
    }
}

data class User(
    val id: UserId,
    val email: EmailAddress,
    val isVerified: Boolean
)

sealed interface UpdateEmailResult {
    data class Success(val updatedUser: User) : UpdateEmailResult
    data class InvalidFormat(val reason: String) : UpdateEmailResult
    data object UserNotFound : UpdateEmailResult
}

class UserProfileManager {
    fun updateEmail(user: User?, rawEmail: String): UpdateEmailResult {
        if (user == null) return UpdateEmailResult.UserNotFound
        
        return try {
            val validEmail = EmailAddress(rawEmail)
            val updated = user.copy(email = validEmail) // Pure copy, zero mutation
            UpdateEmailResult.Success(updated)
        } catch (e: IllegalArgumentException) {
            UpdateEmailResult.InvalidFormat(e.message ?: "Invalid email")
        }
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Swallowing `CancellationException` in `runCatching`**:
    *   *Problem*: `runCatching { ... }` catches all `Throwable` instances, including `kotlinx.coroutines.CancellationException`. This silently breaks cooperative coroutine cancellation and causes leaked background tasks.
    *   *Remedy*: Re-throw `CancellationException` immediately inside catch blocks, or use custom result wrappers.
2.  **Exposing `MutableList` via Getters**:
    *   *Problem*: Exposing a `MutableList` from a repository or state holder allows external callers to modify internal state without the owner's knowledge.
    *   *Remedy*: Always expose read-only `List<T>`:
        ```kotlin
        private val _items = mutableListOf<Item>()
        val items: List<Item> get() = _items.toList()
        ```
3.  **Destructuring Position Hazards**:
    *   *Problem*: Destructuring a `data class` (`val (id, name) = user`) relies strictly on property declaration order, not name. Reordering fields in the data class silently maps the wrong values.
    *   *Remedy*: Use explicit property access (`user.id`, `user.name`) unless destructuring standard pairs/tuples.

---

## 9. Verification Checklist

- [ ] Are all data class properties declared as `val` (immutable)?
- [ ] Are domain states, UI events, and error hierarchies modeled with `sealed interface`?
- [ ] Are domain identifiers wrapped in `@JvmInline value class` where primitive confusion is a risk?
- [ ] Are collections exposed from repositories and ViewModels as read-only (`List`, `Set`, `Map`)?
- [ ] Are scope functions (`let`, `apply`, `run`, `also`) unchained and limited to single operations?
- [ ] Does `when` statement over sealed hierarchies avoid using a catch-all `else` branch (enforcing exhaustiveness)?
