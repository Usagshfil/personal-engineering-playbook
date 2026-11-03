# 02. Modern React Architecture: Server Components, Hooks & Composition

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Web Frontend Engineering  
> **Target Version**: React 19+, Next.js (App Router) / Modern React Frameworks

---

## 1. Definition & Core Concept

**Modern React Architecture** is organized around **Declarative Component Composition**, **Strict Render Purity**, and the **Server / Client Component Boundary (React Server Components — RSC)**.

In modern React, components are pure functions of their props and state. Computation is partitioned into:
1.  **Server Components (Default)**: Execute strictly on the server or build machine. Zero client-side JavaScript bundle impact. Direct access to databases, filesystems, and internal microservices.
2.  **Client Components (`'use client'`)**: Opt-in interactivity boundaries that hydrate in the browser to handle user interactions, DOM event listeners, and browser APIs (`useState`, `useEffect`, `localStorage`).

```
+-------------------------------------------------------------------------+
| React Server Component (RSC) Boundary Model                             |
|                                                                         |
| Server Component (e.g., UserDashboardPage - Zero client JS bundle)      |
|    |---> Server Component (UserStatsDisplay - reads DB directly)        |
|    |                                                                    |
|    `---> [ 'use client' Boundary ] (InteractiveAvatarSelector)          |
|             |---> Client Hook (useState, onClick handler)               |
|             `---> Browser DOM Event Listeners                           |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to minimize client bundle footprints, eliminate unnecessary component re-renders, avoid hook antipatterns (especially `useEffect` sprawl), and build resilient, accessible UIs using composable component patterns.

---

## 3. Why It Matters

*   **Zero-Bundle Server Execution**: Pushing data fetching and heavy transformations into Server Components keeps megabytes of dependencies (parsers, date libraries, markdown renderers) out of client JavaScript bundles.
*   **Predictable Rendering Lifecycles**: Pure render functions prevent subtle race conditions, infinite render loops, and stale closure bugs.
*   **Encapsulated Component Logic**: Custom hooks isolate complex asynchronous orchestration, keyboard interactions, and event subscriptions, leaving UI components clean and focused purely on markup presentation.
*   **Fault Isolation**: Granular `<ErrorBoundary>` and `<Suspense>` wrappers guarantee that a failure in an isolated widget (e.g. recommendations carousel) does not crash the entire application screen.

---

## 4. When to Use It

*   **Server Components (RSC)**: Default to Server Components for layout scaffolding, data fetching, static content, and search-engine-indexed pages.
*   **Client Components (`'use client'`)**: Mark a file with `'use client'` strictly at the lowest possible leaf level where client interactivity is required (button clicks, form inputs, local state, animations).
*   **Component Composition Patterns**:
    *   *Compound Components*: Use when sub-components share implicit state and must work together flexibly (e.g., `<Accordion>`, `<Tabs>`, `<Select>`).
    *   *Slot Pattern (`asChild`)*: Use composition over deep prop drilling to allow consumers to render custom wrappers (e.g. rendering a Next.js `<Link>` as a `<Button>`).
*   **Hook Discipline**:
    *   *Derived State*: Compute derived values during render:
        ```typescript
        // GOOD: Pure calculation during render; zero useEffect or extra useState
        const fullName = `${firstName} ${lastName}`;
        const filteredItems = useMemo(() => items.filter(i => i.active), [items]);
        ```
    *   *Custom Hooks*: Extract reusable UI logic into custom hooks prefixed with `use` (e.g., `useDebounce`, `useLocalStorage`, `useIntersectionObserver`).

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **`useEffect` for Data Fetching or Derived State**: **NEVER** use `useEffect` to fetch data in modern React (use TanStack Query, Next.js Server Components, or React 19 `use()`). Never use `useEffect` to synchronize state that can be calculated during render.
*   **Marking Top-Level Layouts as `'use client'`**: Placing `'use client'` at the root of a page or layout forces the entire sub-tree into client-side hydration, forfeiting the performance and bundle benefits of RSC.
*   **Prop-Drilling Megastructures**: Do not pass callbacks or state down through more than 2–3 levels of intermediate components. Use component composition (`children`), compound components, or lightweight stores (Zustand).
*   **Cheating Hook Dependencies**: **NEVER** disable `eslint-plugin-react-hooks/exhaustive-deps`. Omitting dependencies causes stale closures, invisible bugs, and memory leaks.

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
