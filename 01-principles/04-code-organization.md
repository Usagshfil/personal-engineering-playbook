# 04. Code Organization & Package Architecture

---

## 1. Definition
**Code Organization** is the intentional structural design of directories, packages, modules, and source files within a project. It determines how components are grouped (e.g., **Package-by-Feature** vs. **Package-by-Layer**) and how boundaries between modules are maintained.

---

## 2. Purpose
The purpose of structured code organization is to maximize **locational cohesion**. When you need to understand, modify, or fix a specific feature (such as "Checkout" or "UserProfile"), all relevant code (data models, UI screens, view models, and repositories) should be co-located or logically discoverable without hunting across 15 disparate directories.

---

## 3. Why It Matters
*   **Package-by-Layer Anti-Pattern**: When an intermediate project puts all models in `models/`, all views in `views/`, all adapters in `adapters/`, and all repositories in `repositories/`, touching one feature forces you to jump across four folders. Deleting or refactoring that feature leaves orphan files everywhere.
*   **Package-by-Feature Superiority**: Grouping files by business capability (`feature/cart/`, `feature/authentication/`, `feature/profile/`) creates self-contained vertical slices that are easy to locate, test, and eventually extract into standalone Gradle modules.

---

## 4. When to Use It
*   **Small to Mid-Scale Projects**: Use **Package-by-Feature** inside a single application module.
*   **Large / Modular Projects**: Transition to **Multi-Module Gradle Architecture** where features live in `:feature:checkout`, `:core:database`, `:core:network`, `:core:model`.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Premature Multi-Module Explosion**: Do not split a 2,000-line hobby or learning application into 12 separate Gradle modules. Multi-module setups introduce build script maintenance, dependency substitution, and longer Gradle sync times. Start with clean packages inside `:app`, and extract modules only when build times or team boundaries require it.
*   **The "Misc" or "Common" Junkyard**: Never create a generic `common/` or `utils/` package where unrelated functions are dumped. Instead, group utilities by purpose (e.g. `core/formatting/`, `core/security/`).

---

## 6. Advantages & Disadvantages

| Package-by-Feature (Recommended) | Package-by-Layer (Legacy) |
| :--- | :--- |
| **High Cohesion**: Related files live together. | **Low Cohesion**: Related code is scattered across folders. |
| **Simple Deletion**: Deleting a feature is deleting one folder. | **Brittle Deletion**: Must hunt for parts in 6 different folders. |
| **Encapsulation**: Can use Kotlin `internal` visibility. | **Broken Encapsulation**: Everything must be `public`. |
| **Clear Feature Ownership**: Natural fit for scaling teams. | **Navigation Overhead**: High cognitive friction. |

---

## 7. Practical Examples

### Bad Example: Package-by-Layer (Scattered)
```text
app/src/main/java/com/example/app/
├── models/
│   ├── User.kt
│   ├── Product.kt
│   └── CartItem.kt
├── repositories/
│   ├── UserRepository.kt
│   ├── ProductRepository.kt
│   └── CartRepository.kt
├── viewmodels/
│   ├── UserViewModel.kt
│   ├── ProductViewModel.kt
│   └── CartViewModel.kt
└── ui/
    ├── UserScreen.kt
    ├── ProductScreen.kt
    └── CartScreen.kt
```
*Problem*: To change how Cart discounts work, you have to open 4 distinct folders and touch 4 scattered files.

### Good Example: Package-by-Feature (Cohesive Vertical Slices)
```text
app/src/main/java/com/example/app/
├── core/                               # Reusable foundational modules
│   ├── network/                        # Retrofit/Ktor engine
│   ├── database/                       # Room database configuration
│   └── designsystem/                   # Compose theme, colors, atomic UI components
│
└── features/                           # Vertical business feature packages
    ├── auth/                           # Authentication slice
    │   ├── AuthScreen.kt
    │   ├── AuthViewModel.kt
    │   ├── AuthRepository.kt
    │   └── UserCredentials.kt
    ├── catalog/                        # Product Catalog slice
    │   ├── CatalogScreen.kt
    │   ├── CatalogViewModel.kt
    │   └── Product.kt
    └── cart/                           # Shopping Cart slice
        ├── CartScreen.kt
        ├── CartViewModel.kt
        ├── CartRepository.kt
        ├── CartItem.kt
        └── CartCalculationUtils.kt
```

---

## 8. Common Mistakes
1.  **Circular Package Dependencies**: Package A imports Package B, which in turn imports Package A. Enforce a unidirectional dependency hierarchy: Features depend on Core, but Core never depends on Features.
2.  **The "Utils" Dumping Ground**: A single `Utils.kt` file with 50 static extension functions for dates, strings, network checks, and view animations.
3.  **Leaking Feature Logic into Core**: Adding specific business rules into shared network or database classes.

---

## 9. Verification Checklist

- [ ] Is code grouped primarily by feature/domain capability rather than technical artifact type?
- [ ] Can a complete feature be located and reviewed inside a single directory hierarchy?
- [ ] Are shared components isolated in dedicated `core/` packages?
- [ ] Are dependencies unidirectional (Feature $\rightarrow$ Core, never Core $\rightarrow$ Feature)?
- [ ] Are files and classes scoped with appropriate visibility (`internal` or `private` instead of everything being `public`)?
