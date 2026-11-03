# 03. Android Concurrency: Coroutines, Flow & Reactive Streams

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Kotlin 2.0+, `kotlinx.coroutines` 1.8+

---

## 1. Definition & Core Concept

**Kotlin Coroutines and Flow** provide a declarative, lightweight, non-blocking asynchronous programming model built on **structured concurrency**. Rather than blocking operating system threads or nesting asynchronous callbacks, coroutines allow asynchronous tasks to be written sequentially using `suspend` functions.

**Kotlin Flow** is a cold asynchronous data stream that emits multiple sequentially calculated values. Hot streams (`StateFlow` and `SharedFlow`) act as state holders and event buses across lifecycle boundaries.

```
+-------------------------------------------------------------------------+
| Structured Concurrency Hierarchy                                       |
|                                                                         |
| viewModelScope (SupervisorJob + Dispatchers.Main.immediate)             |
|   |---> Job A (fetchUserProfile: withContext(Dispatchers.IO))            |
|   `---> Job B (observeUserBalance: Flow.collect)                        |
|                                                                         |
| * If viewModelScope is cleared, both Job A and Job B cancel cooperatively|
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to ensure safe, leak-free, non-blocking asynchronous execution across Android components. It standardizes dispatcher selection, lifecycle-aware flow collection, structured exception propagation, and testability.

---

## 3. Why It Matters

*   **ANR (Application Not Responding) Prevention**: Offloading disk, database, and network I/O from `Dispatchers.Main` prevents UI thread starvation and ANR crashes.
*   **Leak-Free Lifecycle Management**: Coroutines tied to structured scopes (`viewModelScope`, `lifecycleScope`) cancel automatically when UI components are destroyed or navigation destinations are popped.
*   **Cooperative Cancellation**: When a user leaves a screen, downstream network calls, queries, and computation loops terminate gracefully, saving battery and bandwidth.
*   **Deterministic Testability**: Injectable dispatchers (`TestDispatcher`, `StandardTestDispatcher`) enable deterministic, instantaneous unit testing of complex asynchronous flows without flaky `Thread.sleep()` calls.

---

## 4. When to Use It

*   **One-Shot Asynchronous Work**: Use `suspend` functions for single-value operations (fetching a REST API payload, querying Room for a single entity, reading a DataStore key).
*   **Continuous Data Streams (Cold Flows)**: Use `Flow<T>` in repositories and DAOs to emit updates whenever database records change or sensors produce telemetry.
*   **UI State Representation (Hot StateFlow)**: Use `StateFlow<T>` in ViewModels to hold and emit immutable UI states. Always initialize with a default state and convert via `stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), InitialState)`.
*   **One-Off Events (SharedFlow / Channel)**:
    *   Use `Channel<T>` (buffered or rendezvous) when an event must be processed by **exactly one** subscriber (e.g., navigating to another screen, showing a one-time snackbar).
    *   Use `SharedFlow<T>` with replay 0 when emitting non-persisted events to **zero or multiple** simultaneous observers.
*   **UI Collection in Compose**: Use `collectAsStateWithLifecycle()` from `androidx.lifecycle:lifecycle-runtime-compose` to halt flow collection when the UI goes into the background.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **GlobalScope**: **NEVER** use `GlobalScope.launch`. It bypasses structured concurrency, leaks coroutines across app lifetimes, and cannot be cleanly cancelled or tested.
*   **Flow for Static Calculations**: Do not wrap simple synchronous functions or in-memory operations in `Flow` or `suspend` unless they perform actual I/O or heavy computation.
*   **Nested launch/async Sprawl**: Do not launch independent top-level coroutines inside loops. Use `coroutineScope { ... }` or `awaitAll()` to maintain structured hierarchical parent-child relationships.
*   **Direct Thread Instantiation**: Never use `java.lang.Thread` or `Executors` directly in Android application code; rely entirely on Coroutine dispatchers.

---

## 6. Advantages & Disadvantages

| Feature / Pattern | Coroutines & Flow | Traditional Callbacks / RxJava 2/3 |
| :--- | :--- | :--- |
| **Code Structure** | Sequential `suspend` syntax. | Deeply nested callback hell or complex reactive operators. |
| **Lifecycle Safety** | Native structured concurrency (`viewModelScope`). | Requires manual `CompositeDisposable.clear()` tracking. |
| **Learning Curve** | Natural Kotlin syntax and standard control flow. | Steep cognitive barrier for complex operators (`flatMapLatest`, `retryWhen`). |
| **Memory Footprint** | Extremely lightweight; millions of coroutines per process. | Thread allocation overhead or heavy subscriber chains. |
| **Android Integration** | First-class Jetpack & Compose lifecycle support. | Requires external bridge libraries (`RxBinding`, adapters). |

---

## 7. Practical Examples

### Bad Example: Unstructured Concurrency, Leaked Lifecycles & Swallowed Cancellations

```kotlin
// BAD: GlobalScope, hardcoded dispatchers, swallowed cancellation, unsafe collection
class BrokenProfileViewModel(
    private val userRepository: UserRepository
) : ViewModel() {

    // BAD: MutableLiveData or SharedFlow without subscription timeout
    val userState = MutableSharedFlow<User>()

    fun loadUser(userId: String) {
        // HAZARD: GlobalScope leaks if user closes screen!
        GlobalScope.launch(Dispatchers.IO) {
            try {
                val user = userRepository.fetchUser(userId) // Blocking or suspend
                userState.emit(user)
            } catch (e: Exception) {
                // HAZARD: Swallows CancellationException! Coroutine cancellation is broken.
                Log.e("VM", "Error loading user", e)
            }
        }
    }
}

@Composable
fun BrokenProfileScreen(viewModel: BrokenProfileViewModel) {
    // HAZARD: collectAsState keeps listening when the app is in the background!
    val user by viewModel.userState.collectAsState(initial = null)
    Text(text = "Hello, ${user?.name}")
}
```

### Good Example: Structured Concurrency, Injected Dispatchers & Safe Lifecycle Collection

```kotlin
// GOOD: Injected dispatcher, structured viewModelScope, safe exception handling
class ProfileViewModel(
    private val userRepository: UserRepository,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : ViewModel() {

    // Hot StateFlow configured with WhileSubscribed(5_000) for configuration changes
    val uiState: StateFlow<ProfileUiState> = userRepository.observeUser()
        .map { user -> ProfileUiState.Success(user) }
        .catch { error -> emit(ProfileUiState.Error(error.localizedMessage ?: "Unknown error")) }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000), // Keeps flow alive for 5s rotation buffer
            initialValue = ProfileUiState.Loading
        )

    fun refreshProfile(userId: String) {
        viewModelScope.launch(ioDispatcher) {
            try {
                userRepository.refreshUserData(userId)
            } catch (e: CancellationException) {
                // CRITICAL: Always rethrow CancellationException for cooperative cancellation
                throw e
            } catch (e: IOException) {
                // Handle domain network failure cleanly
                Log.w("ProfileViewModel", "Network refresh failed: ${e.message}")
            }
        }
    }
}

// In Jetpack Compose:
@Composable
fun ProfileScreen(
    viewModel: ProfileViewModel,
    modifier: Modifier = Modifier
) {
    // Lifecycle-aware collection: pauses collection when app is paused/stopped in background
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    when (val state = uiState) {
        is ProfileUiState.Loading -> CircularProgressIndicator(modifier = modifier)
        is ProfileUiState.Error -> ErrorMessage(message = state.reason, modifier = modifier)
        is ProfileUiState.Success -> ProfileContent(user = state.user, modifier = modifier)
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Swallowing `CancellationException`**:
    *   *Problem*: Catching generic `Exception` or `Throwable` without rethrowing `CancellationException` cancels parent job cooperative cancellation. If a user leaves the screen, child coroutines keep spinning in the background.
    *   *Remedy*: Always rethrow `CancellationException`:
        ```kotlin
        try {
            doWork()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            handleError(e)
        }
        ```
2.  **Using `collectAsState()` Instead of `collectAsStateWithLifecycle()`**:
    *   *Problem*: Standard `collectAsState()` listens to upstream flows as long as the composable is part of the composition, even if the Android Activity/Fragment is stopped in the background. Location tracking, camera updates, or database queries drain battery indefinitely.
    *   *Remedy*: Always use `collectAsStateWithLifecycle()` with `androidx.lifecycle:lifecycle-runtime-compose`.
3.  **Hardcoding Dispatchers**:
    *   *Problem*: Calling `withContext(Dispatchers.IO)` directly makes unit testing impossible to run deterministically with `StandardTestDispatcher` and `runTest`.
    *   *Remedy*: Inject `CoroutineDispatcher` via Hilt or provide a default parameter (`ioDispatcher: CoroutineDispatcher = Dispatchers.IO`).
4.  **Misusing `SharingStarted.Eagerly` on Cold Database Queries**:
    *   *Problem*: Starting a hot Flow with `SharingStarted.Eagerly` executes the Room query immediately upon ViewModel creation and never releases the database cursor, even when there are no UI observers.
    *   *Remedy*: Use `SharingStarted.WhileSubscribed(5_000)`. The 5-second buffer accommodates transient screen configuration changes (e.g. screen rotation) without restarting the upstream flow.

---

## 9. Verification Checklist

- [ ] Are all coroutines launched in structured scopes (`viewModelScope`, `lifecycleScope`, `coroutineScope`)?
- [ ] Is `GlobalScope` completely banned across all production and test modules?
- [ ] Are `Dispatchers.IO`, `Dispatchers.Default`, and `Dispatchers.Main` injected via dependency injection or parameter defaults?
- [ ] Do all `try-catch` blocks either rethrow `CancellationException` or avoid catching `Throwable`/`CancellationException`?
- [ ] Is `collectAsStateWithLifecycle()` used for all Compose Flow observations?
- [ ] Are ViewModel hot state streams converted using `SharingStarted.WhileSubscribed(5_000)`?
- [ ] Are unit tests for coroutines wrapped in `runTest` using `StandardTestDispatcher` or `UnconfinedTestDispatcher`?
