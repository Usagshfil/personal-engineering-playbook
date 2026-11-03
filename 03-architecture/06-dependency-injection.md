# 06. Dependency Injection: Decoupling Creation from Consumption

---

## 1. Definition
**Dependency Injection (DI)** is a software design pattern implementing Inversion of Control (IoC), where an object receives its dependencies (collaborators, services, repositories) from an external provider rather than instantiating them itself using the `new` operator.

DI can be achieved via:
*   **Manual Constructor Injection**: Passing dependencies directly through constructor parameters.
*   **Compile-Time DI Frameworks**: Tools like **Dagger / Hilt** (Google's official standard for Android) that generate binding code at compile time.
*   **Lightweight Service Locators / DSLs**: Tools like **Koin** that resolve dependencies at runtime using Kotlin DSLs.

---

## 2. Purpose
Hardcoding dependency instantiation inside a class (`val repo = UserRepositoryImpl()`) tightly couples the class to that specific implementation, making it impossible to replace with a fake during automated unit tests, and making global configuration changes difficult.

---

## 3. Why It Matters
*   **Frictionless Unit Testing**: When dependencies are passed via constructor, a unit test can pass a fake, in-memory repository in one line: `val vm = UserViewModel(FakeUserRepository())`.
*   **Single-Point Configuration**: You configure network timeouts, database names, or base URLs in one central DI module, and every class in the app automatically receives the correct instance.
*   **Lifecycle Scoping**: DI frameworks manage object lifecycles automatically (e.g. Singleton scope for Database, ViewModelScoped for UI coordinators).

---

## 4. When to Use It
*   **Constructor Injection by Default**: Always pass dependencies via constructor parameters in your classes.
*   **Hilt in Production Android Apps**: Use Hilt for standard to large Android applications to handle Android lifecycle scoping (`@HiltViewModel`, `@AndroidEntryPoint`).
*   **Manual DI or Koin for Small Projects**: In small prototypes or learning projects, simple manual constructor injection avoids heavy annotation processors and long build times.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Service Locator Anti-Pattern**: Do not pass a global `ServiceLocator` or DI container into classes (`ServiceLocator.get<UserRepository>()`). This hides class dependencies and couples classes to the DI framework.
*   **Injecting Data Entities**: Never inject simple data models, value objects, or entities (`data class User(...)`). Inject *services and repositories*, not data.

---

## 6. Advantages & Disadvantages

| Constructor DI / Hilt | Hardcoded `new` / Direct Instantiation |
| :--- | :--- |
| **Effortless Unit Testing**: Swap implementations instantly. | **Untestable**: Hard to test without complex reflection hacks. |
| **Centralized Lifecycle**: Scope singletons or view models cleanly. | **Scattered Singletons**: Static instances leak across app. |
| **Loose Coupling**: Components only depend on interfaces/abstractions. | **Tight Coupling**: Concrete class changes break all callers. |
| **Initial Learning Curve**: Hilt annotations require understanding. | **Easy to Write Today**: Fast to hack initially, nightmare to maintain. |

---

## 7. Practical Examples

### Bad Example: Hardcoded Dependency Creation
```kotlin
// BAD: ViewModel creates its own concrete dependencies
class ProfileViewModel : ViewModel() {
    // Cannot be unit tested without hitting real SQLite disk and real network!
    private val database = Room.databaseBuilder(context, AppDatabase::class.java, "app.db").build()
    private val api = Retrofit.Builder().baseUrl("https://api.com").build().create(Api::class.java)
    private val repository = UserRepository(database.userDao(), api)
}
```

### Good Example: Constructor Injection with Hilt
```kotlin
// 1. DI MODULE: Defines how instances are created and scoped
@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(context, AppDatabase::class.java, "production.db").build()
    }

    @Provides
    @Singleton
    fun provideUserRepository(database: AppDatabase, api: UserApi): UserRepository {
        return OfflineFirstUserRepository(database.userDao(), api)
    }
}

// 2. VIEWMODEL: Injected cleanly via constructor
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val repository: UserRepository
) : ViewModel() {
    // 100% testable in 1 line: ProfileViewModel(FakeUserRepository())
}
```

---

## 8. Common Mistakes
1.  **Field Injection in Normal Classes**: Using `@Inject lateinit var repo: UserRepository` in ordinary classes instead of constructor injection. Field injection should be reserved only for Android framework classes where you don't control the constructor (`Activity`, `Fragment`, `BroadcastReceiver`).
2.  **Over-Scoping to Singleton**: Making every repository and helper a `@Singleton`, consuming memory unnecessarily when they could be transient.
3.  **Hiding Dependencies**: Using a global service locator instead of explicit constructor parameters.

---

## 9. Verification Checklist

- [ ] Are class dependencies passed explicitly through constructor parameters?
- [ ] Is field injection (`lateinit var`) strictly confined to Android framework boundaries (`Activity`, `Service`)?
- [ ] Are data classes and domain entities kept free of DI annotations?
- [ ] Can every ViewModel and Repository be instantiated in a unit test without initializing the DI container?
- [ ] Are singleton scopes reserved only for genuinely stateful, expensive instances (Database, OkHttpClient)?
