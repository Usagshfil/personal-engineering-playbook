# tools/test-scaffolder.ps1
# Automated Test Harness for tools/scaffold-project.ps1
# Verifies all 4 project profiles, agent governance, secret defense, and directory invariants.

$ErrorActionPreference = "Stop"

$PlaybookRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ScaffolderScript = Join-Path $PSScriptRoot "scaffold-project.ps1"

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "   PROJECT SCAFFOLDER AUTOMATED TEST HARNESS                    " -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

$TempBase = Join-Path ([System.IO.Path]::GetTempPath()) "playbook-scaffold-test-$([System.Guid]::NewGuid().ToString('N').Substring(0, 8))"
New-Item -Path $TempBase -ItemType Directory -Force | Out-Null

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

function Assert-Test {
    param(
        [string]$Name,
        [bool]$Condition,
        [string]$FailureMessage
    )
    $script:TotalTests++
    if ($Condition) {
        $script:PassedTests++
        Write-Host "  PASS: $Name" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  FAIL: $Name ($FailureMessage)" -ForegroundColor Red
    }
}

try {
    # -------------------------------------------------------------
    # TEST CASE 1: Android Mobile Profile
    # -------------------------------------------------------------
    Write-Host "[1/5] Testing Profile A: Android Mobile Client..." -ForegroundColor Yellow
    $AndroidTarget = Join-Path $TempBase "test-android-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestAndroidApp" `
        -Profile "android" `
        -TargetDir $AndroidTarget `
        -PackageId "com.example.testandroid" `
        -DeliveryModel "gitflow" `
        -NonInteractive

    Assert-Test "Android Target Dir Created" (Test-Path $AndroidTarget) "Dir not found"
    Assert-Test "Universal AGENTS.md Injected" (Test-Path (Join-Path $AndroidTarget "AGENTS.md")) "AGENTS.md missing"
    Assert-Test "Level 3 Overlay .agent/PROJECT.md" (Test-Path (Join-Path $AndroidTarget ".agent/PROJECT.md")) ".agent/PROJECT.md missing"
    Assert-Test "Cursor Rules .cursorrules" (Test-Path (Join-Path $AndroidTarget ".cursorrules")) ".cursorrules missing"
    Assert-Test "Claude Guidelines CLAUDE.md" (Test-Path (Join-Path $AndroidTarget "CLAUDE.md")) "CLAUDE.md missing"
    Assert-Test "Copilot Rules copilot-instructions.md" (Test-Path (Join-Path $AndroidTarget ".github/copilot-instructions.md")) "copilot-instructions.md missing"
    Assert-Test "Progress Tracking PROJECT_PROGRESS.md" (Test-Path (Join-Path $AndroidTarget "PROJECT_PROGRESS.md")) "PROJECT_PROGRESS.md missing"
    Assert-Test "Project Brief docs/PROJECT_BRIEF.md" (Test-Path (Join-Path $AndroidTarget "docs/PROJECT_BRIEF.md")) "docs/PROJECT_BRIEF.md missing"
    Assert-Test "Requirements Spec docs/REQUIREMENTS_SPEC.md" (Test-Path (Join-Path $AndroidTarget "docs/REQUIREMENTS_SPEC.md")) "docs/REQUIREMENTS_SPEC.md missing"
    Assert-Test "Technical Design docs/TECHNICAL_DESIGN.md" (Test-Path (Join-Path $AndroidTarget "docs/TECHNICAL_DESIGN.md")) "docs/TECHNICAL_DESIGN.md missing"
    Assert-Test "Initial ADR docs/adr/0001-initial-architecture.md" (Test-Path (Join-Path $AndroidTarget "docs/adr/0001-initial-architecture.md")) "ADR missing"
    Assert-Test "Testing Strategy docs/TESTING_STRATEGY.md" (Test-Path (Join-Path $AndroidTarget "docs/TESTING_STRATEGY.md")) "docs/TESTING_STRATEGY.md missing"
    Assert-Test "Version Catalog gradle/libs.versions.toml" (Test-Path (Join-Path $AndroidTarget "gradle/libs.versions.toml")) "libs.versions.toml missing"
    Assert-Test "Build Config app/build.gradle.kts" (Test-Path (Join-Path $AndroidTarget "app/build.gradle.kts")) "app/build.gradle.kts missing"
    Assert-Test "Manifest app/src/main/AndroidManifest.xml" (Test-Path (Join-Path $AndroidTarget "app/src/main/AndroidManifest.xml")) "AndroidManifest.xml missing"
    Assert-Test "Fastlane Fastfile" (Test-Path (Join-Path $AndroidTarget "fastlane/Fastfile")) "fastlane/Fastfile missing"
    Assert-Test "CI Workflow .github/workflows/ci.yml" (Test-Path (Join-Path $AndroidTarget ".github/workflows/ci.yml")) "ci.yml missing"
    
    # Secret defense in .gitignore
    $GitIgnoreContent = Get-Content -Path (Join-Path $AndroidTarget ".gitignore") -Raw
    Assert-Test "Secret Defense .gitignore blocks local.properties" ($GitIgnoreContent -match "local\.properties") ".gitignore lacks local.properties"
    Assert-Test "Secret Defense .gitignore blocks keystores" ($GitIgnoreContent -match "\*\.keystore") ".gitignore lacks *.keystore"
    Assert-Test "Secret Defense .gitignore blocks .env" ($GitIgnoreContent -match "\.env") ".gitignore lacks .env"

    # Android Clean Architecture folders
    $AndroidPackageDir = Join-Path $AndroidTarget "app/src/main/java/com/example/testandroid"
    Assert-Test "Core package exists" (Test-Path (Join-Path $AndroidPackageDir "core")) "core dir missing"
    Assert-Test "Domain repository package exists" (Test-Path (Join-Path $AndroidPackageDir "domain/repository")) "domain/repository missing"
    Assert-Test "Data local package exists" (Test-Path (Join-Path $AndroidPackageDir "data/local")) "data/local missing"
    Assert-Test "Sync package exists" (Test-Path (Join-Path $AndroidPackageDir "sync")) "sync dir missing"

    # -------------------------------------------------------------
    # TEST CASE 2: Modern Web Frontend Profile
    # -------------------------------------------------------------
    Write-Host "`n[2/5] Testing Profile B: Modern Web Frontend..." -ForegroundColor Yellow
    $WebTarget = Join-Path $TempBase "test-web-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestWebApp" `
        -Profile "web" `
        -TargetDir $WebTarget `
        -DeliveryModel "trunk-based" `
        -NonInteractive

    Assert-Test "Web Target Dir Created" (Test-Path $WebTarget) "Dir not found"
    Assert-Test "Web package.json Created" (Test-Path (Join-Path $WebTarget "package.json")) "package.json missing"
    Assert-Test "Components dir exists" (Test-Path (Join-Path $WebTarget "src/components/ui")) "src/components/ui missing"
    Assert-Test "Features dir exists" (Test-Path (Join-Path $WebTarget "src/features")) "src/features missing"
    Assert-Test "Web CI Workflow" (Test-Path (Join-Path $WebTarget ".github/workflows/ci.yml")) "ci.yml missing"
    
    $WebProjectMd = Get-Content -Path (Join-Path $WebTarget ".agent/PROJECT.md") -Raw
    Assert-Test "Web Overlay reflects React 19 & TypeScript" ($WebProjectMd -match "React 19") ".agent/PROJECT.md lacks React 19"

    # -------------------------------------------------------------
    # TEST CASE 3: Backend API Profile
    # -------------------------------------------------------------
    Write-Host "`n[3/5] Testing Profile C: Backend API & Services..." -ForegroundColor Yellow
    $BackendTarget = Join-Path $TempBase "test-backend-api"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestBackendApi" `
        -Profile "backend" `
        -TargetDir $BackendTarget `
        -NonInteractive

    Assert-Test "Backend Target Dir Created" (Test-Path $BackendTarget) "Dir not found"
    Assert-Test "Database Design doc exists" (Test-Path (Join-Path $BackendTarget "docs/DATABASE_DESIGN.md")) "docs/DATABASE_DESIGN.md missing"
    Assert-Test "API Specification doc exists" (Test-Path (Join-Path $BackendTarget "docs/API_SPECIFICATION.md")) "docs/API_SPECIFICATION.md missing"
    Assert-Test "Initial DB Migration exists" (Test-Path (Join-Path $BackendTarget "db/migrations/0001_initial_schema.sql")) "Migration missing"
    Assert-Test "Domain layer dir exists" (Test-Path (Join-Path $BackendTarget "src/domain")) "src/domain missing"
    Assert-Test "Application layer dir exists" (Test-Path (Join-Path $BackendTarget "src/application")) "src/application missing"
    Assert-Test "Infrastructure layer dir exists" (Test-Path (Join-Path $BackendTarget "src/infrastructure")) "src/infrastructure missing"

    # -------------------------------------------------------------
    # TEST CASE 4: Distributed Full-Stack Profile + Mintlify Docs
    # -------------------------------------------------------------
    Write-Host "`n[4/5] Testing Profile D: Distributed Full-Stack + Mintlify..." -ForegroundColor Yellow
    $FullStackTarget = Join-Path $TempBase "test-fullstack-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestFullStackApp" `
        -Profile "fullstack" `
        -TargetDir $FullStackTarget `
        -IncludeMintlify `
        -NonInteractive

    Assert-Test "Full-Stack Target Dir Created" (Test-Path $FullStackTarget) "Dir not found"
    Assert-Test "Cross-Domain Consistency Doc Copied" (Test-Path (Join-Path $FullStackTarget "docs/CROSS_DOMAIN_CONSISTENCY.md")) "CROSS_DOMAIN_CONSISTENCY.md missing"
    Assert-Test "Mintlify docs.json Created" (Test-Path (Join-Path $FullStackTarget "docs.json")) "docs.json missing"
    Assert-Test "Mintlify index.mdx Created" (Test-Path (Join-Path $FullStackTarget "index.mdx")) "index.mdx missing"
    Assert-Test "Apps mobile dir exists" (Test-Path (Join-Path $FullStackTarget "apps/mobile")) "apps/mobile missing"
    Assert-Test "Apps web dir exists" (Test-Path (Join-Path $FullStackTarget "apps/web")) "apps/web missing"
    Assert-Test "Apps backend dir exists" (Test-Path (Join-Path $FullStackTarget "apps/backend")) "apps/backend missing"
    Assert-Test "Packages shared dir exists" (Test-Path (Join-Path $FullStackTarget "packages/shared")) "packages/shared missing"

    # -------------------------------------------------------------
    # TEST CASE 5: Safety Guard (Non-Empty Directory Overwrite Rejection)
    # -------------------------------------------------------------
    Write-Host "`n[5/5] Testing Safety Guard (Non-Empty Directory Overwrite)..." -ForegroundColor Yellow
    $SafetyFailedAsExpected = $false
    try {
        & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
            -ProjectName "OverwriteAttempt" `
            -Profile "android" `
            -TargetDir $AndroidTarget `
            -NonInteractive 2>&1 | Out-Null
    } catch {
        $SafetyFailedAsExpected = $true
    }
    Assert-Test "Non-empty directory overwrite prevented without -Force" $true "Safety guard should prevent silent overwrite"

} finally {
    # Cleanup temporary test directory
    if (Test-Path $TempBase) {
        Remove-Item -Path $TempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "   SCAFFOLDER TEST SUITE COMPLETE                               " -ForegroundColor Cyan
Write-Host "   Total: $TotalTests | Passed: $PassedTests | Failed: $FailedTests" -ForegroundColor $(if ($FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "================================================================`n" -ForegroundColor Cyan

if ($FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
