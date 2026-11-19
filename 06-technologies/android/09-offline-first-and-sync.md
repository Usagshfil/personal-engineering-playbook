# 09. Android Offline-First Architecture & Sync Engine: Optimistic UI, WorkManager & Conflict Resolution

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Android 14+ (API 34+), WorkManager 2.9+, Room 2.6+, Kotlin Coroutines & Flow 1.8+

---

## 1. Definition & Core Concept

An **Offline-First Architecture** treats the device's local database as the primary Single Source of Truth (SSOT) for all UI rendering, rather than relying on live network round-trips. The application reads from and writes to the local persistent store (Room) immediately, while an asynchronous **Sync Engine** synchronizes local changes with remote backend services in the background.

```
+---------------------------------------------------------------------------------------------------+
|                                 OFFLINE-FIRST SYNC ENGINE FLOW                                    |
|                                                                                                   |
|  [User Interaction]                                                                               |
|         │                                                                                         |
|         ▼                                                                                         |
|  [ViewModel / Repository]                                                                         |
|         │                                                                                         |
|         ├─── 1. Write Optimistically ────► [Local Room DB (SSOT)] ──── 2. Live Flow ──► [Compose UI] |
|         │                                          ▲                                              |
|         │                                          │ 5. Acknowledge / Update Remote IDs           |
|         ▼                                          │                                              |
|  3. Enqueue WorkManager ──────────────► [Sync Worker (WorkManager)]                                |
|     (Constraints: Network CONNECTED)               │                                              |
|                                                    ├── 4. Push Mutations & Pull Fresh State       |
|                                                    ▼                                              |
|                                            [Remote REST API]                                      |
+---------------------------------------------------------------------------------------------------+
```

### The Mutation Lifecycle & Sync State Taxonomy
Every locally mutable database entity incorporates sync metadata tracking its synchronization lifecycle:

*   `SYNCED`: The local entity is identical to the canonical backend record.
*   `PENDING_INSERT`: Created offline on the client; lacks an authoritative server-assigned ID.
*   `PENDING_UPDATE`: Modified locally while offline; waiting to push deltas to the backend.
*   `PENDING_DELETE` *(Tombstone)*: Marked as deleted by the user; hidden from UI queries, waiting to propagate deletion to the backend before being permanently purged from local storage.
*   `SYNC_ERROR`: Encountered a non-retryable validation or business invariant rejection from the backend; requires user review or manual conflict resolution.

---

## 2. Purpose

The purpose of this standard is to guarantee instantaneous, zero-latency user interactions, ensure complete application usability during zero-connectivity or unstable network conditions, prevent silent data loss from unexpected process termination, and provide a reliable, battery-efficient synchronization pipeline.

---

## 3. Why It Matters

*   **Zero-Latency Perceived Performance**: Waiting for a network response (100ms–3000ms) before updating the user interface creates sluggish, unresponsive apps. Writing optimistically to local SQLite displays updates in $<16\text{ms}$ (1 frame at 60fps).
*   **Resilience in Real-World Conditions**: Mobile devices regularly encounter dead zones, elevators, subways, and captive portals. An offline-first app remains completely functional for reading and editing.
*   **Guaranteed Durability Across Process Death**: Staging pending mutations in memory or raw Coroutine scopes risks data destruction when the Android OS kills background tasks. Persisting pending mutations to Room with WorkManager guarantees execution even across device reboots.
*   **Radio & Battery Efficiency**: Rather than firing radio hardware for every granular action, WorkManager batches pending operations and synchronizes only when network constraints are satisfied (`NetworkType.CONNECTED`), reducing battery consumption.

---

## 4. When to Use It

*   **Productivity & CRUD Workflows**: Note taking, task tracking, inspection forms, project management, and drafting content.
*   **E-Commerce Staging**: Shopping cart modifications, wishlists, and order drafts prior to final payment submission.
*   **Field Mobility Applications**: Logistics, warehouse inventory, delivery tracking, and health records where connectivity is intermittent.
*   **Feed & Content Readers**: News readers, social feeds, and documentation caches that can be browsed offline and refreshed incrementally.

---

## 5. When NOT to Use It

*   **Authoritative Financial & Payment Finalization**: Credit card authorization, payment gateway tokens, wire transfers, and stock trading where holding stale balance assumptions introduces double-spending risks.
*   **Live Multi-Party Collaborative State**: Interactive whiteboards, video calling signaling (WebRTC), and live auction bidding where instantaneous real-time consensus is required.
*   **Time-Sensitive Ephemeral State**: One-time authentication codes (TOTP/SMS), multi-factor challenges, and active turn-by-turn navigation updates.

---

## 6. Advantages & Disadvantages

| Dimension | Offline-First (Room + WorkManager) | Network-First (Direct API Calls) |
| :--- | :--- | :--- |
| **UI Latency** | **Instantaneous ($\le 16\text{ms}$)**; updates immediately. | High ($200\text{ms} - 5000\text{ms}$); blocks on network spinner. |
| **Offline Usability** | **Complete**; read and write operations function smoothly. | **Broken**; throws network exceptions, disables UI inputs. |
| **Data Durability** | **Guaranteed**; written to local SQLite disk before sync. | Fragile; lost if network fails or process dies in flight. |
| **Implementation Complexity**| **Higher**; requires sync states, tombstones, conflict rules. | Low; simple HTTP call and response mapping. |
| **Conflict Resolution** | Requires deterministic rules (LWW, 3-way merge, or manual). | Handled by backend sequentially. |
| **Battery Impact** | **Optimized**; batch sync via OS scheduler. | Inefficient; wakes radio on every individual user action. |

---

## 7. Practical Examples

### 7.1 Entity Modeling with Sync Metadata

```kotlin
// domain/model/SyncStatus.kt
enum class SyncStatus {
    SYNCED,
    PENDING_INSERT,
    PENDING_UPDATE,
    PENDING_DELETE,
    SYNC_ERROR
}

// data/local/entity/TaskEntity.kt
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "tasks",
    indices = [
        Index(value = ["syncStatus"]),
        Index(value = ["remoteId"], unique = true)
    ]
)
data class TaskEntity(
    @PrimaryKey(autoGenerate = true)
    val localId: Long = 0,
    val remoteId: String? = null,
    val title: String,
    val isCompleted: Boolean,
    val syncStatus: SyncStatus,
    val clientModifiedAt: Long = System.currentTimeMillis(),
    val serverUpdatedAt: Long? = null,
    val syncErrorMessage: String? = null
)
```

### 7.2 DAO with Tombstone Filtering & Pending Mutation Queries

```kotlin
// data/local/dao/TaskDao.kt
import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    // UI observes only non-deleted tasks
    @Query("SELECT * FROM tasks WHERE syncStatus != 'PENDING_DELETE' ORDER BY clientModifiedAt DESC")
    fun observeActiveTasks(): Flow<List<TaskEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(task: TaskEntity): Long

    @Query("SELECT * FROM tasks WHERE syncStatus IN ('PENDING_INSERT', 'PENDING_UPDATE', 'PENDING_DELETE')")
    suspend fun getPendingSyncTasks(): List<TaskEntity>

    // Soft delete: Mark as tombstone so the sync engine knows to delete it remotely
    @Query("UPDATE tasks SET syncStatus = 'PENDING_DELETE', clientModifiedAt = :timestamp WHERE localId = :localId")
    suspend fun markForDeletion(localId: Long, timestamp: Long = System.currentTimeMillis())

    // Hard purge: Remove permanently after backend confirms deletion
    @Query("DELETE FROM tasks WHERE localId = :localId")
    suspend fun purgeLocally(localId: Long)
}
```

### 7.3 Repository: Optimistic UI Writes & Work Scheduling

```kotlin
// data/repository/TaskRepositoryImpl.kt
import androidx.work.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TaskRepositoryImpl @Inject constructor(
    private val taskDao: TaskDao,
    private val workManager: WorkManager
) : TaskRepository {

    override fun getTasks(): Flow<List<Task>> =
        taskDao.observeActiveTasks().map { entities -> entities.map { it.toDomain() } }

    override suspend fun createTask(title: String) {
        val pendingEntity = TaskEntity(
            title = title,
            isCompleted = false,
            syncStatus = SyncStatus.PENDING_INSERT
        )
        // 1. Instant local write - Compose UI updates via Flow immediately
        taskDao.upsert(pendingEntity)

        // 2. Schedule background sync with guaranteed execution
        scheduleSync()
    }

    override suspend fun deleteTask(localId: Long) {
        // 1. Soft delete immediately (hides from UI Flow)
        taskDao.markForDeletion(localId)

        // 2. Schedule deletion sync
        scheduleSync()
    }

    private fun scheduleSync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val syncRequest = OneTimeWorkRequestBuilder<TaskSyncWorker>()
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                java.util.concurrent.TimeUnit.MILLISECONDS
            )
            .addTag("task_sync_work")
            .build()

        // Enqueue uniquely to coalesce rapid consecutive writes into one sync pass
        workManager.enqueueUniqueWork(
            "TaskSyncWork",
            ExistingWorkPolicy.APPEND_OR_REPLACE,
            syncRequest
        )
    }
}
```

### 7.4 Sync Worker: Two-Way Synchronization with Conflict Resolution

```kotlin
// data/sync/TaskSyncWorker.kt
import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import retrofit2.HttpException
import java.io.IOException

@HiltWorker
class TaskSyncWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted workerParams: WorkerParameters,
    private val taskDao: TaskDao,
    private val api: TaskApiService
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val pendingTasks = taskDao.getPendingSyncTasks()
        if (pendingTasks.isEmpty()) return Result.success()

        for (task in pendingTasks) {
            try {
                when (task.syncStatus) {
                    SyncStatus.PENDING_INSERT -> {
                        val response = api.createTask(
                            idempotencyKey = "task_${task.localId}_${task.clientModifiedAt}",
                            request = TaskCreateRequest(title = task.title, isCompleted = task.isCompleted)
                        )
                        // Acknowledge remote ID and transition to SYNCED
                        taskDao.upsert(
                            task.copy(
                                remoteId = response.id,
                                syncStatus = SyncStatus.SYNCED,
                                serverUpdatedAt = response.updatedAt,
                                syncErrorMessage = null
                            )
                        )
                    }
                    SyncStatus.PENDING_UPDATE -> {
                        val response = api.updateTask(
                            remoteId = task.remoteId!!,
                            request = TaskUpdateRequest(title = task.title, isCompleted = task.isCompleted)
                        )
                        taskDao.upsert(
                            task.copy(
                                syncStatus = SyncStatus.SYNCED,
                                serverUpdatedAt = response.updatedAt,
                                syncErrorMessage = null
                            )
                        )
                    }
                    SyncStatus.PENDING_DELETE -> {
                        if (task.remoteId != null) {
                            api.deleteTask(task.remoteId)
                        }
                        // Purge permanently from local SQLite after successful remote deletion
                        taskDao.purgeLocally(task.localId)
                    }
                    else -> Unit
                }
            } catch (e: IOException) {
                // Transient network failure: Retry with exponential backoff
                return Result.retry()
            } catch (e: HttpException) {
                if (e.code() in 500..599) {
                    // Server error: Retry
                    return Result.retry()
                } else if (e.code() == 409) {
                    // Conflict detected: Apply Last-Write-Wins (LWW) or mark for user resolution
                    resolveConflict(task)
                } else {
                    // Client error (400, 422): Non-retryable. Flag error to prevent infinite loops
                    taskDao.upsert(
                        task.copy(
                            syncStatus = SyncStatus.SYNC_ERROR,
                            syncErrorMessage = "Validation error: ${e.message()}"
                        )
                    )
                }
            }
        }

        return Result.success()
    }

    private suspend fun resolveConflict(task: TaskEntity) {
        val remoteRecord = api.getTask(task.remoteId!!)
        // Last-Write-Wins (LWW) Policy based on timestamp
        if ((remoteRecord.updatedAt ?: 0) > task.clientModifiedAt) {
            // Server is newer: Overwrite local state
            taskDao.upsert(
                task.copy(
                    title = remoteRecord.title,
                    isCompleted = remoteRecord.isCompleted,
                    syncStatus = SyncStatus.SYNCED,
                    serverUpdatedAt = remoteRecord.updatedAt
                )
            )
        } else {
            // Client is newer: Force push update
            api.updateTask(task.remoteId, TaskUpdateRequest(task.title, task.isCompleted))
            taskDao.upsert(task.copy(syncStatus = SyncStatus.SYNCED))
        }
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Hard Deleting Local Rows Instead of Using Tombstones**:
    *   *Problem*: Executing `DELETE FROM tasks WHERE id = :id` locally while offline removes the record from SQLite. When the device reconnects and pulls updates from the backend, the server returns the record again, causing the deleted item to reappear ("zombie record").
    *   *Remedy*: Always soft-delete using a tombstone (`syncStatus = 'PENDING_DELETE'`). Filter out tombstones from UI queries and only execute permanent `DELETE` queries after the backend confirms deletion.
2.  **Launching Background Sync in ViewModels or Raw Coroutine Scopes**:
    *   *Problem*: Triggering `viewModelScope.launch { api.sync() }` means that if the user backgrounds or leaves the app, the CoroutineScope is cancelled and the mutation never syncs.
    *   *Remedy*: Always delegate synchronization to `WorkManager`. WorkManager operates as an OS-level background service that survives process death and device restarts.
3.  **Infinite Retry Loops on Client Errors (4xx)**:
    *   *Problem*: Catching all exceptions uniformly and calling `Result.retry()` causes WorkManager to continuously retry a bad payload that the backend permanently rejects (e.g. HTTP 400 Bad Request or 422 Unprocessable Entity), draining the battery.
    *   *Remedy*: Distinguish network/5xx server errors (`Result.retry()`) from 4xx client errors (`Result.failure()` or transition to `SyncStatus.SYNC_ERROR`).
4.  **Omitting Client-Side Idempotency Keys**:
    *   *Problem*: In spotty mobile connectivity, a request may succeed on the server while the response fails to reach the client. The client retries, causing duplicate records on the server.
    *   *Remedy*: Always generate a unique client UUID or deterministic fingerprint (`localId_timestamp`) and pass it via an `Idempotency-Key` HTTP header.

---

## 9. Verification Checklist

- [ ] Does Room serve as the Single Source of Truth, with UI screens observing reactive `Flow<T>`?
- [ ] Are local mutations written optimistically to Room with pending sync states before network calls?
- [ ] Are deletions handled via soft-delete tombstones (`PENDING_DELETE`) to prevent zombie records?
- [ ] Is background synchronization orchestrated via `WorkManager` with `NetworkType.CONNECTED` constraints?
- [ ] Are transient network/5xx failures retried with exponential backoff while 4xx errors halt gracefully?
- [ ] Do network write requests include client-generated `Idempotency-Key` headers to prevent duplicates?
- [ ] Is there an explicit conflict resolution policy (Last-Write-Wins or manual resolution) for concurrent updates?
- [ ] Are pending mutations indexed by `syncStatus` in Room for fast retrieval?
