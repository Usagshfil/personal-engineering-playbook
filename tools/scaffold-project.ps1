# tools/scaffold-project.ps1
# Interactive CLI Scaffolder for the Personal Software Engineering Playbook
# Specification: 4-Level Instruction Hierarchy & 8-Stage Project Bootstrap Lifecycle

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectName,

    [Parameter(Position = 1)]
    [ValidateSet("android", "web", "backend", "fullstack")]
    [string]$Profile,

    [Parameter(Position = 2)]
    [string]$TargetDir,

    [string]$PackageId,

    [ValidateSet("gitflow", "trunk-based")]
    [string]$DeliveryModel = "gitflow",

    [ValidateSet("none", "supabase", "firebase", "both")]
    [string]$BaaS = "none",

    [switch]$IncludeAgentDocs,

    [switch]$IncludeCodeRabbit,

    [switch]$IncludeMcp,

    [switch]$IncludeMintlify,

    [switch]$Force,

    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Text)
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "   $Text" -ForegroundColor Cyan
    Write-Host "================================================================`n" -ForegroundColor Cyan
}

function Write-SuccessStep {
    param([string]$Text)
    Write-Host "[+] $Text" -ForegroundColor Green
}

function Write-InfoStep {
    param([string]$Text)
    Write-Host "[-] $Text" -ForegroundColor Yellow
}

# Resolve Playbook Root
$PlaybookRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# -----------------------------------------------------------------
# 1. Interactive Parameter Gathering (When executed without flags)
# -----------------------------------------------------------------
if (-not $NonInteractive -and [string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Header "PERSONAL ENGINEERING PLAYBOOK - PROJECT SCAFFOLDER"
    Write-Host "This utility scaffolds a production-grade software project tailored with the"
    Write-Host "Playbook's 4-level instruction hierarchy, AI agent governance, Clean Architecture,"
    Write-Host "Risk-Based Testing, and CI/CD quality gates.`n"

    # 1. Project Name
    while ([string]::IsNullOrWhiteSpace($ProjectName)) {
        $InputName = Read-Host "Enter Project Name (e.g. 'ZenithMobile', 'OrderService')"
        if (-not [string]::IsNullOrWhiteSpace($InputName)) {
            $ProjectName = $InputName.Trim()
        }
    }

    # 2. Project Profile
    if ([string]::IsNullOrWhiteSpace($Profile)) {
        Write-Host "`nSelect Architectural Profile:" -ForegroundColor Cyan
        Write-Host "  1) Android Mobile Client   (Modern Compose, Room SSOT, WorkManager, Version Catalogs, Fastlane) [Recommended for Mobile]"
        Write-Host "  2) Modern Web Frontend     (React 19, TypeScript, Tailwind CSS, Core Web Vitals)"
        Write-Host "  3) Backend API & Services  (Clean Architecture/DDD, PostgreSQL 16, Transactional Outbox, RFC 9457)"
        Write-Host "  4) Distributed Full-Stack  (Multi-tier Mobile/Web + Backend + Persistence with Cross-Domain Harmonization)"
        
        $ProfileChoice = ""
        while ($ProfileChoice -notmatch "^[1-4]$") {
            $ProfileChoice = Read-Host "Choose profile [1-4] (Default: 1)"
            if ([string]::IsNullOrWhiteSpace($ProfileChoice)) { $ProfileChoice = "1" }
        }

        switch ($ProfileChoice) {
            "1" { $Profile = "android" }
            "2" { $Profile = "web" }
            "3" { $Profile = "backend" }
            "4" { $Profile = "fullstack" }
        }
    }

    # 3. Target Directory
    if ([string]::IsNullOrWhiteSpace($TargetDir)) {
        $DefaultDir = "./$($ProjectName.ToLower() -replace '\s+', '-')"
        $InputDir = Read-Host "`nEnter Target Directory (Default: '$DefaultDir')"
        $TargetDir = if ([string]::IsNullOrWhiteSpace($InputDir)) { $DefaultDir } else { $InputDir.Trim() }
    }

    # 4. Package / Module Identifier
    if ([string]::IsNullOrWhiteSpace($PackageId)) {
        $SanitizedName = ($ProjectName.ToLower() -replace '[^a-z0-9]', '')
        $DefaultPackage = if ($Profile -eq "android") { "com.example.$SanitizedName" } else { "@workspace/$SanitizedName" }
        $InputPackage = Read-Host "`nEnter Package/Module ID (Default: '$DefaultPackage')"
        $PackageId = if ([string]::IsNullOrWhiteSpace($InputPackage)) { $DefaultPackage } else { $InputPackage.Trim() }
    }

    # 5. Delivery Model
    Write-Host "`nSelect Version Control & Delivery Workflow:" -ForegroundColor Cyan
    Write-Host "  1) Gitflow Workflow  (Permanent main/develop, transient feature/release/hotfix) [Recommended]"
    Write-Host "  2) Trunk-Based       (Short-lived branches, direct merge to main)"
    $DeliveryChoice = Read-Host "Choose workflow [1-2] (Default: 1)"
    if ($DeliveryChoice -eq "2") { $DeliveryModel = "trunk-based" } else { $DeliveryModel = "gitflow" }

    # 6. Backend-as-a-Service (BaaS) Provider
    Write-Host "`nSelect Backend-as-a-Service (BaaS) Provider:" -ForegroundColor Cyan
    Write-Host "  1) None / Custom API       (Pure offline/local or custom backend) [Default]"
    Write-Host "  2) Supabase                (PostgreSQL 16, Auth, Realtime, RLS, Storage) [Recommended for Booking]"
    Write-Host "  3) Firebase                (Firestore NoSQL, Firebase Auth, FCM Push Notifications)"
    Write-Host "  4) Both (Hybrid)           (Supabase Relational/Auth + Firebase FCM Notifications)"
    $BaaSChoice = Read-Host "Choose BaaS [1-4] (Default: 1)"
    switch ($BaaSChoice) {
        "2" { $BaaS = "supabase" }
        "3" { $BaaS = "firebase" }
        "4" { $BaaS = "both" }
        default { $BaaS = "none" }
    }

    # 7. Optional Tooling & Agent Integrations
    Write-Host "`nSelect Optional Tooling & Agent Integrations:" -ForegroundColor Cyan
    $AgentDocsChoice = Read-Host "  [?] Include Curated Agent Skills & Tech Standards (.agent/skills & docs/standards)? [Y/n] (Default: Y)"
    if ($AgentDocsChoice -notmatch "^[nN]") { $IncludeAgentDocs = $true }

    $CodeRabbitChoice = Read-Host "  [?] Include CodeRabbit AI PR review config (.coderabbit.yaml)? [y/N] (Default: N)"
    if ($CodeRabbitChoice -match "^[yY]") { $IncludeCodeRabbit = $true }

    $McpChoice = Read-Host "  [?] Include Figma & Model Context Protocol (MCP) config (.cursor/mcp.json)? [y/N] (Default: N)"
    if ($McpChoice -match "^[yY]") { $IncludeMcp = $true }

    $MintlifyChoice = Read-Host "  [?] Include static Mintlify documentation site config (docs.json)? [y/N] (Default: N)"
    if ($MintlifyChoice -match "^[yY]") { $IncludeMintlify = $true }
}

# Apply Defaults for Unset Non-Interactive Parameters
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "SampleProject" }
if ([string]::IsNullOrWhiteSpace($Profile)) { $Profile = "android" }
if ([string]::IsNullOrWhiteSpace($TargetDir)) { $TargetDir = "./$($ProjectName.ToLower() -replace '\s+', '-')" }
if ([string]::IsNullOrWhiteSpace($PackageId)) {
    $SanitizedName = ($ProjectName.ToLower() -replace '[^a-z0-9]', '')
    $PackageId = if ($Profile -eq "android") { "com.example.$SanitizedName" } else { "@workspace/$SanitizedName" }
}

# -----------------------------------------------------------------
# 2. Target Path Resolution & Safety Validation
# -----------------------------------------------------------------
$TargetFullPath = [System.IO.Path]::GetFullPath($TargetDir)

Write-Header "SCAFFOLDING PROJECT: $ProjectName"
Write-Host "Target Directory : $TargetFullPath"
Write-Host "Profile          : $Profile"
Write-Host "Package ID       : $PackageId"
Write-Host "Delivery Model   : $DeliveryModel"
Write-Host "BaaS Provider    : $BaaS"
Write-Host "Agent Skills/Docs: $(if ($IncludeAgentDocs) { 'Yes' } else { 'No' })"
Write-Host "CodeRabbit Gate  : $(if ($IncludeCodeRabbit) { 'Yes' } else { 'No' })"
Write-Host "Figma & MCP Stubs: $(if ($IncludeMcp) { 'Yes' } else { 'No' })"
Write-Host "Mintlify Docs    : $(if ($IncludeMintlify) { 'Yes' } else { 'No' })`n"

if (Test-Path $TargetFullPath) {
    $ExistingFiles = Get-ChildItem -Path $TargetFullPath -Force
    if ($ExistingFiles.Count -gt 0 -and -not $Force) {
        Write-Error "Target directory '$TargetFullPath' already exists and is not empty. Pass -Force to overwrite."
        exit 1
    }
} else {
    New-Item -Path $TargetFullPath -ItemType Directory -Force | Out-Null
}

function Ensure-Dir {
    param([string]$Path)
    $Full = Join-Path $TargetFullPath $Path
    if (-not (Test-Path $Full)) {
        New-Item -Path $Full -ItemType Directory -Force | Out-Null
    }
}

function Write-TargetFile {
    param(
        [string]$RelativePath,
        [string]$Content
    )
    $Dest = Join-Path $TargetFullPath $RelativePath
    $Parent = Split-Path $Dest -Parent
    if (-not (Test-Path $Parent)) {
        New-Item -Path $Parent -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $Dest -Value $Content.Trim() -Encoding UTF8
    Write-SuccessStep "Created $RelativePath"
}

# -----------------------------------------------------------------
# 3. Base Scaffolding Common to All Profiles
# -----------------------------------------------------------------
Write-InfoStep "Generating Level 1 Universal Governance & Multi-Agent Configurations..."

# 3.1 AGENTS.md (Universal Core)
$AgentsMdSource = Join-Path $PlaybookRoot "AGENTS.md"
if (Test-Path $AgentsMdSource) {
    Copy-Item -Path $AgentsMdSource -Destination (Join-Path $TargetFullPath "AGENTS.md") -Force
    Write-SuccessStep "Copied AGENTS.md (Level 1 Universal Invariant Core)"
} else {
    Write-Error "Could not find source AGENTS.md at $AgentsMdSource"
    exit 1
}

# 3.2 .agent/PROJECT.md (Level 3 Project Overlay)
$ProfileTechSummary = switch ($Profile) {
    "android" {
        @"
*   **Platform**: Android (Target SDK 35, Min SDK 26)
*   **Language & Tooling**: Kotlin 2.0+, Gradle Version Catalogs (`libs.versions.toml`)
*   **UI Framework**: Jetpack Compose (Material 3), Unidirectional Data Flow (UDF)
*   **Persistence & Sync**: Room Database (SSOT), WorkManager background sync
*   **Dependency Injection**: Dagger Hilt
*   **Testing**: JVM Unit (70%), Compose UI (20%), Roborazzi Screenshots (5%), Maestro E2E (5%)
*   **Reference Standards**: Playbook `06-technologies/android/*` (Guides 01-11)
"@
    }
    "web" {
        @"
*   **Platform**: Modern Web Browser (Evergreen browsers, mobile responsive)
*   **Language & Tooling**: TypeScript 5.6+, Vite, ESLint, Prettier
*   **UI Framework**: React 19, Tailwind CSS, Component-Driven Design
*   **State & Networking**: TanStack Query (Server State), Zustand (Client State), Typed Fetch
*   **Testing**: Vitest unit/integration tests, Playwright E2E flows
*   **Reference Standards**: Playbook `06-technologies/web/*` (Guides 01-06)
"@
    }
    "backend" {
        @"
*   **Platform**: Headless Backend Microservice / REST API
*   **Architecture**: Clean Architecture / DDD (Domain, Application, Infrastructure, Interfaces)
*   **Database & Persistence**: PostgreSQL 16+, Connection Pooling, Transactional Outbox Pattern
*   **API Protocol**: REST over HTTPS, RFC 9457 Problem Details, Idempotency-Key support
*   **Testing**: Unit tests (business logic), Contract tests (Zod/Pydantic), Integration tests (Testcontainers)
*   **Reference Standards**: Playbook `06-technologies/backend/*` and `06-technologies/database/*`
"@
    }
    "fullstack" {
        @"
*   **Architecture**: Distributed Full-Stack Platform (Mobile/Web Client + Backend API + Relational DB)
*   **Cross-Domain Harmonization**: Enforce 4-tier deadline hierarchy and RFC 9457 unified errors
*   **Security & Auth**: Dual-Token Family Rotation with 30s mobile grace period
*   **Reference Standards**: Playbook `06-technologies/CROSS_DOMAIN_CONSISTENCY.md` and all Tier 2 guides
"@
    }
}

$BaaSSummary = switch ($BaaS) {
    "supabase" { "*   **Backend-as-a-Service**: Supabase (PostgreSQL 16, Auth, Realtime Websockets, Row-Level Security)" }
    "firebase" { "*   **Backend-as-a-Service**: Firebase (Firestore NoSQL, Firebase Auth, FCM Push Notifications)" }
    "both"     { "*   **Backend-as-a-Service**: Hybrid (Supabase Relational/Auth SSOT + Firebase FCM Push Notifications)" }
    default    { "*   **Backend-as-a-Service**: None (Offline-First / Custom Backend API)" }
}

$ProjectOverlayContent = @"
# Project Specification: $ProjectName

> **Level 3 Project-Specific Overlay**  
> **Applicability**: Active engineering instructions for AI coding agents operating in this repository.  
> **Instruction Precedence**: Project Rules (Level 3) > Technology Standards (Level 2) > Universal Core (Level 1 Invariant Safety Gate).

---

## 1. Project Overview & Domain Context

*   **Project Name**: $ProjectName
*   **Identifier**: $PackageId
*   **Profile**: $Profile
*   **Delivery Model**: $DeliveryModel (Refer to Playbook Git & Version Control standard)

### Technology Stack Summary
$ProfileTechSummary
$BaaSSummary

---

## 2. Directory Layout & Architectural Boundaries

Refer to Clean Architecture standards. Maintain strict boundary separation:
*   Domain layer contains pure entities and business rules (zero platform/framework dependencies).
*   Data / Infrastructure layer implements repository interfaces and manages network/database adapters.
*   Presentation / Interface layer handles UI rendering, view models, and HTTP controllers.

---

## 3. Active Architectural Invariants

1.  **Verification Integrity (Level 1 Invariant)**: Never claim tests pass without empirical execution logs. Run automated tests before proposing merges.
2.  **Zero Silent Overwrites (Level 1 Invariant)**: Always inspect existing files before writing. Never delete existing functions or docstrings silently.
3.  **Security by Default (Level 1 Invariant)**: Zero hardcoded secrets. Store sensitive values in environment variables or keystores. Never commit credentials.
4.  **Single Source of Truth**: UI components observe observable state streams (Flow/Signals). Writes mutate local storage first, followed by background synchronization.

---

## 4. Operational Commands for AI Agents

*   **Build**: See ``README.md``
*   **Test**: See ``README.md``
*   **Progress Tracking**: Record milestone and task status in ``PROJECT_PROGRESS.md`` using standard taxonomy (``Not Started``, ``In Progress``, ``Blocked``, ``In Review``, ``Completed``).
"@
Write-TargetFile ".agent/PROJECT.md" $ProjectOverlayContent

# 3.3 Multi-Agent Tool Adapters (.cursorrules, CLAUDE.md, .github/copilot-instructions.md)
$CursorRulesContent = @"
# Cursor Rules for $ProjectName

1. ALWAYS adhere to AGENTS.md (Universal Core) and .agent/PROJECT.md (Project Overlay).
2. Universal Safety Gate: Never commit hardcoded secrets, bypass verification, or silently overwrite code.
3. Follow the 8-stage delivery lifecycle. When making non-trivial changes, draft an Implementation Plan.
4. Code Style: Keep functions concise, enforce strict typing, use immutable data models by default.
5. Testing: When fixing a bug, first write a reproducing regression test. Verify all unit tests pass before finishing.
"@
Write-TargetFile ".cursorrules" $CursorRulesContent

$ClaudeMdContent = @"
# Claude Code Project Guidelines: $ProjectName

## Project Governance
- Follow AGENTS.md (Level 1 Universal Core) and .agent/PROJECT.md (Level 3 Project Overlay).
- Instruction hierarchy: Project Rules > Tech Standards > Universal Safety Invariants.

## Engineering Workflow
1. Inspect before modifying: Read existing files and understand module architecture.
2. Plan before multi-file implementation: Propose scope, target files, and risks.
3. Verify empirically: Run local test commands and inspect logs. Never assume code compiles.
4. Security: Check for hardcoded secrets, validate all inputs at system boundaries.

## Key Files
- Governance: ``AGENTS.md``, ``.agent/PROJECT.md``
- Operational Progress: ``PROJECT_PROGRESS.md``
- Technical Design: ``docs/TECHNICAL_DESIGN.md``
"@
Write-TargetFile "CLAUDE.md" $ClaudeMdContent

$CopilotInstructionsContent = @"
# GitHub Copilot Instructions for $ProjectName

- Adhere to the core universal engineering principles declared in AGENTS.md.
- Ensure all generated code is accompanied by unit tests covering edge cases and error states.
- Do not introduce new external libraries or dependencies without explicit architectural justification.
- Ensure secrets, tokens, API keys, and credentials are never placed in source code.
"@
Write-TargetFile ".github/copilot-instructions.md" $CopilotInstructionsContent

# 3.4 Operational Progress Tracking (PROJECT_PROGRESS.md)
$ProjectProgressContent = @"
# Project Progress & Operational Status Tracking: $ProjectName

> **Standard Status Taxonomy**: ``Not Started`` | ``In Progress`` | ``Blocked`` | ``In Review`` | ``Completed``  
> **Playbook Version**: 1.0.0-rc.1  
> **Delivery Model**: $DeliveryModel

---

## 1. Milestone Tracking

| Milestone | Scope & Deliverable | Target Date | Status | Lead / Agent |
| :---: | :--- | :---: | :---: | :--- |
| **M1** | Project Discovery, Brief, & Architecture Blueprint | Sprint 1 | ``In Progress`` | Lead Architect |
| **M2** | Core Domain Models, Persistence Harness, & Clean Architecture | Sprint 2 | ``Not Started`` | Coding Agent |
| **M3** | Primary User Flows & Risk-Based Testing Harness | Sprint 3 | ``Not Started`` | Coding / Testing |
| **M4** | Edge Cases, Security Hardening, & Performance Polish | Sprint 4 | ``Not Started`` | Security / QA |
| **M5** | CI/CD Quality Gate, Release Runbook, & Delivery Handover | Sprint 5 | ``Not Started`` | Release Engineer |

---

## 2. Active Sprint Work Items (Backlog)

| Item ID | Title | Assigned Role | Priority | Status | Verification Evidence |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **TASK-01** | Instantiate Project Brief & Requirements Specification | Planning Agent | P1 | ``In Progress`` | ``docs/PROJECT_BRIEF.md`` |
| **TASK-02** | Establish Technical Design & Architecture Decision Record | Architecture Agent | P1 | ``Not Started`` | ``docs/TECHNICAL_DESIGN.md`` |
| **TASK-03** | Verify CI Quality Gate Pipeline | Release Agent | P2 | ``Not Started`` | ``.github/workflows/ci.yml`` |

---

## 3. Risk Register & Impediments

| Risk ID | Description | Severity | Mitigation Strategy | Owner |
| :---: | :--- | :---: | :--- | :--- |
| **R-01** | Scope expansion beyond initial MVP boundary | Medium | Enforce MoSCoW prioritization in ``docs/PROJECT_BRIEF.md`` | Planning Agent |
| **R-02** | Architectural drift from unverified AI code | High | Enforce Verification Integrity and peer reviews | Lead Dev |
"@
Write-TargetFile "PROJECT_PROGRESS.md" $ProjectProgressContent

# 3.5 Project Planning & Documentation Templates (docs/)
$ProjectBriefContent = (Get-Content -Path (Join-Path $PlaybookRoot "templates/01-PROJECT_BRIEF_TEMPLATE.md") -Raw) `
    -replace "\[Project Name\]", $ProjectName
Write-TargetFile "docs/PROJECT_BRIEF.md" $ProjectBriefContent

$RequirementsSpecContent = (Get-Content -Path (Join-Path $PlaybookRoot "templates/02-REQUIREMENTS_SPEC_TEMPLATE.md") -Raw) `
    -replace "\[Project Name\]", $ProjectName
Write-TargetFile "docs/REQUIREMENTS_SPEC.md" $RequirementsSpecContent

$TechnicalDesignContent = (Get-Content -Path (Join-Path $PlaybookRoot "templates/03-TECHNICAL_DESIGN_TEMPLATE.md") -Raw) `
    -replace "\[System Name\]", $ProjectName
Write-TargetFile "docs/TECHNICAL_DESIGN.md" $TechnicalDesignContent

$AdrContent = (Get-Content -Path (Join-Path $PlaybookRoot "templates/04-ADR_TEMPLATE.md") -Raw) `
    -replace "\[Short Title of Decision\]", "Adopt Clean Architecture & $Profile Standards" `
    -replace "\[YYYY-MM-DD\]", (Get-Date -Format "yyyy-MM-dd")
Write-TargetFile "docs/adr/0001-initial-architecture.md" $AdrContent

# 3.6 Standard .gitignore & .env.example
$BaaSGitIgnore = ""
if ($BaaS -in "supabase", "both") {
    $BaaSGitIgnore += @"

# Supabase Local State
supabase/.temp/
.supabase/
"@
}
if ($BaaS -in "firebase", "both") {
    $BaaSGitIgnore += @"

# Firebase Credentials & Local Emulators (NEVER COMMIT)
google-services.json
GoogleService-Info.plist
firebase-adminsdk*.json
.firebase/
"@
}

$GitIgnoreContent = @"
# Secrets & Credentials (NEVER COMMIT)
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.jks
*.keystore
local.properties
credentials.json
secrets.xml$BaaSGitIgnore

# IDE & Editor Configuration
.idea/
.vscode/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# Build Artifacts & Dependencies
node_modules/
dist/
build/
.gradle/
*.class
*.apk
*.aab
target/
bin/
obj/
coverage/
.nyc_output/
.turbo/
"@
Write-TargetFile ".gitignore" $GitIgnoreContent

$BaaSEnvContent = ""
if ($BaaS -in "supabase", "both") {
    $BaaSEnvContent += @"

# Supabase Credentials (Template)
# Use public anon key on mobile clients; NEVER distribute service_role key to clients!
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
"@
}
if ($BaaS -in "firebase", "both") {
    $BaaSEnvContent += @"

# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
"@
}

$EnvExampleContent = @"
# Environment Variables Template for $ProjectName
# Copy this file to .env and replace placeholders with real local secrets.
# NEVER commit the active .env file to version control.

APP_ENV=development
APP_PORT=8080
LOG_LEVEL=debug

# API & Service Configuration
API_BASE_URL=https://api.example.com/v1
API_TIMEOUT_MS=5000

# Security Secrets (Dummy Placeholders)
APP_SECRET_KEY=change_me_to_a_secure_random_64_character_string$BaaSEnvContent
"@
Write-TargetFile ".env.example" $EnvExampleContent

# -----------------------------------------------------------------
# 4. Profile-Specific Scaffolding
# -----------------------------------------------------------------
Write-InfoStep "Generating Profile-Specific Architecture ($Profile)..."

switch ($Profile) {
    "android" {
        $PackageDir = $PackageId -replace '\.', '/'
        Ensure-Dir "app/src/main/java/$PackageDir/core"
        Ensure-Dir "app/src/main/java/$PackageDir/data/local"
        Ensure-Dir "app/src/main/java/$PackageDir/data/remote"
        Ensure-Dir "app/src/main/java/$PackageDir/data/repository"
        Ensure-Dir "app/src/main/java/$PackageDir/domain/model"
        Ensure-Dir "app/src/main/java/$PackageDir/domain/repository"
        Ensure-Dir "app/src/main/java/$PackageDir/presentation"
        Ensure-Dir "app/src/main/java/$PackageDir/sync"
        Ensure-Dir "app/src/test/java/$PackageDir"
        Ensure-Dir "app/src/androidTest/java/$PackageDir"
        Ensure-Dir "gradle"
        Ensure-Dir "fastlane"

        # Version Catalogs
        $LibsVersionsToml = @"
[versions]
agp = "8.7.2"
kotlin = "2.0.21"
coreKtx = "1.15.0"
lifecycleRuntimeKtx = "2.8.7"
activityCompose = "1.9.3"
composeBom = "2024.10.01"
room = "2.6.1"
workManager = "2.9.1"
hilt = "2.52"
ksp = "2.0.21-1.0.28"
junit = "4.13.2"
junitVersion = "1.2.1"
espressoCore = "3.6.1"
roborazzi = "1.29.0"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-lifecycle-runtime-ktx = { group = "androidx.lifecycle", name = "lifecycle-runtime-ktx", version.ref = "lifecycleRuntimeKtx" }
androidx-activity-compose = { group = "androidx.activity", name = "activity-compose", version.ref = "activityCompose" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-ui = { group = "androidx.compose.ui", name = "ui" }
androidx-ui-graphics = { group = "androidx.compose.ui", name = "ui-graphics" }
androidx-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
androidx-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }
androidx-material3 = { group = "androidx.compose.material3", name = "material3" }
androidx-room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
androidx-room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
androidx-room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }
androidx-work-runtime-ktx = { group = "androidx.work", name = "work-runtime-ktx", version.ref = "workManager" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-compiler", version.ref = "hilt" }
junit = { group = "junit", name = "junit", version.ref = "junit" }
androidx-junit = { group = "androidx.test.ext", name = "junit", version.ref = "junitVersion" }
androidx-espresso-core = { group = "androidx.test.espresso", name = "espresso-core", version.ref = "espressoCore" }
androidx-compose-ui-test-junit4 = { group = "androidx.compose.ui", name = "ui-test-junit4" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
hilt-android = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
room = { id = "androidx.room", version.ref = "room" }
"@
        Write-TargetFile "gradle/libs.versions.toml" $LibsVersionsToml

        # App build.gradle.kts
        $BuildGradleContent = @"
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt.android)
    alias(libs.plugins.room)
}

android {
    namespace = "$PackageId"
    compileSdk = 35

    defaultConfig {
        applicationId = "$PackageId"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
    }
    room {
        schemaDirectory("`$projectDir/schemas")
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)
    implementation(libs.androidx.work.runtime.ktx)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)

    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.ui.tooling)
}
"@
        Write-TargetFile "app/build.gradle.kts" $BuildGradleContent

        # AndroidManifest.xml
        $ManifestContent = @"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="false"
        android:icon="@mipmap/ic_launcher"
        android:label="$ProjectName"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.App">
        <activity
            android:name=".presentation.MainActivity"
            android:exported="true"
            android:theme="@style/Theme.App">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
"@
        Write-TargetFile "app/src/main/AndroidManifest.xml" $ManifestContent

        # Fastlane Fastfile
        $FastfileContent = @"
default_platform(:android)

platform :android do
  desc "Runs all unit tests"
  lane :test do
    gradle(task: "testDebugUnitTest")
  end

  desc "Build signed production Android App Bundle (AAB)"
  lane :build_bundle do
    gradle(task: "bundleRelease")
  end

  desc "Deploy to Internal Testing track"
  lane :deploy_internal do
    test
    build_bundle
    upload_to_play_store(
      track: 'internal',
      aab: 'app/build/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
"@
        Write-TargetFile "fastlane/Fastfile" $FastfileContent

        # Mobile specific docs
        $MobileTestingDoc = @"
# Mobile Testing & QA Strategy: $ProjectName

> Derived from Playbook Standard: ``06-technologies/android/10-mobile-testing-and-qa.md``

## 1. The 4-Tier Mobile Testing Pyramid
*   **70% JVM Unit Tests**: Fast, deterministic business logic, ViewModels, and Room DAOs using Robolectric/In-Memory SQLite.
*   **20% Compose UI Tests**: Semantic node matching with test tags (``Modifier.testTag("...")``).
*   **5% Roborazzi Screenshot Regression**: Pixel-diff regression checks for dark mode, font scaling, and error banners.
*   **5% Maestro Declarative E2E**: Black-box user journeys via readable YAML flows.
"@
        Write-TargetFile "docs/TESTING_STRATEGY.md" $MobileTestingDoc

        # CI Workflow for Android
        $AndroidCiWorkflow = @"
name: Android CI Quality Gate

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v3

      - name: Verify Secret Defense (No Hardcoded Credentials)
        run: |
          echo "Scanning for accidental secret leaks..."
          ! grep -rnE "AIza[0-9A-Za-z-_]{35}|ghp_[0-9A-Za-z]{36}|-----BEGIN PRIVATE KEY-----" app/src/ || exit 1

      - name: Run Unit Tests
        run: ./gradlew testDebugUnitTest --no-daemon

      - name: Build Release Bundle
        run: ./gradlew bundleRelease --no-daemon
"@
        Write-TargetFile ".github/workflows/ci.yml" $AndroidCiWorkflow
    }

    "web" {
        Ensure-Dir "src/components/ui"
        Ensure-Dir "src/features"
        Ensure-Dir "src/hooks"
        Ensure-Dir "src/services"
        Ensure-Dir "src/types"

        $PackageJsonContent = @"
{
  "name": "$($ProjectName.ToLower() -replace '\s+', '-')",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "test": "vitest run"
  },
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@tanstack/react-query": "^5.60.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.5.4"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitejs/plugin-react": "^4.3.4",
    "typescript": "^5.6.3",
    "vite": "^5.4.10",
    "vitest": "^2.1.4",
    "tailwindcss": "^3.4.14",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.47"
  }
}
"@
        Write-TargetFile "package.json" $PackageJsonContent

        $WebCiWorkflow = @"
name: Web CI Quality Gate

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test-and-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run test
      - run: npm run build
"@
        Write-TargetFile ".github/workflows/ci.yml" $WebCiWorkflow
    }

    "backend" {
        Ensure-Dir "src/domain"
        Ensure-Dir "src/application"
        Ensure-Dir "src/infrastructure"
        Ensure-Dir "src/interfaces/http"
        Ensure-Dir "db/migrations"

        $DatabaseDesignDoc = (Get-Content -Path (Join-Path $PlaybookRoot "templates/06-DATABASE_DESIGN_TEMPLATE.md") -Raw) `
            -replace "\[Service / System Name\]", $ProjectName
        Write-TargetFile "docs/DATABASE_DESIGN.md" $DatabaseDesignDoc

        $ApiSpecDoc = (Get-Content -Path (Join-Path $PlaybookRoot "templates/05-API_SPECIFICATION_TEMPLATE.md") -Raw) `
            -replace "\[API / Service Name\]", $ProjectName
        Write-TargetFile "docs/API_SPECIFICATION.md" $ApiSpecDoc

        $InitialMigration = @"
-- db/migrations/0001_initial_schema.sql
-- Baseline schema definition adhering to Playbook Database Engineering standards.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS outbox_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(64) NOT NULL,
    aggregate_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(128) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox_messages (status, created_at) WHERE status = 'PENDING';
"@
        Write-TargetFile "db/migrations/0001_initial_schema.sql" $InitialMigration

        $BackendCiWorkflow = @"
name: Backend CI Quality Gate

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Security Audit
        run: |
          echo "Scanning for credentials..."
          ! grep -rnE "BEGIN PRIVATE KEY|AKIA[0-9A-Z]{16}" src/ || exit 1
"@
        Write-TargetFile ".github/workflows/ci.yml" $BackendCiWorkflow
    }

    "fullstack" {
        Ensure-Dir "apps/mobile"
        Ensure-Dir "apps/web"
        Ensure-Dir "apps/backend"
        Ensure-Dir "packages/shared"
        Ensure-Dir "docs/adr"

        Copy-Item -Path (Join-Path $PlaybookRoot "06-technologies/CROSS_DOMAIN_CONSISTENCY.md") `
                  -Destination (Join-Path $TargetFullPath "docs/CROSS_DOMAIN_CONSISTENCY.md") -Force
        Write-SuccessStep "Copied CROSS_DOMAIN_CONSISTENCY.md (Multi-Tier Harmonization)"
    }
}

# -----------------------------------------------------------------
# 5. Optional Deep Agent Documentation & Skills
# -----------------------------------------------------------------
if ($IncludeAgentDocs) {
    Write-InfoStep "Scaffolding Curated Agent Skills, Personas, Standards & Vibe Coding Playbook..."
    
    # 5.1 Curated Skills (.agent/skills/)
    $CoreSkills = @(
        "coding-and-implementation",
        "testing-and-qa",
        "code-review",
        "debugging",
        "git-and-version-control"
    )
    foreach ($Skill in $CoreSkills) {
        $SourceSkillDir = Join-Path $PlaybookRoot "05-skills/$Skill"
        $DestSkillDir = Join-Path $TargetFullPath ".agent/skills/$Skill"
        if (Test-Path $SourceSkillDir) {
            Ensure-Dir ".agent/skills/$Skill"
            Copy-Item -Path (Join-Path $SourceSkillDir "*") -Destination $DestSkillDir -Recurse -Force
            Write-SuccessStep "Copied .agent/skills/$Skill"
        }
    }

    # 5.2 Specialized Agent Roles (.agent/roles/)
    Ensure-Dir ".agent/roles"
    $CoreRoles = @(
        "coding-agent.md",
        "review-agent.md",
        "testing-agent.md",
        "debugging-agent.md"
    )
    foreach ($Role in $CoreRoles) {
        $SourceRole = Join-Path $PlaybookRoot "04-agents/roles/$Role"
        if (Test-Path $SourceRole) {
            Copy-Item -Path $SourceRole -Destination (Join-Path $TargetFullPath ".agent/roles/$Role") -Force
            Write-SuccessStep "Copied .agent/roles/$Role"
        }
    }

    # 5.3 Embedded Level 2 Technology Standards (docs/standards/<profile>/)
    Ensure-Dir "docs/standards"
    switch ($Profile) {
        "android" {
            Ensure-Dir "docs/standards/android"
            $AndroidGuides = @(
                "01-kotlin-idioms.md",
                "02-jetpack-compose.md",
                "03-coroutines-and-flow.md",
                "04-room-database.md",
                "07-architecture-patterns.md",
                "09-offline-first-and-sync.md",
                "10-mobile-testing-and-qa.md"
            )
            foreach ($Guide in $AndroidGuides) {
                $SourceGuide = Join-Path $PlaybookRoot "06-technologies/android/$Guide"
                if (Test-Path $SourceGuide) {
                    Copy-Item -Path $SourceGuide -Destination (Join-Path $TargetFullPath "docs/standards/android/$Guide") -Force
                }
            }
            Write-SuccessStep "Copied Level 2 Android Tech Standards to docs/standards/android/"
        }
        "web" {
            Ensure-Dir "docs/standards/web"
            $WebGuides = Get-ChildItem -Path (Join-Path $PlaybookRoot "06-technologies/web") -Filter "*.md"
            foreach ($Guide in $WebGuides) {
                Copy-Item -Path $Guide.FullName -Destination (Join-Path $TargetFullPath "docs/standards/web/$($Guide.Name)") -Force
            }
            Write-SuccessStep "Copied Level 2 Web Tech Standards to docs/standards/web/"
        }
        "backend" {
            Ensure-Dir "docs/standards/backend"
            $BackendGuides = Get-ChildItem -Path (Join-Path $PlaybookRoot "06-technologies/backend") -Filter "*.md"
            foreach ($Guide in $BackendGuides) {
                Copy-Item -Path $Guide.FullName -Destination (Join-Path $TargetFullPath "docs/standards/backend/$($Guide.Name)") -Force
            }
            Ensure-Dir "docs/standards/database"
            $DbGuides = Get-ChildItem -Path (Join-Path $PlaybookRoot "06-technologies/database") -Filter "*.md"
            foreach ($Guide in $DbGuides) {
                Copy-Item -Path $Guide.FullName -Destination (Join-Path $TargetFullPath "docs/standards/database/$($Guide.Name)") -Force
            }
            Write-SuccessStep "Copied Level 2 Backend & Database Standards to docs/standards/"
        }
        "fullstack" {
            Ensure-Dir "docs/standards"
            Copy-Item -Path (Join-Path $PlaybookRoot "06-technologies/*") -Destination (Join-Path $TargetFullPath "docs/standards/") -Recurse -Force
            Write-SuccessStep "Copied All Level 2 Tech Standards to docs/standards/"
        }
    }

    # 5.4 Modular Cursor Rules (.cursor/rules/*.mdc)
    Ensure-Dir ".cursor/rules"
    $ArchRuleContent = @"
---
description: Universal Clean Architecture & Safety Rules
globs: **/*
alwaysApply: true
---
# Universal Architecture & Safety Rules
- Adhere strictly to AGENTS.md and .agent/PROJECT.md.
- Never commit credentials, private keys, or API tokens.
- Do not delete or silently overwrite existing functions or tests.
- Always provide automated tests for domain logic and bug fixes.
"@
    Write-TargetFile ".cursor/rules/architecture.mdc" $ArchRuleContent

    if ($Profile -eq "android") {
        $ComposeRuleContent = @"
---
description: Jetpack Compose & UI Best Practices
globs: app/src/main/**/presentation/**/*.kt
alwaysApply: false
---
# Jetpack Compose Best Practices
- Follow Unidirectional Data Flow (UDF) with explicit UiState data classes.
- Use stateless Composables with event lambda callbacks.
- Reference design system colors/typography from Theme.kt (never hardcode hex colors).
- Add Modifier.testTag("...") to all interactive clickables.
- Use remember and derivedStateOf to prevent unnecessary recompositions.
"@
        Write-TargetFile ".cursor/rules/android-compose.mdc" $ComposeRuleContent

        $RoomRuleContent = @"
---
description: Room Database & Offline-First SSOT Rules
globs: app/src/main/**/data/**/*.kt
alwaysApply: false
---
# Room Persistence Rules
- Room is the Single Source of Truth (SSOT). UI observes Room via Flow streams.
- Writes modify Room first (optimistic UI), followed by background sync via WorkManager.
- Keep Room entities immutable (@Entity data class).
- Never expose raw Room entities to the presentation layer; map to domain models.
"@
        Write-TargetFile ".cursor/rules/android-room.mdc" $RoomRuleContent
    }

    # 5.5 Team Vibe Coding Playbook (.agent/VIBE_CODING_PLAYBOOK.md)
    $VibeCodingContent = @'
# Team Vibe Coding Playbook for {{PROJECT_NAME}}

> **Operating Standard for Engineering Teams Using AI Coding Agents**  
> **Playbook Precedence**: Project Rules > Tech Standards > Universal Core Invariants

---

## 1. The 5 Golden Rules of Team Vibe Coding

1. **Interface-First, Vibe-Second**:
   - Define domain models in `:core:model` and repository interfaces in `:core:data` first.
   - Once merged to `develop`, all developers can vibe code UI screens simultaneously without merge conflicts.
2. **Use the 3-Part Prompt Template**:
   - Always supply **[Context]**, **[Task & Boundary]**, and **[Verification]**.
3. **Lock Down Gradle Dependencies**:
   - Agents are forbidden from editing `libs.versions.toml` or `build.gradle.kts` without explicit human authorization.
4. **One Feature Slice Per Chat Session**:
   - Avoid context decay. Start a fresh chat for every distinct ViewModel, Screen, or DAO.
5. **Agent as Pull Request Reviewer**:
   - Run an AI review before opening a PR to catch missing test tags, hardcoded strings, or memory leaks.

---

## 2. The 3-Part Prompt Template

When instructing an agent to implement a feature, use this exact structure:

```text
[CONTEXT]
You are working on {{PROJECT_NAME}} adhering to AGENTS.md and .agent/PROJECT.md.
Read :core:model/<RelevantModel>.kt and :core:designsystem/Theme.kt.

[TASK & BOUNDARY]
Implement <TargetScreen> inside <TargetModule>.
- Follow Unidirectional Data Flow (UDF) with a sealed/data class UiState.
- Constraint: You are ONLY permitted to edit files inside <TargetModule>.
- Do NOT touch Gradle files or other modules.

[VERIFICATION]
Write a JVM unit test for <TargetViewModelTest> verifying all state transitions.
Verify tests pass before proposing completion.
```
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
    Write-TargetFile ".agent/VIBE_CODING_PLAYBOOK.md" $VibeCodingContent
}

# -----------------------------------------------------------------
# 6. Optional CodeRabbit Configuration
# -----------------------------------------------------------------
if ($IncludeCodeRabbit) {
    Write-InfoStep "Scaffolding CodeRabbit AI Code Review Configuration..."
    $CodeRabbitYaml = @"
# .coderabbit.yaml - CodeRabbit AI Code Review Configuration for $ProjectName
# Aligned with the Personal Software Engineering Playbook (v1.0.0-rc.1)

version: "2"
language: "en-US"
tone_instructions: "Act as a disciplined, senior software engineering collaborator. Be concise, objective, and pragmatic. Point out security vulnerabilities, performance anti-patterns, and architectural violations."

reviews:
  profile: "assertive"
  request_changes_workflow: false
  high_level_summary: true
  poem: false
  review_status: true
  collapse_walkthrough: false
  auto_review:
    enabled: true
    drafts: false
    base_branches:
      - "main"
      - "develop"

chat:
  auto_reply: true

path_filters:
  - "!build/**"
  - "!**/.gradle/**"
  - "!**/dist/**"
  - "!**/node_modules/**"
  - "!**/*.lock"
  - "!gradle/wrapper/**"

knowledge_base:
  opt_out: false
  learnings:
    scope: "project"

instructions: |
  Review this Pull Request against the following engineering standards:
  1. Universal Safety Gate (Level 1):
     - Zero hardcoded secrets, tokens, private keys, or API credentials.
     - Never bypass verification: require automated unit tests for business logic and bug fixes.
     - Reject silent function deletions or accidental file destruction.
  2. Architecture & Code Quality:
     - Adhere to Clean Architecture layer boundaries defined in .agent/PROJECT.md.
     - Ensure UI state follows Unidirectional Data Flow (UDF) with explicit UiState.
     - Verify that all interactive UI clickables include test tags for automated testing.
     - Check that all network inputs and database queries handle error states gracefully.
"@
    Write-TargetFile ".coderabbit.yaml" $CodeRabbitYaml
}

# -----------------------------------------------------------------
# 7. Optional Model Context Protocol (MCP) & Figma
# -----------------------------------------------------------------
if ($IncludeMcp) {
    Write-InfoStep "Scaffolding Model Context Protocol (MCP) Stubs for Figma & Tools..."
    
    Ensure-Dir ".cursor"
    Ensure-Dir ".claude"

    $CursorMcpJson = @"
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-figma"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "`${FIGMA_ACCESS_TOKEN}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "`${GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "`${DATABASE_URL:-postgresql://localhost:5432/app_db}"]
    }
  }
}
"@
    Write-TargetFile ".cursor/mcp.json" $CursorMcpJson

    $ClaudeMcpJson = @"
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-figma"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "`${FIGMA_ACCESS_TOKEN}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "`${GITHUB_TOKEN}"
      }
    }
  }
}
"@
    Write-TargetFile ".claude/mcp.json" $ClaudeMcpJson

    if ($Profile -eq "android") {
        Ensure-Dir "docs/standards/android"
        $FigmaToComposeDoc = @'
# Figma-to-Compose Implementation Guide: {{PROJECT_NAME}}

> Design System & MCP Translation Workflow

## 1. Connecting Figma via MCP
1. Generate a Figma Personal Access Token in your Figma account settings.
2. Set the environment variable in your terminal or .env:
   `export FIGMA_ACCESS_TOKEN="figd_..."`
3. In Cursor or Claude Code, reference Figma nodes via MCP:
   `@figma https://www.figma.com/design/<file-id>?node-id=1-2`

## 2. Design Token Translation Rules
*   **Colors**: Map Figma color variables directly to `:core:designsystem/Theme.kt` (`MaterialTheme.colorScheme.*`). Never hardcode hex codes in feature Composables.
*   **Typography**: Map Figma text styles to `MaterialTheme.typography.*`.
*   **Spacing**: Use 4dp/8dp grid tokens from `:core:designsystem/Spacing.kt`.
*   **Vector Assets**: Export vector icons from Figma as SVGs, convert to Android Vector Drawables, and place in `app/src/main/res/drawable/`.
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
        Write-TargetFile "docs/standards/android/FIGMA_TO_COMPOSE.md" $FigmaToComposeDoc
    }

    $McpGuideDoc = @'
# Model Context Protocol (MCP) & Tooling Guide: {{PROJECT_NAME}}

## 1. Overview
This project includes pre-configured MCP definitions in `.cursor/mcp.json` and `.claude/mcp.json` enabling AI agents to query external tools:
*   **Figma MCP**: Inspect design files, tokens, and frame layouts.
*   **GitHub MCP**: Query PRs, issue descriptions, and repository context.
*   **PostgreSQL MCP**: Inspect local database schemas, table definitions, and migrations.

## 2. Environment Variables Required
Store these in your local environment or `.env` (NEVER commit credentials):
```bash
export FIGMA_ACCESS_TOKEN="figd_your_personal_access_token"
export GITHUB_TOKEN="ghp_your_github_token"
export DATABASE_URL="postgresql://user:password@localhost:5432/app_db"
```
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
    Write-TargetFile ".agent/TOOLING_AND_MCP_GUIDE.md" $McpGuideDoc
}

# -----------------------------------------------------------------
# 8. Optional Static Documentation Site (Mintlify)
# -----------------------------------------------------------------
if ($IncludeMintlify) {
    Write-InfoStep "Scaffolding Mintlify Documentation Site..."
    $MintlifyDocsJson = @"
{
  "`$schema": "https://mintlify.com/docs.json",
  "theme": "mint",
  "name": "$ProjectName Documentation",
  "colors": {
    "primary": "#0D9373",
    "light": "#10B981",
    "dark": "#047857"
  },
  "navigation": {
    "tabs": [
      {
        "tab": "Docs",
        "groups": [
          {
            "group": "Getting Started",
            "pages": ["index", "docs/PROJECT_BRIEF", "PROJECT_PROGRESS"]
          },
          {
            "group": "Architecture & Specs",
            "pages": ["docs/TECHNICAL_DESIGN", "docs/REQUIREMENTS_SPEC"]
          }
        ]
      }
    ]
  }
}
"@
    Write-TargetFile "docs.json" $MintlifyDocsJson

    $MintlifyIndexMdx = @"
---
title: "$ProjectName Documentation"
sidebarTitle: "Overview"
description: "Architecture, specifications, and delivery documentation for $ProjectName."
---

# $ProjectName Documentation

Welcome to the official developer documentation for **$ProjectName**.

<Columns cols={2}>
  <Card title="Project Brief" icon="rocket" href="/docs/PROJECT_BRIEF">
    Problem statement, scope boundaries, and MoSCoW requirements.
  </Card>
  <Card title="Technical Design" icon="sitemap" href="/docs/TECHNICAL_DESIGN">
    System architecture, Clean Architecture boundaries, and data flow.
  </Card>
  <Card title="Requirements Specification" icon="list-check" href="/docs/REQUIREMENTS_SPEC">
    INVEST user stories with BDD Given-When-Then acceptance criteria.
  </Card>
  <Card title="Project Progress" icon="chart-line" href="/PROJECT_PROGRESS">
    Milestone tracking, active task definitions, and risk register.
  </Card>
</Columns>
"@
    Write-TargetFile "index.mdx" $MintlifyIndexMdx
}

# -----------------------------------------------------------------
# 8.5 Backend-as-a-Service (Supabase & Firebase)
# -----------------------------------------------------------------
if ($BaaS -in "supabase", "both") {
    Write-InfoStep "Scaffolding Supabase PostgreSQL & Realtime Configuration..."
    Ensure-Dir "supabase/migrations"

    $SupabaseMigration = @'
-- 0001_initial_schema.sql
-- Supabase PostgreSQL 16+ Schema for {{PROJECT_NAME}}
-- Compliant with Level 1 Security & Row-Level Security (RLS) standards

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Venues & Courts
CREATE TABLE IF NOT EXISTS venues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS courts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sport_type TEXT NOT NULL DEFAULT 'BADMINTON',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Court Slots
CREATE TABLE IF NOT EXISTS court_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    court_id UUID NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    price_cents INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'HOLD', 'BOOKED')),
    hold_user_id UUID,
    hold_expires_at TIMESTAMPTZ,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_slot_time CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_court_slots_court_start ON court_slots(court_id, start_time);
CREATE INDEX IF NOT EXISTS idx_court_slots_status ON court_slots(status);

-- 4. Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slot_id UUID NOT NULL REFERENCES court_slots(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'CONFIRMED' CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED')),
    total_cents INTEGER NOT NULL,
    payment_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);

-- 5. Atomic Slot Reservation Procedure (OCC + Row-Level Locking)
-- Guarantees atomic 5-minute hold without race conditions or double bookings
CREATE OR REPLACE FUNCTION hold_court_slot(
    p_slot_id UUID,
    p_user_id UUID,
    p_hold_minutes INTEGER DEFAULT 5
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_status TEXT;
    v_hold_expires TIMESTAMPTZ;
BEGIN
    -- Acquire exclusive row lock on slot
    SELECT status, hold_expires_at
    INTO v_current_status, v_hold_expires
    FROM court_slots
    WHERE id = p_slot_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Slot % not found', p_slot_id;
    END IF;

    -- Reclaim slot if available or if existing hold has expired
    IF v_current_status = 'AVAILABLE' OR (v_current_status = 'HOLD' AND v_hold_expires <= NOW()) THEN
        UPDATE court_slots
        SET status = 'HOLD',
            hold_user_id = p_user_id,
            hold_expires_at = NOW() + (p_hold_minutes || ' minutes')::INTERVAL,
            version = version + 1
        WHERE id = p_slot_id;

        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;

-- 6. Row-Level Security (RLS) Invariants
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE courts ENABLE ROW LEVEL SECURITY;
ALTER TABLE court_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public venues read" ON venues FOR SELECT USING (true);
CREATE POLICY "Public courts read" ON courts FOR SELECT USING (true);
CREATE POLICY "Public court slots read" ON court_slots FOR SELECT USING (true);

CREATE POLICY "Users read own bookings" ON bookings
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users insert own bookings" ON bookings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
    Write-TargetFile "supabase/migrations/0001_initial_schema.sql" $SupabaseMigration

    $SupabaseConfig = @'
# Supabase Local Development Configuration for {{PROJECT_NAME}}
[api]
enabled = true
port = 54321
schemas = ["public"]

[db]
port = 54322

[auth]
enabled = true
site_url = "http://localhost:3000"
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
    Write-TargetFile "supabase/config.toml" $SupabaseConfig

    if ($Profile -in "android", "fullstack") {
        Ensure-Dir "docs/standards/android"
        $SupabaseIntegrationDoc = @'
# Supabase Android Integration Standard: {{PROJECT_NAME}}

> Tier 2 Android Technology Standard — Supabase Kotlin Multiplatform Client

## 1. Architectural Role
In this architecture, Supabase serves as the cloud **Single Source of Truth (SSOT)**:
*   **Database**: PostgreSQL 16+ accessed via `postgrest-kt`.
*   **Authentication**: Managed JWT session handling via `gotrue-kt`.
*   **Realtime**: WebSocket live changefeeds via `realtime-kt` for instantaneous slot updates.
*   **Storage**: Asset storage for venue photos via `storage-kt`.

## 2. Dependency Configuration (`libs.versions.toml`)
```toml
[versions]
supabase = "3.1.1"
ktor = "3.0.3"

[libraries]
supabase-bom = { module = "io.github.jan-tennert.supabase:bom", version.ref = "supabase" }
supabase-postgrest = { module = "io.github.jan-tennert.supabase:postgrest-kt" }
supabase-auth = { module = "io.github.jan-tennert.supabase:auth-kt" }
supabase-realtime = { module = "io.github.jan-tennert.supabase:realtime-kt" }
ktor-client-okhttp = { module = "io.ktor:ktor-client-okhttp", version.ref = "ktor" }
```

## 3. Dependency Injection (Hilt)
```kotlin
@Module
@InstallIn(SingletonComponent::class)
object SupabaseModule {

    @Provides
    @Singleton
    fun provideSupabaseClient(): SupabaseClient {
        return createSupabaseClient(
            supabaseUrl = BuildConfig.SUPABASE_URL,
            supabaseKey = BuildConfig.SUPABASE_ANON_KEY
        ) {
            install(Postgrest)
            install(Auth)
            install(Realtime)
        }
    }
}
```

## 4. Atomic Slot Reservation (Calling RPC)
Never execute non-atomic slot updates directly from the client. Always invoke the atomic PostgreSQL stored procedure:

```kotlin
suspend fun holdSlot(slotId: String, userId: String, holdMinutes: Int = 5): Boolean {
    val result = supabase.postgrest.rpc(
        function = "hold_court_slot",
        parameters = buildJsonObject {
            put("p_slot_id", slotId)
            put("p_user_id", userId)
            put("p_hold_minutes", holdMinutes)
        }
    ).decodeAs<Boolean>()
    return result
}
```

## 5. Security Invariant (Level 1 Gate)
*   **Zero Service-Role Key Exposure**: Only distribute `SUPABASE_ANON_KEY` to client apps. The `service_role` key bypasses Row-Level Security and must NEVER be placed in Android code, `.properties`, or version control.
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
        Write-TargetFile "docs/standards/android/SUPABASE_INTEGRATION.md" $SupabaseIntegrationDoc
    }
}

if ($BaaS -in "firebase", "both") {
    Write-InfoStep "Scaffolding Firebase & Firestore Security Rules Configuration..."

    $FirebaseJson = @'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
'@
    Write-TargetFile "firebase.json" $FirebaseJson

    $FirestoreRules = @'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Venues & Courts: Publicly readable, admin write-only
    match /venues/{venueId} {
      allow read: if true;
      allow write: if false;

      match /courts/{courtId} {
        allow read: if true;
        allow write: if false;
      }
    }

    // Court Slots: Publicly readable; reservation requires authentication
    match /court_slots/{slotId} {
      allow read: if true;
      allow update: if isAuthenticated();
      allow create, delete: if false;
    }

    // Bookings: Isolated per authenticated user
    match /bookings/{bookingId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if false;
    }
  }
}
'@
    Write-TargetFile "firestore.rules" $FirestoreRules

    $FirestoreIndexes = @'
{
  "indexes": [],
  "fieldOverrides": []
}
'@
    Write-TargetFile "firestore.indexes.json" $FirestoreIndexes

    if ($Profile -in "android", "fullstack") {
        Ensure-Dir "docs/standards/android"
        $FirebaseIntegrationDoc = @'
# Firebase Android Integration Standard: {{PROJECT_NAME}}

> Tier 2 Android Technology Standard — Firebase Firestore, Auth, and Cloud Messaging (FCM)

## 1. Architectural Role
*   **Firestore**: NoSQL cloud database with real-time snapshot listeners.
*   **Firebase Auth**: OAuth and phone verification provider.
*   **Cloud Messaging (FCM)**: Android push notification delivery engine.

## 2. Dependency Configuration (`libs.versions.toml`)
```toml
[versions]
firebase-bom = "33.7.0"

[libraries]
firebase-bom = { module = "com.google.firebase:firebase-bom", version.ref = "firebase-bom" }
firebase-firestore = { module = "com.google.firebase:firebase-firestore" }
firebase-auth = { module = "com.google.firebase:firebase-auth" }
firebase-messaging = { module = "com.google.firebase:firebase-messaging" }
```

## 3. FCM Push Notification Service
Implement `FirebaseMessagingService` in `:core:network` or `:core:notifications`:
```kotlin
class AppFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        // Send refreshed FCM token to backend/Supabase
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Handle incoming push notification
    }
}
```

## 4. Security & Secret Defense (Level 1 Invariant)
*   `google-services.json` must be excluded from public repositories via `.gitignore`.
*   Never store `firebase-adminsdk*.json` private credentials in mobile client code or Git.
'@.Replace("{{PROJECT_NAME}}", $ProjectName)
        Write-TargetFile "docs/standards/android/FIREBASE_INTEGRATION.md" $FirebaseIntegrationDoc
    }
}

# -----------------------------------------------------------------
# 9. Root README.md
# -----------------------------------------------------------------
$ReadmeContent = @"
# $ProjectName

> **Architecture Profile**: $Profile  
> **Governance Standard**: Personal Software Engineering Playbook (``v1.0.0-rc.1``)  
> **Delivery Model**: $DeliveryModel

---

## 30-Second Quick Start

```bash
# 1. Inspect AI Agent Governance and Invariant Safety Rules
cat AGENTS.md

# 2. Check Operational Status and Milestones
cat PROJECT_PROGRESS.md

# 3. Setup local environment secrets
cp .env.example .env
```

---

## Repository Structure

```
├── .agent/              # Level 3 Project Overlay instructions
├── .github/             # CI/CD workflows and copilot rules
├── docs/                # Architecture, ADRs, and Specifications
├── AGENTS.md            # Level 1 Universal Invariant Core
├── CLAUDE.md            # Claude Code CLI commands and architecture rules
├── .cursorrules         # Cursor IDE configuration
├── PROJECT_PROGRESS.md  # Operational tracking log (Not Started -> Completed)
└── README.md            # Project entry point
```

---

## AI Agent Operating Instructions

This repository is governed by the **4-Level Instruction Hierarchy**:
$$\text{Project Rules (Level 3)} \succ \text{Technology Standards (Level 2)} \succ \text{Universal Engineering Core (Level 1)}$$

*   **Universal Core**: Strictly adhere to ``AGENTS.md``. Verification integrity is mandatory: never claim tests pass without execution logs.
*   **Project Overlay**: Follow ``.agent/PROJECT.md`` for profile-specific conventions and Clean Architecture boundaries.
*   **Before writing code**: Check ``PROJECT_PROGRESS.md`` for the active work item, verify scope boundaries in ``docs/PROJECT_BRIEF.md``, and implement a reproducing regression test for any defect fix.
"@
Write-TargetFile "README.md" $ReadmeContent

# -----------------------------------------------------------------
# 10. Git Initialization & Summary
# -----------------------------------------------------------------
Write-Header "PROJECT SCAFFOLDED SUCCESSFULLY!"
Write-Host "Project Name : $ProjectName" -ForegroundColor Green
Write-Host "Directory    : $TargetFullPath" -ForegroundColor Green
Write-Host "Profile      : $Profile" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. cd $TargetDir"
Write-Host "  2. git init"
if ($DeliveryModel -eq "gitflow") {
    Write-Host "  3. git checkout -b main && git commit --allow-empty -m 'chore: initial commit' && git checkout -b develop"
} else {
    Write-Host "  3. git checkout -b main"
}
Write-Host "  4. Inspect AGENTS.md and .agent/PROJECT.md before prompting AI agents."
Write-Host ""
