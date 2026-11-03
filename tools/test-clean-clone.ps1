# tools/test-clean-clone.ps1
# Clean-Clone Reproducibility Verification Harness
# Clones the committed repository into a clean temp folder, checks out the exact source commit,
# verifies commit equality, and executes the validation suites.

param(
    [string]$SourceRepo = (Get-Location).Path,
    [string]$TargetCommit = ""
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "      CLEAN-CLONE REPRODUCIBILITY VERIFICATION HARNESS         " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Source Repository: $SourceRepo"
Write-Host "PowerShell Ver   : $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
Write-Host "Operating System : $([System.Environment]::OSVersion.VersionString)"

# 1. Determine Source Commit SHA
$SourceCommit = if ([string]::IsNullOrWhiteSpace($TargetCommit)) {
    (git -C $SourceRepo rev-parse HEAD).Trim()
} else {
    $TargetCommit.Trim()
}
Write-Host "Target Commit SHA: $SourceCommit"

$TempCloneDir = Join-Path $env:TEMP ("playbook-clean-clone-" + (Get-Random))
Write-Host "Temporary Dir    : $TempCloneDir`n"

try {
    # 2. Clone repository
    git clone $SourceRepo $TempCloneDir 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL: Git clone failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }

    # 3. Explicitly checkout the target commit in the clone
    git -C $TempCloneDir checkout $SourceCommit 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL: Failed to checkout commit $SourceCommit in clone" -ForegroundColor Red
        exit 1
    }

    # 4. Verify Commit Equality
    $CloneCommit = (git -C $TempCloneDir rev-parse HEAD).Trim()
    Write-Host "--- Commit Verification ---" -ForegroundColor Yellow
    Write-Host "Source Commit SHA : $SourceCommit"
    Write-Host "Clone Commit SHA  : $CloneCommit"

    if ($SourceCommit -eq $CloneCommit) {
        Write-Host "Commit Equality   : EQUAL (Exact Match)" -ForegroundColor Green
    } else {
        Write-Host "Commit Equality   : MISMATCH!" -ForegroundColor Red
        exit 1
    }

    # 5. Run validator on clean clone
    Write-Host "`n--- Executing validate-playbook.ps1 in Clean Clone ---" -ForegroundColor Yellow
    $ValidatorScript = Join-Path $TempCloneDir "tools\validate-playbook.ps1"
    powershell -ExecutionPolicy Bypass -File $ValidatorScript -PlaybookRoot $TempCloneDir
    $ValidatorExitCode = $LASTEXITCODE

    # 6. Run positive test suite on clean clone
    Write-Host "`n--- Executing test-validator-positive.ps1 in Clean Clone ---" -ForegroundColor Yellow
    $PositiveScript = Join-Path $TempCloneDir "tools\test-validator-positive.ps1"
    powershell -ExecutionPolicy Bypass -File $PositiveScript
    $PositiveExitCode = $LASTEXITCODE

    # 7. Run negative test suite on clean clone
    Write-Host "`n--- Executing test-validator-negative.ps1 in Clean Clone ---" -ForegroundColor Yellow
    $NegativeScript = Join-Path $TempCloneDir "tools\test-validator-negative.ps1"
    powershell -ExecutionPolicy Bypass -File $NegativeScript
    $NegativeExitCode = $LASTEXITCODE

    # 8. Run backend representative API verifier on clean clone
    Write-Host "`n--- Executing test-backend-example.ps1 in Clean Clone ---" -ForegroundColor Yellow
    $BackendExampleScript = Join-Path $TempCloneDir "tools\test-backend-example.ps1"
    powershell -ExecutionPolicy Bypass -File $BackendExampleScript -PlaybookRoot $TempCloneDir
    $BackendExampleExitCode = $LASTEXITCODE

    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "Clean Clone Results: Validator ExitCode=$ValidatorExitCode, Positive ExitCode=$PositiveExitCode, Negative ExitCode=$NegativeExitCode, Backend ExitCode=$BackendExampleExitCode"
    if ($ValidatorExitCode -eq 0 -and $PositiveExitCode -eq 0 -and $NegativeExitCode -eq 0 -and $BackendExampleExitCode -eq 0) {
        Write-Host "CLEAN CLONE VERIFICATION PASSED! Repository is fully reproducible." -ForegroundColor Green
        $FinalResult = 0
    } else {
        Write-Host "CLEAN CLONE VERIFICATION FAILED!" -ForegroundColor Red
        $FinalResult = 1
    }
    Write-Host "================================================================" -ForegroundColor Cyan

    exit $FinalResult
}
finally {
    if (Test-Path $TempCloneDir) {
        Remove-Item -Path $TempCloneDir -Recurse -Force | Out-Null
    }
}
