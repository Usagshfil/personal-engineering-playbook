# Tier 2: Android Engineering Standards

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: Active (Priority 1)  
> **Ecosystem Baseline**: Android 14+ (API 34), minSdk 24, Kotlin 2.0+, Jetpack Compose, Gradle 8+

---

## 1. Overview & Architectural Placement

This directory defines the **Tier 2 Android Engineering Standards** of the Personal Software Engineering Playbook. It translates the timeless principles of Tier 1 (Universal Core) into concrete, idiomatic conventions for modern Android application development.

When developing Android applications under this playbook, AI coding agents and human developers must adhere to the **4-Level Instruction Hierarchy**:

$$\text{Tier 3: Project Overlay} \succ \text{Tier 2: Android Standard} \succ \text{Tier 1: Universal Core}$$

> [!CAUTION]
> **The Invariant Safety Gate**: Tier 2 Android conventions can **NEVER** override Tier 1 Universal Safety, Security, or Verification Integrity rules. No Android pattern may authorize hardcoding secrets in `build.gradle.kts`, bypassing regression tests, or claiming tests pass without execution evidence.

---

## 2. Technology Version Governance Matrix

To prevent version drift and ensure reproducible builds, the Android standard defines explicit version baselines:

| Component / Dependency | Minimum Supported | Recommended Baseline | Example Version | Governance & Maintenance Policy |
| :--- | :---: | :---: | :---: | :--- |
| **Android OS / SDK** | `minSdk 24` (7.0) | `targetSdk 34` (14+) | `compileSdk 34` | Minimum covers >96% of global devices; target latest Google Play requirement. |
| **Kotlin Language** | `1.9.20` | `2.0+` (K2) | `2.0.0` | K2 compiler speed, `@JvmInline` value classes, sealed interfaces. |
| **Jetpack Compose** | `1.5.0` | **BOM 2024.06+** | `2024.06.00` | Manage versions via Compose Compiler Gradle plugin (Kotlin 2.0). |
| **Concurrency & Streams** | `1.7.3` | `1.8+` | `1.8.0` | Structured concurrency; `viewModelScope` with injected dispatchers. |
| **Persistence (Room)** | `2.5.0` | `2.6+` | `2.6.1` | KSP code generation; `MigrationTestHelper` and schema export mandatory. |
| **Dependency Injection** | `2.48` | `Dagger Hilt 2.51+` | `2.51.1` | Compile-time graph verification; `@TestInstallIn` module overrides. |
| **Networking & HTTP** | `2.9.0` | `Retrofit 2.11+` | `2.11.0` | OkHttp 4.12.0; Kotlinx Serialization 1.6+ with `@SerialName`. |
| **Build Tools (Gradle/AGP)** | `8.0` | `Gradle 8.4+ / AGP 8.3+` | AGP 8.3.1 | Kotlin DSL (`build.gradle.kts`) and Version Catalogs (`libs.versions.toml`). |
| **Background Work (WorkManager)** | `2.8.0` | `WorkManager 2.9+` | `2.9.0` | OS constraint scheduling (`NetworkType.CONNECTED`), exponential backoff. |
| **Mobile UI & E2E Testing** | `1.5.0` | `Compose Test 1.6+ / Maestro 1.35+` | Maestro 1.35.0 | Declarative black-box YAML flows; Roborazzi 1.10+ JVM screenshot tests. |
| **Release & Publishing** | `2.0` | `Fastlane 2.220+ / Google Play API` | Fastlane 2.220.0 | Automated AAB signing, mapping.txt archival, progressive staged rollouts. |

*Last Verified Matrix Date: 2026-11-03*

---

## 3. Recommendation Strength Taxonomy (RFC 2119)

*   **MUST**: Mandatory requirement for correctness, security, or crash prevention (e.g. zero `GlobalScope`, rethrowing `CancellationException`, zero hardcoded keystore secrets, R8 minification in release).
*   **SHOULD**: Strong default recommendation for production Android applications (e.g. Dagger Hilt for DI, Room for relational persistence, Unidirectional Data Flow).
*   **MAY**: Optional technique or lightweight alternative (e.g. Koin for lightweight scripts, DataStore Preferences for simple key-value flags).
---

## 4. Technology Standards Catalog

The Android standard is structured into 11 comprehensive guides, each adhering to the **9-Part Pedagogical Schema**:

| # | Standard Guide | Core Focus Areas |
| :---: | :--- | :--- |
| **01** | [`01-kotlin-idioms.md`](01-kotlin-idioms.md) | Immutability (`val`), data classes, sealed hierarchies, delegation, value classes (`@JvmInline`), extension & scope functions. |
| **02** | [`02-jetpack-compose.md`](02-jetpack-compose.md) | Declarative UI, state hoisting, recomposition stability (`@Immutable`), Modifier ordering, `rememberSaveable`, side effects, Material 3. |
| **03** | [`03-coroutines-and-flow.md`](03-coroutines-and-flow.md) | Structured concurrency, CoroutineScope, Dispatchers, exception handling, `StateFlow` vs `SharedFlow`, `collectAsStateWithLifecycle`. |
| **04** | [`04-room-database.md`](04-room-database.md) | Entities, DAOs, relations, automated migrations with `MigrationTestHelper`, in-memory tests, Keystore-backed SQLCipher. |
| **05** | [`05-dependency-injection.md`](05-dependency-injection.md) | Constructor injection, Hilt modules (`@InstallIn`), scopes (`@Singleton`, `@ViewModelScoped`), test overrides with `@TestInstallIn`. |
| **06** | [`06-network-and-api.md`](06-network-and-api.md) | Retrofit contracts, OkHttp auth interceptors, PII log scrubbing, Kotlinx Serialization, custom Result CallAdapter, `MockWebServer`. |
| **07** | [`07-architecture-patterns.md`](07-architecture-patterns.md) | Clean Architecture + MVVM/MVI, UI Layer (immutable `UiState`), Domain Use Cases, Data Layer (SSOT Repository, offline sync). |
| **08** | [`08-gradle-and-build.md`](08-gradle-and-build.md) | Kotlin DSL, Version Catalogs (`libs.versions.toml`), convention plugins, build types, R8 optimization rules, compiler flags. |
| **09** | [`09-offline-first-and-sync.md`](09-offline-first-and-sync.md) | Single Source of Truth (SSOT), optimistic UI writes, soft-delete tombstones, WorkManager background sync, conflict resolution (LWW). |
| **10** | [`10-mobile-testing-and-qa.md`](10-mobile-testing-and-qa.md) | Pragmatic testing pyramid, Jetpack Compose UI tests (`testTag`), Roborazzi JVM screenshot tests, Maestro declarative YAML E2E flows. |
| **11** | [`11-release-management-and-cicd.md`](11-release-management-and-cicd.md) | Android App Bundle (AAB), R8 Full Mode shrinking, Keystore signing via CI secrets, Fastlane automation, Google Play staged rollouts. |

---

## 5. Reading & Implementation Order

When onboarding to an Android project or developing new features:
1. **Core Language & Concurrency**: Review [`01-kotlin-idioms.md`](01-kotlin-idioms.md) and [`03-coroutines-and-flow.md`](03-coroutines-and-flow.md).
2. **Data & Persistence**: Implement data models, Room databases, and network clients using [`04-room-database.md`](04-room-database.md) and [`06-network-and-api.md`](06-network-and-api.md).
3. **Offline Sync & Backgrounding**: Implement offline-first caching and WorkManager synchronization using [`09-offline-first-and-sync.md`](09-offline-first-and-sync.md).
4. **Architecture & DI**: Wire repositories and ViewModels via [`05-dependency-injection.md`](05-dependency-injection.md) and [`07-architecture-patterns.md`](07-architecture-patterns.md).
5. **Presentation**: Author declarative UI screens using [`02-jetpack-compose.md`](02-jetpack-compose.md).
6. **Testing & QA**: Author Compose UI tests, Roborazzi screenshots, and Maestro E2E flows using [`10-mobile-testing-and-qa.md`](10-mobile-testing-and-qa.md).
7. **Build & Release**: Configure build scripts, signing, and Fastlane deployment using [`08-gradle-and-build.md`](08-gradle-and-build.md) and [`11-release-management-and-cicd.md`](11-release-management-and-cicd.md).
