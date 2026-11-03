---
name: ui-ux-engineering
description: Design navigation flows, wireframes, component design systems, 4 UI states (Loading, Empty, Content, Error), responsive layouts, and accessibility (a11y). Use when designing or restructuring user interfaces, screens, or Jetpack Compose UI.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: frontend-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# UI/UX Engineering Skill

## 1. Overview & Capability
The **UI/UX Engineering Skill** guides the visual, structural, and behavioral design of user interfaces. It creates intuitive user navigation flows, tokenized design systems, responsive layouts, and ensures all four fundamental UI states (Loading, Empty, Content, Error) and mobile accessibility standards (WCAG AA) are rigorously met.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Designing new screens, user navigation paths, or dialogue flows.
*   Authoring or refactoring Jetpack Compose UI components.
*   Establishing a Design System (Material 3 Theme, colors, typography, shapes).
*   Conducting accessibility audits (touch targets, contrast, screen readers).

### When NOT to Use
*   Writing business rules, discount calculations, or API calls (use `coding-and-implementation`).
*   Configuring database tables or network timeouts (use `database-engineering` or `system-architecture`).

---

## 3. Required Inputs & Prerequisites
*   User stories and acceptance criteria from `requirement-engineering`.
*   Target design system baseline (e.g. Material Design 3).
*   Brand tokens (colors, logo, typography).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Navigation Flow Mapping ──> 2. The 4 UI States Modeling ──> 3. Responsive Layout Design ──> 4. a11y & Contrast Audit ──> 5. Pure Composable Specs
```

### Step 1: Navigation Flow Mapping
1.  Diagram all screen destinations and transitions (Mermaid flowchart).
2.  Define navigation arguments (prefer passing IDs rather than complex serialized objects).
3.  Design backstack behavior (e.g. popping login screen off backstack after authentication).

### Step 2: Model the 4 UI States
Every interactive screen must explicitly define designs for:
1.  **Loading State**: Non-blocking shimmer or circular progress indicator.
2.  **Empty State**: Welcoming illustration, clear explanation, and primary call-to-action button (e.g., "No notes yet. Tap + to create one").
3.  **Content State**: Clean, organized display of data with visual hierarchy.
4.  **Error State**: Actionable error message with a prominent "Retry" button.

### Step 3: Responsive & Adaptive Layout Design
1.  Use flexible layout containers (`LazyColumn`, `BoxWithConstraints`).
2.  Support multiple screen sizes (compact phone, foldable, tablet).
3.  Enforce minimum touch targets: **$\ge 48\times 48$ dp** for all clickable elements.

### Step 4: Accessibility (a11y) Verification
1.  Verify color contrast: minimum **4.5:1** for body text and **3:0:1** for large text against background.
2.  Provide meaningful `contentDescription` strings on all non-decorative image icons.
3.  Support dynamic font scaling without text clipping (use `sp` for typography).

### Step 5: Pure UI Component Specification & State Hoisting
1.  Enforce **State Hoisting**: Screen components receive immutable state data models and emit event callbacks.
2.  Ensure zero database calls, network requests, or state container references inside reusable child widgets.
3.  Delegate platform syntax to active Technology Standards:
    *   *Android*: Jetpack Compose pure composables ([`06-technologies/README.md`](../../06-technologies/README.md); consult official Android Compose mental model per interim fallback).
    *   *Web*: React / Web components ([`06-technologies/README.md`](../../06-technologies/README.md); consult official React documentation per interim fallback).

---

## 5. Expected Outputs & Artifact Formats
*   `08-ui-ux-design-document.md` (screen layouts, state mockups).
*   Navigation Graph specification (Mermaid diagram or route declarations).
*   UI theme design tokens (colors, typography, shapes).

---

## 6. Quality & Verification Checklist
- [ ] Are all 4 UI states (Loading, Empty, Content, Error) explicitly designed for every screen?
- [ ] Are all touch targets verified to be at least $48\times 48$ dp?
- [ ] Does text contrast pass WCAG AA ($4.5:1$ ratio) in both Light and Dark themes?
- [ ] Are icons and images annotated with descriptive `contentDescription` for screen readers?
- [ ] Are reusable UI widgets completely decoupled from business logic and ViewModels?

---

## 7. Common Mistakes & Pitfalls
*   **The Blank Screen Trap**: Forgetting to design the Empty State, leaving first-time users looking at an empty white screen with no instructions.
*   **Tiny Click Targets**: Placing a $16\times 16$ dp icon button that is nearly impossible to tap accurately on a physical touchscreen.
*   **Ignoring Dark Mode**: Hardcoding `Color.Black` text so that when the device switches to system dark theme, the text becomes invisible against a black background.

---

## 8. Real-World Example Walkthrough
**Scenario**: Designing the Shopping Cart Screen in Jetpack Compose.
*   *Loading*: 3 skeleton shimmer cards while cart items are fetched from local Room DB.
*   *Empty*: Cart illustration + "Your cart is empty" + "Start Shopping" button navigating to catalog.
*   *Content*: `LazyColumn` of `CartItemRow` composables with price summary card pinned at bottom.
*   *Error*: "Failed to load cart items" banner with a "Retry" button calling `viewModel.retry()`.
*   *a11y*: Delete button has $48\times 48$ dp hit box and `contentDescription = "Remove item from cart"`.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `coding-and-implementation` to write the Jetpack Compose code.
*   $\rightarrow$ Hands off to `testing-and-qa` to verify UI responsiveness and state transitions.

---

## 10. Tool Compatibility & Limitations
*   Compatible across Antigravity, Cursor, and Claude Code.
*   Agents can generate Jetpack Compose layouts, themes, and Mermaid navigation flows.
