# 03. Input Validation & Sanitization: Fail-Closed & Defense-in-Depth

---

## 1. Definition
**Input Validation** is the process of verifying that incoming external data (from user text fields, deep links, intents, network payloads, or file uploads) conforms strictly to expected formats, lengths, and character sets. **Sanitization** is the process of neutralizing or stripping potentially malicious characters before processing or rendering.

The primary security standard is **Fail-Closed Validation (Allowlist-based)**: accept only data matching an explicit list of allowed safe patterns; reject everything else.

---

## 2. Purpose
Untrusted inputs are the vehicle for almost all software exploits: SQL Injection (SQLi), Cross-Site Scripting (XSS), Command Injection, Path Traversal, and Buffer Overflows. The purpose of input validation is to establish an impenetrable boundary that prevents malicious payloads from reaching application logic or persistent storage.

---

## 3. Why It Matters
*   **Never Trust the Client**: Even if your Android app validates a form, an attacker can bypass the app entirely and send malicious HTTP requests directly to your backend API using Postman or Python scripts.
*   **Android Intent Injection**: Android apps communicate via `Intent` and Deep Links (`myapp://profile?id=123`). If deep link parameters are not validated, an external malicious app installed on the user's phone can exploit internal screens.
*   **Parameterized Queries are Non-Negotiable**: Using string concatenation to build SQL queries is the #1 database security failure. Always use parameterized queries.

---

## 4. When to Use It
*   **All System Boundaries**: Validate at the API gateway, in domain constructors, and before database writes.
*   **Deep Links & Android Intents**: Sanitize and validate every query parameter received from external intents.
*   **File Uploads**: Verify file size limits, MIME types, and sanitize filenames to prevent path traversal (`../../../etc/passwd`).

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Double-Escaping Display Strings**: Do not run regex sanitization on internal strings that were already validated at the boundary and stored safely. Re-sanitizing strings right before rendering in Compose often causes weird visual bugs like displaying `&amp;` instead of `&`.

---

## 6. Advantages & Disadvantages

| Allowlist / Fail-Closed Validation | Denylist / String Replacement |
| :--- | :--- |
| **Comprehensive Protection**: Only safe patterns are admitted. | **Fragile Security**: Attackers easily bypass character filters. |
| **Clear Business Domain**: Models enforce valid invariants. | **Silent Corruption**: Sanitizing by stripping chars alters user data. |
| **Immediate Error Feedback**: Informs user of invalid format. | **Hard to Maintain**: Must continuously update denylist rules. |

---

## 7. Practical Examples

### Bad Example: SQL Injection via String Concatenation
```kotlin
// VULNERABLE TO SQL INJECTION!
fun getUserNotes(userId: String): List<Note> {
    // If userId is: "' OR '1'='1" -> The attacker dumps every user's private notes!
    val query = "SELECT * FROM notes WHERE user_id = '$userId'"
    return rawDatabase.rawQuery(query, null)
}
```

### Good Example: Parameterized Query in Room + Domain Preconditions
```kotlin
// 1. Parameterized Query (Room automatically parameterizes :userId)
@Dao
interface NoteDao {
    @Query("SELECT * FROM notes WHERE user_id = :userId")
    suspend fun getNotesForUser(userId: String): List<NoteEntity>
}

// 2. Fail-Closed Domain Validation
data class UserRegistrationRequest(
    val email: String,
    val username: String,
    val age: Int
) {
    init {
        require(email.isNotBlank() && email.matches(EMAIL_REGEX)) { "Invalid email address" }
        require(username.length in 3..20 && username.all { it.isLetterOrDigit() || it == '_' }) {
            "Username must be 3-20 alphanumeric characters or underscores"
        }
        require(age in 18..120) { "User must be at least 18 years old" }
    }

    companion object {
        private val EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\$".toRegex()
    }
}
```

---

## 8. Common Mistakes
1.  **Denylisting instead of Allowlisting**: Trying to block specific bad characters (like `<script>` or `'`) instead of allowing only expected alphanumeric characters. Attackers easily bypass denylists using URL encoding or hex representations.
2.  **Unvalidated Android Deep Links**: Directly passing a deep link URL string into an internal database query or web view without validating scheme and host.
3.  **Client-Side Only Validation**: Assuming that because your Compose UI checks password length, the backend database is safe.

---

## 9. Verification Checklist

- [ ] Are all database queries parameterized (using Room or prepared statements)?
- [ ] Are incoming deep links and external Android Intents validated against safe allowlists?
- [ ] Do domain models enforce validation invariants upon construction (`require(...)`)?
- [ ] Is input validation enforced independently on both the client (for UX) and the backend (for security)?
- [ ] Are file uploads restricted by strict size caps and validated MIME types?
