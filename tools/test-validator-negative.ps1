# tools/test-validator-negative.ps1
# Comprehensive Negative Verification Harness for the agentskills.io Validator
# Verifies that malformed, invalid, or out-of-spec skills are properly rejected.

param()

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   AGENTSKILLS.IO VALIDATOR NEGATIVE TEST HARNESS (17 CASES)    " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$TempDir = Join-Path $env:TEMP ("agentskills-neg-test-" + (Get-Random))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$Cases = @(
    @{
        Name = "Invalid Name (Uppercase)"
        Dir = "Invalid-Skill"
        Content = @"
---
name: Invalid-Skill
description: Valid description. Use when testing uppercase.
---
# Invalid Skill
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "does not match agentskills.io regex"
    },
    @{
        Name = "Invalid Name (Underscores / Snake_Case)"
        Dir = "invalid_snake_case"
        Content = @"
---
name: invalid_snake_case
description: Valid description. Use when testing snake_case.
---
# Invalid Skill
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "does not match agentskills.io regex"
    },
    @{
        Name = "Missing Name Field"
        Dir = "missing-name"
        Content = @"
---
description: Valid description. Use when testing missing name.
---
# Missing Name
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Missing required 'name' field"
    },
    @{
        Name = "Name Mismatch with Directory"
        Dir = "dir-alpha"
        Content = @"
---
name: dir-beta
description: Valid description. Use when testing directory mismatch.
---
# Mismatch
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "does not match directory"
    },
    @{
        Name = "Name Exceeds 64 Characters"
        Dir = "this-is-an-extremely-long-skill-name-that-definitely-exceeds-the-maximum-sixty-four-char-limit-set-by-agentskills"
        Content = @"
---
name: this-is-an-extremely-long-skill-name-that-definitely-exceeds-the-maximum-sixty-four-char-limit-set-by-agentskills
description: Valid description. Use when testing long names.
---
# Long Name
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Name exceeds 64 characters"
    },
    @{
        Name = "Missing Description Field"
        Dir = "missing-desc"
        Content = @"
---
name: missing-desc
---
# Missing Description
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Missing required 'description' field"
    },
    @{
        Name = "Empty Description Field"
        Dir = "empty-desc"
        Content = @"
---
name: empty-desc
description: ""
---
# Empty Description
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Description is empty"
    },
    @{
        Name = "Description Exceeds 1024 Characters"
        Dir = "long-desc"
        Content = @"
---
name: long-desc
description: Use when testing extraordinarily verbose descriptions. $("A" * 1050)
---
# Long Description
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Description exceeds 1024 characters"
    },
    @{
        Name = "Missing Closing Frontmatter Delimiter"
        Dir = "missing-closing-delimiter"
        Content = @"
---
name: missing-closing-delimiter
description: Missing enclosing dashes. Use when testing missing closing delimiter.
# Malformed Frontmatter
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Missing YAML frontmatter delimiters"
    },
    @{
        Name = "Missing Opening Frontmatter Delimiter"
        Dir = "missing-opening-delimiter"
        Content = @"
name: missing-opening-delimiter
description: Missing opening dashes. Use when testing missing opening delimiter.
---
# Malformed Frontmatter
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Missing YAML frontmatter delimiters"
    },
    @{
        Name = "Empty YAML Frontmatter"
        Dir = "empty-frontmatter"
        Content = @"
---
---
# Empty Frontmatter
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Empty YAML frontmatter"
    },
    @{
        Name = "Invalid YAML Quoting in Name"
        Dir = "unclosed-quote-name"
        Content = @"
---
name: "unclosed-quote-name
description: Valid description. Use when testing unclosed quote in name.
---
# Invalid Quote
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Invalid YAML quoting in 'name'"
    },
    @{
        Name = "Invalid YAML Quoting in Description"
        Dir = "unclosed-quote-desc"
        Content = @"
---
name: unclosed-quote-desc
description: "unclosed quote description string. Use when testing.
---
# Invalid Quote Desc
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Invalid YAML quoting in 'description'"
    },
    @{
        Name = "Duplicate YAML Key (name)"
        Dir = "dup-key-name"
        Content = @"
---
name: dup-key-name
name: dup-key-name-second
description: Valid description. Use when testing duplicate key.
---
# Duplicate Key
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Duplicate 'name' key in frontmatter"
    },
    @{
        Name = "Duplicate YAML Key (description)"
        Dir = "dup-key-desc"
        Content = @"
---
name: dup-key-desc
description: First description. Use when testing.
description: Second description. Use when testing.
---
# Duplicate Key
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Duplicate 'description' key in frontmatter"
    },
    @{
        Name = "Incorrect Metadata Value Type (Scalar String)"
        Dir = "scalar-metadata"
        Content = @"
---
name: scalar-metadata
description: Valid description. Use when testing metadata.
metadata: "not-a-map-just-a-string"
---
# Scalar Metadata
## 1. Overview & Capability
## 2. When to Use & When NOT to Use
## 3. Required Inputs & Prerequisites
## 4. Step-by-Step Deterministic Workflow
## 5. Expected Outputs & Artifact Formats
## 6. Quality & Verification Checklist
## 7. Common Mistakes & Pitfalls
## 8. Real-World Example Walkthrough
## 9. Related Skills & Hand-Offs
## 10. Tool Compatibility & Limitations
"@
        ExpectedError = "Invalid metadata format"
    },
    @{
        Name = "Missing Required Mandatory Sections"
        Dir = "missing-sections"
        Content = @"
---
name: missing-sections
description: Valid description. Use when testing missing sections.
---
# Incomplete Skill Content
This document completely lacks the 10 mandatory sections.
"@
        ExpectedError = "Missing mandatory section"
    }
)

$NegativePassCount = 0
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
        $CaughtExpectedError = $false
        $ActualErrors = @()
        $UnexpectedException = $null

        try {
            if (-not ($Content -match "^---\r?\n([\s\S]*?)(?:\r?\n)?---(?:\r?\n|$)")) {
                $ActualErrors += "Missing YAML frontmatter delimiters"
            } else {
                $Frontmatter = $Matches[1]
                if ([string]::IsNullOrWhiteSpace($Frontmatter)) {
                    $ActualErrors += "Empty YAML frontmatter"
                } else {
                    # Duplicate keys
                    if (([regex]::Matches($Frontmatter, '(?m)^name\s*:')).Count -gt 1) {
                        $ActualErrors += "Duplicate 'name' key in frontmatter"
                    }
                    if (([regex]::Matches($Frontmatter, '(?m)^description\s*:')).Count -gt 1) {
                        $ActualErrors += "Duplicate 'description' key in frontmatter"
                    }

                    # Name check
                    if ($Frontmatter -match "(?m)^name\s*:\s*(.*)$") {
                        $RawName = $Matches[1].Trim()
                        if (($RawName.StartsWith('"') -and -not $RawName.EndsWith('"')) -or
                            ($RawName.StartsWith("'") -and -not $RawName.EndsWith("'")) -or
                            ($RawName -eq '"') -or ($RawName -eq "'")) {
                            $ActualErrors += "Invalid YAML quoting in 'name'"
                            $SkillName = ""
                        } else {
                            $SkillName = $RawName.Trim('"', "'").Trim()
                        }

                        if ($SkillName.Length -gt 64) {
                            $ActualErrors += "Name exceeds 64 characters"
                        }
                        if ($SkillName.Length -gt 0 -and -not ($SkillName -cmatch $SkillNameRegex)) {
                            $ActualErrors += "does not match agentskills.io regex"
                        }
                        if ($SkillName.Length -gt 0 -and $SkillName -ne $TestCase.Dir) {
                            $ActualErrors += "does not match directory"
                        }
                    } else {
                        $ActualErrors += "Missing required 'name' field"
                    }

                    # Description check
                    if ($Frontmatter -match "(?ms)^description\s*:\s*([>|]-?)\s*\r?\n((?:[ \t]+[^\r\n]*\r?\n?)+)") {
                        $Description = ($Matches[2] -split '\r?\n' | ForEach-Object { $_.Trim() }) -join " "
                        $Description = $Description.Trim()
                    } elseif ($Frontmatter -match "(?m)^description\s*:\s*(.*)$") {
                        $RawDesc = $Matches[1].Trim()
                        if (($RawDesc.StartsWith('"') -and -not $RawDesc.EndsWith('"')) -or
                            ($RawDesc.StartsWith("'") -and -not $RawDesc.EndsWith("'")) -or
                            ($RawDesc -eq '"') -or ($RawDesc -eq "'")) {
                            $ActualErrors += "Invalid YAML quoting in 'description'"
                            $Description = ""
                        } else {
                            $Description = $RawDesc.Trim('"', "'").Trim()
                        }
                    } else {
                        $Description = $null
                    }

                    if ($null -eq $Description) {
                        $ActualErrors += "Missing required 'description' field"
                    } else {
                        if ($Description.Length -gt 1024) {
                            $ActualErrors += "Description exceeds 1024 characters"
                        }
                        if ($Description.Length -eq 0) {
                            $ActualErrors += "Description is empty"
                        }
                    }

                    # Metadata check
                    if ($Frontmatter -match "(?m)^metadata[ \t]*:[ \t]*(.*)$") {
                        $MetaVal = $Matches[1].Trim()
                        if ($MetaVal -ne "" -and -not ($MetaVal.StartsWith("{"))) {
                            $ActualErrors += "Invalid metadata format"
                        }
                    }
                }
            }

            foreach ($Section in $RequiredSections) {
                if (-not ($Content -match [regex]::Escape($Section))) {
                    $ActualErrors += "Missing mandatory section"
                    break
                }
            }
        }
        catch {
            $UnexpectedException = $_.Exception.Message
        }

        if ($null -ne $UnexpectedException) {
            Write-Host "FAIL [Negative Case]: '$($TestCase.Name)' threw UNEXPECTED EXCEPTION: $UnexpectedException" -ForegroundColor Red
        } else {
            foreach ($Err in $ActualErrors) {
                if ($Err -match [regex]::Escape($TestCase.ExpectedError)) {
                    $CaughtExpectedError = $true
                    break
                }
            }

            if ($CaughtExpectedError) {
                Write-Host "PASS [Negative Case]: '$($TestCase.Name)' properly rejected with expected error: $($TestCase.ExpectedError)" -ForegroundColor Green
                $NegativePassCount++
            } else {
                Write-Host "FAIL [Negative Case]: '$($TestCase.Name)' was NOT rejected as expected! (Actual: $($ActualErrors -join ', '))" -ForegroundColor Red
            }
        }
    }
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force | Out-Null
    }
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Negative Test Suite Complete: $NegativePassCount/$($Cases.Count) passed." -ForegroundColor $(if ($NegativePassCount -eq $Cases.Count) { "Green" } else { "Red" })
Write-Host "================================================================" -ForegroundColor Cyan

if ($NegativePassCount -eq $Cases.Count) { exit 0 } else { exit 1 }
