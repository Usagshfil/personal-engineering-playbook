# Phase 11: Deployment & Release Management

---

## 1. Phase Overview
Deployment & Release Management transitions the thoroughly tested software into an installable production artifact (e.g. signed Android APK/AAB bundle, or web/backend production deployment). It ensures reproducible builds, cryptographically signed binaries, and clear user documentation.

---

## 2. Inputs
*   Verified, tested codebase passing all Phase 10 Quality Gates.
*   Production keystores, signing keys, and environment variables.
*   Release checklist (`08-quality/checklists/09-release-readiness.md`).

---

## 3. Activities
1.  **Release Build Configuration**:
    *   Set production `versionCode` and `versionName` in `build.gradle.kts`.
    *   Enable ProGuard/R8 code shrinking, obfuscation, and resource optimization.
    *   Ensure all debug flags (`DEBUG_LOGS`, test API URLs) are disabled.
2.  **Cryptographic Binary Signing**: Sign release artifacts (APK or Android App Bundle `.aab`) using the private release keystore via secure environment injection (never hardcoded in Gradle).
3.  **Smoke Testing the Production Artifact**: Install the signed release APK directly onto a clean, physical device to verify that R8 shrinking did not break runtime reflection or JSON parsing.
4.  **Changelog & Release Notes Generation**: Compile human-readable release notes summarizing new features, fixes, and improvements.
5.  **Tagging in Version Control**: Create an annotated, immutable Git release tag (e.g., `git tag -a v1.0.0 -m "Release v1.0.0"`).

---

## 4. Expected Outputs
*   Signed production binary (`app-release.aab` or `app-release.apk`).
*   ProGuard mapping file (`mapping.txt`) archived for crash de-obfuscation.
*   Annotated Git release tag pushed to remote.

---

## 5. Deliverables
*   Production Binary Artifacts.
*   `16-deployment-guide.md` (using template `07-templates/16-deployment-guide.md`).
*   `CHANGELOG.md` updated for the release version.
*   Release Tag in Git.

---

## 6. Completion Criteria (Exit Gate)

- [ ] Does the signed release build execute cleanly on a physical device without crashing?
- [ ] Is R8 code shrinking enabled and verified against JSON serialization models?
- [ ] Are keystores, passwords, and signing keys securely injected via environment/keystore?
- [ ] Has an immutable Git tag matching the release version been created?
- [ ] Has the Pre-Release Gate checklist passed 100%?
