# 06. Web Accessibility & Form Engineering: WCAG 2.1 AA, React Hook Form & Zod

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Web Frontend Engineering  
> **Target Version**: WCAG 2.1 Level AA, React Hook Form 7+, Zod 3+

---

## 1. Definition & Core Concept

**Web Accessibility (a11y) & Form Engineering** ensures that web user interfaces are operable, perceivable, understandable, and robust for all users, including those relying on screen readers, keyboard-only navigation, and assistive technologies.

This standard pairs **WCAG 2.1 Level AA compliance** with high-performance, type-safe form management via **React Hook Form** (uncontrolled inputs with zero re-renders on keystroke) and **Zod** (runtime schema validation).

```
+-------------------------------------------------------------------------+
| Accessible Form Architecture                                            |
|                                                                         |
| <label htmlFor="user-email">Email Address</label>                      |
| <input                                                                  |
|    id="user-email"                                                      |
|    type="email"                                                         |
|    aria-invalid={!!errors.email}                                        |
|    aria-describedby="email-error"                                       |
|    {...register('email')}                                               |
| />                                                                      |
| <p id="email-error" role="alert" aria-live="polite">                    |
|    {errors.email?.message}                                              |
| </p>                                                                    |
+-------------------------------------------------------------------------+
```

### Accessibility Target & Standards Conformance
*   **Normative Baseline**: **WCAG 2.1 Level AA** compliance across all public web interfaces.
*   **WCAG 2.2 Additions Incorporated**:
    *   *SC 2.5.8 (Target Size Minimum)*: Interactive controls **MUST** be at least $24 \times 24$ CSS pixels (recommended $44 \times 44\text{px}$ on mobile touch screens), unless nested inline in prose.
    *   *SC 2.4.11 (Focus Not Obscured)*: Sticky headers, cookie banners, or floating footers **MUST NOT** completely obscure active keyboard focus.
*   **The 4-Tier Accessibility Verification Protocol**:
    1.  *Tier 1: Automated Static Analysis*: Run ESLint `jsx-a11y` and automated `axe-core` tests in CI (detects 30–40% of baseline errors).
    2.  *Tier 2: Keyboard & Focus Traversal*: Manual end-to-end verification without mouse: `Tab`, `Shift+Tab`, `Enter`, `Space`, `Escape`, verifying focus trap in dialogs and focus restoration upon close.
    3.  *Tier 3: Screen Reader Testing*: Manual inspection using native screen readers (VoiceOver on macOS/iOS, NVDA on Windows) to verify announced labels, live error updates, and landmark hierarchy.
    4.  *Tier 4: Cognitive & Visual Checks*: Verify 200% browser text zoom without content clipping, 4.5:1 text contrast ratios (3:1 for large text), and `@media (prefers-reduced-motion)` compliance.

---

## 2. Purpose

The purpose of this standard is to ensure web interfaces comply with international accessibility laws (WCAG 2.1 AA / ADA / Section 508 / EAA), eliminate input lag in complex forms, provide type-safe runtime input validation, and make dialogs and menus accessible without custom hacky scripts.

---

## 3. Why It Matters

*   **Legal Compliance & Universal Access**: Failing WCAG 2.1 AA standards exposes organizations to legal liability under the Americans with Disabilities Act (ADA) and the European Accessibility Act (EAA), while alienating over 15% of the world's population with disabilities.
*   **Keyboard Operability**: Many users navigate exclusively using `Tab`, `Shift+Tab`, `Enter`, `Space`, and `Escape`. Non-semantic clickable elements (`<div onClick={...}>`) are completely invisible and inoperable to keyboard and screen reader users.
*   **Performance via Uncontrolled Inputs**: Storing every keystroke in React component state (`value={val} onChange={e => setVal(e.target.value)}`) triggers a full component re-render on every keystroke. React Hook Form isolates input state in the DOM, keeping complex multi-page forms fluid and fast.
*   **End-to-End Type Safety**: Defining forms with Zod schemas guarantees that client validation, TypeScript types, and server-side validation share a single, verifiable contract.

---

## 4. When to Use It

### Normative Engineering Rules (RFC 2119)

*   **Semantic Elements First (MUST)**: Always use native HTML elements before reaching for ARIA:
    *   `<button>` for interactive actions; `<a>` with a valid `href` for page navigation.
    *   `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>` for landmark navigation.
    *   `<dialog>` or accessible headless primitives (Radix UI / Headless UI) for modals and drawers.
*   **Explicit Label Pairing (MUST)**: Every form input **MUST** have an explicitly linked `<label htmlFor="...">` with an identical `id` on the input element.
*   **Accessible Form Errors (MUST)**:
    *   Invalid inputs **MUST** set `aria-invalid="true"`.
    *   Error messages **MUST** be programmatically linked via `aria-describedby="error-id"`.
    *   Error message text **MUST** be placed in an assertive or polite live region (`role="alert"` or `aria-live="polite"`).
*   **Modal Focus Management (MUST)**:
    *   When opening a modal, trap keyboard focus within the dialog container.
    *   When closing the modal, return focus to the trigger element that opened it.
    *   Allow users to dismiss modals using the `Escape` key.
*   **Form Management with React Hook Form (SHOULD)**: For multi-field forms, developers **SHOULD** use **React Hook Form** paired with `zodResolver(schema)` for uncontrolled DOM performance and type safety.
*   **Lighter Alternative for Single Inputs (MAY)**: Single-input search bars or newsletter subscribe boxes **MAY** use native uncontrolled form actions or simple local `useState` without pulling in React Hook Form.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Div Buttons (AVOID)**: **NEVER** use `<div onClick={...}>` or `<span onClick={...}>` for clickable controls. Always use `<button type="button">`.
*   **Over-ARIA Inflation (AVOID)**: The First Rule of ARIA states: *If you can use a native HTML element with the semantics you need, do NOT add ARIA*. Do not write `<div role="button">` when `<button>` exists.
*   **Stripping Focus Outlines (AVOID)**: Never set `outline: none` or `outline-none` without providing a distinct, high-contrast `focus-visible:ring-2` replacement.
*   **Suppressing Autocomplete (AVOID)**: Do not set `autocomplete="off"` on standard inputs (name, email, address) unless required for one-time sensitive security tokens.

---

## 6. Advantages & Disadvantages

| Pattern | React Hook Form + Zod + Semantic HTML | Controlled State (`useState`) + Div Handlers |
| :--- | :--- | :--- |
| **Re-render Overhead** | Minimal; inputs update uncontrolled in DOM. | Full component tree re-renders on every keystroke. |
| **Accessibility** | Native screen reader announcements & keyboard support. | Inaccessible to screen readers and keyboard users. |
| **Validation Schema** | Single source of truth with Zod schema. | Hand-rolled `if` statements scattered across handlers. |
| **Type Safety** | Types automatically inferred from schema. | Disconnected TypeScript interfaces prone to drift. |

---

## 7. Practical Examples

### Bad Example: Non-Semantic Div Button, Keystroke Re-renders & Inaccessible Errors

```tsx
// BAD: div button, controlled input re-render storms, unlinked inaccessible errors
export function BadForm() {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = () => {
    if (!email.includes('@')) {
      setError('Invalid email'); // HAZARD: Screen reader has no idea an error appeared!
    }
  };

  return (
    <div>
      {/* HAZARD: Missing label, full re-render on every keystroke */}
      <input
        type="text"
        placeholder="Enter email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        className="outline-none" // HAZARD: Strips focus ring completely!
      />
      {error && <span className="text-red-500">{error}</span>}

      {/* HAZARD: Inoperable by keyboard, invisible to screen readers */}
      <div
        onClick={handleSubmit}
        className="bg-blue-600 text-white p-2 rounded cursor-pointer"
      >
        Submit
      </div>
    </div>
  );
}
```

### Good Example: Semantic HTML, React Hook Form, Zod & Full WCAG Compliance

```tsx
// GOOD: React Hook Form + Zod, semantic labels, focus rings, accessible error links
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// 1. Single Source of Truth Validation Contract
const registrationSchema = z.object({
  fullName: z.string().min(2, 'Full name must be at least 2 characters'),
  email: z.string().email('Please enter a valid email address'),
  acceptTerms: z.literal(true, {
    errorMap: () => ({ message: 'You must accept the terms and conditions' }),
  }),
});

type RegistrationFormData = z.infer<typeof registrationSchema>;

export function RegistrationForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<RegistrationFormData>({
    resolver: zodResolver(registrationSchema),
    defaultValues: {
      fullName: '',
      email: '',
    },
  });

  const onSubmit = async (data: RegistrationFormData) => {
    // Process validated registration data
    console.log('Valid registration payload:', data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="max-w-md space-y-4">
      {/* Full Name Field */}
      <div>
        <label htmlFor="reg-fullname" className="block text-sm font-medium text-foreground">
          Full Name
        </label>
        <input
          id="reg-fullname"
          type="text"
          autoComplete="name"
          aria-invalid={errors.fullName ? 'true' : 'false'}
          aria-describedby={errors.fullName ? 'fullname-error' : undefined}
          {...register('fullName')}
          className="mt-1 block w-full rounded-md border border-input px-3 py-2 text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
        />
        {errors.fullName && (
          <p id="fullname-error" role="alert" className="mt-1 text-sm text-destructive">
            {errors.fullName.message}
          </p>
        )}
      </div>

      {/* Email Field */}
      <div>
        <label htmlFor="reg-email" className="block text-sm font-medium text-foreground">
          Email Address
        </label>
        <input
          id="reg-email"
          type="email"
          autoComplete="email"
          aria-invalid={errors.email ? 'true' : 'false'}
          aria-describedby={errors.email ? 'email-error' : undefined}
          {...register('email')}
          className="mt-1 block w-full rounded-md border border-input px-3 py-2 text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
        />
        {errors.email && (
          <p id="email-error" role="alert" className="mt-1 text-sm text-destructive">
            {errors.email.message}
          </p>
        )}
      </div>

      {/* Checkbox */}
      <div className="flex items-center gap-2">
        <input
          id="reg-terms"
          type="checkbox"
          aria-invalid={errors.acceptTerms ? 'true' : 'false'}
          aria-describedby={errors.acceptTerms ? 'terms-error' : undefined}
          {...register('acceptTerms')}
          className="h-4 w-4 rounded border-input text-primary focus-visible:ring-2 focus-visible:ring-primary"
        />
        <label htmlFor="reg-terms" className="text-sm text-foreground">
          I accept the Terms and Privacy Policy
        </label>
      </div>
      {errors.acceptTerms && (
        <p id="terms-error" role="alert" className="text-sm text-destructive">
          {errors.acceptTerms.message}
        </p>
      )}

      {/* Accessible Submit Button */}
      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-md bg-primary py-2 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      >
        {isSubmitting ? 'Creating Account...' : 'Create Account'}
      </button>
    </form>
  );
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Orphaned Inputs Without Associated `<label>`**:
    *   *Problem*: Relying solely on `placeholder="Email"` means screen reader users and users with cognitive disabilities lose all context the moment typing begins. Placeholders are not labels.
    *   *Remedy*: Always pair inputs with an explicit `<label htmlFor="id">` or wrap the input inside a `<label>`.
2.  **Unannounced Error Messages**:
    *   *Problem*: Displaying validation errors visually without `aria-describedby` or `role="alert"` leaves screen reader users completely unaware of why form submission failed.
    *   *Remedy*: Link errors via `aria-describedby` and mark error paragraphs with `role="alert"`.
3.  **Trapping Keyboard Focus with Nowhere to Exit**:
    *   *Problem*: Opening a modal that prevents `Tab` or `Escape` from navigating away traps keyboard-only users inside an inescapable dead-end.
    *   *Remedy*: Ensure `Escape` closes the modal and focus returns to the initiating trigger button.

---

## 9. Verification Checklist

- [ ] Are all clickable controls implemented with `<button>` or `<a>` with a valid `href`?
- [ ] Does every form input have an explicitly linked `<label htmlFor="...">`?
- [ ] Are form validation errors linked to inputs via `aria-invalid` and `aria-describedby`?
- [ ] Are validation error text nodes announced to assistive technology via `role="alert"`?
- [ ] Can the entire application flow (including modals, menus, and forms) be operated purely via keyboard?
- [ ] Do all interactive elements display prominent focus rings under `:focus-visible`?
- [ ] Are form schemas validated at runtime using Zod or a formal type-safe validator?
