# tools/test-validator-positive.ps1
# Positive Verification Harness for the agentskills.io Validator
# Verifies that valid skills with various formatting structures are correctly accepted.

param()

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   AGENTSKILLS.IO VALIDATOR POSITIVE TEST HARNESS (6 FIXTURES)  " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$TempDir = Join-Path $env:TEMP ("agentskills-pos-test-" + (Get-Random))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$Cases = @(
    @{
        Name = "Standard Valid Skill"
        Dir = "standard-skill"
        Content = @"
---
name: standard-skill
description: Standard valid skill. Use when performing standard tasks.
license: MIT
compatibility: Universal
metadata:
  category: engineering
  version: "1.0.0"
---
# Standard Skill
## 1. Overview & Capability
Valid overview.
## 2. When to Use & When NOT to Use
Valid usage.
## 3. Required Inputs & Prerequisites
Valid inputs.
## 4. Step-by-Step Deterministic Workflow
Valid workflow.
## 5. Expected Outputs & Artifact Formats
Valid outputs.
## 6. Quality & Verification Checklist
Valid checklist.
## 7. Common Mistakes & Pitfalls
Valid mistakes.
## 8. Real-World Example Walkthrough
Valid example.
## 9. Related Skills & Hand-Offs
Valid handoffs.
## 10. Tool Compatibility & Limitations
Valid compatibility.
"@
    },
    @{
        Name = "Valid Multiline Folded Description"
        Dir = "multiline-desc"
        Content = @"
---
name: multiline-desc
description: >
  This is a multiline description that spans across multiple indented lines
  in YAML frontmatter. Use when testing multiline description handling.
license: MIT
---
# Multiline Skill
## 1. Overview & Capability
Overview.
## 2. When to Use & When NOT to Use
Usage.
## 3. Required Inputs & Prerequisites
Inputs.
## 4. Step-by-Step Deterministic Workflow
Workflow.
## 5. Expected Outputs & Artifact Formats
Outputs.
## 6. Quality & Verification Checklist
Checklist.
## 7. Common Mistakes & Pitfalls
Mistakes.
## 8. Real-World Example Walkthrough
Example.
## 9. Related Skills & Hand-Offs
Handoffs.
## 10. Tool Compatibility & Limitations
Compatibility.
"@
    },
    @{
        Name = "Valid Boundary-Length Name (64 Characters)"
        # Exactly 64 characters: 'a-' (2) + 62 'b's = 64
        Dir = "a-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        Content = @"
---
name: a-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
description: Valid 64 character name test. Use when testing maximum boundary.
---
# Boundary Name Skill
## 1. Overview & Capability
Overview.
## 2. When to Use & When NOT to Use
Usage.
## 3. Required Inputs & Prerequisites
Inputs.
## 4. Step-by-Step Deterministic Workflow
Workflow.
## 5. Expected Outputs & Artifact Formats
Outputs.
## 6. Quality & Verification Checklist
Checklist.
## 7. Common Mistakes & Pitfalls
Mistakes.
## 8. Real-World Example Walkthrough
Example.
## 9. Related Skills & Hand-Offs
Handoffs.
## 10. Tool Compatibility & Limitations
Compatibility.
"@
    },
    @{
        Name = "Valid Boundary-Length Description (900+ Characters)"
        Dir = "boundary-desc"
        Content = @"
---
name: boundary-desc
description: Use when validating boundary length descriptions. $("This is valid descriptive content providing deep context for the agent to semantically match. " * 9)
---
# Boundary Description Skill
## 1. Overview & Capability
Overview.
## 2. When to Use & When NOT to Use
Usage.
## 3. Required Inputs & Prerequisites
Inputs.
## 4. Step-by-Step Deterministic Workflow
Workflow.
## 5. Expected Outputs & Artifact Formats
Outputs.
## 6. Quality & Verification Checklist
Checklist.
## 7. Common Mistakes & Pitfalls
Mistakes.
## 8. Real-World Example Walkthrough
Example.
## 9. Related Skills & Hand-Offs
Handoffs.
## 10. Tool Compatibility & Limitations
Compatibility.
"@
    },
    @{
        Name = "Valid Quoted Strings in Frontmatter"
        Dir = "quoted-strings"
        Content = @"
---
name: "quoted-strings"
description: "Properly quoted description string. Use when testing quotes."
license: 'MIT'
---
# Quoted Skill
## 1. Overview & Capability
Overview.
## 2. When to Use & When NOT to Use
Usage.
## 3. Required Inputs & Prerequisites
Inputs.
## 4. Step-by-Step Deterministic Workflow
Workflow.
## 5. Expected Outputs & Artifact Formats
Outputs.
## 6. Quality & Verification Checklist
Checklist.
## 7. Common Mistakes & Pitfalls
Mistakes.
## 8. Real-World Example Walkthrough
Example.
## 9. Related Skills & Hand-Offs
Handoffs.
## 10. Tool Compatibility & Limitations
Compatibility.
"@
    },
    @{
        Name = "Valid Inline Map Metadata"
        Dir = "inline-meta"
        Content = @"
---
name: inline-meta
description: Valid inline metadata map. Use when testing inline JSON-style map.
metadata: {"category": "test-cat", "version": "1.0"}
---
# Inline Meta Skill
## 1. Overview & Capability
Overview.
## 2. When to Use & When NOT to Use
Usage.
## 3. Required Inputs & Prerequisites
Inputs.
## 4. Step-by-Step Deterministic Workflow
Workflow.
## 5. Expected Outputs & Artifact Formats
Outputs.
## 6. Quality & Verification Checklist
Checklist.
## 7. Common Mistakes & Pitfalls
Mistakes.
## 8. Real-World Example Walkthrough
Example.
## 9. Related Skills & Hand-Offs
Handoffs.
## 10. Tool Compatibility & Limitations
Compatibility.
"@
    }
)

$PositivePassCount = 0
$SkillNameRegex = "^[a-z0-9]+(-[a-z0-9]+)*$"
$RequiredSections = @(
    "1. Overview & Capability",
    "2. When to Use & When NOT to Use",
    "3. Required Inputs & Prerequisites",
    "4. Step-by-Step Deterministic Workflow",
    "5. Expected Outputs & Artifact Formats",
    "6. Quality & Verification Checklist",
    "7. Common Mistakes & Pitfalls",
    "8. Real-World Example Walkthrough",
    "9. Related Skills & Hand-Offs",
    "10. Tool Compatibility & Limitations"
)

try {
    foreach ($TestCase in $Cases) {
        $CaseDir = Join-Path $TempDir $TestCase.Dir
        New-Item -ItemType Directory -Path $CaseDir -Force | Out-Null
        $FilePath = Join-Path $CaseDir "SKILL.md"
        Set-Content -Path $FilePath -Value $TestCase.Content

        $Content = Get-Content -Path $FilePath -Raw
        $Errors = @()

        if (-not ($Content -match "^---\r?\n([\s\S]*?)\r?\n---")) {
            $Errors += "Missing YAML frontmatter delimiters"
        } else {
            $Frontmatter = $Matches[1]
            if ([string]::IsNullOrWhiteSpace($Frontmatter)) {
                $Errors += "Empty frontmatter"
            } else {
                # Duplicate keys
                if (([regex]::Matches($Frontmatter, '(?m)^name\s*:')).Count -gt 1) { $Errors += "Duplicate 'name' key" }
                if (([regex]::Matches($Frontmatter, '(?m)^description\s*:')).Count -gt 1) { $Errors += "Duplicate 'description' key" }

                # Name check
                if ($Frontmatter -match "(?m)^name\s*:\s*(.*)$") {
                    $RawName = $Matches[1].Trim()
                    if (($RawName.StartsWith('"') -and -not $RawName.EndsWith('"')) -or
                        ($RawName.StartsWith("'") -and -not $RawName.EndsWith("'"))) {
                        $Errors += "Invalid quoting in name"
                    } else {
                        $SkillName = $RawName.Trim('"', "'").Trim()
                        if ($SkillName.Length -gt 64) { $Errors += "Name > 64 chars" }
                        if (-not ($SkillName -cmatch $SkillNameRegex)) { $Errors += "Name invalid regex" }
                        if ($SkillName -ne $TestCase.Dir) { $Errors += "Name mismatch with dir" }
                    }
                } else {
                    $Errors += "Missing name"
                }

                # Description check
                if ($Frontmatter -match "(?ms)^description\s*:\s*([>|]-?)\s*\r?\n((?:[ \t]+[^\r\n]*\r?\n?)+)") {
                    $Description = ($Matches[2] -split '\r?\n' | ForEach-Object { $_.Trim() }) -join " "
                    $Description = $Description.Trim()
                } elseif ($Frontmatter -match "(?m)^description\s*:\s*(.*)$") {
                    $RawDesc = $Matches[1].Trim()
                    if (($RawDesc.StartsWith('"') -and -not $RawDesc.EndsWith('"')) -or
                        ($RawDesc.StartsWith("'") -and -not $RawDesc.EndsWith("'"))) {
                        $Errors += "Invalid quoting in description"
                    } else {
                        $Description = $RawDesc.Trim('"', "'").Trim()
                    }
                } else {
                    $Description = $null
                }

                if ($null -eq $Description -or $Description.Length -eq 0) {
                    $Errors += "Empty description"
                } elseif ($Description.Length -gt 1024) {
                    $Errors += "Description > 1024 chars (Length: $($Description.Length))"
                }

                # Metadata check
                if ($Frontmatter -match "(?m)^metadata[ \t]*:[ \t]*(.*)$") {
                    $MetaVal = $Matches[1].Trim()
                    if ($MetaVal -ne "" -and -not ($MetaVal.StartsWith("{"))) {
                        $Errors += "Invalid metadata format"
                    }
                }
            }
        }

        foreach ($Sec in $RequiredSections) {
            if (-not ($Content -match [regex]::Escape($Sec))) {
                $Errors += "Missing section: $Sec"
            }
        }

        if ($Errors.Count -eq 0) {
            Write-Host "PASS [Positive Case]: '$($TestCase.Name)' successfully accepted." -ForegroundColor Green
            $PositivePassCount++
        } else {
            Write-Host "FAIL [Positive Case]: '$($TestCase.Name)' was unexpectedly rejected! Errors: $($Errors -join '; ')" -ForegroundColor Red
        }
    }
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force | Out-Null
    }
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Positive Test Suite Complete: $PositivePassCount/$($Cases.Count) passed." -ForegroundColor $(if ($PositivePassCount -eq $Cases.Count) { "Green" } else { "Red" })
Write-Host "================================================================" -ForegroundColor Cyan

if ($PositivePassCount -eq $Cases.Count) { exit 0 } else { exit 1 }
