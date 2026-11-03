# Tier 2: Technology-Specific Engineering Standards

> **Architecture Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: In Progress (Priority 1: Android Active & Completed)  
> **Applicability**: Domain-specific extensions augmenting Tier 1 Universal Core

---

## 1. Overview & Architectural Placement

In the **3-Tier Layering Model** of this Playbook:
1. **Tier 1 (Universal Core)**: Language- and framework-agnostic principles, SDLC workflows, architectural patterns, and non-negotiable security/safety rules.
2. **Tier 2 (Technology Standards)**: Concrete, idiomatic standards translating universal principles into specific programming languages, frameworks, runtime environments, and persistence engines.
3. **Tier 3 (Project Overlays)**: Repository-specific requirements, domain models, and business logic.

$$\text{Tier 3: Project Overlay} \succ \text{Tier 2: Technology Standards} \succ \text{Tier 1: Universal Core}$$

> [!CAUTION]
> **The Invariant Safety Gate**: Tier 2 technology standards can **NEVER** override Tier 1 Universal Safety, Security, or Verification Integrity rules. No technology convention may authorize committing credentials, skipping regression tests, or silently overwriting code.

---

## 2. Technology Standards Roadmap (Milestone 4 Delivery)

The following four technology domains are scheduled for comprehensive implementation in **Milestone 4**:

| Domain | Priority | Target Technologies | Standard Documentation | Status |
| :--- | :---: | :--- | :--- | :---: |
| **Android** | **Priority 1** | Kotlin, Jetpack Compose, Coroutines/Flow, Room Database, Hilt/Koin DI, Android Architecture Recommendations | [Android Standards](android/README.md) (8 guides) | **Active (Completed)** |
| **Web Frontend** | **Priority 2** | TypeScript, React 19, Vite/Next.js, Tailwind CSS, Modern Web APIs, Web Performance (CWV) | `06-technologies/web/` (6 guides) | Planned (M4) |
| **Backend & APIs** | **Priority 3** | RESTful API Design, JSON:API, Node.js / Spring Boot / Go, Authentication (OAuth2/JWT), Microservices vs Modular Monolith | `06-technologies/backend/` (6 guides) | Planned (M4) |
| **Database & Persistence** | **Priority 4** | Relational SQL (PostgreSQL, SQLite), 3NF Normalization, Indexing Strategies, Safe Schema Migrations, Connection Pooling | `06-technologies/database/` (5 guides) | Planned (M4) |

---

## 3. Interim Agent Fallback Protocol

> [!IMPORTANT]
> **Normative Guidance for AI Agents Operating Across Technology Domains**:
> - **Android Projects**: Must strictly follow the normative guides in [`06-technologies/android/`](android/README.md).
> - **Web, Backend, and Database Domains**: While these standards remain in `Planned` status, AI coding agents working on tasks requiring technology-specific patterns must follow this strict fallback hierarchy:
>   1. **Tier 1 Universal Primacy**: Strictly observe all universal rules in `01-principles/`, `03-architecture/`, `10-security-and-privacy/`, and `AGENTS.md`.
>   2. **Authoritative Official Standards**: Default to the highest official industry documentation:
>      - **Web**: [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/), [React Documentation](https://react.dev/), and [MDN Web Docs](https://developer.mozilla.org/).
>      - **Backend**: RFC 9110 (HTTP Semantics), OpenAPI 3.1 Specification, and language-standard idiomatic guidelines.
>      - **Database**: ANSI SQL-92/99, PostgreSQL Documentation, and SQLite Architecture Guidelines.
>   3. **Zero Invention of Ad-Hoc Conventions**: Do NOT invent bespoke architectural layers, custom annotations, or idiosyncratic conventions not recognized in the target ecosystem.
>   4. **Graceful Delegation**: When skills (such as `database-engineering` or `ui-ux-engineering`) refer to Tier 2 standards for pending domains, agents must interpret the reference as a delegation to this Interim Fallback Protocol until the dedicated files are generated in Milestone 4.
