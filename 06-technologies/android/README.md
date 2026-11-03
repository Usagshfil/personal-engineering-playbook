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

## 2. Modern Android Technology Baseline

Our engineering standard reflects the modern, production-hardened Android architecture recommendations:

| Component | Standard Selection | Rationale & Alternatives |
| :--- | :--- | :--- |
| **Language** | **Kotlin 2.0+** | Modern language idioms, null safety, K2 compiler speed, value classes. |
| **UI Toolkit** | **Jetpack Compose** | Declarative, reactive UI; eliminates XML views, ViewBinding, and fragmentation. |
| **Concurrency** | **Coroutines & Flow** | Structured concurrency, cooperative cancellation, non-blocking streams. |
| **Persistence** | **Room 2.6+ & DataStore** | Compile-time SQL verification, reactive Flow queries, type-safe settings. |
| **Dependency Injection** | **Dagger Hilt** | Standard Android DI with compile-time verification; Koin accepted for small scripts. |
| **Networking** | **Retrofit 2.11+ / OkHttp** | Industry standard REST client with Kotlinx Serialization and interceptors. |
| **Architecture** | **MVVM / MVI (Clean)** | Unidirectional Data Flow (UDF), immutable `UiState`, lifecycle-aware collection. |
| **Build Configuration** | **Gradle Kotlin DSL & TOML** | Type-safe `build.gradle.kts` with centralized `gradle/libs.versions.toml`. |

---

## 3. Technology Standards Catalog

The Android standard is structured into 8 comprehensive guides, each adhering to the **9-Part Pedagogical Schema**:

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

---

## 4. Reading & Implementation Order

When onboarding to an Android project or developing new features:
1. **Core Language & Concurrency**: Review [`01-kotlin-idioms.md`](01-kotlin-idioms.md) and [`03-coroutines-and-flow.md`](03-coroutines-and-flow.md).
2. **Data & Persistence**: Implement data models, Room databases, and network clients using [`04-room-database.md`](04-room-database.md) and [`06-network-and-api.md`](06-network-and-api.md).
3. **Architecture & DI**: Wire repositories and ViewModels via [`05-dependency-injection.md`](05-dependency-injection.md) and [`07-architecture-patterns.md`](07-architecture-patterns.md).
4. **Presentation**: Author declarative UI screens using [`02-jetpack-compose.md`](02-jetpack-compose.md).
5. **Build & Release**: Configure build scripts and optimization rules using [`08-gradle-and-build.md`](08-gradle-and-build.md).
