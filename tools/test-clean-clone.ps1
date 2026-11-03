# tools/test-clean-clone.ps1
# Clean-Clone Reproducibility Verification Harness
# Clones the committed repository into a clean temp folder and executes the validation suites.

param(
    [string]$SourceRepo = (Get-Location).Path
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "      CLEAN-CLONE REPRODUCIBILITY VERIFICATION HARNESS         " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Source Repository: $SourceRepo"

$TempCloneDir = Join-Path $env:TEMP ("playbook-clean-clone-" + (Get-Random))
Write-Host "Cloning into temporary directory: $TempCloneDir`n"

try {
    # 1. Clone repository
    git clone $SourceRepo $TempCloneDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL: Git clone failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }

    # 2. Run validator on clean clone
    Write-Host "`n--- Executing validate-playbook.ps1 in Clean Clone ---" -ForegroundColor Yellow
    $ValidatorScript = Join-Path $TempCloneDir "tools\validate-playbook.ps1"
    powershell -ExecutionPolicy Bypass -File $ValidatorScript -PlaybookRoot $TempCloneDir
    $ValidatorExitCode = $LASTEXITCODE

    # 3. Run negative test suite on clean clone
    Write-Host "`n--- Executing test-validator-negative.ps1 in Clean Clone ---" -ForegroundColor Yellow
    $NegativeScript = Join-Path $TempCloneDir "tools\test-validator-negative.ps1"
    powershell -ExecutionPolicy Bypass -File $NegativeScript
    $NegativeExitCode = $LASTEXITCODE

    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "Clean Clone Results: Validator ExitCode=$ValidatorExitCode, Negative ExitCode=$NegativeExitCode"
    if ($ValidatorExitCode -eq 0 -and $NegativeExitCode -eq 0) {
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
