# 05. Web Performance: Core Web Vitals, Code-Splitting & Asset Optimization

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Domain**: Web Frontend Engineering  
> **Target Version**: Core Web Vitals 2024+ (LCP, INP, CLS), Modern Bundlers (Vite / Next.js)

---

## 1. Definition & Core Concept

**Web Performance Engineering** focuses on optimizing the critical user journey to meet Google's **Core Web Vitals (CWV)** thresholds:

1.  **LCP (Largest Contentful Paint)**: Measures perceived loading speed. Marks when the primary hero element or content block is rendered on screen ($\le 2.5\text{s}$).
2.  **INP (Interaction to Next Paint)**: Measures responsiveness and latency to user input. Replaced FID in 2024. Measures how fast the browser renders the next visual frame after a user interaction ($\le 200\text{ms}$).
3.  **CLS (Cumulative Layout Shift)**: Measures visual stability. Quantifies unexpected layout movements that cause users to misclick ($\le 0.1$).

```
+-------------------------------------------------------------------------+
| Core Web Vitals Targets & Strategies                                    |
|                                                                         |
| LCP <= 2.5s  ===> Server render HTML, preload hero image (fetchpriority)|
| INP <= 200ms ===> Yield main thread, useTransition, zero long tasks (>50ms)
| CLS <= 0.1   ===> Explicit image dimensions, reserve space, font-display|
+-------------------------------------------------------------------------+
```

### Measurement Methodology & Conditions
To avoid hallucinated performance passes, Core Web Vitals must be interpreted in their empirical measurement context:
*   **The 75th Percentile Rule (p75)**: A site passes a Core Web Vital metric only if at least **75% of page visits** achieve the "Good" threshold. Averaging metrics is invalid; the 75th percentile of real users determines compliance.
*   **Field Data (RUM / CrUX) vs. Laboratory Data (Lighthouse)**:
    *   *Lab Data (Lighthouse / DevTools)*: Synthetic, reproducible testing on simulated throttled CPU/network. Crucial for pre-commit regression checks.
    *   *Field Data (CrUX / Real User Monitoring)*: Real-world user telemetry collected across actual browsers, devices, and cellular connections. Field data is the **authoritative arbiter** of Core Web Vitals compliance.
*   **Mobile Segmentation Primacy**: Always audit mobile devices separately. High-end developer laptops with Gigabit fiber will hide main-thread blocking tasks and resource contention that cripple mobile users.

---

## 2. Purpose

The purpose of this standard is to ensure web applications load instantly, respond smoothly to user input without interface freezing, avoid jarring layout shifts, and maintain high search engine rankings and conversion rates.

---

## 3. Why It Matters

*   **User Retention & Bounce Rates**: Studies consistently demonstrate that an increase of 100ms in load latency decreases conversion rates by up to 7%.
*   **Search Engine Visibility**: Google search algorithms directly penalize pages that fail Core Web Vitals assessments.
*   **Mobile Battery & CPU Preservation**: Heavy JavaScript bundles force mobile processors to spin at maximum capacity, draining user battery and making the browser unresponsive.
*   **Preventing Misclicks**: Unstable layouts (high CLS) cause users to click unintended buttons (e.g. accidentally clicking "Confirm Purchase" instead of "Cancel").

---

## 4. When to Use It

### Normative Engineering Rules (RFC 2119)

*   **Explicit Dimensions for Stability (MUST)**: Developers **MUST** provide explicit `width` and `height` attributes (or CSS `aspect-ratio`) on all `<img>`, `<video>`, and `<iframe>` elements to maintain CLS $\le 0.1$.
*   **Zero Lazy-Loading on LCP Candidates (MUST)**: Developers **MUST NOT** attach `loading="lazy"` to above-the-fold hero images or primary banner content.
*   **Hero Preload with Empirical Verification (SHOULD)**: Preload the LCP candidate using `fetchpriority="high"`. *Note*: `fetchpriority` is an optimization tool, not an automatic fix; its effectiveness **MUST** be verified in Chrome DevTools Network Waterfall.
*   **Input Responsiveness with `useTransition` (SHOULD)**: Wrap non-urgent state updates in `useTransition` or `startTransition` to keep user keystrokes and clicks responsive (INP $\le 200\text{ms}$). The effect **MUST** be verified using the Performance Profiler to confirm elimination of Long Tasks (>50ms).
*   **Container Space Reservation (SHOULD)**: Reserve minimum container heights (`min-h-[...]` or skeleton loaders) for dynamically injected content (banners, comments, advertisements).
*   **Dynamic Code-Splitting (SHOULD)**: Code-split heavy dependencies (charts, rich-text editors, video players) via `dynamic()` or `React.lazy()` so they load on demand.
*   **Zero-Shift Font Strategy (SHOULD)**: Use `next/font` or `@font-face { font-display: swap; }` paired with size-adjust fallbacks to eliminate Flash of Unstyled Text (FOUT) layout shifts.

---

## 5. When NOT to Use It (Anti-Complexity Limits)

*   **Lazy-Loading Hero Images**: **NEVER** set `loading="lazy"` on above-the-fold hero images or primary banner graphics. Lazy-loading the hero image delays LCP by up to 1–2 seconds.
*   **Over-Splitting Tiny Components**: Do NOT dynamically import small components (\<10KB). The overhead of additional HTTP requests and bundle metadata outweighs the negligible bundle savings.
*   **Micro-Optimizing Trivial Renders**: Do not wrap every callback in `useCallback` or every object in `useMemo`. Focus on expensive computations (>1000 items) or components with deep child subtrees.
*   **Blocking Fonts via Render-Blocking CSS**: Never import Google Fonts via `@import url(...)` inside CSS files. Use modern font loaders with preloading.

---

## 6. Advantages & Disadvantages

| Performance Strategy | Modern CWV Pattern | Legacy / Anti-Pattern |
| :--- | :--- | :--- |
| **Hero Image Loading** | Preload with `fetchpriority="high"`. | Lazy-loaded or buried in CSS `background-image`. |
| **Input Responsiveness** | Yielding main thread with `useTransition`. | Monolithic synchronous loops blocking user input. |
| **Visual Stability** | Reserved aspect ratio containers. | Images loading with 0px height, popping page down. |
| **Bundle Architecture** | Granular route-based dynamic code-splitting. | Monolithic 3MB single-page JavaScript bundle. |

---

## 7. Practical Examples

### Bad Example: Lazy Hero Image, Blocking Main Thread & Shifting Layouts

```tsx
// BAD: Lazy hero image, missing dimensions causing CLS, blocking synchronous calculation
export function BadHeroSection() {
  const [data, setData] = useState<any[]>([]);

  // HAZARD: Heavy synchronous calculation blocks the main thread, destroying INP
  const handleFilter = (filterKey: string) => {
    const start = performance.now();
    while (performance.now() - start < 150) {
      // Artificially blocking main thread for 150ms!
    }
    setData(filterHeavyData(filterKey));
  };

  return (
    <div>
      {/* HAZARD: Lazy loading hero image destroys LCP! Missing width/height causes massive CLS! */}
      <img src="/hero.jpg" loading="lazy" alt="Hero banner" />
      
      {/* Dynamic banner without reserved height causes page to jump down */}
      {data.length === 0 && <div className="p-4">Loading updates...</div>}
    </div>
  );
}
```

### Good Example: Preloaded Hero Image, Non-Blocking Transitions & Reserved Dimensions

```tsx
// GOOD: fetchpriority="high", explicit dimensions, non-blocking transition
import Image from 'next/image';
import { useState, useTransition } from 'react';

export function GoodHeroSection({ bannerUrl }: { bannerUrl: string }) {
  const [filterQuery, setFilterQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const nextValue = e.target.value;
    
    // Urgent update: Keep input typing immediate and responsive (INP <= 200ms)
    setFilterQuery(nextValue);

    // Non-urgent update: Defer heavy filtering calculation to non-blocking transition
    startTransition(() => {
      applyHeavyFilter(nextValue);
    });
  };

  return (
    <section className="space-y-6">
      {/* 
        GOOD: Explicit aspect-ratio reserves space immediately (CLS <= 0.1).
        priority & fetchpriority="high" loads image immediately (LCP <= 2.5s).
      */}
      <div className="relative aspect-[16/9] w-full overflow-hidden rounded-xl bg-muted">
        <Image
          src={bannerUrl}
          alt="Hero Banner"
          fill
          priority // Automatically sets fetchpriority="high" and preloads
          sizes="(max-width: 768px) 100vw, 1200px"
          className="object-cover"
        />
      </div>

      {/* Input field with non-blocking transition */}
      <div className="relative">
        <input
          type="search"
          value={filterQuery}
          onChange={handleInputChange}
          placeholder="Filter catalog..."
          className="w-full px-4 py-2 border rounded-md"
        />
        {isPending && (
          <span className="text-xs text-muted-foreground absolute right-3 top-3">
            Updating...
          </span>
        )}
      </div>

      {/* Skeleton container reserves minimum height to prevent layout shift */}
      <div className="min-h-[200px]">
        {/* Render filtered catalog results */}
      </div>
    </section>
  );
}
```

---

## 8. Common Mistakes & Pitfalls

1.  **Setting `loading="lazy"` on LCP Candidate Images**:
    *   *Problem*: Adding `loading="lazy"` to a hero image prevents the browser from fetching the image until the layout engine calculates its viewport position, adding hundreds of milliseconds of delay to LCP.
    *   *Remedy*: Mark hero images with `priority` or `loading="eager"` and `fetchpriority="high"`.
2.  **Long Tasks Freezing User Clicks (INP Failures)**:
    *   *Problem*: Processing a large array or JSON payload synchronously inside an `onClick` or `onChange` handler freezes the UI, causing taps and keystrokes to feel laggy.
    *   *Remedy*: Wrap non-urgent updates in `startTransition` or chunk processing using `scheduler.yield()`.
3.  **Missing `font-display: swap` or Fallback Metrics Override**:
    *   *Problem*: When custom web fonts load, text suddenly shifts size and position (FOUT), producing noticeable layout shift.
    *   *Remedy*: Use Next.js font optimization (`next/font`) or configure CSS `size-adjust` to match fallback font metrics.

---

## 9. Verification Checklist

- [ ] Does the primary above-the-fold hero image have `priority` or `fetchpriority="high"` (and NOT `loading="lazy"`)?
- [ ] Do all images and video elements specify explicit `width` and `height` or CSS `aspect-ratio`?
- [ ] Are dynamic content areas (ads, comments, async widgets) wrapped in containers with reserved minimum height?
- [ ] Are heavy third-party libraries (charts, editors, date pickers) code-split via dynamic imports?
- [ ] Are non-urgent state updates wrapped in `startTransition` to protect input responsiveness (INP $\le 200\text{ms}$)?
- [ ] Are web fonts hosted locally or loaded via `next/font` with zero-shift fallback metrics?
- [ ] Does Chrome Lighthouse or WebPageTest report green passes for LCP ($\le 2.5\text{s}$), INP ($\le 200\text{ms}$), and CLS ($\le 0.1$)?
