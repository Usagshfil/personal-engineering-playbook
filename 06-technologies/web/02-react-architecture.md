# 02. Modern React Architecture: Server Components, Hooks & Composition

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Web Frontend Engineering  
> **Target Version**: React 19+, Next.js (App Router) / Modern React Frameworks

---

## 1. Definition & Core Concept

**Modern React Architecture** is organized around **Declarative Component Composition**, **Strict Render Purity**, and **Framework-Appropriate Execution Boundaries**.

React applications fall into two primary architectural models, both anchored by the **Universal React Core**:

1.  **Universal React Core (Universal to ALL React Applications)**:
    *   Components are pure functions of their inputs (props, state, context).
    *   Unidirectional data flow (state flows down, events flow up).
    *   Hooks rules, error isolation via `<ErrorBoundary>`, and asynchronous loading via `<Suspense>`.
2.  **Server-Driven Architecture (React Server Components — Next.js App Router, Remix)**:
    *   **Server Components (Default)**: Execute strictly on the server or build machine. Zero client JavaScript bundle impact. Direct access to databases, filesystems, and backend caches.
    *   **Client Components (`'use client'`)**: Leaf-level interactive boundaries that hydrate in the browser to handle user events, DOM listeners, and browser state (`useState`).
3.  **Client-Only Single Page Applications (Vite, Standard SPAs)**:
    *   All components execute and render on the client browser.
    *   `'use client'` directives are unnecessary or treated as no-ops.
    *   Data fetching is orchestrated via client caching libraries (**TanStack Query**) rather than server component fetches.

```
+-------------------------------------------------------------------------+
| Framework Execution Architecture Comparison                             |
|                                                                         |
| [ Server-Driven / RSC (Next.js) ]     [ Client-Only SPA (Vite) ]        |
|                                                                         |
| Server Component (Zero Client Bundle)    App Root Component (Client JS) |
|    |---> Server Data Fetch (DB/API)          |---> TanStack Query Client|
|    |                                         |                          |
|    `---> [ 'use client' Boundary ]           `---> Standard Client      |
|             |---> Browser DOM Events                  Interactive UI    |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to ensure clean component boundaries, eliminate hook antipatterns (particularly `useEffect` misuse), prevent main-thread hydration bottlenecks, and select the right architectural pattern for the project's requirements without forcing RSC where a client SPA is more appropriate.

---

## 3. Why It Matters

*   **Zero-Bundle Server Execution (in RSC)**: In server-driven setups, heavy libraries (markdown parsers, date formatters, sanitizers) execute on the server and ship 0 KB of JavaScript to the user's browser.
*   **Predictable Rendering Lifecycles**: Pure render functions eliminate race conditions, infinite render loops, and stale closures.
*   **Encapsulated Stateful Logic**: Custom hooks isolate complex asynchronous orchestration and event subscriptions, leaving UI components focused purely on presentation.
*   **Targeted Fault Isolation**: Granular `<ErrorBoundary>` and `<Suspense>` boundaries ensure a failure in an isolated widget (e.g. recommendations carousel) does not crash the entire application screen.

---

## 4. When to Use It

### Framework Selection Decision Matrix
*   **Choose Server-Driven / RSC (Next.js App Router)** when:
    *   Public-facing web applications requiring Search Engine Optimization (SEO).
    *   Content-heavy websites, marketing portals, e-commerce, or blogs.
    *   Applications where direct database access reduces internal API boilerplate.
*   **Choose Client-Only SPA (Vite)** when:
    *   Internal enterprise dashboards, admin panels behind authentication.
    *   Offline-first applications (PWAs) or heavy desktop-like browser tools (canvas, editors).
    *   Teams requiring simple static hosting (S3/Cloudflare Pages) without server runtimes.

### Normative Engineering Rules (RFC 2119)
*   **Render Purity (MUST)**: Component render functions **MUST** remain pure. Do NOT trigger side effects, mutate external variables, or perform network requests during render.
*   **Hook Dependency Integrity (MUST)**: Developers **MUST** satisfy `eslint-plugin-react-hooks/exhaustive-deps`. Disabling or suppressing hook dependency warnings is strictly prohibited.
*   **Leaf-Level Client Boundaries (SHOULD in RSC)**: In Server Component applications, developers **SHOULD** push `'use client'` to the lowest possible leaf interactive elements (buttons, inputs, local drawers) to maximize server-rendered HTML.
*   **Pure Derived State (SHOULD)**: Compute derived values directly during render rather than synchronizing them via `useEffect` + `useState`:
    ```typescript
    // GOOD: Pure calculation during render; zero useEffect
    const fullName = `${firstName} ${lastName}`;
    const filteredItems = useMemo(() => items.filter(i => i.active), [items]);
    ```
*   **Component Composition Patterns (MAY)**:
    *   *Compound Components*: Use when sub-components share implicit state (e.g. `<Accordion>`, `<Tabs>`, `<Select>`).
    *   *Slot Pattern (`asChild`)*: Use composition over deep prop drilling to allow consumers to render custom wrappers.
*   **Custom Hooks (SHOULD)**: Extract reusable UI orchestration into custom hooks prefixed with `use` (e.g., `useDebounce`, `useIntersectionObserver`).

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **`useEffect` for Data Fetching or Derived State (AVOID)**: **NEVER** use `useEffect` to fetch data in modern React (use TanStack Query for client SPAs, Server Components for RSC, or React 19 `use()`). Never use `useEffect` to synchronize state that can be calculated during render.
*   **Mandating RSC in Client SPAs (AVOID)**: Do NOT force RSC patterns, `'use client'` directives, or server actions in pure client Vite applications.
*   **Top-Level `'use client'` on Layouts (AVOID)**: In RSC frameworks, placing `'use client'` on a root layout forces the entire subtree into client hydration, negating RSC performance benefits.
*   **Prop-Drilling Megastructures (AVOID)**: Do not pass callbacks or state down through more than 2–3 levels of intermediate components. Use component composition (`children`), compound components, or lightweight stores (Zustand).

---

## 6. Advantages & Disadvantages

| Modern React Pattern | Legacy React Pattern (Classes / Unconstrained Hooks) |
| :--- | :--- |
| **Server Components**: Zero client bundle for static & DB logic. | Client-only SPA: Bundles entire backend fetchers and parsers to browser. |
| **Pure Derived State**: Computed directly during render cycle. | `useEffect` + `setState` chains causing double renders and flicker. |
| **Leaf-Level Hydration**: Only interactive widgets hydrate in browser. | Monolithic full-page hydration blocking the main thread. |
| **Compound Components**: Highly flexible, declarative JSX composition. | Giant monolithic components with 40+ configuration props. |

---

## 7. Practical Examples

### Bad Example: Top-Level Client Component, `useEffect` Sprawl & Prop Drilling

```tsx
// BAD: Top-level 'use client', useEffect for derived state, useEffect for data fetching
'use client';

import { useState, useEffect } from 'react';

export function BadUserProfilePage({ userId }: { userId: string }) {
  const [user, setUser] = useState<any>(null);
  const [posts, setPosts] = useState<any[]>([]);
  const [activePosts, setActivePosts] = useState<any[]>([]); // HAZARD: Redundant state!

  // HAZARD: Data fetching in useEffect causes race conditions and waterfalls
  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => setUser(data));

    fetch(`/api/users/${userId}/posts`)
      .then(res => res.json())
      .then(data => setPosts(data));
  }, [userId]);

  // HAZARD: Synchronizing state via useEffect causes second render pass and UI flash!
  useEffect(() => {
    if (posts) {
      setActivePosts(posts.filter(p => !p.isArchived));
    }
  }, [posts]);

  return (
    <div>
      <h1>{user?.name}</h1>
      <BadPostList posts={activePosts} />
    </div>
  );
}
```

### Good Example: Server Component, Leaf-Level Client Boundary & Pure Derived State

```tsx
// GOOD: Server Component fetches data cleanly; Client Component handles only interactivity
// 1. Server Component (Zero client JS bundle, direct DB/API access)
import { Suspense } from 'react';
import { db } from '@/lib/db';
import { BookmarkButton } from './BookmarkButton'; // Leaf client component

interface PostPageProps {
  params: { postId: string };
}

export default async function PostPage({ params }: PostPageProps) {
  // Fetch data directly on the server without client water-falling
  const post = await db.post.findUniqueOrThrow({
    where: { id: params.postId },
  });

  return (
    <article className="max-w-2xl mx-auto py-8">
      <header className="flex justify-between items-center mb-4">
        <h1 className="text-3xl font-bold">{post.title}</h1>
        {/* Leaf Client Boundary: Only the interactive bookmark button ships client JS */}
        <BookmarkButton postId={post.id} initialBookmarked={post.isBookmarked} />
      </header>
      <div className="prose">{post.content}</div>
    </article>
  );
}

// 2. Leaf Client Component ('use client' strictly bounded to the interactive control)
// BookmarkButton.tsx
'use client';

import { useState, useTransition } from 'react';
import { togglePostBookmarkAction } from '@/actions/post';

interface BookmarkButtonProps {
  postId: string;
  initialBookmarked: boolean;
}

export function BookmarkButton({ postId, initialBookmarked }: BookmarkButtonProps) {
  const [isBookmarked, setIsBookmarked] = useState(initialBookmarked);
  const [isPending, startTransition] = useTransition();

  const handleToggle = () => {
    // Optimistic state toggle
    const nextState = !isBookmarked;
    setIsBookmarked(nextState);

    startTransition(async () => {
      try {
        await togglePostBookmarkAction(postId, nextState);
      } catch (error) {
        // Rollback on failure
        setIsBookmarked(!nextState);
        console.error('Failed to update bookmark', error);
      }
    });
  };

  return (
    <button
      type="button"
      onClick={handleToggle}
      disabled={isPending}
      aria-pressed={isBookmarked}
      className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
        isBookmarked ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'
      }`}
    >
      {isPending ? 'Saving...' : isBookmarked ? 'Bookmarked' : 'Bookmark'}
    </button>
  );
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Using `useEffect` to Synchronize or Derive State**:
    *   *Problem*: Calculating filtered lists, formatted prices, or combined strings inside a `useEffect` triggers an additional unnecessary re-render and can cause infinite render loops.
    *   *Remedy*: Calculate derived state directly during render, wrapping in `useMemo` only if the computation is genuinely expensive (>1000 items).
2.  **Over-Using Context for High-Frequency State**:
    *   *Problem*: Storing rapidly updating values (e.g. mouse position, scroll coordinates, form field keystrokes) in React Context forces every component consuming that Context to re-render, causing severe input lag (poor INP).
    *   *Remedy*: Use atomic state libraries with selector subscriptions (such as Zustand) or local component state.
3.  **Missing Error Boundaries Around Dynamic Features**:
    *   *Problem*: An uncaught JavaScript runtime error in an optional widget (e.g. third-party analytics chart) unmounts the entire React tree, leaving the user with a blank white screen.
    *   *Remedy*: Wrap non-critical sections in localized `<ErrorBoundary>` components with friendly fallback UI.

---

## 9. Verification Checklist

- [ ] Are `'use client'` directives placed strictly at the leaf interactive boundaries?
- [ ] Is data fetching in Server Components performed natively on the server without client `useEffect`?
- [ ] Are all derived values computed inline during render rather than synchronized via `useEffect` + `useState`?
- [ ] Is `eslint-plugin-react-hooks/exhaustive-deps` strictly enforced with zero suppressed warnings?
- [ ] Are non-critical dynamic UI sections isolated with `<ErrorBoundary>` and `<Suspense>`?
- [ ] Are props passed via clean composition (`children`, compound components) rather than 4+ levels of prop-drilling?
- [ ] Do interactive elements (buttons, inputs) expose accessible attributes (`aria-pressed`, `aria-expanded`)?
