---
name: git-and-version-control
description: Manage Git branching strategies, Conventional Commits, atomic changesets, pull request descriptions, release tagging, and clean commit history. Use when committing code, preparing branches, or managing version control workflows.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: devops-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Git and Version Control Skill

## 1. Overview & Capability
The **Git and Version Control Skill** guides the disciplined management of source code repositories. It enforces **Trunk-Based Feature Branching**, **Conventional Commits**, **Atomic Commits**, and **Semantic Version Tagging**, ensuring that Git history remains a clean, readable audit trail of the project's evolution.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Staging and authoring Git commits for feature additions or bug fixes.
*   Naming and managing feature, bugfix, or release branches.
*   Drafting Pull Request titles and descriptions.
*   Creating release tags (`v1.0.0`) in version control.

### When NOT to Use
*   Writing application code (use `coding-and-implementation`).
*   Running unit tests (use `testing-and-qa`).

---

## 3. Required Inputs & Prerequisites
*   Clean Git working tree (`git status`).
*   Completed and verified code modifications.
*   Issue or task reference from `PROJECT_PROGRESS.md`.

---

## 4. Step-by-Step Deterministic Workflow

```
1. Inspect Status & Diff ──> 2. Stage Atomic Changes ──> 3. Author Conventional Commit ──> 4. Branch Management ──> 5. Tag Releases
```

### Step 1: Inspect Status & Review Diff
1.  Run `git status` to identify modified, added, or untracked files.
2.  Run `git diff` to review exact changes line-by-line.
3.  Ensure no temporary scratch files, build outputs (`build/`, `.gradle/`), or `.env` secrets are staged.

### Step 2: Stage Atomic Changes
An **Atomic Commit** represents a single, complete logical change that leaves the repository in a working, compilable state:
*   Do not combine a feature addition and an unrelated refactoring into one commit.
*   Stage specific files: `git add src/main/... src/test/...`.

### Step 3: Author Conventional Commit Message
Follow the **Conventional Commits 1.0.0** specification:
$$\text{<type>}(\text{<optional scope>}): \text{<concise description>}$$
*   **`feat`**: A new feature for the user.
*   **`fix`**: A bug fix.
*   **`refactor`**: Code change that neither fixes a bug nor adds a feature.
*   **`test`**: Adding or correcting tests.
*   **`docs`**: Documentation changes only.
*   **`chore`**: Maintenance, build script, or dependency version updates.

```text
feat(auth): implement token refresh interceptor in OkHttpClient

Automatically requests a fresh access token when encountering HTTP 401 
using stored refresh token in EncryptedSharedPreferences.
Closes #104.
```

### Step 4: Branch Management (Trunk-Based Development)
1.  Branch names: `feat/<short-name>`, `fix/<short-name>`, `chore/<short-name>`.
2.  Keep branch lifespans short (1–3 days) to minimize merge conflicts.

### Step 5: Release Tagging
When completing a milestone release, create an annotated Git tag:
```bash
git tag -a v1.0.0 -m "Release v1.0.0 - Core offline features"
git push origin v1.0.0
```

---

## 5. Expected Outputs & Artifact Formats
*   Clean, linear Git commit history.
*   Annotated Git tags matching SemVer versions.
*   Structured Pull Request summaries.

---

## 6. Quality & Verification Checklist
- [ ] Does `git status` confirm that zero secrets or build artifacts are staged?
- [ ] Does every commit message adhere to the Conventional Commits specification?
- [ ] Is each commit atomic (compilable on its own with passing tests)?
- [ ] Are feature branches short-lived and focused on a single task?
- [ ] Are releases marked with annotated Git tags (`git tag -a`)?

---

## 7. Common Mistakes & Pitfalls
*   **The "WIP" / "Fixed stuff" Commit**: Writing meaningless commit messages that provide zero context when debugging a regression via `git bisect`.
*   **Giant Monolithic Commits**: Bundling 45 files touching 6 unrelated features into a single commit.
*   **Accidental Secret Commits**: Committing `local.properties` or keystores because `.gitignore` was missing.

---

## 8. Real-World Example Walkthrough
**Scenario**: Committing an edge-case bug fix in discount calculation.
1.  *Verify*: `git diff` shows only `DiscountCalculator.kt` and `DiscountCalculatorTest.kt`.
2.  *Test*: `./gradlew test` passes 100%.
3.  *Stage*: `git add app/src/main/.../DiscountCalculator.kt app/src/test/.../DiscountCalculatorTest.kt`.
4.  *Commit*:
    ```bash
    git commit -m "fix(billing): prevent negative total when coupon exceeds order amount"
    ```

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Preceded by `coding-and-implementation` or `debugging`.
*   $\rightarrow$ Followed by `deployment-release` to tag and build the release.

---

## 10. Tool Compatibility & Limitations
*   Antigravity can execute git commands directly in the shell.
*   AI agents must never run destructive git commands (`git reset --hard`, `git push --force`) without explicit user authorization.
