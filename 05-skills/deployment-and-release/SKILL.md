---
name: deployment-and-release
description: Prepare production builds, configure cryptographic binary signing, execute R8 shrinking and obfuscation, verify release checklists, and author user-facing release notes. Use when packaging, releasing, or deploying applications.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: release-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Deployment and Release Skill

## 1. Overview & Capability
The **Deployment and Release Skill** guides the production release pipeline for software applications. It manages version numbering, R8/ProGuard code shrinking and obfuscation, cryptographic binary signing, Pre-Release Gate verification, and user-facing changelog generation.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Preparing an Android APK or App Bundle (`.aab`) for distribution.
*   Incrementing `versionCode` and `versionName` for a new release.
*   Verifying that release binaries are obfuscated and free of debug flags.
*   Executing the formal Pre-Release Gate checklist.

### When NOT to Use
*   Running daily debug builds during local coding (use `coding-and-implementation`).
*   Fixing bugs or writing unit tests (use `debugging` or `testing-and-qa`).

---

## 3. Required Inputs & Prerequisites
*   Verified codebase passing 100% of automated tests.
*   Production release keystore and signing credentials (injected via environment).
*   Pre-Release Gate checklist (`08-quality/gates/pre-release-gate.md`).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Version Bump ──> 2. Security & Config Check ──> 3. Production Build & Sign ──> 4. Physical Device Smoke Test ──> 5. Tag & Publish
```

### Step 1: Version Number Increment
In `build.gradle.kts`:
*   Increment `versionCode`: Integer incremented monotonically (+1).
*   Increment `versionName`: SemVer string (`MAJOR.MINOR.PATCH`).

### Step 2: Security & Configuration Audit
Verify production hardening settings:
1.  Confirm `isMinifyEnabled = true` (R8 shrinking/obfuscation enabled).
2.  Confirm `isShrinkResources = true` (unused assets removed).
3.  Confirm `android:usesCleartextTraffic="false"` in manifest.
4.  Confirm `android:allowBackup="false"` in manifest.
5.  Confirm all debug logging interceptors are stripped or disabled.

### Step 3: Production Build & Cryptographic Signing
Execute release build command:
```bash
./gradlew bundleRelease
# or for direct APK install testing:
./gradlew assembleRelease
```
*   Signing credentials must be read from environment variables or `local.properties`, **NEVER hardcoded in Gradle scripts**.
*   Archive the ProGuard mapping file (`mapping.txt`) to allow de-obfuscating crash reports in Firebase Crashlytics.

### Step 4: Smoke Test on Physical Hardware
**Rule**: Never publish a release without testing the exact signed release artifact on a real physical phone.
1.  Install signed release APK onto a physical Android device.
2.  Verify that R8 shrinking did not break runtime JSON serialization or Room entities.
3.  Test critical user journeys (Login, Data Entry, Offline Sync).

### Step 5: Changelog & Release Tagging
1.  Compile user-facing release notes into `CHANGELOG.md`.
2.  Tag commit with `git tag -a v1.0.0 -m "Release v1.0.0"`.
3.  Update `PROJECT_PROGRESS.md` to mark milestone `Completed`.

---

## 5. Expected Outputs & Artifact Formats
*   Signed production bundle (`app-release.aab` or `app-release.apk`).
*   Archived `mapping.txt` obfuscation map.
*   Updated `CHANGELOG.md` and `16-deployment-guide.md`.
*   Annotated Git tag.

---

## 6. Quality & Verification Checklist
- [ ] Are `versionCode` and `versionName` incremented properly?
- [ ] Is R8 code shrinking and obfuscation enabled on the release build?
- [ ] Are release signing credentials kept out of Git and injected via environment?
- [ ] Has the signed release binary been smoke-tested on a physical device?
- [ ] Is the ProGuard `mapping.txt` file safely archived for crash de-obfuscation?

---

## 7. Common Mistakes & Pitfalls
*   **Releasing Debug Builds**: Releasing an APK with `isDebuggable = true`, allowing anyone to attach a debugger to inspect memory.
*   **Testing Only Debug Builds**: Assuming that because the debug APK worked, the release APK works. R8 shrinking frequently strips classes required by reflection or JSON serialization if keep-rules are missing.
*   **Losing the Keystore**: Storing the release keystore in a temporary directory without a secure offsite backup. Losing the keystore permanently prevents updating the app on Google Play.

---

## 8. Real-World Example Walkthrough
**Scenario**: Shipping Version 1.1.0 of the Android Task Tracker.
1.  *Gradle*: `versionCode = 2`, `versionName = "1.1.0"`.
2.  *Build*: Run `./gradlew assembleRelease`.
3.  *Test*: Install `app-release.apk` on Google Pixel device via `adb install`.
4.  *Verification*: Verify task creation, database persistence, and dark mode toggle.
5.  *Tag*: `git tag -a v1.1.0 -m "Release v1.1.0 - Category tagging and performance improvements"`.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Preceded by `testing-and-qa` and `code-review`.
*   $\rightarrow$ Followed by `lifecycle/12-maintenance.md` to monitor post-release crash telemetry.

---

## 10. Tool Compatibility & Limitations
*   Antigravity can execute Gradle release builds if Android SDK and Java are configured in the environment.
*   Agents must never expose release keystore passwords in terminal logs or conversation text.
