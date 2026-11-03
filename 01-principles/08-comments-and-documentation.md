# 08. Comments and Documentation: Explaining Why, Not What

---

## 1. Definition
**Code Documentation** encompasses inline comments, KDoc/Javadoc method contracts, architecture decision records (TDRs/ADRs), and project README files. The golden rule of commenting is: **Code explains WHAT and HOW; comments explain WHY.**

---

## 2. Purpose
Code cannot easily express intent, business rationale, historical bugs, or external hardware constraints. The purpose of comments is to capture the non-obvious **context, business rules, and trade-offs** that motivated a specific technical decision, preventing other developers (or AI agents) from inadvertently breaking it.

---

## 3. Why It Matters
*   **Preventing "Fixing" Intentional Workarounds**: Without a comment explaining that a 200ms delay is required due to an OEM Bluetooth chip timing bug, a well-meaning developer will delete the delay and reintroduce a catastrophic hardware disconnect bug.
*   **Obsolete Comments are Worse than No Comments**: A comment that says `// Returns active users sorted by age` when the code was changed to return `inactive users sorted by date` actively deceives the reader.
*   **Public API Discoverability**: Public library interfaces and core repositories require KDoc so IDE tooltips immediately explain parameter contracts and boundary conditions.

---

## 4. When to Use It
*   **Workarounds & Hacks**: Explain any non-intuitive workaround forced by third-party library bugs, platform quirks, or legacy API idiosyncrasies.
*   **Complex Business Formulas**: When implementing tax rates, cryptographic hashing, or complex physics algorithms, link to the official specification or business document.
*   **Public Interfaces & Contracts**: Document class and interface purposes, expected parameter invariants, and possible exceptions.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Restating the Obvious**: Never write comments that merely repeat the code identifier in English (`// Increments counter: counter++`).
*   **Comments as Crutches for Bad Code**: Never use a comment to explain convoluted, poorly-named code. Refactor the code and rename variables until it explains itself.
*   **Commented-Out Zombie Code**: Never leave commented-out blocks of dead code in Git. Version control history remembers deleted code; zombie blocks only cause confusion.

---

## 6. Advantages & Disadvantages

| Intent-Focused Comments ("Why") | Redundant Comments ("What") |
| :--- | :--- |
| **Preserves Business Context**: Explains decisions that code cannot. | **Noise & Clutter**: Takes up vertical space without adding value. |
| **Prevents Regressions**: Warns against naive refactorings. | **Lies Over Time**: Quickly falls out of sync with code changes. |
| **High Educational Value**: Mentors developers reading the codebase. | **Distracts Reviewers**: Creates false sense of documentation. |

---

## 7. Practical Examples

### Bad Example: Redundant Comments & Missing Context
```kotlin
// BAD: Comments state the obvious, but fail to explain the weird workaround
class SyncService {
    // Variable for user id
    var uId: String = ""

    // This method syncs
    fun sync() {
        // Check if id is empty
        if (uId.isEmpty()) {
            return
        }

        // Wait 300 milliseconds
        Thread.sleep(300) // WHY? Nobody knows! A future developer will delete this.

        /*
        val oldWay = api.legacySync()
        oldWay.flush()
        */ // Zombie code left behind
    }
}
```

### Good Example: Clean Self-Documenting Code with Intent Comments
```kotlin
// GOOD: Code is self-explanatory; comment documents non-obvious hardware quirk
class DeviceSyncService(private val hardwareApi: HardwareApi) {

    /**
     * Synchronizes local telemetry with the external peripheral.
     *
     * @throws HardwareTimeoutException if the peripheral does not respond within 5 seconds.
     */
    suspend fun syncTelemetry(deviceId: String) {
        if (deviceId.isBlank()) return

        // NOTE: Firmware v2.1 requires a 300ms delay between BLE connection establishment 
        // and the first buffer read, otherwise the hardware FIFO buffer drops packets.
        // See Vendor Ticket #4829 for hardware errata details.
        delay(300)

        hardwareApi.readTelemetryBuffer(deviceId)
    }
}
```

---

## 8. Common Mistakes
1.  **Zombie Code**: Leaving old blocks of code commented out "just in case we need it later." (Trust Git history instead).
2.  **TODO Abandonment**: Writing `// TODO: Fix this memory leak later` and leaving it untouched for 3 years. Either file a ticket or fix it immediately.
3.  **Out-of-Date Javadoc/KDoc**: Renaming function parameters but leaving the old names in the `@param` documentation.

---

## 9. Verification Checklist

- [ ] Are all redundant comments that merely restate the code deleted?
- [ ] Do comments focus on *why* a non-obvious decision or workaround was made?
- [ ] Is all commented-out dead code eliminated from the file?
- [ ] Do public interfaces and domain use-cases have clear KDoc/Javadoc summaries?
- [ ] Are all `TODO` comments accompanied by an actionable issue tracker reference or clear completion condition?
