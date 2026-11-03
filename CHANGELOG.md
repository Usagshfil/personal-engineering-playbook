# Changelog

All notable changes to the Personal Software Engineering Playbook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-alpha.1] - 2026-11-03

### Added
- **3-Tier Framework Architecture**: Clear separation of Tier 1 (Universal Core), Tier 2 (Technology Extensions), and Tier 3 (Project Overlay).
- **4-Level AI Instruction Hierarchy**: Precedence and conflict resolution across Universal Rules (L1), Technology Standards (L2), Project Rules (L3), and Task Skills (L4).
- **The Iron Safety Gate**: Non-overridable safety baseline for secrets, test verification integrity, and non-destructive file operations.
- **Section 01: Universal Engineering Principles**: 12 core engineering principles structured using a 9-part pedagogical schema for intermediate developer education.
- **Section 02: Software Development Lifecycle**: 12 SDLC phases detailing Inputs, Activities, Outputs, Deliverables, and Gate Criteria.
- **Section 03: Architecture Standards & Fit Matrix**: Universal guidance covering Layered, Clean Architecture, MVC, MVVM, Repository, DI, and modular boundaries with anti-overengineering rules.
- **Section 04: AI Agent Rules & Roles**: Specialized instructions for Planning, Architecture, Coding, Debugging, Testing, Review, and Documentation agents.
- **Section 10: Security and Privacy Engineering**: Comprehensive universal security guidelines covering secret management, authentication, input validation, supply chain, data privacy, and STRIDE threat modeling.
- **Risk-Based Testing Doctrine**: Replaced arbitrary numerical test quotas with pragmatic, risk-driven verification rules.
- **Priority 1 Android Standards (Tier 2)**: 8 comprehensive educational engineering guides adhering to the 9-part pedagogical schema (`06-technologies/android/`), covering Modern Kotlin 2.0 idioms, Jetpack Compose UI & recomposition stability, Coroutines & Flow structured concurrency, Room 2.6+ persistence with automated migration testing & SQLCipher encryption, Dagger Hilt dependency injection, Retrofit 2.11+ secure networking with synchronized token refresh, Clean Architecture + MVVM/MVI with Unidirectional Data Flow, and Gradle 8+ Kotlin DSL with TOML Version Catalogs.
- **Priority 2 Web Frontend Standards (Tier 2)**: 6 comprehensive educational engineering guides adhering to the 9-part pedagogical schema (`06-technologies/web/`), covering Strict TypeScript 5.5+ idioms & discriminating unions, React 19 architecture & Server Components (RSC), 3-tier client state management (TanStack Query, Zustand, URL parameters), modern styling & container queries with Tailwind CSS, Core Web Vitals optimization (LCP, INP, CLS) & code-splitting, and WCAG 2.1 AA accessibility & form validation with React Hook Form + Zod.
- **Priority 3 Backend & API Standards (Tier 2)**: 6 comprehensive educational engineering guides adhering to the 9-part pedagogical schema (`06-technologies/backend/`), covering RESTful API design (RFC 9110, status code discipline, URI hierarchy $\le 2$ levels, cursor pagination, OpenAPI 3.1), boundary data validation and serialization (Zod / Go Validator / Bean Validation, mass assignment defense), authentication and authorization (OAuth 2.0 / OIDC, short-lived JWTs $\le 15\text{m}$, secure refresh rotation, RBAC/ABAC, BOLA/IDOR prevention), service layer and domain logic isolation (thin controllers, atomic Unit of Work transactions, RFC 9457 Problem Details `application/problem+json`), resilience and fault tolerance (distributed Redis rate limiting, circuit breaker pattern, exponential backoff with full jitter, idempotency keys), and observability & logging (structured JSON logging, W3C trace context `traceparent`, RED metrics, automated PII scrubbing, decoupled `/healthz` and `/readyz` probes). Includes production reference implementation in `06-technologies/backend/examples/representative-api.ts`.
- **Governance Documentation**: `VERSION.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, and `IMPROVEMENT_BACKLOG.md`.
