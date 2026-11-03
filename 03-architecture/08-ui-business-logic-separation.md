# 08. Separation of Business Logic and UI (Keep UI Pure)

---

## 1. Definition
**Separation of Business Logic and UI** is the architectural mandate that user interface components (such as Jetpack Compose `@Composable` functions, React components, or XML views) must be **pure presentation mechanisms**. They are solely responsible for rendering state on the screen and capturing user gestures, while all validation, formatting algorithms, calculations, and data fetching reside exclusively in ViewModels, Domain Use Cases, or Repositories.

---

## 2. Purpose
When business calculations, sorting algorithms, or network calls are embedded directly inside UI rendering blocks (e.g. inside a Compose function), you cannot test that logic without running a slow, brittle UI test on an Android device or emulator. Separating logic makes the application **testable in milliseconds on the JVM**.

---

## 3. Why It Matters
*   **Zero UI Test Burden**: 90% of bugs are logic errors (e.g., wrong discount percentage, incorrect date math, missing edge cases). When logic is separated from UI, you can test it with simple, fast unit tests without launching any UI.
*   **Compose Performance & Recomposition**: Compose functions execute frequently during recomposition (sometimes 60 times a second during animations). If a Composable performs database access or heavy string processing inside its body, it will cause noticeable UI stutter and lag (dropped frames).
*   **Design Freedom**: You can completely redesign the UI from Material 2 to Material 3 without touching a single business rule.

---

## 4. When to Use It
*   **Universal Rule for UI Development**: Never perform database queries, calculations, or network calls inside a Composable function.
*   **State Hoisting**: Pass state *down* into UI components as simple parameters (`name: String`, `isButtonEnabled: Boolean`) and hoist events *up* as lambdas (`onNameChanged: (String) -> Unit`, `onSubmitClicked: () -> Unit`).

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Purely Visual UI State**: Temporary, ephemeral visual state—such as whether a dropdown menu is currently expanded, or the current scroll offset of a list—belongs in the UI layer (using `remember { mutableStateOf(false) }`). Do not pollute your ViewModel with transient UI-only flags that have zero business impact.

---

## 6. Advantages & Disadvantages

| Pure UI + Separated Logic | Logic Embedded in UI |
| :--- | :--- |
| **Instant Testing**: Logic verified in local JVM unit tests. | **Painful Testing**: Requires running slow Android instrumentation tests. |
| **Smooth UI (60fps)**: Composables only render, never block. | **Jank & Dropped Frames**: Logic runs during recomposition loops. |
| **Reusable Components**: Clean widgets can be reused across screens. | **Tightly Coupled**: Widgets cannot be reused without dragging logic. |

---

## 7. Practical Examples

### Bad Example: Business Logic & Formatting Embedded in Composable
```kotlin
// BAD: Heavy business calculations and formatting inside UI recomposition loop
@Composable
fun BadOrderSummary(order: Order, isVip: Boolean) {
    // DISASTER: Runs on EVERY recomposition, blocks the UI thread!
    var discount = 0.0
    if (isVip && order.total > 100.0) {
        discount = order.total * 0.15
    }
    val finalTotal = order.total - discount
    val formatted = NumberFormat.getCurrencyInstance().format(finalTotal)

    Column {
        Text("Order Total: $formatted")
        Button(onClick = {
            // DISASTER: Direct database access inside UI onClick!
            AppDatabase.getInstance().orderDao().markPaid(order.id)
        }) {
            Text("Pay Now")
        }
    }
}
```

### Good Example: Pure Composable with Hoisted State & Events
```kotlin
// GOOD: Pure presentation. Receives prepared display state, hoists events
data class OrderSummaryDisplayState(
    val formattedTotal: String,
    val isPayButtonEnabled: Boolean
)

@Composable
fun OrderSummaryScreen(
    displayState: OrderSummaryDisplayState,
    onPayClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.padding(16.dp)) {
        Text(text = "Order Total: ${displayState.formattedTotal}")
        Button(
            onClick = onPayClicked,
            enabled = displayState.isPayButtonEnabled
        ) {
            Text("Pay Now")
        }
    }
}
```

---

## 8. Common Mistakes
1.  **Performing Calculations in Compose**: Calculating tax totals or sorting lists inside the Composable body instead of doing it in the ViewModel or Domain Use Case.
2.  **Passing ViewModels to Child Composables**: Passing the entire ViewModel into small reusable child components (e.g., passing `UserViewModel` into `AvatarImage`). Pass only the data the child needs (`avatarUrl: String`).
3.  **Hoisting Ephemeral State to ViewModel**: Putting text field cursor position or dialog visibility flags into a ViewModel when they are purely UI concerns.

---

## 9. Verification Checklist

- [ ] Are Composables free of database calls, HTTP requests, or repository references?
- [ ] Are reusable child widgets stateless (receiving data via arguments and emitting events via lambdas)?
- [ ] Are calculations and data formatting performed in the ViewModel before exposing UI state?
- [ ] Does the UI render smoothly without dropped frames during scrolling or user input?
- [ ] Can the business logic be fully verified by unit tests without mocking UI classes?
