# Tier 2: Web Frontend Engineering Standards

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: Active (Priority 2)  
> **Ecosystem Baseline**: TypeScript 5.5+, React 19+, Next.js (App Router) / Vite 5+, Tailwind CSS 3.4+ / 4.0, Node.js 20+ LTS

---

## 1. Overview & Architectural Placement

This directory defines the **Tier 2 Web Frontend Engineering Standards** of the Personal Software Engineering Playbook. It translates the universal principles of Tier 1 (Universal Core) into concrete, idiomatic conventions for modern web application engineering.

When developing web client applications under this playbook, AI coding agents and human developers must adhere to the **4-Level Instruction Hierarchy**:

$$\text{Tier 3: Project Overlay} \succ \text{Tier 2: Web Standard} \succ \text{Tier 1: Universal Core}$$

> [!CAUTION]
> **The Invariant Safety Gate**: Tier 2 Web Frontend conventions can **NEVER** override Tier 1 Universal Safety, Security, or Verification Integrity rules. No web convention may authorize committing API secrets in client-side bundles, bypassing automated regression tests, disabling sanitization of external HTML inputs, or claiming verification passed without empirical execution.

---

## 2. Modern Web Technology Baseline

Our engineering standard reflects modern, production-hardened web architecture:

| Component | Standard Selection | Rationale & Alternatives |
| :--- | :--- | :--- |
| **Language** | **Strict TypeScript 5.5+** | Compile-time type safety, zero `any`, discriminating unions, `satisfies`. |
| **UI Library** | **React 19** | Modern component model, Server vs. Client component boundaries (RSC), actions. |
| **Application Framework** | **Next.js (App Router) / Vite** | Next.js for fullstack/SSR/SEO apps; Vite for pure Single Page Applications (SPAs). |
| **Server State Cache** | **TanStack Query (v5)** | Dedicated server data caching, background revalidation, optimistic updates. |
| **Global Client State** | **Zustand** | Minimalist atomic store with selector subscriptions; avoids Context re-render storms. |
| **Styling & Design Tokens** | **Tailwind CSS / CSS Modules** | Zero-runtime CSS generation; eliminates runtime CSS-in-JS performance bottlenecks. |
| **Form Management** | **React Hook Form + Zod** | Uncontrolled input performance with runtime schema validation. |
| **Accessibility Target** | **WCAG 2.1 Level AA** | Semantic HTML, keyboard navigability, focus management, ARIA compliance. |

---

## 3. Technology Standards Catalog

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

## 4. Reading & Implementation Order

When onboarding to a web frontend project or developing new features:
1. **Core Language & Type Safety**: Master [`01-typescript-idioms.md`](01-typescript-idioms.md).
2. **Component Architecture & State**: Structure screens using [`02-react-architecture.md`](02-react-architecture.md) and [`03-state-management.md`](03-state-management.md).
3. **Styling & Layout**: Implement accessible, responsive layouts using [`04-modern-styling-and-css.md`](04-modern-styling-and-css.md).
4. **Forms & Accessibility**: Build resilient user input flows using [`06-accessibility-and-forms.md`](06-accessibility-and-forms.md).
5. **Performance & Auditing**: Optimize bundle size and Core Web Vitals using [`05-web-performance-and-cwv.md`](05-web-performance-and-cwv.md).
