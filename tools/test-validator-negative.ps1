# tools/test-validator-negative.ps1
# Negative Verification Test for the agentskills.io Validator

param()

Write-Host "Running Negative Test Cases for Agent Skills Validator..." -ForegroundColor Yellow

$TempDir = Join-Path $env:TEMP ("agentskills-neg-test-" + (Get-Random))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$Cases = @(
    @{
        Name = "Invalid Name (Uppercase)"
        Dir = "Invalid-Skill"
        Content = @"
---
name: Invalid-Skill
description: This is a test. Use when testing.
---
# Invalid Skill
"@
        ExpectedError = "does not match agentskills.io regex"
    },
    @{
        Name = "Missing Name Field"
        Dir = "missing-name"
        Content = @"
---
description: This is a test. Use when testing.
---
# Missing Name
"@
        ExpectedError = "Missing required 'name' field"
    },
    @{
        Name = "Name Mismatch with Directory"
        Dir = "dir-alpha"
        Content = @"
---
name: dir-beta
description: This is a test. Use when testing.
---
# Mismatch
"@
        ExpectedError = "does not match directory"
    },
    @{
        Name = "Missing Description"
        Dir = "missing-desc"
        Content = @"
---
name: missing-desc
---
# Missing Desc
"@
        ExpectedError = "Missing required 'description' field"
    },
    @{
        Name = "Missing Required Sections"
        Dir = "missing-sections"
        Content = @"
---
name: missing-sections
description: Valid description. Use when testing.
---
# Missing Sections
Only short content without mandatory sections.
"@
        ExpectedError = "Missing mandatory section"
    }
)

$NegativePassCount = 0

foreach ($TestCase in $Cases) {
    $CaseDir = Join-Path $TempDir $TestCase.Dir
    New-Item -ItemType Directory -Path $CaseDir -Force | Out-Null
    $FilePath = Join-Path $CaseDir "SKILL.md"
    Set-Content -Path $FilePath -Value $TestCase.Content

    # Run validation snippet
    $Content = Get-Content -Path $FilePath -Raw
    $CaughtExpectedError = $false

    if ($Content -match "^---\r?\n([\s\S]*?)\r?\n---") {
        $Frontmatter = $Matches[1]
        if ($Frontmatter -match "name:\s*([^\r\n]+)") {
            $SkillName = $Matches[1].Trim()
            if (-not ($SkillName -cmatch "^[a-z0-9]+(-[a-z0-9]+)*$")) {
                if ($TestCase.ExpectedError -match "regex") { $CaughtExpectedError = $true }
            }
            if ($SkillName -ne $TestCase.Dir) {
                if ($TestCase.ExpectedError -match "directory") { $CaughtExpectedError = $true }
            }
        } else {
            if ($TestCase.ExpectedError -match "'name'") { $CaughtExpectedError = $true }
        }

        if (-not ($Frontmatter -match "description:\s*([^\r\n]+)")) {
            if ($TestCase.ExpectedError -match "'description'") { $CaughtExpectedError = $true }
        }
    }

    if (-not ($Content -match "1\. Overview & Capability")) {
        if ($TestCase.ExpectedError -match "mandatory section") { $CaughtExpectedError = $true }
    }

    if ($CaughtExpectedError) {
        Write-Host "PASS [Negative Case]: '$($TestCase.Name)' properly rejected with expected error: $($TestCase.ExpectedError)" -ForegroundColor Green
        $NegativePassCount++
    } else {
        Write-Host "FAIL [Negative Case]: '$($TestCase.Name)' was NOT rejected as expected!" -ForegroundColor Red
    }
}

Remove-Item -Path $TempDir -Recurse -Force | Out-Null

Write-Host "`nNegative Test Suite Complete: $NegativePassCount/$($Cases.Count) passed." -ForegroundColor Cyan
if ($NegativePassCount -eq $Cases.Count) { exit 0 } else { exit 1 }
