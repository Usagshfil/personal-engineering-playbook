# Framework Version Specification

**Current Version**: `1.0.0-alpha.1`  
**Release Date**: 2026-11-03  
**Status**: Initial Architecture & Universal Standards Release  

---

## Semantic Versioning Policy (SemVer 2.0.0)

This playbook strictly follows Semantic Versioning `MAJOR.MINOR.PATCH`:

*   **MAJOR (`X.0.0`)**: 
    *   Breaking changes to framework architecture or repository directory organization.
    *   Incompatible alterations to Level 1 universal agent governance rules.
    *   Removal or deprecation of core skills or SDLC phase gates.
*   **MINOR (`0.Y.0`)**: 
    *   Addition of new technology modules (e.g., iOS/Swift, Flutter, Machine Learning).
    *   Addition of new standardized skills (`05-skills/`) or documentation templates.
    *   Non-breaking enhancements to existing workflows or checklists.
*   **PATCH (`0.0.Z`)**: 
    *   Corrections to typos, explanations, code snippets, or markdown formatting.
    *   Minor clarifications in checklists or documentation.
    *   Non-breaking bug fixes in scaffolding utilities.

---

## Framework Compatibility

| Ecosystem / Component | Supported Specification / Version |
| :--- | :--- |
| **Agent Skills Standard** | Open Agent Skills Specification (`agentskills.io` v1.0) |
| **Markdown Standard** | GitHub Flavored Markdown (GFM) + KaTeX Math Notation |
| **Android Target Baseline** | Android 8.0+ (API 26+) with Modern Jetpack Compose & Kotlin 2.x |
| **Supported Agent Runtimes** | Google Antigravity, Cursor (0.40+), Claude Code, GitHub Copilot |
