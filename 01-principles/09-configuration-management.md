# 09. Configuration Management & Environment Parity

---

## 1. Definition
**Configuration Management** is the practice of externalizing runtime variables, API endpoints, feature flags, and environment settings away from application source code. It follows the **12-Factor App methodology (Config)**: code remains strictly identical across environments (local, dev, staging, production), while configuration is injected from outside.

---

## 2. Purpose
Hardcoding URLs, timeout limits, and feature toggles inside source code creates dangerous build variants, forces code recompilations just to change a server address, and leads to production disasters when staging credentials accidentally leak into production builds.

---

## 3. Why It Matters
*   **Security**: Prevents production credentials or test flags from being accidentally bundled into client applications.
*   **Environment Agility**: Switching an Android app from connecting to a local emulator backend (`10.0.2.2:8080`) to a cloud staging API requires only changing a build flavor or configuration file, with zero source code edits.
*   **Feature Toggles**: Allows safely enabling or disabling in-development features without redeploying code.

---

## 4. When to Use It
*   **API Base URLs**: Any backend endpoint must be provided via `BuildConfig` fields, `local.properties`, or environment configs.
*   **Timeout & Cache Limits**: Network timeouts, database page sizes, and cache expiration durations must be configurable constants.
*   **Feature Flags**: Guard incomplete or experimental features behind boolean configuration flags.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Trivial Invariant Constants**: Do not extract standard physical or mathematical constants (e.g. `SECONDS_PER_MINUTE = 60`) into external configuration files. Keep invariant constants in simple local code companion objects.
*   **Over-Parameterized Configurations**: Do not make every UI button color and font size dynamically configurable via a remote server unless you are genuinely building a server-driven UI engine.

---

## 6. Advantages & Disadvantages

| Externalized Configuration | Hardcoded Constants |
| :--- | :--- |
| **Instant Switching**: Change environments without recompiling code. | **Rigid Builds**: Recompilation and Git commits required for every URL change. |
| **Zero Secret Leakage**: Private keys stay out of public repos. | **High Risk**: Staging passwords committed directly to Git. |
| **Cleaner Testing**: Trivial to inject test URLs and mock servers. | **Testing Headaches**: Mocks must fight hardcoded endpoints. |

---

## 7. Practical Examples

### Bad Example: Hardcoded Environment URLs
```kotlin
// BAD: Hardcoded URLs and secrets directly in source code
class RetrofitClient {
    // Problem: Connecting to staging requires modifying this file and risking committing it!
    private val BASE_URL = "https://api.myproductionserver.com/v1/"
    private val API_KEY = "prod_secret_key_12345" // CRITICAL SECURITY LEAK

    val api: ApiService = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .build()
        .create(ApiService::class.java)
}
```

### Good Example: Android BuildConfig & Gradle Properties
```kotlin
// 1. In root local.properties (gitignored):
// API_BASE_URL=https://staging.api.example.com/v1/
// API_KEY=staging_secret_key_9999

// 2. In app/build.gradle.kts:
// android {
//     buildTypes {
//         debug {
//             buildConfigField("String", "BASE_URL", "\"https://dev.api.example.com/\"")
//         }
//         release {
//             buildConfigField("String", "BASE_URL", "\"https://api.example.com/\"")
//         }
//     }
// }

// 3. In Kotlin source code:
data class AppConfig(
    val baseUrl: String,
    val timeoutSeconds: Long = 30L
)

class NetworkModule(private val config: AppConfig) {
    fun provideRetrofit(): Retrofit {
        return Retrofit.Builder()
            .baseUrl(config.baseUrl)
            .client(
                OkHttpClient.Builder()
                    .connectTimeout(config.timeoutSeconds, TimeUnit.SECONDS)
                    .build()
            )
            .build()
    }
}
```

---

## 8. Common Mistakes
1.  **Committing `local.properties` or `.env` to Git**: Pushing sensitive environment files containing developer API tokens into public or shared version control.
2.  **Configuring Business Logic**: Putting algorithmic rules or domain decisions in configuration files instead of code. Configuration is for *environmental parameters*, not business policies.
3.  **Missing Defaults**: Crashing abruptly if an optional configuration property is missing from the environment. Always provide sane fallback values for non-critical settings.

---

## 9. Verification Checklist

- [ ] Are all base URLs and environment endpoints externalized from source code?
- [ ] Is `local.properties` (or `.env`) listed in `.gitignore`?
- [ ] Does the application support debug vs. release configurations cleanly?
- [ ] Are default timeouts and operational thresholds clearly documented?
- [ ] Is sensitive configuration injected securely at build or runtime without hardcoding?
