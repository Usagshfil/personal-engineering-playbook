# 03. Web State Management: Server Cache, Global Stores & URL State

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Web Frontend Engineering  
> **Target Version**: TanStack Query v5+, Zustand 4.5+, React 19+

---

## 1. Definition & Core Concept

**Modern Web State Management** decomposes application state into four distinct, specialized categories rather than dumping all application data into a monolithic global store:

1.  **Server Cache State**: Asynchronous data owned by the backend (user profiles, product lists, order histories). Managed by dedicated caching tools (**TanStack Query** / SWR).
2.  **Global Client UI State**: Synchronous client-only state shared across disconnected UI branches (active theme, navigation drawer, audio playback, active modal). Managed by lightweight atomic stores (**Zustand**).
3.  **URL Query State**: State that controls what the user sees and should be shareable, reloadable, or bookmarkable (search queries, filters, active tab, pagination). Managed via **URL search parameters**.
4.  **Local Component State**: Ephemeral state private to a single component or small subtree (dropdown open/close, hover state, input validation focus). Managed via **`useState`** or **`useReducer`**.

```
+-------------------------------------------------------------------------+
| The 4-Tier State Decision Matrix                                        |
|                                                                         |
| Is the data owned by the backend and fetched asynchronously?            |
|    |---> YES ===> Server Cache (TanStack Query / SWR)                   |
|    |                                                                    |
|    `---> NO: Should it be shareable via URL / bookmarkable?             |
|             |---> YES ===> URL Search Params (nuqs / Next.js router)    |
|             |                                                           |
|             `---> NO: Is it needed by multiple disconnected screens?     |
|                      |---> YES ===> Global Store (Zustand)              |
|                      |                                                  |
|                      `---> NO  ===> Local State (useState / useReducer) |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to prevent cache staleness bugs, eliminate redundant manual data-fetching logic, avoid re-render performance bottlenecks caused by bloated React Contexts, and ensure consistent URL-driven shareability.

---

## 3. Why It Matters

*   **Eliminating Cache Synchronization Bugs**: When backend data is duplicated into a global client store (like Redux or Zustand), developers must manually write actions, reducers, loading flags, error flags, refetch triggers, and cache invalidation. TanStack Query automates deduplication, background caching, garbage collection, and window-focus revalidation.
*   **Selector-Based Re-render Isolation**: In vanilla React Context, updating any property causes every consumer component to re-render. Zustand uses selector subscriptions (`useStore(s => s.theme)`) so components only re-render when their specific slice of state changes.
*   **Shareable Web Ergonomics**: Storing active tab index or filter options in URL parameters guarantees that when a user copies the browser URL and sends it to a colleague, both see the exact same view.
*   **Instant Perceived Performance**: Optimistic UI mutations instantly update the interface before the network request finishes, rolling back gracefully only if the server returns an error.

---

## 4. When to Use It

### Recommendation Strength & Selection Criteria (RFC 2119)

*   **Dedicated Server Cache (SHOULD in Production SPAs)**: Production web applications with multiple asynchronous data-fetching endpoints **SHOULD** adopt **TanStack Query** (or SWR).
    *   Use `useQuery` with structured array query keys (`['users', userId]`).
    *   Use `useMutation` with cache invalidation (`queryClient.invalidateQueries(...)`).
    *   Implement `onMutate` for optimistic updates with rollback snapshots.
*   **Lighter Alternative for Small Apps (MAY)**: Small applications or simple prototypes with minimal remote state **MAY** use vanilla `fetch` inside a dedicated custom hook or rely on Next.js Server Components without introducing TanStack Query.
*   **Global Client UI State (MAY / SHOULD)**: When UI state must be shared across disconnected component subtrees (e.g., active modal stack, cart drawer, toast notifications), developers **SHOULD** use **Zustand**.
    *   **Selector Subscriptions (MUST)**: Components subscribing to global stores **MUST** use granular selectors (`useUiStore(s => s.isDrawerOpen)`) to prevent full-tree re-renders.
*   **Shareable URL State (SHOULD)**: Search queries, category filters, sorting keys, and pagination indices **SHOULD** be synchronized with **URL Search Parameters** (`useSearchParams` or `nuqs`) for bookmarkability.
*   **Local Component State (SHOULD)**: Ephemeral state isolated to a single component or immediate parent-child hierarchy **SHOULD** use native `useState` or `useReducer`.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Duplicating Server Data in Global Stores (AVOID)**: **NEVER** copy remote API or TanStack Query response data into Zustand, Redux, or Context stores. Remote state must have a single source of truth.
*   **Monolithic Context for High-Frequency State (AVOID)**: Do NOT use React Context for rapidly changing values (mouse positions, animation frames, keystroke feeds). Updating Context forces all consumer components to re-render.
*   **Premature Global Stores (AVOID)**: Do not create a global Zustand store for state used by only one component and its direct children. Keep it local with `useState`.
*   **URL Bloat (AVOID)**: Do NOT store non-serializable objects, private credentials, or large JSON payloads in URL search params.

---

## 6. Advantages & Disadvantages

| State Category | Recommended Tool | Anti-Pattern / Legacy Approach |
| :--- | :--- | :--- |
| **Server Cache** | **TanStack Query** (automated caching, deduplication). | Manual Redux thunks with custom `loading/error` flags. |
| **Global UI State** | **Zustand** (selector subscriptions, zero wrapper boilerplate). | Monolithic Context API causing full-app re-renders. |
| **Shareable State** | **URL Search Params** (native browser history, bookmarkable). | Local state lost upon page refresh or link sharing. |
| **Local State** | **`useState` / `useReducer`** (native, minimal cognitive load). | Over-engineering local toggles into global stores. |

---

## 7. Practical Examples

### Bad Example: Manual Server Sync in Global Context with Re-render Storms

```tsx
// BAD: Storing server data in React Context, manual fetch logic, full-tree re-renders
const UserContext = createContext<any>(null);

export function BadUserProvider({ children }: { children: ReactNode }) {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [theme, setTheme] = useState('light'); // HAZARD: Mixing UI theme with server data in one Context!

  const fetchUsers = async () => {
    setLoading(true);
    const res = await fetch('/api/users');
    const data = await res.json();
    setUsers(data);
    setLoading(false);
  };

  // HAZARD: Any change to 'theme' forces ALL components reading 'users' to re-render!
  return (
    <UserContext.Provider value={{ users, loading, theme, setTheme, fetchUsers }}>
      {children}
    </UserContext.Provider>
  );
}
```

### Good Example: TanStack Query + Zustand with Optimistic Mutation

```tsx
// GOOD: TanStack Query handles server data; Zustand handles global UI state
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { create } from 'zustand';

// 1. Global UI Store (Zustand) for client-only state
interface UiStore {
  readonly isSidebarOpen: boolean;
  toggleSidebar: () => void;
}

export const useUiStore = create<UiStore>((set) => ({
  isSidebarOpen: true,
  toggleSidebar: () => set((state) => ({ isSidebarOpen: !state.isSidebarOpen })),
}));

// 2. Server Cache (TanStack Query) with optimistic update
interface Todo {
  id: string;
  title: string;
  completed: boolean;
}

export function useTodos() {
  const queryClient = useQueryClient();

  // Query hook
  const todosQuery = useQuery<Todo[]>({
    queryKey: ['todos'],
    queryFn: async () => {
      const res = await fetch('/api/todos');
      if (!res.ok) throw new Error('Network response was not ok');
      return res.json();
    },
    staleTime: 1000 * 60 * 5, // 5 minutes fresh
  });

  // Mutation with optimistic UI update and error rollback
  const toggleTodoMutation = useMutation({
    mutationFn: async ({ id, completed }: { id: string; completed: boolean }) => {
      const res = await fetch(`/api/todos/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ completed }),
      });
      if (!res.ok) throw new Error('Failed to update todo');
      return res.json();
    },
    // Optimistic update lifecycle
    onMutate: async ({ id, completed }) => {
      // Cancel outgoing refetches so they don't overwrite optimistic update
      await queryClient.cancelQueries({ queryKey: ['todos'] });

      // Snapshot the previous state for rollback
      const previousTodos = queryClient.getQueryData<Todo[]>(['todos']);

      // Optimistically update cache
      queryClient.setQueryData<Todo[]>(['todos'], (old) =>
        old?.map((t) => (t.id === id ? { ...t, completed } : t))
      );

      return { previousTodos };
    },
    // If the mutation fails, rollback to snapshot
    onError: (err, variables, context) => {
      if (context?.previousTodos) {
        queryClient.setQueryData(['todos'], context.previousTodos);
      }
    },
    // Always refetch after error or success to guarantee synchronization
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });

  return {
    todos: todosQuery.data ?? [],
    isLoading: todosQuery.isLoading,
    isError: todosQuery.isError,
    toggleTodo: toggleTodoMutation.mutate,
  };
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Omitting Selector Functions in Zustand**:
    *   *Problem*: Calling `const { isSidebarOpen } = useUiStore()` without a selector subscribes the component to the *entire* store. Any change to any other property triggers an unwanted re-render.
    *   *Remedy*: Always pass a selector: `const isSidebarOpen = useUiStore(s => s.isSidebarOpen)`.
2.  **Unstructured or Static Query Keys**:
    *   *Problem*: Using static strings like `queryKey: ['user']` instead of parametric keys `['user', userId]` causes different user profiles to collide in the cache or fail to refetch on ID change.
    *   *Remedy*: Structure keys as hierarchical arrays: `['entities', entityId, 'sub-resources']`.
3.  **Forgetting `staleTime` Configuration**:
    *   *Problem*: TanStack Query defaults `staleTime: 0`, marking queries stale immediately. Refetching occurs on every window focus or component remount, creating excessive backend load.
    *   *Remedy*: Configure a reasonable default `staleTime` (e.g. 1 to 5 minutes) in `defaultOptions` based on domain volatility.

---

## 9. Verification Checklist

- [ ] Is remote backend data managed exclusively through TanStack Query / SWR (never duplicated in client stores)?
- [ ] Are query keys structured hierarchically as arrays containing all relevant parameters?
- [ ] Does global UI state utilize Zustand with strict selector-based subscriptions?
- [ ] Are filters, tabs, and pagination state synchronized with URL search parameters?
- [ ] Are mutations that alter UI state accompanied by proper cache invalidation or optimistic updates?
- [ ] Do optimistic updates include `onMutate` rollback snapshots to restore state on failure?
- [ ] Is local component state kept local to components that own the interaction?
