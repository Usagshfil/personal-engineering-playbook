# Tier 2: Web Frontend Engineering Standards

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: Active (Priority 2)  
> **Target Version**: TypeScript 5.5+, React 19+, Next.js 15+ / Vite 5.4+, Tailwind CSS 3.4+ / 4.0  
> **Last Verified**: 2026-11-03

---

## 1. Overview & Architectural Placement

This directory defines the **Tier 2 Web Frontend Engineering Standards** of the Personal Software Engineering Playbook. It translates the universal principles of Tier 1 (Universal Core) into concrete, idiomatic conventions for modern web application engineering.

When developing web client applications under this playbook, AI coding agents and human developers must adhere to the **4-Level Instruction Hierarchy**:

$$\text{Tier 3: Project Overlay} \succ \text{Tier 2: Web Standard} \succ \text{Tier 1: Universal Core}$$

> [!CAUTION]
> **The Invariant Safety Gate**: Tier 2 Web Frontend conventions can **NEVER** override Tier 1 Universal Safety, Security, or Verification Integrity rules. No web convention may authorize committing API secrets in client-side bundles, bypassing automated regression tests, disabling sanitization of external HTML inputs, or claiming verification passed without empirical execution.

---

## 2. Technology Version Governance Matrix

To prevent version ambiguity and ensure long-term reproducibility, this standard distinguishes minimum supported versions from recommended defaults:

| Technology / Component | Minimum Supported | Recommended Baseline | Example Version | Governance & Maintenance Policy |
| :--- | :---: | :---: | :---: | :--- |
| **TypeScript** | `5.0` | `5.5+` | `5.5.4` | Strict mode mandatory. Verify with `tsc --noEmit`. |
| **React** | `18.2` | `19.0+` | `19.0.0` | Server Components supported in RSC frameworks; pure client otherwise. |
| **Application Framework** | — | **Next.js 15+ / Vite 5.4+** | Next.js 15.0 / Vite 5.4 | Next.js for SSR/SEO/Fullstack; Vite for pure client SPAs. |
| **Node.js Runtime** | `18.18.0` | `20.x LTS` | `20.18.0 LTS` | Standardized via `.nvmrc` and `engines` field in `package.json`. |
| **Server State Cache** | `5.0` | `5.50+` | TanStack Query 5.50 | Dedicated cache for asynchronous remote data. |
| **Global Client State** | `4.4` | `4.5+` | Zustand 4.5 | Lightweight atomic UI state with selector subscriptions. |
| **Styling Engine** | — | **Tailwind CSS 3.4+ / 4.0** | Tailwind 3.4.10 | Zero-runtime CSS generation with semantic CSS tokens. |
| **Form Management** | `7.45` | `7.52+` | React Hook Form 7.52 | Uncontrolled inputs paired with Zod runtime validation. |
| **Validation Schema** | `3.21` | `3.23+` | Zod 3.23.8 | Single source of truth for runtime boundary validation. |

*Last Verified Matrix Date: 2026-11-03*

---

## 3. Recommendation Strength Taxonomy (RFC 2119)

To ensure recommendations are not misconstrued as dogmatic mandates, guidelines in this directory use standard normative keywords:

*   **MUST**: Mandatory requirement for correctness, security, or accessibility (e.g. strict type-checking, keyboard accessibility, explicit image dimensions, zero unvetted `any`).
*   **SHOULD**: Strong default recommendation for production web applications (e.g. TanStack Query for remote asynchronous caching, Tailwind CSS for zero-runtime styling). Exceptions must be justified in `TECHNICAL_DECISIONS.md`.
*   **MAY**: Optional technique or design pattern appropriate for complex use cases (e.g. Zustand for cross-cutting client UI state, Compound Components for design system libraries).
*   **AVOID**: Discouraged pattern that induces performance, security, or maintenance bugs (e.g. runtime CSS-in-JS inside RSC frameworks, `useEffect` for derived state, blind `as TargetType` assertions).

---

## 4. Scale & Complexity Selection Guide (Simpler Alternatives)

Not every web application warrants a full ecosystem library stack. Choose the simplest viable abstraction:

| Concern | Small App / Prototype (Simpler Alternative) | Production Web Application (Standard Recommendation) |
| :--- | :--- | :--- |
| **Data Fetching** | Native `fetch` with `useState` or Next.js Server Components. | **TanStack Query** (automated deduplication, caching, background revalidation). |
| **Global UI State** | React `useState` lifted to common ancestor or focused Context. | **Zustand** (selector-based atomic subscriptions without Context re-renders). |
| **Styling** | Standard CSS Modules or scoped native CSS. | **Tailwind CSS** with Design Tokens and Container Queries. |
| **Form Handling** | Native `<form>` with uncontrolled inputs or React 19 Actions. | **React Hook Form + Zod** (complex validation, multi-field error binding). |
| **Component Structure** | Simple function components with direct props. | **Compound Components / Slot Pattern** for highly flexible component libraries. |

---

## 5. Technology Standards Catalog

The Web Frontend standard is structured into 6 comprehensive guides, each adhering strictly to the **9-Part Pedagogical Schema**:

| # | Standard Guide | Core Focus Areas |
| :---: | :--- | :--- |
| **01** | [`01-typescript-idioms.md`](01-typescript-idioms.md) | Strict mode, discriminating unions, utility types (`Pick`, `Omit`, `Record`), type guards (`is`), `satisfies`, zero `any`. |
| **02** | [`02-react-architecture.md`](02-react-architecture.md) | React 19 architecture, Server Components vs Client Components, hook discipline, compound components, error boundaries. |
| **03** | [`03-state-management.md`](03-state-management.md) | 3-tier state hierarchy: Server cache (TanStack Query), Global client state (Zustand), Local state (`useState`), optimistic UI. |
| **04** | [`04-modern-styling-and-css.md`](04-modern-styling-and-css.md) | Tailwind CSS utility discipline, CSS Modules, design tokens, container queries (`@container`), `:has()`, dark mode. |
| **05** | [`05-web-performance-and-cwv.md`](05-web-performance-and-cwv.md) | Core Web Vitals (LCP, INP, CLS), code-splitting (`lazy`, `Suspense`), image/font optimization, critical rendering path. |
| **06** | [`06-accessibility-and-forms.md`](06-accessibility-and-forms.md) | WCAG 2.1 AA compliance, semantic HTML, ARIA attributes, keyboard navigation, focus management, React Hook Form + Zod. |

---

## 6. Reading & Implementation Order

When onboarding to a web frontend project or developing new features:
1. **Core Language & Type Safety**: Master [`01-typescript-idioms.md`](01-typescript-idioms.md).
2. **Component Architecture & State**: Structure screens using [`02-react-architecture.md`](02-react-architecture.md) and [`03-state-management.md`](03-state-management.md).
3. **Styling & Layout**: Implement accessible, responsive layouts using [`04-modern-styling-and-css.md`](04-modern-styling-and-css.md).
4. **Forms & Accessibility**: Build resilient user input flows using [`06-accessibility-and-forms.md`](06-accessibility-and-forms.md).
5. **Performance & Auditing**: Optimize bundle size and Core Web Vitals using [`05-web-performance-and-cwv.md`](05-web-performance-and-cwv.md).

---

## 7. Concrete Reference Implementation

A complete, self-contained reference implementation demonstrating these standards in practice is located in:
*   [`examples/representative-feature.tsx`](examples/representative-feature.tsx) — User Profile Editor component exercising strict TypeScript types, Zod boundary validation, accessible WCAG 2.1 AA form controls, non-blocking UI transitions (`useTransition`), and container-queried responsive styling with design tokens.

