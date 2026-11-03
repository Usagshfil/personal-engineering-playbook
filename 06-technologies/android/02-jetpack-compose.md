# 02. Jetpack Compose: Declarative UI, State Hoisting & Recomposition Hygiene

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android UI Development  
> **Target Version**: Jetpack Compose (Compose BOM 2024.04+), Material Design 3

---

## 1. Definition & Core Concept

**Jetpack Compose** is Android's modern declarative UI toolkit. In Compose, user interface elements are defined as pure functions of state:

$$\text{UI} = f(\text{State})$$

Rather than mutating imperative view hierarchies (`findViewById`, `setText()`), a Composable function emits UI components based on immutable state passed to it. Key architectural foundations include **State Hoisting** (lifting state to a coordinator so composables remain stateless and testable), **Recomposition Hygiene** (ensuring composables are skippable via `@Immutable` / `@Stable` contracts), and **Modifier Sequencing**.

---

## 2. Purpose

The purpose of this standard is to ensure smooth 60/120fps rendering, prevent memory leaks and dropped frames during recomposition, maintain a single source of truth for UI state, and guarantee that components are reusable, accessible, and trivial to preview in Android Studio.

---

## 3. Why It Matters

*   **Zero Synchronization Overhead**: Because UI is automatically regenerated when state changes, there are zero desynchronization bugs between the underlying data model and the screen.
*   **Recomposition Performance**: Composable functions re-execute whenever their inputs change (sometimes multiple times per frame during animation). Code inside composables must be cheap; any heavy calculation or database query inside a composable causes severe UI jank.
*   **Modifier Order Determinism**: In Compose, modifier chains are evaluated sequentially. `Modifier.padding(16.dp).clickable { }` creates a clickable area with an outer margin, whereas `Modifier.clickable { }.padding(16.dp)` creates an inner padding inside a larger clickable touch target.
*   **Design System Consistency**: Tokenized theming via Material 3 (`MaterialTheme.colorScheme`, `typography`, `shapes`) allows instant dark-mode, dynamic color (Material You), and accessibility scaling without touching individual layouts.

---

## 4. When to Use It

*   **State Hoisting Principle**:
    *   *Stateful Screen (Coordinator)*: One high-level composable per screen injects the `ViewModel`, collects `StateFlow<UiState>`, and passes immutable state down.
    *   *Stateless UI Components*: All child composables receive plain immutable data models and emit lambda callbacks:
        ```kotlin
        @Composable
        fun NoteCard(
            note: NoteUiModel,
            onCardClicked: (String) -> Unit,
            modifier: Modifier = Modifier
        )
        ```
*   **Configuration Change Persistence**:
    *   Use `remember` for transient visual state across recompositions (e.g. animation transition progress).
    *   Use `rememberSaveable` for UI state that must survive device rotation or process recreation (e.g. user input in an unsaved text field).
*   **Lifecycle-Safe Side Effects**:
    *   Use `LaunchedEffect(key)` for executing one-off suspend functions (e.g. fetching initial data or showing a Snackbar).
    *   Use `DisposableEffect(key)` for registering and cleaning up listeners (e.g. system sensor callbacks).
    *   Use `rememberCoroutineScope()` strictly for launching coroutines from user interactions (e.g. button click callbacks).

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **No ViewModels in Reusable Components**: Never pass a `ViewModel` instance into reusable leaf components (buttons, headers, list cards). Doing so couples the widget to a specific feature, breaks `@Preview`, and renders unit testing impossible.
*   **No Business or Persistence Logic**: Never invoke database queries, network calls, or complex calculations directly in the body of a Composable.
*   **No Launching Coroutines in Composable Body**: Never call `scope.launch { }` directly inside a Composable body without a side-effect wrapper; doing so fires a new coroutine on every single recomposition pass.

---

## 6. Advantages & Disadvantages

| Pure Composables & State Hoisting | Imperative Views / Coupled Composables |
| :--- | :--- |
| **Instant Interactive Previews**: Every component can render isolated previews. | **Broken Previews**: Previews crash due to missing ViewModel or Android context. |
| **Skipped Recompositions**: Compiler skips unchanged composables, ensuring 60fps. | **Jank & Recomposition Loops**: Passing unstable types causes constant recomposition. |
| **Effortless Theming**: Dark mode and dynamic colors apply automatically. | **Fragmented Styling**: Hardcoded colors in XML or manual attribute resolution. |
| **Single Source of Truth**: UI reflects immutable state deterministically. | **State Desync**: View state diverges from model state. |

---

## 7. Practical Examples

### Bad Example: Embedded ViewModel, Heavy Calculation & Modifier Mishap
```kotlin
// BAD: Coupled to ViewModel, runs heavy calculation during recomposition, bad modifier order
@Composable
fun BadProductScreen(viewModel: ProductViewModel = hiltViewModel()) {
    val products = viewModel.products // Raw mutable reference!

    Column {
        for (product in products) {
            // DISASTER: Heavy string formatting and tax math runs on EVERY frame!
            val formattedPrice = NumberFormat.getCurrencyInstance().format(product.price * 1.08)

            // DISASTER: Modifier order means padding is NOT clickable!
            Text(
                text = "${product.name}: $formattedPrice",
                modifier = Modifier
                    .padding(24.dp)
                    .clickable { viewModel.onProductSelected(product.id) }
            )
        }
    }
}
```

### Good Example: Hoisted State, Pure Component, Preview & Stable Contract
```kotlin
// GOOD: Immutable state model, hoisted events, clean modifier chaining, isolated preview
@Immutable
data class ProductUiModel(
    val id: String,
    val name: String,
    val formattedPrice: String
)

@Immutable
data class ProductListUiState(
    val products: List<ProductUiModel> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)

@Composable
fun ProductScreen(
    uiState: ProductListUiState,
    onProductSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    if (uiState.isLoading) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(
            items = uiState.products,
            key = { it.id } // Stable keys optimize LazyColumn recycling
        ) { product ->
            ProductRow(
                product = product,
                onClicked = { onProductSelected(product.id) }
            )
        }
    }
}

@Composable
fun ProductRow(
    product: ProductUiModel,
    onClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClicked), // Entire card clickable
        shape = MaterialTheme.shapes.medium
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = product.name, style = MaterialTheme.typography.bodyLarge)
            Text(text = product.formattedPrice, style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun ProductRowPreview() {
    MaterialTheme {
        ProductRow(
            product = ProductUiModel("1", "Organic Coffee", "$14.99"),
            onClicked = {}
        )
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Unstable Parameters Breaking Skippability**:
    *   *Problem*: The standard Kotlin `List<T>` is an interface; the Compose compiler cannot guarantee it is immutable, marking composables that take `List<T>` as "unstable" and re-executing them on every recomposition.
    *   *Remedy*: Mark UI state holder models with `@Immutable` or `@Stable`, or use `kotlinx.collections.immutable.ImmutableList`.
2.  **Modifier Parameter Default & Sizing Mistakes**:
    *   *Problem*: Omitting `modifier: Modifier = Modifier` in child composables prevents parent layouts from positioning or styling them. Hardcoding `Modifier.fillMaxSize()` inside a child widget breaks flexible layout composition.
    *   *Remedy*: Always expose `modifier: Modifier = Modifier` as the first optional parameter on reusable composables.
3.  **Forgetting `key` in Lazy Layouts**:
    *   *Problem*: Omitting `key = { item.id }` in `items()` causes `LazyColumn` to identify items by index. When items are inserted or deleted, Compose recreates item states and animations stutter.
    *   *Remedy*: Always provide a unique, persistent key to `items()`.

---

## 9. Verification Checklist

- [ ] Does every reusable Composable expose `modifier: Modifier = Modifier`?
- [ ] Are state models marked with `@Immutable` or `@Stable` to ensure skippable recomposition?
- [ ] Are Lazy layouts (`LazyColumn`, `LazyRow`) provided with persistent keys (`key = { it.id }`)?
- [ ] Is interactive visual state hoisted, leaving child composables stateless?
- [ ] Are touch targets $\ge 48\times 48$dp for clickable elements?
- [ ] Are all side effects encapsulated in `LaunchedEffect` or `DisposableEffect`?
- [ ] Do composables provide `@Preview` annotations with realistic mock data?
