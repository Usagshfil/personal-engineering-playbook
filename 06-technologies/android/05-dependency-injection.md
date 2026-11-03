# 05. Android Dependency Injection: Dagger Hilt & Architecture Boundaries

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Dagger Hilt 2.51+, Kotlin 2.0+ (KSP)

---

## 1. Definition & Core Concept

**Dependency Injection (DI)** is a software engineering technique where an object receives its dependencies from an external source rather than creating them internally. In modern Android development, **Dagger Hilt** is the standard, compile-time verified dependency injection framework built on top of Dagger 2.

Hilt automates the generation of Dagger components, unifies component lifecycles with standard Android framework classes (Application, Activity, Fragment, ViewModel, Service), and provides standardized testing support.

```
+-------------------------------------------------------------------------+
| Hilt Component Lifecycle Hierarchy                                     |
|                                                                         |
| SingletonComponent (@Singleton)                                         |
|    |                                                                    |
|    |---> ActivityRetainedComponent (@ActivityRetainedScoped)            |
|    |        |                                                           |
|    |        +---> ViewModelComponent (@ViewModelScoped)                 |
|    |        |                                                           |
|    |        `---> ActivityComponent (@ActivityScoped)                  |
|    |                 `---> FragmentComponent / ViewComponent           |
|    |                                                                    |
|    `---> ServiceComponent (@ServiceScoped)                              |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to enforce loose coupling between architectural layers, eliminate boilerplate factory instantiation, enforce strict lifecycle scoping, and make Android classes immediately testable via mock injection.

---

## 3. Why It Matters

*   **Compile-Time Verification**: Hilt validates the entire dependency graph at compile time. Missing bindings, circular dependencies, or incompatible scopes break the build immediately rather than crashing at runtime.
*   **Leak Prevention**: Standard Android lifecycles are prone to memory leaks when objects hold references across configuration changes. Hilt ties object lifecycles directly to the component hierarchy (e.g. `@ViewModelScoped` lives and dies with the ViewModel).
*   **Zero-Boilerplate Testing**: Through `@TestInstallIn` and `@UninstallModules`, production network or persistence modules can be swapped with mock or in-memory implementations in test suites without altering production code.
*   **Single Responsibility Principle**: Classes focus purely on their core business logic rather than how to instantiate collaborators.

---

## 4. When to Use It

*   **Constructor Injection**: Always prefer constructor injection with `@Inject constructor(...)` for repositories, use cases, mappers, and ViewModels.
*   **Interface Binding**: Use `@Binds` inside an `abstract class` or `interface` module to bind an interface abstraction to its concrete implementation with zero runtime overhead:
    ```kotlin
    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository
    ```
*   **Third-Party & System Instances**: Use `@Provides` inside an `@InstallIn` module for types you do not own (e.g. `Retrofit`, `OkHttpClient`, `RoomDatabase`, `SharedPreferences`).
*   **ViewModel Scoping**: Annotate Android ViewModels with `@HiltViewModel` and inject dependencies through the constructor.
*   **Context Disambiguation**: Use `@ApplicationContext` or `@ActivityContext` qualifiers to prevent leaking short-lived Activity contexts into long-lived Singletons.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Over-Scoping with `@Singleton`**: Do **NOT** annotate every class with `@Singleton`. Most repositories and use cases should be unscoped (factory-bound, created on demand) unless they maintain shared in-memory state or costly synchronization locks.
*   **Field Injection in Non-Android Classes**: Do **NOT** use field injection (`@Inject lateinit var`) in ViewModels, repositories, or domain use cases. Field injection is strictly reserved for framework-instantiated classes (`@AndroidEntryPoint` Activities/Fragments).
*   **Service Locator Anti-Pattern**: Avoid querying `EntryPoints.get()` dynamically inside domain classes. Pass dependencies explicitly via constructor parameters.
*   **Injecting Data Entities**: Never inject entity data models, DTOs, or UI states. Inject only behaviors, services, repositories, and coordinators.

---

## 6. Advantages & Disadvantages

| Pattern / Approach | Dagger Hilt (Compile-Time) | Service Locator / Manual DI / Koin |
| :--- | :--- | :--- |
| **Verification** | Verified at compile time (fail-fast build). | Runtime resolution; missing dependencies crash at runtime. |
| **Performance** | Zero reflection overhead at runtime; generated code. | Reflection or runtime hash-map lookups. |
| **Android Integration** | Built-in Jetpack Compose, ViewModel, and WorkManager support. | Requires separate runtime integration extensions. |
| **Build Speed** | Requires annotation processing / KSP; slightly longer compile time. | Faster build times; no code generation overhead. |
| **Refactoring Safety** | Renaming or removing a dependency fails compilation everywhere. | Runtime lookup failures can escape unnoticed. |

---

## 7. Practical Examples

### Bad Example: Static Singletons, Leaked Activity Context & Untestable ViewModels

```kotlin
// BAD: Manual singleton, leaking activity context, no dependency injection
object ServiceLocator {
    var appContext: Context? = null
    var apiService: BadApiService? = null
}

class BadProfileViewModel : ViewModel() {
    // HAZARD: Direct coupling to static locator, impossible to unit test cleanly
    private val api = ServiceLocator.apiService ?: BadApiService()

    // HAZARD: Holding activity context inside ViewModel causes memory leaks on rotation!
    var activityContext: Context? = null

    fun loadData() {
        // ...
    }
}
```

### Good Example: Modern Dagger Hilt with Constructor Injection & Test Modules

```kotlin
// GOOD: Constructor injection, clean abstraction binding, scoped modules
interface UserRepository {
    suspend fun getUserProfile(userId: String): Result<UserProfile>
}

@Singleton
class UserRepositoryImpl @Inject constructor(
    private val apiService: UserApiService,
    private val userDao: UserDao,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : UserRepository {
    override suspend fun getUserProfile(userId: String): Result<UserProfile> = 
        withContext(ioDispatcher) {
            // Business logic here
            Result.success(UserProfile("User", "user@example.com"))
        }
}

// Module binding interface to implementation
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    @Singleton
    abstract fun bindUserRepository(
        userRepositoryImpl: UserRepositoryImpl
    ): UserRepository
}

// Network module providing third-party clients
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .build()
    }
}

// ViewModel with Hilt injection
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {
    private val userId: String = checkNotNull(savedStateHandle["userId"])
    
    // ViewModel logic
}

// Automated Test Override Module
@Module
@TestInstallIn(
    components = [SingletonComponent::class],
    replaces = [RepositoryModule::class]
)
abstract class FakeRepositoryModule {
    @Binds
    @Singleton
    abstract fun bindFakeUserRepository(
        fakeImpl: FakeUserRepository
    ): UserRepository
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Leaking Activity Context into Singletons**:
    *   *Problem*: Passing an Activity's `Context` into a `@Singleton` repository retains the entire destroyed Activity, its Views, and its resources in memory forever.
    *   *Remedy*: Always use the `@ApplicationContext` qualifier when a persistent component requires a context:
        ```kotlin
        @Provides
        @Singleton
        fun provideDatabase(@ApplicationContext context: Context): AppDatabase
        ```
2.  **Circular Dependencies**:
    *   *Problem*: `ClassA` depends on `ClassB`, which in turn depends on `ClassA`. Dagger compilation fails with a circular dependency error.
    *   *Remedy*: Refactor shared logic into a separate coordinator or use `Lazy<T>` / `Provider<T>` injection to break the direct cycle:
        ```kotlin
        class ClassA @Inject constructor(private val b: dagger.Lazy<ClassB>)
        ```
3.  **Missing `@AndroidEntryPoint` on Hosts**:
    *   *Problem*: Adding `@Inject` into a Fragment without annotating both the Fragment AND its host `ComponentActivity` with `@AndroidEntryPoint` causes a runtime `IllegalStateException`.
    *   *Remedy*: Ensure all enclosing Activities and Fragments in the hierarchy are annotated with `@AndroidEntryPoint`.

---

## 9. Verification Checklist

- [ ] Are all repositories, use cases, and services instantiated via constructor injection with `@Inject constructor(...)`?
- [ ] Is field injection (`@Inject lateinit var`) restricted strictly to framework-instantiated classes?
- [ ] Are interfaces bound to implementations using `@Binds` in abstract modules rather than `@Provides`?
- [ ] Is `@ApplicationContext` used for long-lived components that require Android Context?
- [ ] Are ViewModels annotated with `@HiltViewModel` and injected cleanly without manual factories?
- [ ] Are test implementations cleanly swappable via `@TestInstallIn` or fake modules without polluting production code?
- [ ] Does the project compile without Dagger graph cycle warnings or missing binding errors?
