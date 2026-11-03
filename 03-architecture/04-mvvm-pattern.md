# 04. Model-View-ViewModel (MVVM) Pattern & Unidirectional Data Flow

---

## 1. Definition
**Model-View-ViewModel (MVVM)** is the standard architectural pattern for modern mobile development (especially Android with Jetpack Compose). It separates an application into:
*   **Model**: Domain objects, repositories, and data sources.
*   **View**: Declarative UI (Jetpack Compose composables) that observes state and dispatches user actions.
*   **ViewModel**: Holds and manages observable UI state (`StateFlow`), handles business coordination, survives configuration changes (like screen rotations), and exposes methods for user events.

---

## 2. Purpose
In mobile apps, activities and screens are frequently destroyed and recreated by the operating system during screen rotation, theme changes, or background process death. MVVM's purpose is to **decouple the UI state from the fragile screen lifecycle**, while enforcing a clean **Unidirectional Data Flow (UDF)**.

---

## 3. Why It Matters
*   **Survives Configuration Changes**: An Android Jetpack `ViewModel` stays alive when a device rotates from portrait to landscape. The screen simply re-attaches and displays the exact same state without re-fetching network data.
*   **Declarative Harmony**: Jetpack Compose is a function of state: $\text{UI} = f(\text{State})$. MVVM provides the ideal state container (`StateFlow<UiState>`) that triggers automatic recomposition when state changes.
*   **100% JVM Testability**: ViewModels do not require Android UI frameworks or emulators to test. You can write instant JVM unit tests that simulate user events and assert emitted states.

---

## 4. When to Use It
*   **Every Modern Android Application**: MVVM is the official Google recommended architecture for Android with Jetpack Compose.
*   **Interactive Web Frontends**: Modern React, Vue, and Angular applications use identical state-driven component patterns.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Stateless Static Screens**: A simple "About Us" or "Terms of Service" screen displaying static text does not need a ViewModel. Pass static data directly to the Composable.
*   **Over-Fragmenting ViewModels**: Do not create a separate ViewModel for every minor reusable UI widget (like a custom button). The top-level Screen should have the ViewModel, passing state down and hoisting events up.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **Lifecycle Survival**: State is preserved across device rotation. | **State Modeling Overhead**: Requires defining explicit UI State data classes. |
| **High Testability**: Test UI logic completely on local JVM. | **Learning Curve**: Requires understanding reactive streams (`StateFlow`, Coroutines). |
| **Clean UDF**: Single source of truth eliminates UI sync bugs. | **Boilerplate for Tiny Views**: Overkill for purely static informational screens. |

---

## 7. Practical Examples

```
          ┌─────────────────────────────────────────────────────────┐
          │   View (Jetpack Compose)                                │
          │   - Displays state via StateFlow.collectAsStateWithLifecycle() │
          │   - Dispatches user events (e.g., onRefreshClicked())   │
          └──────────────────────────┬──────────────────────────────┘
                         Events Up   │   State Down
                                     ▼
          ┌─────────────────────────────────────────────────────────┐
          │   ViewModel                                             │
          │   - Holds MutableStateFlow<UiState>                     │
          │   - Exposes StateFlow<UiState> (read-only)              │
          │   - Executes business operations via viewModelScope     │
          └──────────────────────────┬──────────────────────────────┘
                                     │ Calls
                                     ▼
          ┌─────────────────────────────────────────────────────────┐
          │   Model / Repository Layer                              │
          │   - Single source of truth (Room DB + Retrofit API)    │
          └─────────────────────────────────────────────────────────┘
```

### Idiomatic Android MVVM (Jetpack Compose + StateFlow)
```kotlin
// 1. UI STATE MODEL (Immutable)
data class TaskUiState(
    val isLoading: Boolean = false,
    val tasks: List<Task> = emptyList(),
    val errorMessage: String? = null
)

// 2. VIEWMODEL
class TaskViewModel(
    private val repository: TaskRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TaskUiState(isLoading = true))
    val uiState: StateFlow<TaskUiState> = _uiState.asStateFlow()

    init {
        loadTasks()
    }

    fun loadTasks() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            repository.getTasks()
                .onSuccess { taskList ->
                    _uiState.update { it.copy(isLoading = false, tasks = taskList) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.localizedMessage) }
                }
        }
    }
}

// 3. COMPOSE VIEW (Pure observation & event hoisting)
@Composable
fun TaskScreen(
    viewModel: TaskViewModel,
    modifier: Modifier = Modifier
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    when {
        state.isLoading -> LoadingIndicator()
        state.errorMessage != null -> ErrorBanner(message = state.errorMessage!!, onRetry = viewModel::loadTasks)
        else -> TaskList(tasks = state.tasks)
    }
}
```

---

## 8. Common Mistakes
1.  **Exposing Mutable State**: Exposing `MutableStateFlow` directly from the ViewModel to the View, allowing UI composables to mutate state directly. Always expose read-only `StateFlow`.
2.  **Passing Context into ViewModels**: Storing `android.content.Context` or View references in a ViewModel causes memory leaks when activities are destroyed.
3.  **Doing Heavy Work on the Main Thread**: Forgetting to use Coroutine dispatchers (`Dispatchers.IO`) for disk or network operations.

---

## 9. Verification Checklist

- [ ] Does the ViewModel expose read-only state (`StateFlow<T>`) while keeping `MutableStateFlow` strictly private?
- [ ] Is the ViewModel completely free of `Context`, `View`, or Activity references?
- [ ] Are UI composables pure: receiving state as parameters and hoisting events via lambdas?
- [ ] Does state survive screen rotation without re-triggering network requests?
- [ ] Are all ViewModel actions tested via local JVM unit tests using `StandardTestDispatcher`?
