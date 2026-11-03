# 10. Robust API Communication: Networking, Serialization & Resilience

---

## 1. Definition
**API Communication** refers to the architecture, protocols, serialization engines, and error resilience patterns used by a client application to exchange data with external backend web services. In modern Android, this is implemented using **Retrofit** or **Ktor Client**, backed by **OkHttp** and **Kotlinx.serialization**.

---

## 2. Purpose
Mobile networks are inherently unreliable. Phones transition between 5G, Wi-Fi, airplane mode, tunnels, and captive portals. The purpose of disciplined API architecture is to guarantee that network communication is **resilient to transient dropouts, secure against eavesdropping, and fail-safe against malformed JSON payloads**.

---

## 3. Why It Matters
*   **Crash Prevention via Strict Serialization**: Using modern `kotlinx.serialization` with non-nullable types ensures that if the backend sends an unexpected null or missing field, it is caught at the network boundary rather than causing random `NullPointerException` crashes deep in your UI code.
*   **Battery & Data Efficiency**: Configuring proper HTTP caching headers and gzip compression minimizes data usage and battery consumption.
*   **Security (TLS & Cert Pinning)**: Proper HTTPS enforcement and certificate management prevent Man-in-the-Middle (MITM) attacks on public Wi-Fi networks.

---

## 4. When to Use It
*   **All External Network Traffic**: Every HTTP request must go through a centralized network client configured with timeouts, logging interceptors, and auth token injectors.
*   **Exponential Backoff for Retries**: Use retry policies only on idempotent requests (GET, PUT) when encountering transient $5xx$ server errors or network disconnects.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Blind Infinite Retries**: Never retry failed requests infinitely. Limit retries to 3 attempts with exponential backoff (e.g. 1s, 2s, 4s). Never automatically retry non-idempotent operations like `POST /payments/charge` without idempotency keys.
*   **Direct Network Calls in ViewModels**: Never instantiate Retrofit directly inside a ViewModel or Activity. Network communication belongs strictly behind a Repository interface.

---

## 6. Advantages & Disadvantages

| Structured Retrofit / OkHttp Pipeline | Ad-hoc `HttpURLConnection` / Raw Requests |
| :--- | :--- |
| **Automatic Type Serialization**: JSON parsed directly to data classes. | **Manual String Parsing**: Brittle, error-prone manual JSON extraction. |
| **Centralized Auth & Logging**: Interceptors handle tokens once. | **Scattered Token Logic**: Every call must manually attach auth headers. |
| **Configurable Timeouts & Retries**: Robust failure recovery. | **Hangs & Leaks**: Requests hang indefinitely on spotty networks. |

---

## 7. Practical Examples

### Modern Retrofit & OkHttp Configuration
```kotlin
// 1. DATA TRANSFER OBJECT (DTO)
@Serializable
data class UserDto(
    val id: String,
    val username: String,
    val email: String,
    val avatarUrl: String? = null // Explicitly nullable for optional fields
)

// 2. RETROFIT API INTERFACE
interface UserApiService {
    @GET("v1/users/{id}")
    suspend fun getUserProfile(@Path("id") userId: String): Response<UserDto>
}

// 3. OKHTTP CLIENT CONFIGURATION
object NetworkFactory {
    fun createOkHttpClient(tokenProvider: () -> String?): OkHttpClient {
        return OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .writeTimeout(15, TimeUnit.SECONDS)
            // Auth Interceptor: Automatically attaches Bearer token
            .addInterceptor { chain ->
                val requestBuilder = chain.request().newBuilder()
                tokenProvider()?.let { token ->
                    requestBuilder.addHeader("Authorization", "Bearer $token")
                }
                chain.proceed(requestBuilder.build())
            }
            // Logging Interceptor: Enabled only in Debug builds
            .apply {
                if (BuildConfig.DEBUG) {
                    addInterceptor(HttpLoggingInterceptor().apply {
                        level = HttpLoggingInterceptor.Level.BODY
                    })
                }
            }
            .build()
    }
}
```

---

## 8. Common Mistakes
1.  **Hardcoded Base URLs**: Embedding backend URLs directly in interface annotations instead of injecting them via configuration.
2.  **Missing Network Timeouts**: Failing to configure explicit connect/read/write timeouts on OkHttp, causing the app to hang indefinitely on dead cellular connections.
3.  **Assuming 200 OK Always Means Success**: Parsing response bodies without checking `response.isSuccessful` or handling HTTP $401, 403, 404, 500$ status codes properly.

---

## 9. Verification Checklist

- [ ] Are explicit connect, read, and write timeouts configured (typically 15–30 seconds)?
- [ ] Is authentication handled centrally via an OkHttp interceptor rather than manually on each request?
- [ ] Are HTTP logging interceptors completely stripped or restricted to `Level.NONE` in release builds?
- [ ] Are JSON DTOs defined with strict nullability to avoid runtime serialization crashes?
- [ ] Are network calls isolated behind repository interfaces on `Dispatchers.IO`?
