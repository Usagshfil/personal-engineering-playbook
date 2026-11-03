# Code Review Checklist: [PR Title / Feature Name]

> **Pull Request**: #[PR Number]  
> **Author**: [Developer]  
> **Reviewer**: [Peer Engineer / AI Review Agent]  
> **Date**: [YYYY-MM-DD]  
> **Review Outcome**: Approved / Changes Requested / Commented  

---

## 1. Architectural & Design Integrity

- [ ] **Single Responsibility**: Each new class, module, or function has one clear reason to change.
- [ ] **Layering Discipline**: UI does not query database directly; Controllers are thin; Domain logic is decoupled from transport DTOs.
- [ ] **YAGNI & Anti-Overengineering**: No speculative abstractions, unused generic interfaces, or premature caching layers.
- [ ] **ADR Conformance**: Changes align with established Architectural Decision Records.

---

## 2. Code Quality & Idiomatic Standards

- [ ] **Naming Clarity**: Variables, functions, and types clearly communicate intent without misleading abbreviations.
- [ ] **Error Handling**: No empty `catch` blocks or swallowed exceptions; typed domain exceptions thrown.
- [ ] **Boundary Validation**: External inputs parsed using strict schemas (e.g. Zod `.strict()`) before reaching domain.
- [ ] **Immutability by Default**: Use of `val` / `readonly` / `const` wherever possible.
- [ ] **Zero Silent Overwrites**: Unrelated functions, comments, and docstrings preserved intact.

---

## 3. Concurrency, Performance & Resilience

- [ ] **Deadline Propagation**: Timeouts and cancellations (`AbortSignal` / Coroutine cancellation) propagated downstream.
- [ ] **Thread Safety & Race Conditions**: Shared mutable state protected with mutexes, atomic operations, or database row locks.
- [ ] **Resource Cleanup**: Sockets, streams, file handles, and database connections closed via `try-with-resources` / `using` / `finally`.
- [ ] **Database Hygiene**: No unindexed queries (`Seq Scan` on large tables); query parameters parameterized against SQL injection.

---

## 4. Security & Privacy Hygiene

- [ ] **Zero Hardcoded Secrets**: Zero API keys, private tokens, passwords, or credentials in source code.
- [ ] **Object-Level Authorization (BOLA/IDOR)**: Endpoint verifies `subject_id` possesses ownership of target `resource_id`.
- [ ] **PII Redaction**: Passwords, tokens, credit cards, and sensitive identifiers scrubbed from log statements.
- [ ] **Error Information Leakage**: Database engine errors (SQLSTATE, schema names) suppressed from client JSON responses.

---

## 5. Verification & Test Evidence

- [ ] **Reproducing Regression Test**: Bug fix includes a test demonstrating failure before fix and success after fix.
- [ ] **Risk-Based Testing**: Core domain logic, boundary edge cases (`null`, empty, max limits) covered by unit tests.
- [ ] **CI Pass**: All automated CI workflows execute successfully with zero failures.

---

## 6. Review Summary & Action Items

* **Key Strengths**: [What was well executed in this PR?]
* **Required Changes (Blocking)**:
  1. [Action item 1]
* **Suggested Improvements (Non-blocking)**:
  1. [Suggestion 1]
