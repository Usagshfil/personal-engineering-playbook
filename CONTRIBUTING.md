# Contributing to the Personal Software Engineering Playbook

This playbook is your lifelong engineering knowledge base. It is designed to grow, adapt, and refine as your software development experience deepens and technologies evolve.

---

## Core Guiding Principles for Changes

1. **Maintain Universal Core Purity**: 
   * Never insert technology-specific syntax (e.g. Kotlin code, React hooks, SQL dialect quirks) into Tier 1 Universal Core modules (`01-principles/`, `02-lifecycle/`, `03-architecture/`, `10-security-and-privacy/`).
   * Tier 1 must remain true whether developing an embedded C system, an Android mobile app, or a distributed cloud microservice.
2. **Preserve the 9-Part Pedagogical Schema**:
   * Every major engineering standard in `01-principles/`, `03-architecture/`, and `10-security-and-privacy/` must adhere to the 9 educational components (Definition, Purpose, Why It Matters, When to Use, When NOT to Use, Trade-Offs, Good/Bad Examples, Common Mistakes, Verification Checklist).
3. **Guard Against Overengineering (KISS & YAGNI)**:
   * Always state *when a pattern introduces unnecessary complexity*. Never recommend architectural overhead without explicit trigger conditions.
4. **Follow Agent Skills Specification**:
   * Any new skill in `05-skills/` must follow the open [agentskills.io](https://agentskills.io/) standard with valid YAML frontmatter.

---

## Step-by-Step Change Workflow

```
1. Identify Gap / Lesson Learned (from project work or study)
   │
   ▼
2. Evaluate Layer (Is it Universal Core, Technology Extension, or Project-Specific?)
   │
   ▼
3. Draft Change in a Local Branch or Staging Directory
   │
   ▼
4. Verify Internal Links & Cross-References
   │
   ▼
5. Update CHANGELOG.md (under [Unreleased] or new version)
   │
   ▼
6. Update VERSION.md if SemVer bump is warranted
```

---

## Rule Change Impact Assessment

Before modifying any existing rule in Level 1 (Universal Core):
*   **What changed?** Clearly summarize the rule update.
*   **Why did it change?** What real-world failure or insight justified the change?
*   **Which projects are affected?** Are existing repositories in danger of violating new constraints?
*   **Is migration required?** Do existing projects need configuration updates?
