# 09. State Management: Unidirectional Data Flow & StateFlow

---

## 1. Definition
**State Management** is the system architecture used to store, update, and emit application state to the user interface. Modern state management relies on **Unidirectional Data Flow (UDF)** and **Immutable UI State Data Classes**, utilizing Kotlin's **`StateFlow`** as the state container.

---

## 2. Purpose
When state is scattered across multiple mutable variables in activities, fragments, and adapters, updates easily fall out of sync: the list updates, but the badge counter does not; the loading spinner starts, but never dismisses on error. UDF and StateFlow guarantee a **single, authoritative state** at any given moment.

---

## 3. Why It Matters
*   **Predictable UI State Progression**: State is modeled as a single immutable data class:
    ```kotlin
    data class ScreenUiState(val isLoading: Boolean, val items: List<Item>, val error: String?)
    ```
    The UI simply reflects this snapshot. It is impossible to be in an ambiguous state.
*   **Thread Safety**: Kotlin `StateFlow` is thread-safe and conflated (it only emits the most recent value to new observers, preventing backlog processing).
*   **Safe Recomposition**: In Jetpack Compose, observing `StateFlow` via `collectAsStateWithLifecycle()` ensures that the UI stops listening when the app is in the background, conserving battery and CPU.

---

## 4. When to Use It
*   **Every Screen in Android**: Every screen with dynamic data should have an associated `UiState` data class managed by a `ViewModel` via `StateFlow`.
*   **Cross-Screen Shared State**: Use an application-scoped state repository (e.g., `UserSessionManager`) exposing a `StateFlow<UserSession>` for global authentication or cart state.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **One-Time Events (Navigation, Snackbars)**: Continuous state (like `isLoading`) is ideal for `StateFlow`. However, transient one-shot actions (like showing a single Snackbar or navigating to a new screen) should be handled via explicit event channels or resetting state properties (e.g. `_uiState.update { it.copy(userMessage = null) }`) rather than complex custom event buses.

---

## 6. Advantages & Disadvantages

| StateFlow & Unidirectional Data Flow | Multiple Mutable Variables |
| :--- | :--- |
| **Single Source of Truth**: UI reflects exactly one state object. | **State Desynchronization**: Variables get out of sync. |
| **Lifecycle-Aware**: Halts observation when screen is stopped. | **Memory Leaks**: Listeners continue running in background. |
| **Reproducible Bugs**: UI state can be captured in a test. | **Difficult Debugging**: Hard to reconstruct what changed when. |

---

## 7. Practical Examples

```
                ┌──────────────────────────────────────┐
                │          Jetpack Compose UI          │
                └──────────────────┬───────────────────┘
                                   │
              Dispatches User Event│ Emits Immutable UiState
              (e.g., onSearch(q))  │ (e.g., StateFlow<SearchUiState>)
                                   ▼
                ┌──────────────────────────────────────┐
                │              ViewModel               │
                │  - Updates MutableStateFlow          │
                │  - Coordinates Data Layer calls      │
                └──────────────────────────────────────┘
```

### Complete Android StateFlow & UDF Pattern
```kotlin
// 1. IMMUTABLE UI STATE (Single snapshot of the screen)
data class SearchUiState(
    val query: String = "",
    val isLoading: Boolean = false,
    val results: List<SearchResult> = emptyList(),
    val errorMessage: String? = null
)

// 2. VIEWMODEL (State Holder)
class SearchViewModel(
    private val searchRepository: SearchRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    fun onQueryChanged(newQuery: String) {
        _uiState.update { it.copy(query = newQuery) }
    }

    fun onSearchSubmitted() {
        val currentQuery = _uiState.value.query
        if (currentQuery.isBlank()) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            
            searchRepository.search(currentQuery)
                .onSuccess { results ->
                    _uiState.update { it.copy(isLoading = false, results = results) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.localizedMessage) }
                }
        }
    }
}
```

---

## 8. Common Mistakes
1.  **Exposing `MutableStateFlow`**: Giving the View access to modify `_uiState.value` directly, completely breaking Unidirectional Data Flow.
2.  **Using `collectAsState()` instead of `collectAsStateWithLifecycle()`**: Using the basic Compose collector keeps the coroutine active in the background when the Android app is minimized, draining battery.
3.  **Multiple Competing Flows**: Exposing 5 separate flows (`val isLoading`, `val users`, `val errors`, `val isVip`) instead of unifying them into a cohesive `UiState` data class.

---

## 9. Verification Checklist

- [ ] Is screen state unified into a single immutable data class?
- [ ] Is `MutableStateFlow` kept strictly `private`, exposing only read-only `StateFlow`?
- [ ] Are state updates executed safely using `_uiState.update { ... }` to prevent race conditions?
- [ ] Are Compose observations collected using `collectAsStateWithLifecycle()`?
- [ ] Can the entire UI state progression be tested deterministically in a JVM unit test?
