# 07. Android Architecture Patterns: Clean Architecture, MVVM/MVI & UDF

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Android Architecture Recommendations, Jetpack Compose, Kotlin 2.0+

---

## 1. Definition & Core Concept

**Modern Android Architecture** is based on the **Unidirectional Data Flow (UDF)** model and **Clean Architecture** principles. The application is segregated into three strictly bounded layers:

1.  **UI Layer**: Declarative presentation (Jetpack Compose) consuming immutable `UiState` streams emitted by state holders (`ViewModel`).
2.  **Domain Layer** *(Optional)*: Encapsulates complex business rules and coordinates multiple repositories via single-responsibility **Use Cases** (Interactors). Pure Kotlin; zero Android framework dependencies.
3.  **Data Layer**: Serves as the application's Single Source of Truth (SSOT). Repositories coordinate remote network endpoints and local persistence caches.

```
+-------------------------------------------------------------------------+
| Unidirectional Data Flow (UDF) & Layer Boundaries                       |
|                                                                         |
| [ UI Layer ]                                                            |
|    Compose Screen  <=== (UiState) ===  ViewModel                        |
|         |                                   ^                           |
|         `======== (User Events) ============'                           |
|                                             |                           |
| [ Domain Layer ]                            v                           |
|                                         Use Case                        |
|                                             |                           |
| [ Data Layer ]                              v                           |
|                                         Repository (SSOT)               |
|                                         /              \                |
|                                        v                v               |
|                                   Local Cache     Remote API            |
|                                     (Room)        (Retrofit)            |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to prevent God-ViewModels and UI-coupled business logic, ensure modular codebases that can be independently developed and tested, and provide a predictable, debuggable state model across all screens.

---

## 3. Why It Matters

*   **Predictable State via UDF**: State flows down from ViewModels to Composable screens; events flow up from Composables to ViewModels. This eliminates inconsistent UI state, race conditions, and duplicated data representations.
*   **Decoupled Testability**: The Domain layer contains zero Android dependencies, allowing business rules to be tested with pure, instantaneous JVM unit tests without Android emulators.
*   **Offline-First Resilience**: Implementing repositories as Single Sources of Truth ensures the application renders instantly from local database caches before network requests resolve.
*   **Maintainable Separation**: Distinct data models (Data Transfer Objects, Database Entities, Domain Models, and UI States) protect business logic from backend schema shifts.

---

## 4. When to Use It

*   **Immutable UI State**: Always represent the entire screen state in a single immutable `data class` or `sealed interface`:
    ```kotlin
    data class FeedUiState(
        val isLoading: Boolean = false,
        val items: List<FeedItem> = emptyList(),
        val errorMessage: String? = null
    )
    ```
*   **One-Off UI Events**: Handle non-persisted one-time actions (navigation, Toast/Snackbar display) via `Channel<UiEffect>` exposed as `receiveAsFlow()`.
*   **Use Cases**: Introduce Use Cases when business logic is reused across multiple ViewModels, or when a workflow involves orchestrating multiple repositories (e.g. `CheckoutUseCase` coordinating `CartRepository`, `PaymentRepository`, and `UserRepository`).
*   **Model Mapping**: Explicitly map DTOs $\to$ Entities $\to$ Domain Models $\to$ UI State across layer boundaries.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Pass-Through Use Cases**: Do **NOT** create boilerplate Use Cases that merely delegate directly to a single repository method with zero business logic (e.g., `GetUserUseCase` that only calls `userRepository.getUser()`). In simple scenarios, ViewModels may call the Repository directly.
*   **God ViewModels**: Do not create ViewModels with more than 300–400 lines of code. If a ViewModel manages multiple independent UI sections or complex workflows, decompose it into smaller child ViewModels or Use Cases.
*   **Exposing Database Entities to UI**: Never pass Room `@Entity` classes directly to Composable UI layouts. Entity changes should not cause UI rebuilds or bypass domain validations.
*   **Framework Leaks in Domain Layer**: Never import `android.content.Context`, `android.os.Bundle`, or any Android framework classes into the Domain layer.

---

## 6. Advantages & Disadvantages

| Pattern / Layering | Clean Architecture + UDF | Monolithic Activity / God ViewModel |
| :--- | :--- | :--- |
| **Testability** | 100% testable on JVM without emulators. | Difficult to test; relies on expensive UI/Instrumentation tests. |
| **Separation of Concerns** | Strict boundaries between storage, business, and UI. | Tangled spaghetti code; network and DB calls inside UI. |
| **Boilerplate** | Requires data mappers and boundary interfaces. | Fewer initial files; quick for trivial proof-of-concepts. |
| **Scalability** | Easy to split into Gradle multi-module architecture. | Breaks down rapidly as team or feature count grows. |

---

## 7. Practical Examples

### Bad Example: God ViewModel, Leaked Framework Classes & Ad-Hoc Mutability

```kotlin
// BAD: ViewModel performs network and database operations, mutates shared state, leaks Context
class BadFeedViewModel(private val context: Context) : ViewModel() {
    // HAZARD: Multiple fragmented mutable states create inconsistent UI glitches
    var isLoading = false
    var feedItems = mutableListOf<String>()
    var errorMessage: String? = null

    fun loadData() {
        isLoading = true
        // HAZARD: Direct network call inside ViewModel with no repository abstraction
        thread {
            val response = URL("https://api.example.com/feed").readText()
            feedItems.add(response)
            isLoading = false
        }
    }
}
```

### Good Example: Clean Architecture with UDF, Use Case & Single Source of Truth

```kotlin
// GOOD: Immutable state, UseCase for business logic, Repository SSOT
// 1. Domain Layer: Pure Kotlin
data class Article(
    val id: String,
    val title: String,
    val isBookmarked: Boolean
)

interface ArticleRepository {
    fun observeArticles(): Flow<List<Article>>
    suspend fun refreshArticles(): Result<Unit>
    suspend fun toggleBookmark(articleId: String): Result<Unit>
}

class ToggleBookmarkUseCase @Inject constructor(
    private val repository: ArticleRepository
) {
    suspend operator fun invoke(articleId: String): Result<Unit> {
        // Business logic: validations, telemetry, or precondition checks
        require(articleId.isNotBlank()) { "Article ID cannot be blank" }
        return repository.toggleBookmark(articleId)
    }
}

// 2. UI Layer: ViewModel & Immutable State
sealed interface FeedUiState {
    data object Loading : FeedUiState
    data class Success(val articles: List<Article>) : FeedUiState
    data class Error(val message: String) : FeedUiState
}

@HiltViewModel
class FeedViewModel @Inject constructor(
    private val repository: ArticleRepository,
    private val toggleBookmarkUseCase: ToggleBookmarkUseCase
) : ViewModel() {

    val uiState: StateFlow<FeedUiState> = repository.observeArticles()
        .map { articles -> 
            if (articles.isEmpty()) FeedUiState.Loading 
            else FeedUiState.Success(articles) 
        }
        .catch { error -> emit(FeedUiState.Error(error.message ?: "Failed to load feed")) }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = FeedUiState.Loading
        )

    fun onBookmarkClicked(articleId: String) {
        viewModelScope.launch {
            toggleBookmarkUseCase(articleId)
                .onFailure { error ->
                    // Handle failure or emit one-off effect
                }
        }
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Exposing Mutable State Outside the ViewModel**:
    *   *Problem*: Exposing `MutableStateFlow` instead of read-only `StateFlow` permits Composables or other external classes to alter UI state directly, violating Unidirectional Data Flow.
    *   *Remedy*: Always expose read-only `StateFlow`:
        ```kotlin
        private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
        val uiState: StateFlow<UiState> = _uiState.asStateFlow()
        ```
2.  **Creating Redundant "Pass-Through" Use Cases**:
    *   *Problem*: Adding a Use Case for every single repository method (e.g. `GetNotesUseCase` containing only `return noteRepository.getNotes()`) adds architectural friction without delivering value.
    *   *Remedy*: Only introduce Use Cases when business logic, data combination, or domain validation exists. Otherwise, inject the Repository directly into the ViewModel.
3.  **Handling One-Off Events in Persistent StateFlow**:
    *   *Problem*: Storing transient events like `showToast: Boolean` in `StateFlow` causes the event to replay when screen orientation changes, showing the Toast repeatedly.
    *   *Remedy*: Use a Kotlin `Channel<UiEffect>` or reset state flags immediately upon consumption.

---

## 9. Verification Checklist

- [ ] Does the UI layer strictly adhere to Unidirectional Data Flow (State down, Events up)?
- [ ] Is UI state exposed as an immutable `StateFlow` and collected using `collectAsStateWithLifecycle()`?
- [ ] Does the Domain layer remain free of Android SDK dependencies (`android.*`)?
- [ ] Are repositories serving as the Single Source of Truth for local and remote data?
- [ ] Are Room database entities mapped to clean Domain Models before reaching the UI layer?
- [ ] Are Use Cases created only when genuine domain logic or cross-repository orchestration is required?
- [ ] Are transient one-off events managed via `Channel` / `SharedFlow` rather than sticky `StateFlow` flags?
