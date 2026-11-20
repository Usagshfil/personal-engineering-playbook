# 04. Android Persistence: Room Database, Migrations & Security

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Room 2.6+, SQLite 3.35+, SQLCipher / AndroidX Security

---

## 1. Definition & Core Concept

**Room** is Android's primary Object-Relational Mapping (ORM) library built on top of SQLite. It provides compile-time verification of raw SQL statements, abstracts boilerplate database boilerplate, and integrates seamlessly with Kotlin Coroutines and reactive `Flow`.

In this Playbook, Room serves as the local persistent cache and the Single Source of Truth (SSOT) for offline-first Android applications.

```
+-------------------------------------------------------------------------+
| Room Layered Architecture                                               |
|                                                                         |
| UI / ViewModel  <--- (Flow<T>) --- DAO (Data Access Object)            |
|                                     |                                   |
|                                     v                                   |
|                               RoomDatabase (Encrypted via SQLCipher)   |
|                                     |                                   |
|                                     v                                   |
|                              Underlying SQLite Database (/data/data/...) |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to guarantee compile-time SQL safety, eliminate UI freezes through asynchronous execution, prevent silent data loss during schema evolutions via rigorous migration testing, and secure data-at-rest using hardware-backed encryption.

---

## 3. Why It Matters

*   **Compile-Time Query Verification**: Room validates `@Query` statements at build time against the entity schemas. Syntax typos or invalid table/column references fail the build immediately rather than crashing in production.
*   **Reactive Single Source of Truth**: Room DAOs returning `Flow<T>` automatically emit fresh data whenever underlying tables update, eliminating manual synchronization logic between network refreshes and UI state.
*   **Zero Silent Data Destruction**: Uncontrolled database migrations risk wiping local user data via `fallbackToDestructiveMigration()`. Structured migrations ensure user data integrity across app updates.
*   **Data-at-Rest Security (Tier 1 Invariant Gate)**: Mobile devices are subject to physical extraction, backup theft, and rooting attacks. PII and sensitive state must be encrypted at rest with hardware-backed keys.

---

## 4. When to Use It

*   **Structured Relational Persistence**: Use Room for domain entities, relational models (1:1, 1:N, N:M), transaction history, and offline content caches.
*   **Reactive Local Observables**: Expose `Flow<List<T>>` or `Flow<T?>` from DAOs for UI screens that observe live database state.
*   **One-Shot Data Operations**: Declare DAO operations as `suspend fun` for inserts, updates, deletes, and single snapshot queries.
*   **Schema Migrations**:
    *   Use `AutoMigration` for simple additive changes (adding nullable columns, creating new tables).
    *   Use explicit `Migration(from, to)` classes for destructive transformations (renaming columns, altering constraints, splitting tables).
*   **Migration Testing**: Always test migrations using `MigrationTestHelper` against real SQLite schema hashes generated in `schemas/`.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **KeyValue Settings & Preferences**: Do NOT use Room for storing simple key-value pairs (e.g. user theme preferences, onboarding flags). Use Jetpack **DataStore Preferences** instead.
*   **Destructive Fallbacks in Production**: **NEVER** enable `fallbackToDestructiveMigration()` in release builds. Wiping the database on upgrade leads to disastrous data loss for end users.
*   **Main-Thread Queries**: **NEVER** use `allowMainThreadQueries()`. All queries must run on background dispatchers or be exposed as `suspend` / `Flow`.
*   **Heavy Binary Blobs**: Do not store large images, audio files, or video assets directly in Room as `BLOB`. Store media files in app-private disk storage (`context.filesDir`) and store only the relative file path in the database.

---

## 6. Advantages & Disadvantages

| Feature | Room ORM | Raw SQLite / SQLiteOpenHelper |
| :--- | :--- | :--- |
| **Safety** | Compile-time syntax and schema verification. | Runtime syntax errors and runtime crashes. |
| **Reactive Integration** | Native first-class Kotlin `Flow` and Coroutines support. | Requires manual cursor listeners and notify triggers. |
| **Type Converters** | Clean `@TypeConverter` annotations for complex types. | Manual cursor parsing boilerplate (`getString`, `getInt`). |
| **Migration Tooling** | Schema JSON export and `MigrationTestHelper`. | Fragile manual SQL scripts without compile validation. |
| **Overhead** | Minimal annotation processing / KSP overhead. | Zero framework overhead, but massive development debt. |

---

## 7. Practical Examples

### Bad Example: Main-Thread Access, Destructive Migration & Hardcoded Credentials

```kotlin
// BAD: Destructive migration, allowMainThreadQueries, plaintext credentials, missing indices
@Entity(tableName = "users")
data class BadUserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val creditCardNumber: String // HAZARD: Sensitive financial data unencrypted in plaintext SQLite!
)

@Database(entities = [BadUserEntity::class], version = 1)
abstract class BadAppDatabase : RoomDatabase() {
    companion object {
        fun build(context: Context): BadAppDatabase {
            return Room.databaseBuilder(context, BadAppDatabase::class.java, "bad.db")
                .allowMainThreadQueries() // HAZARD: Causes UI freezes and ANRs!
                .fallbackToDestructiveMigration() // HAZARD: Wipes all user data on schema upgrade!
                .build()
        }
    }
}
```

### Good Example: Encrypted Database, Indexed Relational Schema, Reactive DAO & Safe Migration

```kotlin
// GOOD: Proper indices, value types, reactive DAO, encrypted SQLCipher support
@Entity(
    tableName = "notes",
    indices = [
        Index(value = ["user_id"]), // Index foreign key for optimal query performance
        Index(value = ["created_at"])
    ]
)
data class NoteEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0,
    
    @ColumnInfo(name = "user_id")
    val userId: String,
    
    @ColumnInfo(name = "title")
    val title: String,
    
    @ColumnInfo(name = "content")
    val content: String,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis()
)

@Dao
interface NoteDao {
    @Query("SELECT * FROM notes WHERE user_id = :userId ORDER BY created_at DESC")
    fun observeNotesByUser(userId: String): Flow<List<NoteEntity>>

    @Query("SELECT * FROM notes WHERE id = :id")
    suspend fun getNoteById(id: Long): NoteEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNote(note: NoteEntity): Long

    @Query("DELETE FROM notes WHERE id = :id")
    suspend fun deleteNote(id: Long): Int

    // ATOMIC CONDITIONAL UPDATE (Concurrency Defense)
    // Eliminates TOCTOU race condition: evaluates current state and transitions atomically in a single statement
    @Query("""
        UPDATE notes 
        SET content = :newContent, created_at = :now
        WHERE id = :id AND created_at = :expectedCreatedAt
    """)
    suspend fun updateNoteAtomically(id: Long, expectedCreatedAt: Long, newContent: String, now: Long): Int
}

@Database(
    entities = [NoteEntity::class],
    version = 2,
    autoMigrations = [
        AutoMigration(from = 1, to = 2) // Automated migration with schema verification
    ],
    exportSchema = true // Required for MigrationTestHelper and schema version tracking
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun noteDao(): NoteDao

    companion object {
        fun createEncrypted(
            context: Context,
            passphraseChars: CharArray // Retrieved securely from Android Keystore
        ): AppDatabase {
            val factory = net.sqlcipher.database.SupportFactory(
                net.sqlcipher.database.SQLiteDatabase.getBytes(passphraseChars)
            )
            // Immediately wipe the sensitive char array from memory (Tier 1 Rule 7)
            java.util.Arrays.fill(passphraseChars, '\u0000')

            return Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                "secure_app.db"
            )
            .openHelperFactory(factory)
            .build()
        }
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Omitting Foreign Key and Query Indices**:
    *   *Problem*: Defining an entity with foreign keys or frequently queried columns (e.g. `userId`, `status`) without adding `@Index(value = ["user_id"])` forces SQLite to perform a full table scan on every query.
    *   *Remedy*: Always specify `indices = [Index(value = ["col"])]` in `@Entity` annotations for filtered or joined columns.
2.  **Disabling Schema Export (`exportSchema = false`)**:
    *   *Problem*: Setting `exportSchema = false` stops Room from generating schema JSON files into the `schemas/` directory. Without schema files, `MigrationTestHelper` cannot reconstruct legacy database versions to verify schema migrations.
    *   *Remedy*: Set `exportSchema = true` and configure the schema location in Gradle KSP options.
3.  **Leaking SQLCipher Passphrases via String**:
    *   *Problem*: Storing a database passphrase in an immutable `String` keeps the raw secret in JVM memory indefinitely until garbage collection, leaving it vulnerable to memory dump extraction.
    *   *Remedy*: Handle passphrases as `CharArray` or `ByteArray` and defensively wipe them with `Arrays.fill(array, '\u0000')` immediately after initialization.
4.  **Silent Destructive Fallbacks in Production**:
    *   *Problem*: Leaving `.fallbackToDestructiveMigration()` active in release builds wipes customer data when a user upgrades across schema versions.
    *   *Remedy*: Restrict destructive fallbacks to debug configurations only (`if (BuildConfig.DEBUG) ...`) and provide automated or manual migrations for all production releases.
5.  **TOCTOU Race Conditions in State Transitions (Non-Atomic Reservation/Hold)**:
    *   *Problem*: Performing read-modify-write sequences in Kotlin coroutines (`val item = dao.get(); if (item.isAvailable) dao.upsert(item.copy(status = HOLD))`) creates a classic Time-of-Check to Time-of-Use (TOCTOU) race condition when concurrent background tasks or user actions execute simultaneously.
    *   *Remedy*: Execute an atomic conditional SQL update directly in the DAO (`UPDATE items SET status = 'HOLD' WHERE id = :id AND status = 'AVAILABLE'`) and inspect the affected rows count (`1` = success, `0` = slot already reserved/conflict).

---

## 9. Verification Checklist

- [ ] Is `exportSchema = true` enabled with schema JSON files committed to version control?
- [ ] Is `allowMainThreadQueries()` completely absent from production builds?
- [ ] Is `fallbackToDestructiveMigration()` strictly forbidden in release builds?
- [ ] Are all foreign key and frequently filtered columns covered by explicit `@Index` annotations?
- [ ] Are all DAO read operations returning reactive `Flow` or `suspend fun` for single queries?
- [ ] Are state transitions and contested resource reservations protected against TOCTOU race conditions via atomic conditional SQL updates?
- [ ] Are schema migrations verified with `MigrationTestHelper` automated unit tests?
- [ ] Is sensitive data encrypted using SQLCipher or Android Keystore wrappers, with memory wiped after use?
