# tools/test-backend-example.ps1
# Automated Verification Utility for Backend Representative Reference Implementation
# Verifies contracts, schema rules, idempotency logic, and test suite coverage

param(
    [string]$PlaybookRoot = (Get-Location).Path
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   BACKEND REPRESENTATIVE API REFERENCE IMPLEMENTATION VERIFIER " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Root Path    : $PlaybookRoot"
Write-Host "Execution Time: $([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))`n"

$ErrorCount = 0
$BackendExamplesDir = Join-Path $PlaybookRoot "06-technologies\backend\examples"

$SourceFile = Join-Path $BackendExamplesDir "representative-api.ts"
$TestFile   = Join-Path $BackendExamplesDir "representative-api.test.ts"
$PackageFile = Join-Path $BackendExamplesDir "package.json"
$TsconfigFile = Join-Path $BackendExamplesDir "tsconfig.json"

# Check 1: File Existence
Write-Host "--- Check 1: Artifact Existence & Configuration ---" -ForegroundColor Yellow
$RequiredFiles = @($SourceFile, $TestFile, $PackageFile, $TsconfigFile)
foreach ($File in $RequiredFiles) {
    if (Test-Path $File) {
        $RelPath = $File.Substring($PlaybookRoot.Length).TrimStart('\', '/')
        Write-Host "PASS: Found required file '$RelPath'" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Missing required file '$File'" -ForegroundColor Red
        $ErrorCount++
    }
}

if ($ErrorCount -gt 0) {
    Write-Host "`nTerminating early due to missing files." -ForegroundColor Red
    exit $ErrorCount
}

# Check 2: Configuration & Engine Compliance
Write-Host "`n--- Check 2: Package & TypeScript Configuration ---" -ForegroundColor Yellow
$PackageJson = Get-Content $PackageFile -Raw | ConvertFrom-Json
if ($PackageJson.dependencies.zod) {
    Write-Host "PASS: package.json declares 'zod' dependency ($($PackageJson.dependencies.zod))" -ForegroundColor Green
} else {
    Write-Host "FAIL: package.json missing 'zod' dependency" -ForegroundColor Red
    $ErrorCount++
}

if ($PackageJson.engines.node -match ">=20") {
    Write-Host "PASS: package.json specifies Node.js engine policy '$($PackageJson.engines.node)'" -ForegroundColor Green
} else {
    Write-Host "FAIL: package.json engine does not specify Node >=20 LTS" -ForegroundColor Red
    $ErrorCount++
}

$TsconfigContent = Get-Content $TsconfigFile -Raw
if ($TsconfigContent -match '"strict"\s*:\s*true' -and $TsconfigContent -match '"noImplicitAny"\s*:\s*true') {
    Write-Host "PASS: tsconfig.json enforces strict TypeScript compiler options" -ForegroundColor Green
} else {
    Write-Host "FAIL: tsconfig.json lacks strict mode compiler options" -ForegroundColor Red
    $ErrorCount++
}

# Check 3: Architecture & Source Implementation Verification
Write-Host "`n--- Check 3: Clean Architecture & Idempotency Source Verification ---" -ForegroundColor Yellow
$SourceContent = Get-Content $SourceFile -Raw

$RequiredSourceTokens = @(
    @{ Name = "Zod Request Schema"; Pattern = 'CreateOrderRequestSchema\s*=\s*z\.object' },
    @{ Name = "Domain Entity Order"; Pattern = 'class\s+Order\b' },
    @{ Name = "Domain Exception (InsufficientInventory)"; Pattern = 'class\s+InsufficientInventoryError\b' },
    @{ Name = "Domain Exception (OrderAlreadyProcessed)"; Pattern = 'class\s+OrderAlreadyProcessedError\b' },
    @{ Name = "Application Service"; Pattern = 'class\s+OrderApplicationService\b' },
    @{ Name = "HTTP Transport Controller"; Pattern = 'class\s+OrderHttpController\b' },
    @{ Name = "RFC 9457 Problem Details Mapping"; Pattern = 'application/problem\+json' },
    @{ Name = "Payload Fingerprinting (SHA-256)"; Pattern = 'createHash\(\s*[\x27"]sha256[\x27"]\s*\)' },
    @{ Name = "Payload Mismatch Rejection (422)"; Pattern = 'idempotency-payload-mismatch' },
    @{ Name = "Concurrent Lock Contention Rejection (409)"; Pattern = 'concurrent-mutation' },
    @{ Name = "Cached Idempotency Replay Header"; Pattern = 'X-Cache-Replay' },
    @{ Name = "PII Sanitization Masker"; Pattern = 'function\s+sanitize\b' },
    @{ Name = "In-Memory Test Adapters"; Pattern = 'class\s+InMemoryOrderRepository\b' }
)

foreach ($Token in $RequiredSourceTokens) {
    if ($SourceContent -match $Token.Pattern) {
        Write-Host "PASS: Source implements $($Token.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Source missing $($Token.Name) (pattern: $($Token.Pattern))" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check 4: Test Suite Scenario Coverage
Write-Host "`n--- Check 4: Test Suite Scenario Coverage ---" -ForegroundColor Yellow
$TestContent = Get-Content $TestFile -Raw

$RequiredTestScenarios = @(
    "Happy Path Order Creation",
    "Missing Idempotency-Key",
    "Cached Idempotency Replay",
    "Payload Mismatch Detection",
    "Concurrent In-Flight Lock Rejection",
    "Zod Boundary Schema Validation",
    "Domain Invariant Rejection",
    "PII & Secret Metadata Sanitization"
)

foreach ($Scenario in $RequiredTestScenarios) {
    if ($TestContent -match [regex]::Escape($Scenario)) {
        Write-Host "PASS: Test suite covers scenario '$Scenario'" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Test suite missing scenario '$Scenario'" -ForegroundColor Red
        $ErrorCount++
    }
}

# Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "   BACKEND REPRESENTATIVE API VERIFICATION PASSED (0 ERRORS)    " -ForegroundColor Green
} else {
    Write-Host "   BACKEND REPRESENTATIVE API VERIFICATION FAILED ($ErrorCount ERRORS)  " -ForegroundColor Red
}
Write-Host "================================================================" -ForegroundColor Cyan

exit $ErrorCount
