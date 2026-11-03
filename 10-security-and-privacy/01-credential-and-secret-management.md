# 01. Credential & Secret Management: Zero Hardcoding & Hardware Keystores

---

## 1. Definition
**Credential and Secret Management** is the set of practices and tools used to store, inject, and protect digital secrets—such as API keys, OAuth tokens, private encryption keys, database passwords, and signing certificates—throughout the software lifecycle. It mandates **Zero Hardcoded Secrets** in source code or version control, relying on environment injection and secure hardware enclaves (like the Android Keystore).

---

## 2. Purpose
Hardcoding secrets into source code is the most common cause of catastrophic security incidents. Automated GitHub bots scan public and private repositories in milliseconds. Once an API key or AWS secret is leaked, attackers can spin up crypto-miners, exfiltrate user databases, or impersonate your application.

---

## 3. Why It Matters
*   **Decompilation Exposure**: Client applications (Android APKs, web JavaScript bundles) are delivered directly to the end user. Any string or constant embedded in your code can be extracted in seconds using decompilers like `jadx` or browser developer tools.
*   **Revocation Agility**: When secrets are externalized, rotating a compromised key requires only changing an environment variable or keystore entry, without rebuilding and re-distributing an application binary.
*   **Hardware Isolation**: The Android Keystore stores cryptographic keys inside secure hardware (Secure Element / TEE), making them impossible to extract even if the device is rooted.

---

## 4. When to Use It
*   **Always**: Every API secret, database password, third-party token, and private key must be managed via secure external mechanisms.
*   **Client vs. Server Distinction**: Understand that an API key placed in an Android app is *technically public*. Secrets that authorize unrestricted database or administrative access must **NEVER** touch mobile client code; they belong exclusively on a backend server.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Public Non-Sensitive Identifiers**: Truly public, non-secret configuration values (such as an application ID, a public Firebase project ID, or public UI styling strings) do not require hardware encryption. Standard `BuildConfig` or resource files are appropriate for non-sensitive public metadata.

---

## 6. Advantages & Disadvantages

| External Secrets & Keystores | Hardcoded Code Constants |
| :--- | :--- |
| **Zero Repository Leak Risk**: Secrets never enter Git history. | **Instant Git Leak**: Pushing code exposes keys to the public. |
| **Effortless Rotation**: Change keys without rebuilding apps. | **Hard to Rotate**: Must edit code, commit, re-release, and update apps. |
| **Hardware-Backed Protection**: Immune to mobile memory dumps. | **Extractable via Decompiler**: Extracted via `jadx` in 5 seconds. |

---

## 7. Practical Examples

### Bad Example: Hardcoded API Secret in Kotlin
```kotlin
// CRITICAL SECURITY VULNERABILITY!
class OpenAiClient {
    // Anyone who downloads your APK can decompile it and steal this key!
    private val API_KEY = "sk-proj-99998888777766665555444433332222"
}
```

### Good Example: Storing Secrets in `local.properties` + Android Keystore
```kotlin
// 1. In local.properties (strictly listed in .gitignore):
// MAPS_API_KEY=AIzaSyA1234567890abcdef

// 2. In app/build.gradle.kts:
// val properties = Properties().apply {
//     val localProps = project.rootProject.file("local.properties")
//     if (localProps.exists()) load(localProps.inputStream())
// }
// android {
//     defaultConfig {
//         manifestPlaceholders["MAPS_API_KEY"] = properties.getProperty("MAPS_API_KEY", "")
//     }
// }

// 3. Storing User Sensitive Tokens in Android EncryptedSharedPreferences (Hardware-backed):
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val securePreferences = EncryptedSharedPreferences.create(
    context,
    "secure_user_prefs",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

// Store auth token securely:
securePreferences.edit().putString("auth_token", jwtToken).apply()
```

---

## 8. Common Mistakes
1.  **Committing `local.properties` or `.env`**: Forgetting to add `.env` or `local.properties` to `.gitignore` before the initial Git commit.
2.  **Deleting Secrets via a New Commit**: Trying to "fix" a committed secret by deleting the line in a new commit. The secret remains fully visible in Git commit history. (You must immediately revoke and rotate the secret).
3.  **Client-Side Admin Secrets**: Putting Stripe Secret Keys, AWS Master Keys, or Firebase Admin credentials inside a mobile client app.

---

## 9. Verification Checklist

- [ ] Are `.env`, `local.properties`, and `*.keystore` files explicitly listed in `.gitignore`?
- [ ] Has git history been audited (e.g. via `git-secrets` or `trufflehog`) to ensure zero keys were committed?
- [ ] Are sensitive user tokens stored locally using `EncryptedSharedPreferences` or Android Keystore?
- [ ] Are administrative or master database secrets confined strictly to backend servers?
- [ ] Is an automated secret-scanning action enabled on the repository?
