---
name: technical-documentation
sidebarTitle: "Technical Documentation"
description: Author and maintain living technical documentation, including Software Requirements Specifications (SRS), Architecture Documents (SAD), API references, READMEs, changelogs, and user manuals. Use when creating or updating project documentation.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: documentation-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Technical Documentation Skill

## 1. Overview & Capability
The **Technical Documentation Skill** establishes the workflow for authoring, maintaining, and synchronizing project documentation alongside code development. It ensures documentation remains **accurate, concise, living, and educational**, capturing the rationale and constraints that code cannot express.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Authoring or updating project `README.md`, `CHANGELOG.md`, or `CONTRIBUTING.md`.
*   Creating formal documentation (SRS, SAD, API references, User Manuals) from templates.
*   Writing KDoc/Javadoc contracts for public APIs or reusable library interfaces.
*   Updating `TECHNICAL_DECISIONS.md` or `PROJECT_PROGRESS.md` after architectural changes.

### When NOT to Use
*   Writing inline code comments that restate the obvious (`i++ // increment i`).
*   Writing marketing copy or commercial sales pitches.

---

## 3. Required Inputs & Prerequisites
*   Source code, architecture blueprints, or completed feature PRs.
*   Documentation templates catalog (`07-templates/`).
*   Audience profile (e.g. intermediate developer, API consumer, or end-user).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Identify Audience & Purpose ──> 2. Select Template ──> 3. Document Rationale & Invariants ──> 4. Verify Code Alignment ──> 5. Link Integrity Audit
```

### Step 1: Identify Audience & Purpose
Tailor technical depth to the primary reader:
*   *End User*: Focus on step-by-step tasks, screenshots, and troubleshooting (User Manual).
*   *Fellow Engineer / AI Agent*: Focus on setup commands, architecture diagrams, data flows, and constraints (README, SAD).
*   *External Integrator*: Focus on endpoints, payloads, status codes, and auth headers (API Docs).

### Step 2: Select and Instantiate Standard Template
Choose the corresponding Markdown template from `07-templates/` (e.g., `07-templates/01-project-proposal.md`, `07-templates/13-readme-template.md`).

### Step 3: Document Rationale, Trade-Offs, and Invariants
*   Document **WHY** decisions were made, not just **WHAT** the code does.
*   Explain non-obvious constraints (e.g. why a 200ms delay exists, why a specific SQLite index is needed).
*   Use standard GitHub alerts (`> [!NOTE]`, `> [!WARNING]`, `> [!IMPORTANT]`) to emphasize critical information.

### Step 4: Verify Alignment with Actual Source Code
*   Confirm that method signatures, parameter names, and endpoints in docs match the actual code.
*   Verify that setup and build commands (`./gradlew assembleDebug`) actually execute without error.

### Step 5: Link Integrity & Markdown Formatting Audit
*   Audit all markdown links: verify that relative file links point to existing files.
*   Ensure Mermaid diagrams render cleanly without syntax errors.

---

## 5. Expected Outputs & Artifact Formats
*   Completed templates in `docs/` or repository root.
*   Accurate KDoc/Javadoc in source code.
*   Updated `CHANGELOG.md` following the Keep a Changelog standard.

---

## 6. Quality & Verification Checklist
- [ ] Does the documentation explain the *rationale* behind non-obvious technical decisions?
- [ ] Do all code examples and command lines match actual compilable code?
- [ ] Are all internal file hyperlinks and anchors verified to be working?
- [ ] Is `CHANGELOG.md` updated under the appropriate semantic category (Added, Changed, Fixed)?
- [ ] Are complex architectures visualized using valid Mermaid diagrams?

---

## 7. Common Mistakes & Pitfalls
*   **Stale Documentation**: Updating code but leaving outdated parameter names or old endpoints in docs.
*   **Superficial Documentation**: Restating the code in English without explaining business rules or edge cases.
*   **Broken Hyperlinks**: Renaming a file without updating references across other documents.

---

## 8. Real-World Example Walkthrough
**Task**: Documenting a new REST Authentication Endpoint.
1.  *Template*: Instantiate `07-templates/07-api-documentation.md`.
2.  *Content*: Document `POST /api/v1/auth/login`, request body schema (`username`, `password`), response tokens (`accessToken` 15m, `refreshToken` 30d).
3.  *Error States*: Document 400 Bad Request, 401 Unauthorized, and 429 Too Many Requests.
4.  *Verification*: Verify field names match Kotlin `LoginRequestDto` and `AuthResponseDto`.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Works alongside all skills to maintain living documentation.
*   $\rightarrow$ Hands off to `git-and-version-control` to commit documentation updates alongside code.

---

## 10. Tool Compatibility & Limitations
*   Antigravity, Cursor, and Claude Code can produce high-quality markdown and Mermaid diagrams.
*   Always inspect code files directly to avoid hallucinating parameters in documentation.
