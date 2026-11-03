# 09. API & Database Security: Transport Encryption & SQL Protection

---

## 1. Definition
**API and Database Security** encompasses the defensive measures applied at the data transmission and persistence layers. It includes enforcing **TLS 1.3** transport encryption, **Certificate Pinning** for high-risk mobile endpoints, **Parameterized SQL Queries** (preventing SQL Injection), **Database Encryption at Rest (SQLCipher)**, and **API Rate Limiting**.

---

## 2. Purpose
Data is most vulnerable when traveling across the wire (subject to interception, eavesdropping, and tampering) and when stored on a physical device disk (subject to extraction if the phone is lost, stolen, or rooted). The purpose of this standard is to guarantee **end-to-end cryptographic protection** of data in flight and at rest.

---

## 3. Why It Matters
*   **SQL Injection Immunity**: Using Room or parameterized queries guarantees that user input is always treated as data, never as executable SQL code.
*   **Encrypted Storage for Highly Sensitive Apps**: Standard SQLite databases store data in plain text on the device flash storage. For medical, financial, or sensitive personal apps, using SQLCipher (Encrypted Room) encrypts the entire database file with AES-256.
*   **Man-in-the-Middle (MITM) Defense**: In hostile network environments, attackers can install custom root certificates on user devices. Certificate Pinning ensures your app communicates *only* with your verified backend server certificate.

---

## 4. When to Use It
*   **All Database Access**: Use Room's compile-time parameterized query system by default.
*   **SQLCipher Database Encryption**: Implement when building apps that store sensitive health data, private financial records, or offline encrypted credentials.
*   **API Security**: Always communicate via HTTPS (TLS 1.2+). Implement Certificate Pinning on mission-critical financial endpoints.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Certificate Pinning on Small/Personal Projects**: **Do not implement certificate pinning unless you have a dedicated DevOps team managing certificate rotations.** If an SSL certificate expires or is renewed and your mobile app has pinned the old certificate, the app will instantly fail all network calls for every user worldwide until an emergency app update is approved by Google Play.
*   **Encrypting Public Catalog Caches**: Do not encrypt temporary image caches or public product catalog databases. Encrypting non-sensitive public data wastes CPU cycles and battery life without adding security.

---

## 6. Advantages & Disadvantages

| Parameterized Queries & SQLCipher | Raw SQL & Unencrypted Storage |
| :--- | :--- |
| **SQLi Immune**: Safe against malicious query injection. | **Catastrophic SQLi**: Single quote character can dump entire database. |
| **Encrypted at Rest**: Flash memory dumps yield only ciphertext. | **Plaintext Exposure**: Database easily opened in SQLite viewer on rooted phone. |
| **Cryptographic Integrity**: Data tampering is immediately detected. | **Tamper Vulnerable**: Local database records can be forged. |
| **Slight CPU Overhead**: Decrypting database pages takes minor CPU. | **Zero Encryption Overhead**: Maximum speed, zero protection. |

---

## 7. Practical Examples

### Encrypted Room Database with SQLCipher
```kotlin
// In build.gradle.kts:
// implementation("net.zetetic:android-database-sqlcipher:4.5.4")

// Generating or retrieving passphrase from Android Keystore (requesting StrongBox if available):
val passphraseBytes: ByteArray = KeystoreManager.getOrCreateDatabasePassphrase()
val factory = SupportFactory(passphraseBytes)

// Defensive hygiene: Overwrite raw key bytes in memory after factory initialization
java.util.Arrays.fill(passphraseBytes, 0.toByte())

val encryptedDatabase = Room.databaseBuilder(
    context,
    AppDatabase::class.java,
    "secure_user_records.db"
)
.openHelperFactory(factory) // SQLCipher encrypts entire SQLite file with AES-256
.build()
```

### Safe Parameterized Queries vs. Unsafe String Queries
```kotlin
// BAD: Prone to SQL Injection
@Dao
interface UnsafeDao {
    // DISASTER: String interpolation is unsafe
    @RawQuery
    fun searchNotes(query: SupportSQLiteQuery): List<NoteEntity>
}

// GOOD: Compile-time verified parameterized query in Room
@Dao
interface SafeDao {
    @Query("SELECT * FROM notes WHERE title LIKE '%' || :searchQuery || '%' AND user_id = :userId")
    suspend fun searchNotes(searchQuery: String, userId: String): List<NoteEntity>
}
```

---

## 8. Common Mistakes
1.  **String Concatenation in SQLite**: Writing `db.execSQL("DELETE FROM users WHERE id = " + inputId)` instead of using parameterized arguments `arrayOf(inputId)`.
2.  **Hardcoding the Database Encryption Key**: Using a static hardcoded string `"my_secret_password_123"` as the SQLCipher passphrase, rendering the encryption illusory. Always generate the key dynamically and store it in the Android Keystore (requesting StrongBox backing where supported).
3.  **Allowing Downgrade to Plaintext HTTP**: Missing configuration that allows an attacker to downgrade a connection from HTTPS to HTTP.

---

## 9. Verification Checklist (OWASP MASVS-STORAGE / ASVS V5)

- [ ] Are 100% of database queries parameterized (via Room or prepared statements)?
- [ ] If SQLCipher is used, is the encryption passphrase generated securely and stored in the Android Keystore?
- [ ] Are plaintext key arrays immediately cleared (`Arrays.fill(..., 0)`) after initialization?
- [ ] Are network requests forced over HTTPS with modern TLS (TLS 1.2 or 1.3)?
- [ ] Is sensitive personal data excluded from unencrypted local cache files?
- [ ] Are backend endpoints configured with rate limiting to prevent automated brute-force attacks?
