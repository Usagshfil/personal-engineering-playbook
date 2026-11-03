# 02. Authentication & Authorization: Token Lifecycles & Least Privilege

---

## 1. Definition
**Authentication (AuthN)** is the process of verifying *who a user or client is* (e.g. via passwords, biometric passkeys, or OAuth). **Authorization (AuthZ)** is the process of verifying *what permissions that authenticated identity has* (e.g. Role-Based Access Control - RBAC). Standard mobile/cloud security relies on short-lived **Access Tokens** and revocable **Refresh Tokens**.

---

## 2. Purpose
Flawed authentication allows unauthorized attackers to impersonate legitimate users, while broken authorization allows a regular user to modify another user's private data (Insecure Direct Object Reference - IDOR) or perform administrator actions.

---

## 3. Why It Matters
*   **The Principle of Least Privilege**: Every component, user, and background worker must only possess the bare minimum permissions necessary to complete its specific task.
*   **Short-Lived Token Security**: If an access token expires in 15 minutes, an intercepted token is only dangerous for a tiny window. The refresh token allows obtaining a new access token seamlessly, and can be immediately revoked on the server if the phone is reported stolen.
*   **Server-Side AuthZ Verification**: Client-side UI checks (e.g., hiding a "Delete" button in the Android app) are purely cosmetic. **The server must verify authorization on every single API request.**

---

## 4. When to Use It
*   **Any Application with User Accounts**: Implement standard OAuth 2.0 / OpenID Connect (OIDC) or JWT token workflows.
*   **Biometric Authentication**: Use the Android `BiometricPrompt` API to gate access to sensitive screens (financial transactions, secure notes).

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Offline Standalone Utilities**: A local offline calculator, unit converter, or local-only markdown reader should not require user sign-in or authentication. Forcing user accounts on simple tools creates unnecessary user friction.

---

## 6. Advantages & Disadvantages

| Token-Based Auth (JWT + Refresh) | Session Cookies / Permanent Keys |
| :--- | :--- |
| **Stateless Scalability**: Server verifies JWT signature without DB lookup. | **Server Session State**: Requires centralized session store (Redis). |
| **Mobile Native**: Works naturally across mobile apps and APIs. | **Cookie Quirkiness**: Mobile cookie managers are fragile. |
| **Instant Revocation**: Refresh tokens can be blacklisted on server. | **Permanent Leaks**: Static permanent keys cannot be safely scoped. |

---

## 7. Practical Examples

### OkHttp Token Authenticator for Auto-Refreshing Tokens
```kotlin
class TokenAuthenticator(
    private val tokenStorage: TokenStorage,
    private val authApi: AuthApiService
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        // 1. Guard: If we already retried and failed, do not loop infinitely
        if (responseCount(response) >= 2) return null

        // 2. Synchronously refresh the access token using the stored refresh token
        val refreshToken = tokenStorage.getRefreshToken() ?: return null
        val refreshResult = authApi.refreshAccessToken(refreshToken).execute()

        if (refreshResult.isSuccessful && refreshResult.body() != null) {
            val newTokens = refreshResult.body()!!
            tokenStorage.saveTokens(newTokens.accessToken, newTokens.refreshToken)

            // 3. Retry the original request with the new access token
            return response.request.newBuilder()
                .header("Authorization", "Bearer ${newTokens.accessToken}")
                .build()
        }

        // 4. If refresh token is expired or revoked, trigger logout
        tokenStorage.clearTokens()
        return null
    }

    private fun responseCount(response: Response): Int {
        var result = 1
        var prior = response.priorResponse
        while (prior != null) {
            result++
            prior = prior.priorResponse
        }
        return result
    }
}
```

---

## 8. Common Mistakes
1.  **Client-Side Only Authorization**: Hiding a button in Compose (`if (user.isAdmin) AdminButton()`) but forgetting to verify the user's role in the backend API endpoint (`DELETE /api/users/{id}`). Anyone can call the endpoint using curl.
2.  **Permanent Tokens**: Issuing access tokens that never expire, making stolen tokens dangerous indefinitely.
3.  **Storing Tokens in Plain Text**: Saving JWT tokens in unencrypted `SharedPreferences` on an Android device where they can be extracted on rooted phones or via backup dumps.

---

## 9. Verification Checklist

- [ ] Are access tokens short-lived ($\le 15–60$ minutes) and refreshed via secure refresh tokens?
- [ ] Is token refresh failure handled gracefully by redirecting the user to login?
- [ ] Are tokens stored in encrypted local storage (`EncryptedSharedPreferences` / Android Keystore)?
- [ ] Does the backend enforce authorization on every request, regardless of client UI state?
- [ ] Is biometric authentication integrated using the official Android `BiometricPrompt` API?
