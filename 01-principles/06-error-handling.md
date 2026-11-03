# 06. Robust Error Handling: Fail-Fast, Typed Results & Boundary Isolation

---

## 1. Definition
**Error Handling** is the disciplined strategy a system uses to anticipate, detect, contain, and recover from exceptional runtime conditions (network dropouts, corrupted files, invalid user inputs, hardware constraints). Robust error handling relies on **Fail-Fast** design (failing immediately when an illegal state is detected) and **Typed Results** (e.g. `Result<T>` or sealed interfaces) rather than unchecked exception bubbling.

---

## 2. Purpose
Uncontrolled errors crash applications, corrupt user databases, and expose stack traces to attackers. The purpose of systematic error handling is to ensure that errors are either **safely handled and recovered from**, or **cleanly reported to the user with actionable feedback**, while preventing invalid state from persisting.

---

## 3. Why It Matters
*   **Silent Failures are Disasters**: Catching an exception with an empty block (`catch (e: Exception) {}`) swallows errors. The app appears to work, but data is secretly lost or left in an inconsistent state.
*   **Compile-Time Guarantees**: Using typed result patterns (`Result<T>` or sealed interfaces) forces the caller to explicitly handle both Success and Failure cases before accessing the data.
*   **User Trust**: A graceful error dialog stating "Network connection lost. Tap to retry" preserves user trust, whereas an unhandled crash destroys it.

---

## 4. When to Use It
*   **System Boundaries**: Always wrap network calls, disk I/O, JSON parsing, and hardware sensors in structured error-handling constructs.
*   **Domain Validation**: Use `require()` and `check()` preconditions to validate assumptions immediately upon receiving data.
*   **Domain Models**: Represent business outcomes (e.g. `PaymentResult.Success`, `PaymentResult.InsufficientFunds`, `PaymentResult.CardExpired`) using sealed hierarchies.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Exceptions for Control Flow**: Never use `try/catch` blocks to control normal program flow (e.g., catching `IndexOutOfBoundsException` to terminate a loop instead of checking list size). Exceptions are computationally expensive and obscure program intent.
*   **Catching `Throwable` or `Error`**: Never catch `OutOfMemoryError` or general `Throwable` unless you are writing a low-level crash reporting framework. Severe system errors cannot be safely recovered from.

---

## 6. Advantages & Disadvantages

| Typed Results (`Result<T>` / Sealed) | Blind Exceptions (`throw` / `catch`) |
| :--- | :--- |
| **Exhaustive Handling**: Compiler forces handling of errors. | **Invisible Failures**: Compiler gives no warning of uncaught exceptions. |
| **Clear API Contract**: Function signature declares failure possibility. | **Hidden Surprises**: Any function can throw without warning. |
| **High Performance**: No stack-trace unwinding overhead. | **Performance Cost**: Generating stack traces is slow. |
| **Slight Boilerplate**: Requires unwrapping results (`when` / `fold`). | **Easy to Throw**: Fast to write initially, but fragile to maintain. |

---

## 7. Practical Examples

### Bad Example: Swallowed Exceptions & Magic Nulls
```kotlin
// BAD: Swallows exception, returns null, hides error cause
class ProductRepository {
    fun fetchProduct(id: String): Product? {
        return try {
            val response = api.getProduct(id).execute()
            response.body()
        } catch (e: Exception) {
            // SILENT DISASTER: Swallows network, serialization, and auth errors!
            null
        }
    }
}
```

### Good Example: Sealed Error Hierarchy & Typed Result
```kotlin
// GOOD: Explicit, exhaustive domain results with clear error details
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    sealed interface Failure : DataResult<Nothing> {
        data class NetworkError(val message: String, val cause: Throwable? = null) : Failure
        data class NotFound(val id: String) : Failure
        data class ServerError(val code: Int, val message: String) : Failure
        data class Unknown(val throwable: Throwable) : Failure
    }
}

class ProductRepository(private val api: ProductApi) {
    suspend fun getProduct(id: String): DataResult<Product> {
        return try {
            val response = api.getProduct(id)
            if (response.isSuccessful) {
                val product = response.body()
                if (product != null) {
                    DataResult.Success(product)
                } else {
                    DataResult.Failure.NotFound(id)
                }
            } else {
                DataResult.Failure.ServerError(response.code(), response.message())
            }
        } catch (e: IOException) {
            DataResult.Failure.NetworkError("Check internet connection", e)
        } catch (e: Exception) {
            DataResult.Failure.Unknown(e)
        }
    }
}

// In the UI or ViewModel:
fun displayProduct(result: DataResult<Product>) {
    when (result) {
        is DataResult.Success -> renderUi(result.data)
        is DataResult.Failure.NetworkError -> showRetrySnackbar(result.message)
        is DataResult.Failure.NotFound -> showEmptyState("Product not found")
        is DataResult.Failure.ServerError -> showErrorBanner("Server error: ${result.code}")
        is DataResult.Failure.Unknown -> showErrorBanner("Unexpected error occurred")
    }
}
```

---

## 8. Common Mistakes
1.  **Empty Catch Blocks**: Catching an error and doing nothing: `catch (e: Exception) {}`.
2.  **Catching the Wrong Exception**: Catching general `Exception` when you only intended to handle `SocketTimeoutException`, inadvertently masking `NullPointerException` or programmer bugs.
3.  **Leaking Stack Traces to Users**: Printing raw stack traces or database error strings directly onto the user's mobile screen instead of sanitized, friendly messages.

---

## 9. Verification Checklist

- [ ] Are empty `catch` blocks strictly forbidden?
- [ ] Are boundary functions (network, database, file system) returning typed results (`Result<T>` or sealed classes)?
- [ ] Are preconditions validated using `require()` (argument check) or `check()` (state check)?
- [ ] Are user-facing error messages clean, helpful, and free of technical stack traces?
- [ ] Does the UI handle both success and error states explicitly?
