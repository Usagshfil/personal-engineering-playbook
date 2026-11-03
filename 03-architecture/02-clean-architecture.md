# 02. Clean Architecture (Hexagonal / Onion / Ports & Adapters)

---

## 1. Definition
**Clean Architecture** (pioneered by Robert C. Martin, Alistair Cockburn, and Jeffrey Palermo) is an architectural philosophy centered on the **Dependency Inversion Principle**. Its fundamental rule is the **Dependency Rule**: *Source code dependencies must only point inwards, toward the higher-level policies (the Domain).* 

The core Domain (Entities and Use Cases) knows nothing about Android, Jetpack Compose, Room, Retrofit, SQL, or the web. External technologies are mere "details" that adapt to the core via interfaces (Ports and Adapters).

---

## 2. Purpose
Traditional layered architectures often couple business logic to database schemas or framework SDKs. The purpose of Clean Architecture is to make your business rules **framework-independent**, **database-independent**, and **100% testable without any external hardware, emulators, or UI**.

---

## 3. Why It Matters
*   **Technology Independence**: You can replace Room with an encrypted SQLCipher database or replace Retrofit with Ktor without changing a single line of business logic in your Use Cases.
*   **Fast Unit Testing**: Since Domain Use Cases have zero dependencies on Android or Android SDK classes, unit tests run on the local JVM in milliseconds.
*   **Long-Lived Codebases**: Protects enterprise business rules from framework obsolescence over a 5- to 10-year lifespan.

---

## 4. When to Use It
*   **Complex Enterprise / Multi-Year Projects**: Applications with intricate business algorithms, multiple data sources, strict compliance requirements, and large engineering teams.
*   **Projects with Rapidly Shifting Infrastructure**: Systems expected to swap backend providers, persistence mechanisms, or client platforms.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Standard / CRUD Android Apps**: For a typical Android app fetching JSON from a REST API and displaying it in a Room list, Clean Architecture introduces massive boilerplate: an Entity, a Room Entity, an API DTO, two Mapper classes, a Repository Interface, a Repository Implementation, and a 3-line Use Case class that simply calls the repository.
*   **Small Teams & MVPs**: The sheer volume of mapping and forwarding classes will slow down intermediate developers and early-stage startup velocity.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **Complete Decoupling**: Business logic is completely pure. | **Severe Boilerplate**: Requires 4x more files (Mappers, DTOs, UseCases). |
| **Instant Tests**: Domain tests execute in milliseconds on local JVM. | **Cognitive Friction**: Navigating a simple feature requires hopping through 6 files. |
| **Technology Swapping**: Swapping databases or APIs is trivial. | **Overkill for Simple CRUD**: Passing data through Use Cases with zero logic is wasted effort. |

---

## 7. Practical Examples

```
       ┌────────────────────────────────────────────────────────┐
       │ Frameworks & Drivers (Compose UI, Room DB, Retrofit)   │
       │   ┌────────────────────────────────────────────────┐   │
       │   │ Interface Adapters (ViewModels, Repositories)   │   │
       │   │   ┌────────────────────────────────────────┐   │   │
       │   │   │ Application Business Rules (Use Cases) │   │   │
       │   │   │   ┌────────────────────────────────┐   │   │   │
       │   │   │   │ Enterprise Domain (Entities)   │   │   │   │
       │   │   │   └────────────────────────────────┘   │   │   │
       │   │   └────────────────────────────────────────┘   │   │
       │   └────────────────────────────────────────────────┘   │
       └────────────────────────────────────────────────────────┘
                       Dependencies point INWARD only
```

### Clean Architecture Slice in Kotlin
```kotlin
// 1. DOMAIN LAYER (Pure Kotlin - Zero Android dependencies)
data class User(val id: String, val name: String, val isPremium: Boolean)

interface UserRepository { // Port (Interface defined by domain)
    suspend fun getUser(id: String): Result<User>
}

class GetUserProfileUseCase(private val repository: UserRepository) {
    suspend operator fun invoke(userId: String): Result<User> {
        if (userId.isBlank()) return Result.failure(IllegalArgumentException("Invalid ID"))
        return repository.getUser(userId)
    }
}

// 2. DATA LAYER (Adapter - Implements Domain Port)
class UserRepositoryImpl(
    private val api: UserApi,
    private val dao: UserDao
) : UserRepository {
    override suspend fun getUser(id: String): Result<User> = runCatching {
        // Fetches from local DB or remote API, maps DTO to Domain Entity
        dao.getUserById(id).toDomainModel()
    }
}

// 3. PRESENTATION LAYER (Adapter - Drives the Use Case)
class ProfileViewModel(
    private val getUserProfile: GetUserProfileUseCase
) : ViewModel() {
    // Collects domain state and translates to UI state
}
```

---

## 8. Common Mistakes
1.  **Framework Contamination in Domain**: Importing `android.content.Context`, `androidx.compose.*`, or Room annotations into Domain entity classes.
2.  **Pointless Pass-Through Use Cases**: Creating `GetUsersUseCase` that does nothing except call `userRepository.getUsers()` in a simple CRUD app with zero business rules.
3.  **Premature Clean Architecture**: Forcing Clean Architecture on a personal side project before business complexity justifies it.

---

## 9. Verification Checklist

- [ ] Does the Domain layer have ZERO dependencies on frameworks, Android SDK, or external database libraries?
- [ ] Do all dependencies point strictly inward toward the Domain?
- [ ] Are external interfaces (Repositories) defined in the Domain and implemented in the Data layer?
- [ ] Can all Use Cases be unit-tested without mocking Android framework classes?
- [ ] Are Use Cases justified by real business logic, validation, or orchestration rather than empty pass-through forwarding?
