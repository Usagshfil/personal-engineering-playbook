# tools/validate-playbook.ps1
# Automated Validation Utility for the Personal Software Engineering Playbook
# Specification: Agent Skills Standard (agentskills.io v1.0) & GFM Link Integrity

param(
    [string]$PlaybookRoot = (Get-Location).Path
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   PERSONAL SOFTWARE ENGINEERING PLAYBOOK VALIDATION SUITE      " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Root Path    : $PlaybookRoot"
Write-Host "PS Version   : $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
Write-Host "OS Platform  : $([System.Environment]::OSVersion.VersionString)"
Write-Host "Execution Time: $([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))`n"

$ErrorCount = 0
$WarningCount = 0

# -----------------------------------------------------------------
# TEST SUITE 1: REPOSITORY DOCUMENT INVENTORY & ABSOLUTE PATH CHECK
# -----------------------------------------------------------------
Write-Host "--- TEST SUITE 1: Repository Inventory & Portability Check ---" -ForegroundColor Yellow

$AllMdFiles = Get-ChildItem -Path $PlaybookRoot -Recurse -File -Filter "*.md"
$TotalFiles = $AllMdFiles.Count
Write-Host "Total Markdown Documents Found: $TotalFiles" -ForegroundColor Green

# Inventory Breakdown by Top-Level Directory
$Inventory = $AllMdFiles | Group-Object {
    $Relative = $_.FullName.Substring($PlaybookRoot.Length).TrimStart('\', '/')
    $Parts = $Relative.Split('\/')
    if ($Parts.Length -gt 1) { $Parts[0] } else { "(root)" }
}

Write-Host "`nDocument Distribution:"
foreach ($Group in $Inventory) {
    Write-Host ("  {0,-25} : {1,3} files" -f $Group.Name, $Group.Count) -ForegroundColor Gray
}

# Check for forbidden absolute file:/// links
Write-Host "`nScanning for forbidden absolute file:/// links..."
$AbsoluteLinkViolations = @()
foreach ($File in $AllMdFiles) {
    $Matches = Select-String -Path $File.FullName -Pattern "file:///"
    if ($Matches) {
        $AbsoluteLinkViolations += [PSCustomObject]@{
            File  = $File.FullName.Substring($PlaybookRoot.Length).TrimStart('\', '/')
            Count = $Matches.Count
        }
    }
}

if ($AbsoluteLinkViolations.Count -gt 0) {
    Write-Host "FAIL: Found absolute file:/// links in $($AbsoluteLinkViolations.Count) files!" -ForegroundColor Red
    $AbsoluteLinkViolations | Format-Table -AutoSize
    $ErrorCount += $AbsoluteLinkViolations.Count
} else {
    Write-Host "PASS: Zero absolute file:/// links found. All links are portable." -ForegroundColor Green
}

# -----------------------------------------------------------------
# TEST SUITE 2: AGENT SKILLS SPECIFICATION (agentskills.io)
# -----------------------------------------------------------------
Write-Host "`n--- TEST SUITE 2: Agent Skills Schema Validation (agentskills.io) ---" -ForegroundColor Yellow

$SkillsDir = Join-Path $PlaybookRoot "05-skills"
$SkillFiles = Get-ChildItem -Path $SkillsDir -Recurse -File -Filter "SKILL.md"

Write-Host "Found $($SkillFiles.Count) skill files for validation (Expected: 12).`n"

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

$SkillValidationResults = @()

foreach ($SkillFile in $SkillFiles) {
    $ParentDirName = $SkillFile.Directory.Name
    $RelativePath = $SkillFile.FullName.Substring($PlaybookRoot.Length).TrimStart('\', '/')
    $Content = Get-Content -Path $SkillFile.FullName -Raw
    
    $SkillPass = $true
    $FailureReasons = @()

    # 1. Frontmatter delimiter check
    if (-not ($Content -match "^---\r?\n([\s\S]*?)\r?\n---")) {
        $SkillPass = $false
        $FailureReasons += "Missing YAML frontmatter delimiters (---)"
    } else {
        $Frontmatter = $Matches[1]
        
        # 2. Name check
        if ($Frontmatter -match "name:\s*([^\r\n]+)") {
            $SkillName = $Matches[1].Trim()
            if ($SkillName.Length -gt 64) {
                $SkillPass = $false
                $FailureReasons += "Name exceeds 64 characters (Length: $($SkillName.Length))"
            }
            if (-not ($SkillName -cmatch $SkillNameRegex)) {
                $SkillPass = $false
                $FailureReasons += "Name '$SkillName' does not match agentskills.io regex (lowercase, numbers, hyphens)"
            }
            if ($SkillName -ne $ParentDirName) {
                $SkillPass = $false
                $FailureReasons += "Name '$SkillName' does not match directory '$ParentDirName'"
            }
        } else {
            $SkillPass = $false
            $FailureReasons += "Missing required 'name' field"
        }

        # 3. Description check
        if ($Frontmatter -match "description:\s*([^\r\n]+)") {
            $Description = $Matches[1].Trim()
            if ($Description.Length -gt 1024) {
                $SkillPass = $false
                $FailureReasons += "Description exceeds 1024 characters (Length: $($Description.Length))"
            }
            if ($Description.Length -eq 0) {
                $SkillPass = $false
                $FailureReasons += "Description is empty"
            }
            if (-not ($Description -match "Use when")) {
                $FailureReasons += "WARNING: Description lacks explicit 'Use when' trigger phrase"
                $WarningCount++
            }
        } else {
            $SkillPass = $false
            $FailureReasons += "Missing required 'description' field"
        }
    }

    # 4. Mandatory Section Checklist
    foreach ($Section in $RequiredSections) {
        if (-not ($Content -match [regex]::Escape($Section))) {
            $SkillPass = $false
            $FailureReasons += "Missing mandatory section: '$Section'"
        }
    }

    if (-not $SkillPass) {
        $ErrorCount++
    }

    $SkillValidationResults += [PSCustomObject]@{
        SkillName = $ParentDirName
        Status    = if ($SkillPass) { "PASS" } else { "FAIL" }
        Issues    = if ($FailureReasons.Count -gt 0) { ($FailureReasons -join "; ") } else { "None" }
    }
}

$SkillValidationResults | Format-Table -AutoSize

# -----------------------------------------------------------------
# TEST SUITE 3: RELATIVE MARKDOWN LINK INTEGRITY
# -----------------------------------------------------------------
Write-Host "`n--- TEST SUITE 3: Markdown Relative Link Integrity ---" -ForegroundColor Yellow

$BrokenLinks = @()
$TotalLinksChecked = 0

foreach ($File in $AllMdFiles) {
    $Content = Get-Content -Path $File.FullName -Raw
    # Match markdown links: [text](path) excluding external http/https/mailto
    $LinkMatches = [regex]::Matches($Content, '\[([^\]]+)\]\((?!http|https|mailto|#)([^)]+)\)')

    foreach ($Match in $LinkMatches) {
        $TotalLinksChecked++
        $LinkTarget = $Match.Groups[2].Value.Split('#')[0] # Strip anchor fragment
        if ([string]::IsNullOrWhiteSpace($LinkTarget)) { continue }

        $TargetResolved = Join-Path $File.Directory.FullName $LinkTarget
        if (-not (Test-Path $TargetResolved)) {
            $BrokenLinks += [PSCustomObject]@{
                SourceFile = $File.FullName.Substring($PlaybookRoot.Length).TrimStart('\', '/')
                LinkText   = $Match.Groups[1].Value
                Target     = $LinkTarget
            }
        }
    }
}

Write-Host "Total Relative Markdown Links Checked: $TotalLinksChecked" -ForegroundColor Green

if ($BrokenLinks.Count -gt 0) {
    Write-Host "FAIL: Found $($BrokenLinks.Count) broken relative links!" -ForegroundColor Red
    $BrokenLinks | Format-Table -AutoSize
    $ErrorCount += $BrokenLinks.Count
} else {
    Write-Host "PASS: All $TotalLinksChecked relative markdown links resolve to existing files." -ForegroundColor Green
}

# -----------------------------------------------------------------
# TEST SUITE 4: VERSION CONSISTENCY CHECK
# -----------------------------------------------------------------
Write-Host "`n--- TEST SUITE 4: Version Metadata Consistency ---" -ForegroundColor Yellow

$VersionFile = Join-Path $PlaybookRoot "VERSION.md"
$ExpectedVersion = "1.0.0-alpha.1"

if (Test-Path $VersionFile) {
    $VersionContent = Get-Content $VersionFile -Raw
    if ($VersionContent -match '\*\*Current Version\*\*:\s*`([^`]+)`') {
        $ParsedVersion = $Matches[1].Trim()
        if ($ParsedVersion -eq $ExpectedVersion) {
            Write-Host "PASS: VERSION.md declares correct version '$ParsedVersion'." -ForegroundColor Green
        } else {
            Write-Host "FAIL: VERSION.md declares '$ParsedVersion', expected '$ExpectedVersion'." -ForegroundColor Red
            $ErrorCount++
        }
    } else {
        Write-Host "FAIL: Could not parse version pattern in VERSION.md" -ForegroundColor Red
        $ErrorCount++
    }
} else {
    Write-Host "FAIL: VERSION.md not found!" -ForegroundColor Red
    $ErrorCount++
}

# -----------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------
Write-Host "`n================================================================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "   VALIDATION SUITE PASSED! ($TotalFiles files verified, $WarningCount warnings)   " -ForegroundColor Green
} else {
    Write-Host "   VALIDATION SUITE FAILED WITH $ErrorCount ERRORS!              " -ForegroundColor Red
}
Write-Host "================================================================" -ForegroundColor Cyan

exit $ErrorCount
