# 01. Clean Code & Core Principles (SOLID, KISS, YAGNI)

---

## 1. Definition
**Clean Code** is code that is simple, direct, readable, and reads like well-crafted prose. It clearly expresses its intent without forcing the reader to reverse-engineer hidden assumptions or decipher clever tricks.

Core supporting heuristics:
*   **SOLID**: Five object-oriented design principles (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) to maximize maintainability.
*   **KISS (Keep It Simple, Stupid)**: Systems work best when kept simple rather than made complicated.
*   **YAGNI (You Aren't Gonna Need It)**: Do not add functionality or abstractions until you actually have an immediate requirement for them.

---

## 2. Purpose
Code is read far more often than it is written (an estimated 10:1 ratio). The purpose of Clean Code is to minimize the **cognitive load** required for another developer (or your future self) to understand, modify, and safely extend the system without introducing regressions.

---

## 3. Why It Matters
When code is messy and opaque:
*   Adding a simple feature takes days instead of hours because every change risks breaking hidden side effects.
*   Onboarding new engineers or collaborating with AI coding agents results in hallucinations and bugs.
*   Bugs multiply because logic is scattered across deeply nested conditionals.

Clean code provides an immediate **maintenance dividend**: fewer bugs, simpler unit testing, and predictable velocity.

---

## 4. When to Use It
*   **Everyday Default**: Clean naming, small functions, and clear flow apply to every single line of production code.
*   **Component Boundaries**: Apply SOLID principles when building services, repositories, and business logic modules where multiple implementations or integrations might evolve.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Throwaway Prototypes**: In a 2-hour proof-of-concept to test an API endpoint or UI animation, building 4 layers of interfaces and factories violates KISS and YAGNI.
*   **Premature SOLID**: Do not create interfaces with only one implementation unless required for unit test mocking or dependency injection. Over-abstracting a 10-line calculation into 3 strategy classes violates KISS.
*   **Performance Hot Paths**: In tight graphics or DSP loops, excessive object allocation from deep object-oriented abstractions can cause garbage collection churn; clean low-level procedural code is preferable there.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **High Readability**: Intent is clear in seconds. | **Slight Initial Overhead**: Writing thoughtful abstractions takes more time upfront. |
| **Easy Unit Testing**: Decoupled classes with single responsibilities are trivial to isolate and test. | **File Proliferation**: Strict separation creates more classes/files to navigate if overdone. |
| **Safe Refactoring**: Isolated modules allow localized changes without ripple effects. | **Risk of Dogmatism**: Strict adherents may create unnecessary interfaces and design patterns. |

---

## 7. Practical Examples

### Bad Example: Violating Single Responsibility & KISS
```kotlin
// BAD: One massive class does networking, JSON parsing, disk caching, and UI updates
class UserManager {
    fun processUserData(jsonString: String) {
        // 1. Parsing
        val user = JSONObject(jsonString)
        val name = user.getString("name")
        val email = user.getString("email")
        
        // 2. Business validation & logic
        if (!email.contains("@")) {
            println("Invalid email")
            return
        }
        
        // 3. Database operation
        val db = SQLiteDatabase.openOrCreateDatabase("app.db", null)
        db.execSQL("INSERT INTO users VALUES ('$name', '$email')")
        
        // 4. UI Notification
        Toast.makeText(context, "User saved: $name", Toast.LENGTH_SHORT).show()
    }
}
```

### Good Example: Applying SRP and Clean Structure
```kotlin
// GOOD: Clean separation of concerns with clear intent
data class User(val name: String, val email: String) {
    init {
        require(email.contains("@")) { "Invalid email address: $email" }
    }
}

interface UserRepository {
    suspend fun saveUser(user: User): Result<Unit>
}

class SqliteUserRepository(private val database: AppDatabase) : UserRepository {
    override suspend fun saveUser(user: User): Result<Unit> = runCatching {
        database.userDao().insert(user.toEntity())
    }
}

class UserViewModel(
    private val userRepository: UserRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<UserUiState>(UserUiState.Idle)
    val uiState: StateFlow<UserUiState> = _uiState.asStateFlow()

    fun onSaveUser(name: String, email: String) {
        viewModelScope.launch {
            _uiState.value = UserUiState.Loading
            userRepository.saveUser(User(name, email))
                .onSuccess { _uiState.value = UserUiState.Success }
                .onFailure { error -> _uiState.value = UserUiState.Error(error.localizedMessage) }
        }
    }
}
```

---

## 8. Common Mistakes
1.  **Premature Abstraction (YAGNI violation)**: Creating an interface `IOrderProcessingStrategy` when there is only ever one domestic credit card processor.
2.  **God Classes**: Allowing a single class (e.g., `MainActivity`, `AppManager`, `Utils`) to collect hundreds of unrelated functions.
3.  **Deep Nesting**: Nesting `if/else` and `for` loops 4 or 5 levels deep instead of using early returns (guard clauses).

---

## 9. Verification Checklist

- [ ] Does every class and function have a single, clearly stated responsibility?
- [ ] Are functions short (ideally under 25 lines) and focused on a single level of abstraction?
- [ ] Are early returns (guard clauses) used to avoid deep indentation?
- [ ] Are all interfaces justified by either testing requirements or multiple concrete implementations?
- [ ] Does this code solve today's concrete requirement rather than an unrequested future feature?
