# 05. The Repository Pattern: Mediating Data Sources & Single Source of Truth

---

## 1. Definition
The **Repository Pattern** mediates between the domain/business layer and data-mapping layers (Room database, network APIs, in-memory caches). It acts as an in-memory collection of domain entities, providing clean CRUD and reactive query interfaces while hiding the underlying storage mechanisms.

---

## 2. Purpose
Without a repository, UI or ViewModel classes must coordinate network calls, parse JSON responses, write to SQLite databases, handle offline caching, and resolve network conflicts. The Repository isolates all data source orchestration into a single class, establishing a **Single Source of Truth (SSOT)**.

---

## 3. Why It Matters
*   **Offline-First Capabilities**: With the Repository pattern, the UI observes a local database stream (e.g., Room `Flow<List<Item>>`). The repository fetches fresh data from the remote API in the background and saves it to Room. The UI updates automatically via database observation.
*   **Decoupled Network Details**: The ViewModel doesn't care whether data came from a Room database, an in-memory memory cache, or an AWS REST API.
*   **Effortless Testing**: You can mock the repository interface in ViewModel unit tests with simple fake data, without touching network or SQL.

---

## 4. When to Use It
*   **Multiple Data Sources**: Anytime an app reads or writes data across a local database AND a remote API.
*   **Offline-First Applications**: Essential for keeping UI functional when the user loses internet connection.
*   **Caching & Synchronization**: When incoming network payloads need caching, transformations, or conflict resolution before display.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Direct In-Memory Utilities**: A tool that only queries a hardware sensor (e.g. accelerometer) in real-time without caching or persistence does not need a repository.
*   **Over-Abstracted One-Liner Wrappers**: Do not create 5 layers of abstract repository bases if you are merely calling a read-only endpoint that has no local caching.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **Single Source of Truth**: UI only observes one authoritative stream. | **Mapping Boilerplate**: Requires mapping Network DTO $\rightarrow$ Room Entity $\rightarrow$ Domain Model. |
| **Robust Offline Support**: Seamless fallback when network drops. | **Sync Complexity**: Handling offline conflict resolution requires care. |
| **Simple Mocking**: Trivial to inject fake repositories during unit tests. | **Extra Layer**: Adds one more class between ViewModel and data. |

---

## 7. Practical Examples

```
       ┌────────────────────────┐
       │   ViewModel / Domain   │
       └───────────┬────────────┘
                   │ Observes Flow<List<Task>> / calls sync()
                   ▼
       ┌────────────────────────┐
       │     TaskRepository     │ (Single Source of Truth)
       └─────┬────────────┬─────┘
             │ Reads/Writes│ Fetches background updates
             ▼            ▼
      ┌───────────┐  ┌─────────────┐
      │  Room DB  │  │ Network API │
      └───────────┘  └─────────────┘
```

### Offline-First Repository Implementation (Kotlin Flow)
```kotlin
interface TaskRepository {
    fun getTasksStream(): Flow<List<Task>>
    suspend fun refreshTasks(): Result<Unit>
}

class OfflineFirstTaskRepository(
    private val localDao: TaskDao,
    private val remoteApi: TaskApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : TaskRepository {

    // 1. Single Source of Truth: UI always observes the database
    override fun getTasksStream(): Flow<List<Task>> {
        return localDao.observeAllTasks().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    // 2. Background Sync: Fetch from network, persist to local DB
    override suspend fun refreshTasks(): Result<Unit> = withContext(ioDispatcher) {
        runCatching {
            val response = remoteApi.fetchTasks()
            val entities = response.map { it.toEntity() }
            localDao.upsertAll(entities)
        }
    }
}
```

---

## 8. Common Mistakes
1.  **Returning DTOs to the UI**: Leaking raw Retrofit network models directly to ViewModels or Compose screens. Always map to domain models in the repository.
2.  **Dual Sources of Truth**: Having the ViewModel observe the database AND also update its state directly from the network response, causing UI flickering and race conditions.
3.  **Threading Violations**: Running database queries or network calls on the Main/UI thread instead of using `withContext(Dispatchers.IO)`.

---

## 9. Verification Checklist

- [ ] Does the repository serve as the Single Source of Truth for its entity?
- [ ] Are raw network DTOs mapped to domain models or database entities inside the repository?
- [ ] Are blocking I/O calls dispatched to `Dispatchers.IO`?
- [ ] Does the repository provide reactive streams (`Flow`) for observable data?
- [ ] Can the repository interface be cleanly substituted with a fake test repository in unit tests?
