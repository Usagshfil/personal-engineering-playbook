# 01. Credential & Secret Management: Zero Hardcoding & Secure Enclaves

---

## 1. Definition
**Credential and Secret Management** is the set of practices and tools used to store, inject, and protect digital secrets—such as API keys, OAuth tokens, private encryption keys, database passwords, and signing certificates—throughout the software lifecycle. It mandates **Zero Hardcoded Secrets** in source code or version control, relying on environment injection, secure hardware key stores (TEE / Secure Element / StrongBox when available), and dedicated secret management infrastructure.

---

## 2. Purpose
Hardcoding secrets into source code is among the most prevalent and damaging causes of catastrophic security incidents. Automated scrapers scan public repositories in milliseconds. Once an administrative API key or database credential is leaked, attackers can spin up unauthorized compute resources, exfiltrate user databases, or compromise production systems.

---

## 3. Why It Matters
*   **Decompilation Exposure (OWASP MASVS-STORAGE / NIST SP 800-63B)**: Client applications (Android APKs, iOS IPAs, Web JavaScript bundles) are distributed directly to end users. Any constant embedded in binary or bytecode can be extracted in seconds using decompilers like `jadx` or browser developer tools. No code obfuscator can make client-side secrets truly private.
*   **Revocation Agility**: When secrets are externalized, rotating a compromised key requires updating an environment variable, secret manager, or keystore entry, without rebuilding and re-distributing an application binary to thousands of end users.
*   **Hardware Key Isolation & Boundaries**: The Android Keystore system allows apps to generate and store cryptographic keys that are protected against userspace memory extraction. On modern devices equipped with a Trusted Execution Environment (TEE) or StrongBox Keymaster, the private key material never enters the main operating system memory. However, hardware backing is device-dependent (budget devices or emulators may fall back to software keystore implementations). Furthermore, hardware protection safeguards the key from extraction, but cannot prevent unauthorized cryptographic operations if the host OS is compromised while authenticated.

---

## 4. When to Use It
*   **Always**: Every API secret, database password, third-party token, and private key must be managed via secure external mechanisms.
*   **Client vs. Server Secret Distinction (OWASP MASVS)**:
    - *Client Keys*: Public third-party API keys (e.g., Google Maps API key) placed in mobile/web clients are **technically public**. They must be restricted via cloud provider consoles (restricted by Android package name + SHA-1 signing certificate fingerprint, or web HTTP referrer).
    - *Server Secrets*: Secrets that authorize administrative access, database writes, Stripe charges, or LLM tokens (e.g. OpenAI secret keys) must **NEVER** touch client code; they belong exclusively on a backend server behind authenticated API endpoints.
*   **Local Development vs. Production Secret Management**:
    - *Local Development*: Secrets reside in local workstation files (`local.properties`, `.env.local`) strictly ignored by Git (`.gitignore`).
    - *Production & CI/CD*: Secrets must be managed via dedicated Secret Managers (e.g., HashiCorp Vault, AWS Secrets Manager, Google Cloud Secret Manager) or KMS with audited role-based access control (RBAC).

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Public Non-Sensitive Identifiers**: Truly public, non-secret configuration values (such as an application ID, a public Firebase project ID, or public UI styling strings) do not require hardware encryption. Standard `BuildConfig` or resource files are appropriate for non-sensitive public metadata.

---

## 6. Advantages & Disadvantages

| External Secrets & Hardware Enclaves | Hardcoded Code Constants |
| :--- | :--- |
| **Zero Repository Leak Risk**: Secrets never enter Git history. | **Instant Git Leak**: Pushing code exposes keys to the public. |
| **Effortless Rotation**: Change keys without rebuilding apps. | **Hard to Rotate**: Must edit code, commit, re-release, and update apps. |
| **Hardware Key Isolation (TEE/StrongBox)**: Private key bytes protected from userspace extraction. | **Extractable via Decompiler**: Extracted via `jadx` in 5 seconds. |
| **Console-Restricted Scope**: Compromised client keys limited by origin/SHA-1. | **Unrestricted Blast Radius**: Leaked server keys grant full root access. |

---

## 7. Practical Examples

### Bad Example: Hardcoded API Secret in Kotlin
```kotlin
// CRITICAL SECURITY VULNERABILITY!
class OpenAiClient {
    // Anyone who downloads your APK can decompile it and steal this administrative key!
    private val API_KEY = "sk-proj-99998888777766665555444433332222"
}
```

### Good Example: Development Injection (`local.properties`) & Keystore Token Storage
```kotlin
// 1. In local.properties (strictly listed in .gitignore) for local developer builds:
// MAPS_API_KEY=AIzaSyA1234567890abcdef
// (Note: Maps API Key must also be restricted by SHA-1 fingerprint in Google Cloud Console)

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

// 3. Storing User Sensitive Tokens in Android EncryptedSharedPreferences (Backed by Keystore):
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .setRequestStrongBoxed(true) // Requests StrongBox hardware security if available
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
4.  **Assuming Keystore is Always Hardware-Backed**: Failing to recognize that older devices or budget chipsets may lack StrongBox or TEE, resulting in software-backed keystore operations.

---

## 9. Verification Checklist (OWASP MASVS-STORAGE / ASVS V2)

- [ ] Are `.env`, `local.properties`, and `*.keystore` files explicitly listed in `.gitignore`?
- [ ] Has git history been audited (e.g. via `git-secrets` or `trufflehog`) to ensure zero keys were committed?
- [ ] Are sensitive user tokens stored locally using `EncryptedSharedPreferences` or Android Keystore?
- [ ] Are administrative or master database secrets confined strictly to backend servers?
- [ ] Are client-side third-party API keys restricted by package name, SHA-1 certificate fingerprint, or HTTP referrer?
- [ ] Is an automated secret-scanning action enabled on the repository?
