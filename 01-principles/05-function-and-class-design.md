# 05. Function and Class Design: Cohesion, Immutability & Scope

---

## 1. Definition
**Function and Class Design** refers to the principles governing how small units of software are constructed. Good design emphasizes **High Cohesion** (class elements belong together), **Low Coupling** (minimal inter-dependency), **Immutability by Default** (data structures that cannot be mutated after creation), and **Minimal Scope** (keeping variables and methods as private as possible).

---

## 2. Purpose
Poorly designed functions and classes become tangled webs of mutable state and hidden side effects. The purpose of disciplined design is to ensure that every function is a predictable, testable, and isolated unit that does **one thing well**.

---

## 3. Why It Matters
*   **Predictability**: An immutable data structure cannot have its fields mysteriously changed by a background thread, an event handler, or a downstream function.
*   **Testability**: Pure functions that take explicit inputs and return outputs without mutating global variables can be unit tested in isolation without mocks or complex setup.
*   **Composability**: Small, focused functions can be easily reused and combined like Lego bricks.

---

## 4. When to Use It
*   **Universal Invariant (Immutability by Default)**: Default to immutable data bindings and read-only data structures across all languages:
    *   *Kotlin*: Prefer `val` over `var`; default to `List` over `MutableList`.
    *   *TypeScript / JavaScript*: Prefer `const` over `let`/`var`; use `readonly` collections and frozen objects.
    *   *Python*: Prefer frozen `dataclass` or immutable `tuple`/`frozenset`.
*   **Small Functions**: Target functions that fit on a single screen without scrolling (ideally 10–25 lines).
*   **Parameter Limits**: Keep function parameter counts to $\le 3$. If a function requires 5 or 6 arguments, group them into a dedicated configuration or data object.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Excessive Micro-Methods**: Do not extract every 2-line expression into a separate private method if the extraction destroys readability and forces readers to bounce through 15 trivial methods to understand a simple linear sequence.
*   **Immutability in High-Frequency Hot Loops**: In performance-critical image processing or 60fps game loops, instantiating hundreds of new immutable objects per frame can trigger garbage collector stutters. Here, a pre-allocated reusable mutable buffer is the correct pragmatic choice.

---

## 6. Advantages & Disadvantages

| Immutability & Small Functions | Mutable State & Long Functions |
| :--- | :--- |
| **Thread-Safe**: Safe across coroutines and threads. | **Race Conditions**: Susceptible to multi-threaded corruption. |
| **Trivial Testing**: Output is purely a function of input. | **Hard Testing**: Requires inspecting and setting up hidden state. |
| **Local Reasoning**: You only need to read 20 lines to understand. | **High Cognitive Load**: Must remember 100 lines of prior state. |
| **Slight Memory Overhead**: New instances created during updates. | **Direct Mutation**: Reuses memory, but state tracking is fragile. |

---

## 7. Practical Examples

### Bad Example: Mutable State, Side Effects & Too Many Parameters
```kotlin
// BAD: Mutates external state, relies on side effects, too many arguments
class OrderService {
    var lastOrderTotal: Double = 0.0 // Dangerous shared mutable state

    fun processOrder(
        userId: String,
        items: MutableList<Item>,
        couponCode: String?,
        isExpress: Boolean,
        shippingAddress: String,
        billingAddress: String
    ) {
        // Mutates the input list directly!
        items.removeIf { it.isOutOfStock }
        
        var total = 0.0
        for (item in items) {
            total += item.price
        }
        if (couponCode != null) {
            total *= 0.9
        }
        if (isExpress) {
            total += 15.0
        }
        
        // Mutates global field
        lastOrderTotal = total
        sendEmail(userId, total) // Unmocked hidden side effect
    }
}
```

### Good Example: Pure Function, Immutable Data Class & Scoped State
```kotlin
// GOOD: Immutable models, encapsulated parameters, pure calculation
data class OrderRequest(
    val userId: String,
    val items: List<Item>,
    val couponCode: String? = null,
    val isExpressShipping: Boolean = false,
    val shippingAddress: Address,
    val billingAddress: Address
)

data class OrderSummary(
    val validItems: List<Item>,
    val subtotal: Double,
    val discount: Double,
    val shippingFee: Double,
    val grandTotal: Double
)

class OrderCalculator {
    fun calculateSummary(request: OrderRequest): OrderSummary {
        val validItems = request.items.filterNot { it.isOutOfStock }
        val subtotal = validItems.sumOf { it.price }
        val discount = if (request.couponCode != null) subtotal * 0.10 else 0.0
        val shippingFee = if (request.isExpressShipping) 15.0 else 0.0
        val grandTotal = subtotal - discount + shippingFee

        return OrderSummary(
            validItems = validItems,
            subtotal = subtotal,
            discount = discount,
            shippingFee = shippingFee,
            grandTotal = grandTotal
        )
    }
}
```

---

## 8. Common Mistakes
1.  **Output Arguments**: Passing an object into a function so that the function modifies its properties rather than returning a new value.
2.  **Boolean Flag Arguments**: Passing `fun render(isVip: Boolean)` is a code smell indicating the function does two completely different things. Split it into `renderStandard()` and `renderVip()`.
3.  **Leaking Internal State**: Returning a direct reference to a mutable private list from a ViewModel or class. Always expose read-only types (`val items: StateFlow<List<Item>>`).

---

## 9. Verification Checklist

- [ ] Are variables declared as immutable (`val`) by default, using `var` only when strictly necessary?
- [ ] Do functions accept $\le 3$ arguments, grouping related parameters into data classes?
- [ ] Are public methods and properties kept to the absolute minimum necessary?
- [ ] Are functions free of unexpected side effects on their input parameters?
- [ ] Does every function operate at a consistent level of abstraction?
