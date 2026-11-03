# 10. Lean Dependency Management & Supply Chain Hygiene

---

## 1. Definition
**Dependency Management** is the strategic governance of third-party libraries, SDKs, and build plugins integrated into a project. It enforces **Lean Dependencies** (introducing only well-vetted, essential external libraries) and **Supply Chain Hygiene** (pinning exact versions, monitoring vulnerabilities, and avoiding abandoned packages).

---

## 2. Purpose
Every external dependency added to a project represents **code you did not write, do not control, but must maintain and debug**. The purpose of disciplined dependency management is to protect the codebase from bloat, security vulnerabilities, API deprecations, licensing risks, and build breakages.

---

## 3. Why It Matters
*   **Dependency Bloat**: Adding a massive library just for a single helper function inflates APK download size, increases method counts, and slows down compile times.
*   **Supply Chain Attacks**: Compromised or abandoned open-source packages can introduce malicious code that steals user data or keystrokes.
*   **Maintenance Debt**: When Android OS updates or Gradle introduces breaking changes, having 40 external dependencies often causes build failures while waiting for third-party authors to release updates.

---

## 4. When to Use It
*   **Vetting Checklist**: Before adding any dependency, evaluate:
    1. Does the standard library already provide this capability?
    2. Is the library actively maintained (commits within the last 6 months)?
    3. Is it backed by a reputable organization (e.g. Google, JetBrains, Square)?
    4. What license does it use (MIT, Apache 2.0 vs. copyleft GPL)?
*   **Version Catalogs**: Use Gradle Version Catalogs (`libs.versions.toml`) to declare and organize dependencies centrally.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Reinventing Complex Wheels (Not-Invented-Here Syndrome)**: Do not write your own custom HTTP client, JSON parser, or image caching engine. Vetted foundational libraries (Retrofit, OkHttp, Kotlinx.serialization, Coil) represent years of battle-tested edge-case handling.
*   **Banning All Dependencies**: The goal is *lean and disciplined* dependencies, not zero dependencies.

---

## 6. Advantages & Disadvantages

| Disciplined & Lean Dependencies | Careless "Add an SDK" Strategy |
| :--- | :--- |
| **Fast Build Times**: Smaller dependency graph compiles quickly. | **Slow Gradle Sync**: Minutes lost waiting for dependency resolution. |
| **Minimal Security Vulnerabilities**: Low attack surface. | **High Vulnerability Exposure**: Unpatched CVEs lurk in transitive packages. |
| **Effortless OS Upgrades**: Smooth upgrades when new Android SDKs drop. | **Blocked Upgrades**: One unmaintained library blocks the entire app. |

---

## 7. Practical Examples

### Modern Gradle Version Catalog (`gradle/libs.versions.toml`)
```toml
[versions]
kotlin = "2.0.21"
coreKtx = "1.15.0"
composeBom = "2024.10.01"
room = "2.6.1"
retrofit = "2.11.0"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-compose-ui = { group = "androidx.compose.ui", name = "ui" }
androidx-room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
retrofit-core = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }

[bundles]
compose = ["androidx-compose-ui"]
```

### Bad Example: Dynamic Versions & Mystery Plugins
```kotlin
// BAD in build.gradle.kts:
dependencies {
    // Dangerous: '+' means every build pulls a random new version, causing surprise breakage!
    implementation("com.some.unvetted.library:widget:1.+") 
    
    // Pulled 500kb library just to check if a string is alphanumeric!
    implementation("org.apache.commons:commons-lang3:3.14.0")
}
```

### Good Example: Standard Library Replacement
```kotlin
// GOOD: Use Kotlin standard library instead of pulling an external dependency
fun isAlphanumeric(text: String): Boolean {
    return text.all { it.isLetterOrDigit() }
}
```

---

## 8. Common Mistakes
1.  **Using Dynamic or Plus Versions**: Declaring `implementation("com.lib:sdk:1.0.+")`, which causes builds to change unpredictably from day to day.
2.  **Duplicate Functionality Libraries**: Having both `Gson` and `Kotlinx.serialization`, or both `Glide` and `Coil` in the same project.
3.  **Ignoring Transitive Vulnerabilities**: Never running dependency vulnerability audits (`./gradlew dependencyCheckAnalyze` or GitHub Dependabot).

---

## 9. Verification Checklist

- [ ] Are all dependencies declared centrally in a version catalog (`libs.versions.toml`)?
- [ ] Are all versions pinned to exact, deterministic release versions (no `+` or dynamic ranges)?
- [ ] Has every third-party library been evaluated against standard library alternatives?
- [ ] Are duplicate libraries serving the same purpose eliminated?
- [ ] Is an automated vulnerability scanning tool (e.g., Dependabot) enabled for the repository?
