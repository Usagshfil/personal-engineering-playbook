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

    # 6. Documentation Platform
    $MintlifyChoice = Read-Host "`nInclude static Mintlify documentation site config? [y/N] (Default: N)"
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
secrets.xml

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
APP_SECRET_KEY=change_me_to_a_secure_random_64_character_string
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
# 5. Optional Static Documentation Site (Mintlify)
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
# 6. Root README.md
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
# 7. Git Initialization & Summary
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
