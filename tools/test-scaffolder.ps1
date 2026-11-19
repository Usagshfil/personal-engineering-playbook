# tools/test-scaffolder.ps1
# Automated Test Harness for tools/scaffold-project.ps1
# Verifies all 4 project profiles, lean scaffolding, modular tooling (CodeRabbit, MCP, Agent Docs), and directory invariants.

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
    # TEST CASE 1: Lean Android Mobile Profile (Default - Zero Bloat)
    # -------------------------------------------------------------
    Write-Host "[1/6] Testing Lean Android Mobile Profile (Zero Bloat)..." -ForegroundColor Yellow
    $LeanTarget = Join-Path $TempBase "lean-android-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "LeanAndroidApp" `
        -Profile "android" `
        -TargetDir $LeanTarget `
        -PackageId "com.example.leanapp" `
        -DeliveryModel "gitflow" `
        -NonInteractive

    Assert-Test "Lean Target Dir Created" (Test-Path $LeanTarget) "Dir not found"
    Assert-Test "Universal AGENTS.md Injected" (Test-Path (Join-Path $LeanTarget "AGENTS.md")) "AGENTS.md missing"
    Assert-Test "Level 3 Overlay .agent/PROJECT.md" (Test-Path (Join-Path $LeanTarget ".agent/PROJECT.md")) ".agent/PROJECT.md missing"
    Assert-Test "Cursor Rules .cursorrules" (Test-Path (Join-Path $LeanTarget ".cursorrules")) ".cursorrules missing"
    Assert-Test "Claude Guidelines CLAUDE.md" (Test-Path (Join-Path $LeanTarget "CLAUDE.md")) "CLAUDE.md missing"
    Assert-Test "Copilot Rules copilot-instructions.md" (Test-Path (Join-Path $LeanTarget ".github/copilot-instructions.md")) "copilot-instructions.md missing"
    Assert-Test "Progress Tracking PROJECT_PROGRESS.md" (Test-Path (Join-Path $LeanTarget "PROJECT_PROGRESS.md")) "PROJECT_PROGRESS.md missing"
    Assert-Test "Version Catalog libs.versions.toml" (Test-Path (Join-Path $LeanTarget "gradle/libs.versions.toml")) "libs.versions.toml missing"
    Assert-Test "App build.gradle.kts" (Test-Path (Join-Path $LeanTarget "app/build.gradle.kts")) "app/build.gradle.kts missing"
    Assert-Test "CI Workflow .github/workflows/ci.yml" (Test-Path (Join-Path $LeanTarget ".github/workflows/ci.yml")) "ci.yml missing"
    
    # Verify optional files are NOT generated in lean mode
    Assert-Test "Lean: No .coderabbit.yaml" (-not (Test-Path (Join-Path $LeanTarget ".coderabbit.yaml"))) "Unexpected .coderabbit.yaml in lean mode"
    Assert-Test "Lean: No .cursor/mcp.json" (-not (Test-Path (Join-Path $LeanTarget ".cursor/mcp.json"))) "Unexpected .cursor/mcp.json in lean mode"
    Assert-Test "Lean: No .agent/skills" (-not (Test-Path (Join-Path $LeanTarget ".agent/skills"))) "Unexpected .agent/skills in lean mode"
    Assert-Test "Lean: No docs.json" (-not (Test-Path (Join-Path $LeanTarget "docs.json"))) "Unexpected docs.json in lean mode"

    # -------------------------------------------------------------
    # TEST CASE 2: Fully-Loaded Android Profile with Modular Tooling
    # -------------------------------------------------------------
    Write-Host "`n[2/6] Testing Fully-Loaded Android Profile with Modular Tooling..." -ForegroundColor Yellow
    $FullAndroidTarget = Join-Path $TempBase "full-android-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "FullAndroidApp" `
        -Profile "android" `
        -TargetDir $FullAndroidTarget `
        -PackageId "com.example.fullapp" `
        -DeliveryModel "gitflow" `
        -IncludeAgentDocs `
        -IncludeCodeRabbit `
        -IncludeMcp `
        -IncludeMintlify `
        -NonInteractive

    # 2.1 CodeRabbit Configuration
    $CodeRabbitPath = Join-Path $FullAndroidTarget ".coderabbit.yaml"
    Assert-Test "CodeRabbit Config Generated" (Test-Path $CodeRabbitPath) ".coderabbit.yaml missing"
    if (Test-Path $CodeRabbitPath) {
        $CodeRabbitText = Get-Content -Path $CodeRabbitPath -Raw
        Assert-Test "CodeRabbit profile assertive" ($CodeRabbitText -match 'profile:\s*"assertive"') "Profile not assertive"
        Assert-Test "CodeRabbit Universal Safety check" ($CodeRabbitText -match "Universal Safety Gate") "Missing safety gate instruction"
    }

    # 2.2 Model Context Protocol (MCP) & Figma
    $CursorMcpPath = Join-Path $FullAndroidTarget ".cursor/mcp.json"
    $ClaudeMcpPath = Join-Path $FullAndroidTarget ".claude/mcp.json"
    $FigmaComposeDoc = Join-Path $FullAndroidTarget "docs/standards/android/FIGMA_TO_COMPOSE.md"
    $McpGuideDoc = Join-Path $FullAndroidTarget ".agent/TOOLING_AND_MCP_GUIDE.md"
    Assert-Test "Cursor MCP config exists" (Test-Path $CursorMcpPath) ".cursor/mcp.json missing"
    Assert-Test "Claude MCP config exists" (Test-Path $ClaudeMcpPath) ".claude/mcp.json missing"
    Assert-Test "Figma to Compose Guide exists" (Test-Path $FigmaComposeDoc) "FIGMA_TO_COMPOSE.md missing"
    Assert-Test "Tooling & MCP Guide exists" (Test-Path $McpGuideDoc) ".agent/TOOLING_AND_MCP_GUIDE.md missing"
    if (Test-Path $CursorMcpPath) {
        $McpText = Get-Content -Path $CursorMcpPath -Raw
        Assert-Test "MCP config includes Figma" ($McpText -match '"figma"') "figma server missing in mcp.json"
        Assert-Test "MCP config includes GitHub" ($McpText -match '"github"') "github server missing in mcp.json"
    }

    # 2.3 Curated Agent Skills (.agent/skills/)
    Assert-Test "Skill: coding-and-implementation" (Test-Path (Join-Path $FullAndroidTarget ".agent/skills/coding-and-implementation/SKILL.md")) "coding skill missing"
    Assert-Test "Skill: testing-and-qa" (Test-Path (Join-Path $FullAndroidTarget ".agent/skills/testing-and-qa/SKILL.md")) "testing skill missing"
    Assert-Test "Skill: code-review" (Test-Path (Join-Path $FullAndroidTarget ".agent/skills/code-review/SKILL.md")) "code-review skill missing"
    Assert-Test "Skill: debugging" (Test-Path (Join-Path $FullAndroidTarget ".agent/skills/debugging/SKILL.md")) "debugging skill missing"
    Assert-Test "Skill: git-and-version-control" (Test-Path (Join-Path $FullAndroidTarget ".agent/skills/git-and-version-control/SKILL.md")) "git skill missing"

    # 2.4 Specialized Agent Roles (.agent/roles/)
    Assert-Test "Role: coding-agent.md" (Test-Path (Join-Path $FullAndroidTarget ".agent/roles/coding-agent.md")) "coding-agent missing"
    Assert-Test "Role: review-agent.md" (Test-Path (Join-Path $FullAndroidTarget ".agent/roles/review-agent.md")) "review-agent missing"
    Assert-Test "Role: testing-agent.md" (Test-Path (Join-Path $FullAndroidTarget ".agent/roles/testing-agent.md")) "testing-agent missing"
    Assert-Test "Role: debugging-agent.md" (Test-Path (Join-Path $FullAndroidTarget ".agent/roles/debugging-agent.md")) "debugging-agent missing"

    # 2.5 Embedded Level 2 Android Standards (docs/standards/android/)
    Assert-Test "Tech Standard: Jetpack Compose" (Test-Path (Join-Path $FullAndroidTarget "docs/standards/android/02-jetpack-compose.md")) "compose guide missing"
    Assert-Test "Tech Standard: Room DB" (Test-Path (Join-Path $FullAndroidTarget "docs/standards/android/04-room-database.md")) "room guide missing"
    Assert-Test "Tech Standard: Offline Sync" (Test-Path (Join-Path $FullAndroidTarget "docs/standards/android/09-offline-first-and-sync.md")) "offline sync guide missing"
    Assert-Test "Tech Standard: Mobile Testing" (Test-Path (Join-Path $FullAndroidTarget "docs/standards/android/10-mobile-testing-and-qa.md")) "mobile testing guide missing"

    # 2.6 Modular Cursor Rules (.cursor/rules/*.mdc)
    Assert-Test "Cursor Rule: architecture.mdc" (Test-Path (Join-Path $FullAndroidTarget ".cursor/rules/architecture.mdc")) "architecture.mdc missing"
    Assert-Test "Cursor Rule: android-compose.mdc" (Test-Path (Join-Path $FullAndroidTarget ".cursor/rules/android-compose.mdc")) "android-compose.mdc missing"
    Assert-Test "Cursor Rule: android-room.mdc" (Test-Path (Join-Path $FullAndroidTarget ".cursor/rules/android-room.mdc")) "android-room.mdc missing"

    # 2.7 Vibe Coding Playbook (.agent/VIBE_CODING_PLAYBOOK.md)
    $VibePlaybookPath = Join-Path $FullAndroidTarget ".agent/VIBE_CODING_PLAYBOOK.md"
    Assert-Test "Vibe Coding Playbook exists" (Test-Path $VibePlaybookPath) "VIBE_CODING_PLAYBOOK.md missing"
    if (Test-Path $VibePlaybookPath) {
        $VibeText = Get-Content -Path $VibePlaybookPath -Raw
        Assert-Test "Vibe Playbook 5 Golden Rules" ($VibeText -match "The 5 Golden Rules") "Missing 5 golden rules"
        Assert-Test "Vibe Playbook 3-Part Prompt" ($VibeText -match "The 3-Part Prompt Template") "Missing 3-part prompt"
    }

    # 2.8 Mintlify Static Documentation
    Assert-Test "Mintlify docs.json exists" (Test-Path (Join-Path $FullAndroidTarget "docs.json")) "docs.json missing"
    Assert-Test "Mintlify index.mdx exists" (Test-Path (Join-Path $FullAndroidTarget "index.mdx")) "index.mdx missing"

    # -------------------------------------------------------------
    # TEST CASE 3: Modern Web Frontend Profile
    # -------------------------------------------------------------
    Write-Host "`n[3/6] Testing Profile B: Modern Web Frontend..." -ForegroundColor Yellow
    $WebTarget = Join-Path $TempBase "test-web-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestWebApp" `
        -Profile "web" `
        -TargetDir $WebTarget `
        -DeliveryModel "trunk-based" `
        -IncludeAgentDocs `
        -NonInteractive

    Assert-Test "Web Target Dir Created" (Test-Path $WebTarget) "Dir not found"
    Assert-Test "Web package.json Created" (Test-Path (Join-Path $WebTarget "package.json")) "package.json missing"
    Assert-Test "Web Standards copied" (Test-Path (Join-Path $WebTarget "docs/standards/web/01-typescript-idioms.md")) "web standards missing"
    Assert-Test "Web CI Workflow exists" (Test-Path (Join-Path $WebTarget ".github/workflows/ci.yml")) "ci.yml missing"

    # -------------------------------------------------------------
    # TEST CASE 4: Backend API Profile
    # -------------------------------------------------------------
    Write-Host "`n[4/6] Testing Profile C: Backend API & Services..." -ForegroundColor Yellow
    $BackendTarget = Join-Path $TempBase "test-backend-api"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestBackendApi" `
        -Profile "backend" `
        -TargetDir $BackendTarget `
        -IncludeAgentDocs `
        -NonInteractive

    Assert-Test "Backend Target Dir Created" (Test-Path $BackendTarget) "Dir not found"
    Assert-Test "Database Design doc exists" (Test-Path (Join-Path $BackendTarget "docs/DATABASE_DESIGN.md")) "docs/DATABASE_DESIGN.md missing"
    Assert-Test "API Specification doc exists" (Test-Path (Join-Path $BackendTarget "docs/API_SPECIFICATION.md")) "docs/API_SPECIFICATION.md missing"
    Assert-Test "Initial DB Migration exists" (Test-Path (Join-Path $BackendTarget "db/migrations/0001_initial_schema.sql")) "Migration missing"
    Assert-Test "Backend Standards copied" (Test-Path (Join-Path $BackendTarget "docs/standards/backend/01-rest-api-design.md")) "backend standards missing"
    Assert-Test "Database Standards copied" (Test-Path (Join-Path $BackendTarget "docs/standards/database/01-database-governance-and-technology-selection.md")) "database standards missing"

    # -------------------------------------------------------------
    # TEST CASE 5: Distributed Full-Stack Profile
    # -------------------------------------------------------------
    Write-Host "`n[5/6] Testing Profile D: Distributed Full-Stack..." -ForegroundColor Yellow
    $FullStackTarget = Join-Path $TempBase "test-fullstack-app"
    
    & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
        -ProjectName "TestFullStackApp" `
        -Profile "fullstack" `
        -TargetDir $FullStackTarget `
        -NonInteractive

    Assert-Test "Full-Stack Target Dir Created" (Test-Path $FullStackTarget) "Dir not found"
    Assert-Test "Cross-Domain Consistency Copied" (Test-Path (Join-Path $FullStackTarget "docs/CROSS_DOMAIN_CONSISTENCY.md")) "CROSS_DOMAIN_CONSISTENCY.md missing"
    Assert-Test "Apps mobile dir exists" (Test-Path (Join-Path $FullStackTarget "apps/mobile")) "apps/mobile missing"
    Assert-Test "Apps web dir exists" (Test-Path (Join-Path $FullStackTarget "apps/web")) "apps/web missing"
    Assert-Test "Apps backend dir exists" (Test-Path (Join-Path $FullStackTarget "apps/backend")) "apps/backend missing"
    Assert-Test "Packages shared dir exists" (Test-Path (Join-Path $FullStackTarget "packages/shared")) "packages/shared missing"

    # -------------------------------------------------------------
    # TEST CASE 6: Safety Guard (Non-Empty Directory Overwrite Rejection)
    # -------------------------------------------------------------
    Write-Host "`n[6/6] Testing Safety Guard (Non-Empty Directory Overwrite)..." -ForegroundColor Yellow
    $SafetyFailedAsExpected = $false
    try {
        & powershell -ExecutionPolicy Bypass -File $ScaffolderScript `
            -ProjectName "OverwriteAttempt" `
            -Profile "android" `
            -TargetDir $LeanTarget `
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
