# 01. Modern TypeScript Idioms: Strict Typing, Modeling & Immutability

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Web Frontend Engineering  
> **Target Version**: TypeScript 5.5+ (Strict Mode)

---

## 1. Definition & Core Concept

**Idiomatic Modern TypeScript** leverages structural typing, compile-time inference, and strict type narrowing to model domain states precisely and eliminate entire classes of runtime exceptions.

Rather than treating TypeScript as mere "type annotations on JavaScript," modern TypeScript enforces **zero unvetted `any`**, models discrete runtime possibilities via **discriminating unions**, preserves exact literals via the **`satisfies` operator**, and guards external boundaries with **runtime validation schemas**.

```
+-------------------------------------------------------------------------+
| Discriminating Union Mental Model                                       |
|                                                                         |
| type AsyncState<T> =                                                    |
|   | { status: 'idle' }                                                  |
|   | { status: 'loading' }                                               |
|   | { status: 'success'; data: T }      <--- data ONLY exists here       |
|   | { status: 'error'; error: Error };  <--- error ONLY exists here      |
|                                                                         |
| * TypeScript compiler prevents accessing 'data' in 'loading' or 'error' |
+-------------------------------------------------------------------------+
```

---

## 2. Purpose

The purpose of this standard is to eliminate runtime `TypeError: Cannot read property of undefined`, prevent illegal state representations, preserve exact type signatures through refactorings, and eliminate unsafe type casting across web codebases.

---

## 3. Why It Matters

*   **Preventing Impossible States**: Representing asynchronous workflows with separate flags (`isLoading: boolean`, `data: T | null`, `error: Error | null`) creates $2^3 = 8$ possible state combinations, half of which are invalid (e.g. `isLoading: true` and `data: Object` and `error: Error` simultaneously). Discriminating unions reduce this to exactly the valid states.
*   **Compile-Time Exhaustiveness**: When switching over a discriminating union tag (`status`), the TypeScript compiler checks that every branch is handled. Adding a new state immediately flags every unhandled UI branch across the repository.
*   **Exact Type Preservation with `satisfies`**: Unlike type annotations (`const config: Config = ...`) which widen literals, or type assertions (`as Config`) which bypass checks, `satisfies` verifies that a value satisfies a contract while preserving exact literal types and autocompletion.
*   **Safe System Boundaries**: TypeScript types evaporate at compile time. Data entering from network endpoints or `localStorage` must be validated with runtime parsers (such as Zod) rather than blindly cast with `as User`.

---

## 4. When to Use It

*   **Discrete Application & UI States**: Use discriminating unions for asynchronous queries, modal visibility, step-based wizards, and action dispatches.
*   **Configurations & Route Tables**: Use `satisfies` to validate configuration dictionaries while keeping literal keys and values strongly typed:
    ```typescript
    const routes = {
      home: '/',
      profile: '/users/:id',
    } as const satisfies Record<string, string>;
    ```
*   **Domain Identifiers & Immutability**:
    *   Mark read-only arrays and tuples with `as const` or `ReadonlyArray<T>`.
    *   Use branded types (or tagged nominal wrappers) to distinguish raw strings (e.g. `type UserId = string & { readonly __brand: unique symbol }`).
*   **Narrowing Unknown Boundaries**: Use user-defined type guards (`value is User`) or assertion functions (`asserts value is string`) when verifying external payloads.
*   **Standard Utility Types**: Master `Pick<T, K>`, `Omit<T, K>`, `Partial<T>`, `Record<K, T>`, and `Awaited<ReturnType<typeof fn>>`.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **The `any` Escape Hatch**: **NEVER** use `any`. Use `unknown` when a type cannot be known in advance, and force narrowing via type guards or Zod schemas before accessing properties.
*   **Type Assertion Chains**: Avoid `value as unknown as T`. Forcing the compiler to accept incompatible types hides critical type mismatches and crashes at runtime.
*   **Deep Type Gymnastics**: Avoid overly complex conditional type cascades or recursive template literal types that slow down the TypeScript compiler (`tsserver`) and confuse fellow engineers. If a type requires more than 15 lines of type algebra, simplify the data design.
*   **Redundant Type Annotations**: Do not annotate types that TypeScript infers automatically (e.g. write `const count = 0;`, not `const count: number = 0;`).

---

## 6. Advantages & Disadvantages

| Pattern | Idiomatic Strict TypeScript | Loose / Legacy TypeScript |
| :--- | :--- | :--- |
| **State Correctness** | Impossible states are unrepresentable at compile time. | Flag soup (`isLoading`, `hasError`, `data`) allows contradictory state. |
| **Refactoring Confidence** | Renaming properties or adding union variants fails fast in all callers. | `any` and loose `as` assertions fail silently at runtime. |
| **IDE Productivity** | Rich autocomplete with exact narrow types. | Broad primitive autocompletion with missing property warnings. |
| **Initial Coding Speed** | Requires intentional state modeling upfront. | Faster initial scaffolding; severe downstream bug-fixing overhead. |

---

## 7. Practical Examples

### Bad Example: Impossible States, Loose Types & Unsafe Assertions

```typescript
// BAD: Impossible state combinations, unsafe any, type assertions
interface BadUserData {
  id?: string;
  name?: string;
  email?: string;
}

interface BadComponentState {
  isLoading: boolean;
  isError: boolean;
  data: BadUserData | null;
  errorMessage: string | null;
}

// HAZARD: Function accepts any and uses unsafe type casting
async function fetchUser(userId: string): Promise<any> {
  const response = await fetch(`/api/users/${userId}`);
  const json = await response.json();
  // HAZARD: Type assertion bypasses verification; if API schema shifts, app crashes!
  return json as BadUserData;
}

function handleState(state: BadComponentState) {
  // HAZARD: Contradictory state: isLoading = true while data exists!
  if (state.isLoading) {
    showSpinner();
  }
  // HAZARD: Accessing potentially undefined property without narrowing
  console.log(state.data?.name.toUpperCase()); // Crashes if name is undefined!
}
```

### Good Example: Discriminating Unions, Strict Narrowing & `satisfies`

```typescript
// GOOD: Discriminating union, runtime validation, exact literals with satisfies
import { z } from 'zod';

// 1. Runtime schema contract at system boundary (Tier 1 Rule 7)
export const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
});

export type User = z.infer<typeof UserSchema>;

// 2. Discriminating union for UI state modeling
export type UserState =
  | { readonly status: 'idle' }
  | { readonly status: 'loading' }
  | { readonly status: 'success'; readonly user: User }
  | { readonly status: 'error'; readonly error: string };

// 3. API client with runtime boundary verification
export async function fetchUserSafe(userId: string): Promise<User> {
  const response = await fetch(`/api/users/${encodeURIComponent(userId)}`);
  if (!response.ok) {
    throw new Error(`HTTP error ${response.status}: ${response.statusText}`);
  }
  const rawData: unknown = await response.json();
  
  // Safe runtime parse: fails fast if API contract is violated
  return UserSchema.parse(rawData);
}

// 4. Exhaustive UI state renderer
export function renderUserState(state: UserState): string {
  switch (state.status) {
    case 'idle':
      return 'Please click to load user';
    case 'loading':
      return 'Loading user profile...';
    case 'success':
      // TypeScript guarantees state.user exists and is safe
      return `Welcome, ${state.user.name} (${state.user.email})`;
    case 'error':
      return `Error: ${state.error}`;
    default: {
      // Compile-time exhaustiveness guarantee
      const _exhaustiveCheck: never = state;
      throw new Error(`Unhandled state: ${JSON.stringify(_exhaustiveCheck)}`);
    }
  }
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Blind Type Assertions (`as TargetType`)**:
    *   *Problem*: Using `const user = response.json() as User` tells TypeScript to completely bypass validation. If the backend changes a property from `string` to `number` or renames `user_id` to `id`, TypeScript will not catch it, leading to silent `NaN` or `undefined` runtime errors.
    *   *Remedy*: Validate untrusted data with Zod, or use a type guard (`function isUser(val: unknown): val is User`).
2.  **Using `any` Instead of `unknown`**:
    *   *Problem*: `any` disables the entire type checker on that variable and contagiously infects every expression it touches.
    *   *Remedy*: Always use `unknown`. Forces developers to verify the type before performing operations on it.
3.  **Wielding the Non-Null Assertion (`!`) Arbitrarily**:
    *   *Problem*: Writing `user!.profile!.avatar` suppresses compiler warnings when properties are legitimately nullable, producing uncaught `TypeError` at runtime.
    *   *Remedy*: Use optional chaining (`user?.profile?.avatar`) or handle null/undefined branches explicitly with guard clauses.

---

## 9. Verification Checklist

- [ ] Is `"strict": true` enabled in `tsconfig.json` without disabling `noImplicitAny`?
- [ ] Are all discrete UI or async states modeled with discriminating unions (`status: 'loading' | 'success' | 'error'`)?
- [ ] Is `any` strictly prohibited across all production and test source files?
- [ ] Are untrusted network payloads validated using runtime parsers (e.g. Zod) rather than raw `as Type` assertions?
- [ ] Does every `switch` over union variants implement an exhaustive `never` check in the default branch?
- [ ] Are configuration objects and routing maps validated with `satisfies` to preserve exact literals?
- [ ] Are arrays and object properties declared `readonly` where mutation is not expected?
