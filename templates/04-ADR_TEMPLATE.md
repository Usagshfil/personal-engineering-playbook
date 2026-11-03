# ADR-[Number]: [Short Title of Architectural Decision]

> **Status**: Proposed / Accepted / Deprecated / Superseded  
> **Date**: [YYYY-MM-DD]  
> **Deciders**: [Architect, Tech Lead, Engineers]  
> **Consulted**: [Product, Security, SRE]  
> **Informed**: [Engineering Team]  

---

## 1. Context and Problem Statement

*What is the context, architectural problem, business driver, or constraint that requires a decision? What forces (performance, security, cognitive load, cost, deadline) are in tension?*

---

## 2. Decision Drivers

* Driver 1: [e.g. Need for offline-first transactional integrity on mobile devices]
* Driver 2: [e.g. Minimizing operational infrastructure complexity and maintenance cost]
* Driver 3: [e.g. Compliance with statutory consumer tax rounding mandates (HMRC / EU VAT)]
* Driver 4: [e.g. Developer productivity and maintainability for an intermediate team]

---

## 3. Considered Options

* **Option 1**: [Option Title / Technology Choice]
* **Option 2**: [Option Title / Technology Choice]
* **Option 3**: [Option Title / Technology Choice]

---

## 4. Decision Outcome

**Chosen Option**: **Option [X] — [Title]**, because:
1. [Core technical rationale 1]
2. [Core technical rationale 2]
3. [Core technical rationale 3]

### Positive Consequences
* [Advantage 1: e.g. Eliminates race conditions via database-level serialization]
* [Advantage 2: e.g. Zero external cloud infrastructure needed for local offline mode]

### Negative Consequences / Trade-offs
* [Drawback 1: e.g. Slightly higher initial code verbosity due to explicit DTO mapping]
* [Drawback 2: e.g. Requires team training on structured concurrency cancellation]

---

## 5. Pros and Cons of Considered Options

### Option 1: [Option Name]
* *Description*: [Brief overview of option]
* **Good**: [Advantage]
* **Bad**: [Disadvantage / Reason rejected]

### Option 2: [Option Name]
* *Description*: [Brief overview of option]
* **Good**: [Advantage]
* **Bad**: [Disadvantage / Reason rejected]

---

## 6. Implementation Notes & Verification Checklist

- [ ] Updated architecture diagrams and technical documentation.
- [ ] Added automated test harness verifying the architectural invariant.
- [ ] Documented migration path for legacy code.
