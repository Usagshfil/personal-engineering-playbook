# Tier 2: Technology-Specific Engineering Standards

> **Architecture Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: Completed (Priority 1: Android, Priority 2: Web, Priority 3: Backend, and Priority 4: Database & Persistence Active & Completed)  
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

All four core technology domains of **Milestone 4** are fully implemented and verified:

| Domain | Priority | Target Technologies | Standard Documentation | Status |
| :--- | :---: | :--- | :--- | :---: |
| **Android** | **Priority 1** | Kotlin, Jetpack Compose, Coroutines/Flow, Room Database, Hilt/Koin DI, Android Architecture Recommendations | [Android Standards](android/README.md) (8 guides) | **Active (Completed)** |
| **Web Frontend** | **Priority 2** | TypeScript, React 19, Vite/Next.js, Tailwind CSS, Modern Web APIs, Web Performance (CWV) | [Web Standards](web/README.md) (6 guides) | **Active (Completed)** |
| **Backend & APIs** | **Priority 3** | RESTful API Design, RFC 9110, Node.js / Go / Spring Boot, OAuth2/OIDC, Resilience & Observability | [Backend Standards](backend/README.md) (6 guides) | **Active (Completed)** |
| **Database & Persistence** | **Priority 4** | Relational SQL (PostgreSQL 16+, SQLite), 3NF Normalization, Indexing Strategies, Safe Migrations, Concurrency, Pooling, Backup/Recovery | [Database Standards](database/README.md) (7 guides) | **Active (Completed)** |
| **Cross-Domain Integration** | **Milestone 4.3** | Ownership Matrix, Harmonization, Transactional Outbox, RFC 9457, Token Family Rotation, Unified Deadlines | [Cross-Domain Standards](CROSS_DOMAIN_CONSISTENCY.md) | **Active (Completed)** |

---

## 3. Normative Agent Operating Guidance

> [!IMPORTANT]
> **Normative Guidance for AI Agents Operating Across Technology Domains**:
> - **Android Projects**: Must strictly follow the normative guides in [`06-technologies/android/`](android/README.md).
> - **Web Projects**: Must strictly follow the normative guides in [`06-technologies/web/`](web/README.md).
> - **Backend Projects**: Must strictly follow the normative guides in [`06-technologies/backend/`](backend/README.md).
> - **Database & Persistence Projects**: Must strictly follow the normative guides in [`06-technologies/database/`](database/README.md).
> - **Cross-Tier / Full-Stack Work**: When features span multiple tiers (e.g. mobile/web to backend to database), agents must strictly enforce the authoritative ownership contracts, transactional outbox pattern, and unified timeout budgets defined in [`06-technologies/CROSS_DOMAIN_CONSISTENCY.md`](CROSS_DOMAIN_CONSISTENCY.md).
>
> When executing engineering tasks within these domains, AI coding agents must observe this precedence hierarchy:
> 1. **Tier 1 Universal Primacy**: Strictly observe all universal rules in `01-principles/`, `03-architecture/`, `10-security-and-privacy/`, and `AGENTS.md`.
> 2. **Tier 2 Domain Standards**: Apply idiomatic patterns, non-blocking migrations, strict typing, and security invariants defined in the respective domain guides.
> 3. **Zero Invention of Ad-Hoc Conventions**: Do NOT invent bespoke architectural layers, unverified libraries, custom annotations, or idiosyncratic conventions not recognized in the target ecosystem.
> 4. **Skill Delegation**: Agent skills (such as `database-engineering`, `system-architecture`, `coding-and-implementation`) reference these Tier 2 standards as their direct normative execution substrate.
