# 11. Database Integration: Offline-First Persistence & Room Database

---

## 1. Definition
**Database Integration** refers to the architecture, design, and query patterns used to persist application data locally on a device. In modern Android, this is standardly implemented using **Room Database**—Google's official object-mapping abstraction layer built on top of SQLite, featuring compile-time SQL verification and reactive `Flow` query streams.

---

## 2. Purpose
Without local persistence, a mobile application is completely helpless when internet connectivity drops: screens display blank error spinners, user edits are lost, and every app launch requires slow, bandwidth-heavy network refetches. Database integration enables **instant app startup, seamless offline capabilities, and zero data loss**.

---

## 3. Why It Matters
*   **Compile-Time SQL Validation**: Room verifies SQL queries at compile time. If you misspell a column name or query a non-existent table, your build fails instantly before you ever run the app on a phone.
*   **Reactive Flow Streams**: Room DAOs can return Kotlin `Flow<List<T>>`. Whenever any background worker or user action modifies the table, Room automatically pushes the updated list to your ViewModel and Compose UI in real time.
*   **Controlled Migrations**: Room provides structured migration classes (`Migration(1, 2)`) to safely alter tables and preserve user data across app updates.

---

## 4. When to Use It
*   **Any Application Storing User Data**: Notes, expense records, cached catalog items, user preferences, and pending offline sync queues.
*   **Offline-First Architectures**: The local database acts as the single source of truth, with the network serving only to synchronize updates.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Simple Key-Value Settings**: Do not create a SQLite database table with columns `(key, value)` just to store dark mode preference or an auth token. Use **Jetpack DataStore** for simple key-value pairs or small user settings.
*   **Large Binary Blobs**: Never store large image files, audio recordings, or video clips directly inside SQLite BLOB columns. Store media files on the filesystem (app internal storage) and store only their local file paths in Room.

---

## 6. Advantages & Disadvantages

| Room Database (SQLite Abstraction) | Raw SQLite / Key-Value Misuse |
| :--- | :--- |
| **Compile-Time SQL Safety**: Catches syntax errors during build. | **Runtime Crashes**: Typo in SQL string crashes app at runtime. |
| **Reactive Observability**: Automatically emits updates via `Flow`. | **Manual Polling**: Must write custom listeners to detect updates. |
| **Structured Migrations**: Clean APIs to handle version upgrades. | **Fragile Upgrades**: Prone to accidentally wiping user databases. |

---

## 7. Practical Examples

### Modern Room Database Setup in Kotlin
```kotlin
// 1. ENTITY
@Entity(
    tableName = "notes",
    indices = [Index(value = ["created_at"])] // Index for fast sorting
)
data class NoteEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    @ColumnInfo(name = "title") val title: String,
    @ColumnInfo(name = "content") val content: String,
    @ColumnInfo(name = "created_at") val createdAtMillis: Long = System.currentTimeMillis()
)

// 2. DATA ACCESS OBJECT (DAO)
@Dao
interface NoteDao {
    // Reactive: Emits every time notes table changes
    @Query("SELECT * FROM notes ORDER BY created_at DESC")
    fun observeAllNotes(): Flow<List<NoteEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertNote(note: NoteEntity): Long

    @Query("DELETE FROM notes WHERE id = :id")
    suspend fun deleteNoteById(id: Long): Int
}

// 3. DATABASE DEFINITION & MIGRATION
@Database(
    entities = [NoteEntity::class],
    version = 1,
    exportSchema = true // Exports schema JSON for migration testing
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun noteDao(): NoteDao
}
```

---

## 8. Common Mistakes
1.  **Running Queries on Main Thread**: Calling Room methods without `suspend` or outside `Dispatchers.IO`, freezing the UI. Room will crash by default if called on the Main thread.
2.  **`fallbackToDestructiveMigration()` in Production**: Calling destructive fallback wipes the user's entire local database if a migration is missing during an update. Always provide explicit `Migration` objects for production releases.
3.  **Missing Indexes on Foreign Keys**: Forgetting to add `@Index` to foreign key columns, causing table scans and lag on large joins.

---

## 9. Verification Checklist

- [ ] Are all database operations marked as `suspend` or returning reactive `Flow`?
- [ ] Is `exportSchema = true` enabled in `@Database` to verify schema history in version control?
- [ ] Are foreign keys and query filter columns indexed?
- [ ] Is `fallbackToDestructiveMigration()` strictly forbidden in production builds?
- [ ] Are large files and images stored on disk rather than directly inside database BLOBs?
