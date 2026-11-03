# 06. Android Network Communication: Retrofit, OkHttp & Secure APIs

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Android & Kotlin Development  
> **Target Version**: Retrofit 2.11+, OkHttp 4.12+, Kotlinx Serialization 1.6+

---

## 1. Definition & Core Concept

**Modern Android Network Architecture** couples **Retrofit** (a type-safe HTTP client abstraction) with **OkHttp** (the underlying HTTP transport engine) and **Kotlinx Serialization** (a multiplatform, reflection-free JSON serializer).

Network communication transforms remote RESTful contracts into asynchronous Kotlin `suspend` functions, utilizing interceptors for cross-cutting concerns (authentication, token refresh, logging, telemetry, and caching).

```
+-------------------------------------------------------------------------+
| Network Communication Stack                                             |
|                                                                         |
| Repository (Data Layer)                                                 |
|    |                                                                    |
|    v                                                                    |
| Retrofit API Interface (suspend fun getProfile(): NetworkResponse<User>)  |
|    |                                                                    |
|    v                                                                    |
| Kotlinx Serialization Converter (Strict JSON Deserialization)           |
|    |                                                                    |
|    v                                                                    |
| OkHttp Client                                                           |
|    |---> Auth Interceptor (Injects Bearer Token)                        |
|    |---> OkHttp Authenticator (Thread-Safe 401 Token Refresh)           |
|    |---> Redacting Logging Interceptor (Scrubs PII / Secrets)           |
|    `---> TLS / Certificate Pinner                                       |
|    |                                                                    |
|    v                                                                    |
| Remote API Server (HTTPS / TLS 1.3)                                     |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to guarantee resilient, secure, and performant HTTP communication. It mandates non-blocking asynchronous execution, secure credential handling, thread-safe token refresh mechanisms, PII log redaction, and reliable unit testing using `MockWebServer`.

---

## 3. Why It Matters

*   **Security & Privacy by Default (Tier 1 Rule 7)**: Logging sensitive authentication tokens, session cookies, or PII exposes credentials in logcat and crash reporting tools. Interceptors must scrub sensitive headers.
*   **Token Refresh Race Conditions**: When multiple API calls fail simultaneously with HTTP 401 Unauthorized, naive refresh logic fires duplicate token refresh requests, causing race conditions and session invalidation.
*   **Minification & ProGuard Safety**: Using reflection-based JSON parsers without explicit annotations leads to runtime crashes in release builds when R8 obfuscates property names. Kotlinx Serialization guarantees type-safe field mapping via `@SerialName`.
*   **Resilience & Offline Caching**: Disciplined HTTP cache headers (`Cache-Control`) reduce mobile battery and cellular data consumption.

---

## 4. When to Use It

*   **RESTful API Endpoints**: Define all HTTP endpoints using Retrofit interface annotations (`@GET`, `@POST`, `@PUT`, `@DELETE`) with `suspend fun`.
*   **JSON Serialization**: Use `kotlinx.serialization.json.Json` with `ignoreUnknownKeys = true` and `explicitNulls = false` for flexible forward compatibility.
*   **Authentication & Token Refresh**: Implement an OkHttp `Authenticator` for transparent HTTP 401 re-authentication and token renewal.
*   **Logging in Non-Production**: Restrict detailed network logging (`HttpLoggingInterceptor.Level.BODY`) strictly to `debug` builds, and always sanitize `Authorization` and `Cookie` headers.
*   **Integration Testing**: Use `MockWebServer` to test error responses (400, 401, 500, network timeouts) deterministically without hitting live endpoints.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Synchronous Execution**: **NEVER** call `.execute()` on a Retrofit `Call<T>` on the main thread. Always define Retrofit methods as `suspend fun`.
*   **Logging in Production**: **NEVER** attach a verbose body logger to OkHttp in production release builds. This degrades performance, consumes CPU cycles, and risks leaking user data.
*   **Hardcoded API Keys in Code**: **NEVER** commit API secrets, bearer tokens, or sensitive base URLs into source code. Inject them via `local.properties` and Gradle `buildConfigField`.
*   **Bypassing TLS Verification**: **NEVER** use trust-all `X509TrustManager` or disable hostname verification, even in internal testing environments.

---

## 6. Advantages & Disadvantages

| Feature | Retrofit + OkHttp + Kotlinx | HttpURLConnection / Custom Client |
| :--- | :--- | :--- |
| **Type Safety** | Complete compile-time type verification. | Manual JSON parsing and raw string manipulation. |
| **Connection Pooling** | Transparent HTTP/2 and HTTP/3 multiplexing. | Manual connection handling and socket management. |
| **Interceptors** | Modular middleware chain for auth, cache, and telemetry. | Tangled cross-cutting code dispersed across calls. |
| **Memory Footprint** | Extremely optimized zero-reflection serialization. | High memory overhead with reflection-based parsers. |

---

## 7. Practical Examples

### Bad Example: Plaintext Logging, Hardcoded Secrets & Unsafe Refresh Logic

```kotlin
// BAD: Hardcoded secrets, unredacted body logging in production, unhandled 401 race conditions
class BadNetworkClient {
    // HAZARD: Hardcoded API key committed to source code! (Tier 1 Violation)
    private val apiKey = "secret_sk_live_1234567890abcdef"

    fun createClient(): OkHttpClient {
        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY // HAZARD: Logs passwords, tokens, and PII in production!
        }

        return OkHttpClient.Builder()
            .addInterceptor(logging)
            .addInterceptor { chain ->
                val req = chain.request().newBuilder()
                    .addHeader("Authorization", "Bearer $apiKey")
                    .build()
                chain.proceed(req)
            }
            .build()
    }
}
```

### Good Example: Thread-Safe Authenticator, Header Redaction & Kotlinx Serialization

```kotlin
// GOOD: Safe serialization, sanitized logging, synchronized token refresh
@Serializable
data class UserProfileDto(
    @SerialName("user_id") val userId: String,
    @SerialName("email") val email: String,
    @SerialName("display_name") val displayName: String? = null
)

interface UserApiService {
    @GET("v1/users/{id}")
    suspend fun getUserProfile(
        @Path("id") userId: String
    ): UserProfileDto
}

// Token Provider managing atomic token renewal
class TokenManager @Inject constructor(
    private val authLocalStore: AuthLocalStore
) {
    private val mutex = Mutex()

    suspend fun getAccessToken(): String? = authLocalStore.getAccessToken()

    suspend fun refreshTokens(): String? = mutex.withLock {
        // Double-check if another thread already refreshed the token
        val currentToken = authLocalStore.getAccessToken()
        // Perform atomic network refresh call and persist new token
        val newToken = performTokenRefreshNetworkCall()
        authLocalStore.saveAccessToken(newToken)
        newToken
    }

    private suspend fun performTokenRefreshNetworkCall(): String {
        // Network call to auth server
        return "new_access_token"
    }
}

// Thread-safe OkHttp Authenticator
class TokenAuthenticator @Inject constructor(
    private val tokenManager: TokenManager
) : Authenticator {
    override fun authenticate(route: Route?, response: Response): Request? {
        // Prevent infinite loops if refresh fails
        if (responseCount(response) >= 3) return null

        val newAccessToken = runBlocking {
            tokenManager.refreshTokens()
        } ?: return null

        return response.request.newBuilder()
            .header("Authorization", "Bearer $newAccessToken")
            .build()
    }

    private fun responseCount(response: Response): Int {
        var count = 1
        var prior = response.priorResponse
        while (prior != null) {
            count++
            prior = prior.priorResponse
        }
        return count
    }
}

// Factory constructing secure OkHttpClient
object NetworkFactory {
    fun createOkHttpClient(
        tokenAuthenticator: TokenAuthenticator,
        tokenManager: TokenManager,
        isDebug: Boolean
    ): OkHttpClient {
        val builder = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .authenticator(tokenAuthenticator)
            .addInterceptor { chain ->
                val token = runBlocking { tokenManager.getAccessToken() }
                val request = chain.request().newBuilder()
                if (token != null) {
                    request.header("Authorization", "Bearer $token")
                }
                chain.proceed(request.build())
            }

        if (isDebug) {
            val loggingInterceptor = HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.HEADERS
                redactHeader("Authorization") // SCRUB sensitive auth token from logs
                redactHeader("Cookie")        // SCRUB sensitive session cookies
            }
            builder.addInterceptor(loggingInterceptor)
        }

        return builder.build()
    }

    fun createRetrofit(okHttpClient: OkHttpClient, baseUrl: String): Retrofit {
        val json = Json {
            ignoreUnknownKeys = true
            coerceInputValues = true
            encodeDefaults = true
        }

        return Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
    }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Omitting `@SerialName` on DTO Properties**:
    *   *Problem*: If `@SerialName("user_id")` is omitted and ProGuard/R8 minification is active, property `userId` is obfuscated to `a`, causing JSON deserialization to fail at runtime in release builds.
    *   *Remedy*: Always annotate DTO fields with `@SerialName` or configure `@Keep` / `@Serializable` rules properly.
2.  **Infinite 401 Loops in Authenticator**:
    *   *Problem*: If an expired refresh token causes the refresh endpoint itself to return 401, a naive `Authenticator` loops endlessly until the app crashes with an `OutOfMemoryError`.
    *   *Remedy*: Track prior response count (`responseCount(response) >= 3`) and abort further retry attempts.
3.  **Leaking Sensitive Data in Release Logs**:
    *   *Problem*: Attaching `HttpLoggingInterceptor` without checking `BuildConfig.DEBUG` leaks sensitive request bodies and authentication headers into public logcat.
    *   *Remedy*: Only attach logging interceptors in debug builds, and always call `.redactHeader("Authorization")`.

---

## 9. Verification Checklist

- [ ] Are all network requests defined as `suspend fun` without blocking calls?
- [ ] Are all API secrets and base URLs passed via `BuildConfig` or environment properties rather than hardcoded?
- [ ] Is `HttpLoggingInterceptor` disabled or set to `NONE` in release builds?
- [ ] Are sensitive headers (`Authorization`, `Cookie`) redacted in logging interceptors?
- [ ] Are all DTO classes annotated with `@Serializable` and explicit `@SerialName` tags?
- [ ] Is the 401 token refresh mechanism thread-safe and protected against infinite retry loops?
- [ ] Are API client behaviors verified with `MockWebServer` unit tests for error scenarios (timeouts, 401s, 500s)?
