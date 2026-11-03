# 06. Secure Logging & Telemetry: Redaction, Sanitization & PII Scrubbing

---

## 1. Definition
**Secure Logging and Telemetry** is the systematic architecture used to capture operational diagnostics and crash reports while ensuring that **Personally Identifiable Information (PII)**, user credentials, authentication tokens, and financial data are strictly redacted and never persisted into log files, system logcat, or third-party monitoring platforms (e.g. Firebase Crashlytics, Datadog, Sentry).

---

## 2. Purpose
Developers often print raw HTTP request bodies or objects to debug issues. When these logs run on production devices or are shipped to cloud crash trackers, sensitive user data (passwords, auth headers, credit card numbers, home addresses) is permanently stored in third-party log servers, creating massive compliance breaches.

---

## 3. Why It Matters
*   **Logcat Sniffing on Android**: Prior to recent Android versions (and on rooted or compromised devices today), other applications or USB debugging connections can read system logcat messages. Any unredacted secret printed to logcat is accessible to attackers.
*   **Third-Party Processor Liability**: Shipping unencrypted PII to analytics tools violates GDPR and PCI-DSS (Payment Card Industry Data Security Standard).
*   **Sanitized Crash Reporting**: Crash reports should contain stack traces and device metadata (OS version, device model, free memory), but **never** user input strings or account passwords.

---

## 4. When to Use It
*   **All Production Logging**: Ensure custom logging facades (like `Timber`) strip debug logs in release builds, or pipe sanitized breadcrumbs to Crashlytics.
*   **Network Interceptors**: Configure HTTP logging interceptors to run at `Level.NONE` or sanitize headers in release builds.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Local Test Suites**: In local JVM unit tests, printing full diagnostic object graphs is harmless because the execution happens on your private developer machine and is not shipped to production.

---

## 6. Advantages & Disadvantages

| Automated Log Sanitization | Raw Unchecked `println()` Logging |
| :--- | :--- |
| **Zero PII Exposure**: Compliance with GDPR and PCI-DSS. | **Severe Compliance Violations**: Fines and data leaks. |
| **Clean Crashlytics Reports**: Fast triage without legal panic. | **Emergency Purges**: Must purge entire log systems when secrets leak. |
| **Stripped Release Builds**: Zero battery drain and zero disk waste. | **Logcat Bloat**: Slows down app and floods device storage. |

---

## 7. Practical Examples

### Custom Timber Tree Redacting PII & Stripping Debug Logs
```kotlin
// In Application.kt:
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            // Production tree: Only logs WARN and ERROR, scrubbed of PII
            Timber.plant(ProductionCrashlyticsTree())
        }
    }
}

class ProductionCrashlyticsTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        if (priority < Log.WARN) return // Ignore DEBUG and INFO in production

        // Scrub sensitive patterns (emails, tokens, passwords)
        val sanitizedMessage = scrubSensitiveData(message)

        FirebaseCrashlytics.getInstance().log(sanitizedMessage)
        if (t != null) {
            FirebaseCrashlytics.getInstance().recordException(t)
        }
    }

    private fun scrubSensitiveData(text: String): String {
        return text
            .replace(Regex("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}"), "[EMAIL_REDACTED]")
            .replace(Regex("Bearer\\s+[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_=]+\\.?[A-Za-z0-9-_.+/=]*"), "Bearer [TOKEN_REDACTED]")
    }
}
```

---

## 8. Common Mistakes
1.  **Logging Full HTTP Headers**: Leaving `HttpLoggingInterceptor.Level.BODY` or `Level.HEADERS` active in release builds, dumping `Authorization: Bearer <token>` into logcat.
2.  **Printing `user.toString()`**: Relying on default Kotlin `data class User(val password: String, ...)` generated `toString()`, which automatically prints passwords when logged.
3.  **Logging Credit Card Numbers**: Violating PCI-DSS by logging full 16-digit card numbers or CVV codes.

---

## 9. Verification Checklist

- [ ] Are raw `println()` and `System.out.println()` calls banned by linter rules?
- [ ] Are debug log outputs stripped or disabled in production release builds?
- [ ] Do network logging interceptors sanitize or omit `Authorization` and cookie headers?
- [ ] Are sensitive fields (passwords, tokens, emails, phone numbers) masked before logging?
- [ ] Are crash reports verified to contain zero PII or user-entered text?
