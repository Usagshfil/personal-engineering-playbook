# tools/test-database-example.ps1
# Automated Verification Utility for Database Representative Reference Implementation
# Verifies SQL schema design, constraints, index patterns, migration lifecycle, and concurrency

param(
    [string]$PlaybookRoot = (Get-Location).Path
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   DATABASE REPRESENTATIVE SQL IMPLEMENTATION VERIFIER          " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Root Path    : $PlaybookRoot"
Write-Host "Execution Time: $([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))`n"

$ErrorCount = 0
$SqlFile = Join-Path $PlaybookRoot "06-technologies\database\examples\representative-schema-and-migration.sql"

# Check 1: File Existence
Write-Host "--- Check 1: Artifact Existence ---" -ForegroundColor Yellow
if (Test-Path $SqlFile) {
    $RelPath = $SqlFile.Substring($PlaybookRoot.Length).TrimStart('\', '/')
    Write-Host "PASS: Found required SQL reference file '$RelPath'" -ForegroundColor Green
} else {
    Write-Host "FAIL: Missing required file '$SqlFile'" -ForegroundColor Red
    $ErrorCount++
    exit $ErrorCount
}

$SqlContent = Get-Content $SqlFile -Raw

# Check 2: Least Privilege Role Separation
Write-Host "`n--- Check 2: Least Privilege Role Separation ---" -ForegroundColor Yellow
$RequiredRoles = @(
    @{ Name = "Migration Runner Role"; Pattern = 'CREATE\s+ROLE\s+migration_runner\b' },
    @{ Name = "Application DML Role"; Pattern = 'CREATE\s+ROLE\s+app_user\b' },
    @{ Name = "Readonly Analyst Role"; Pattern = 'CREATE\s+ROLE\s+readonly_analyst\b' },
    @{ Name = "DML-Only Permission Granting"; Pattern = 'GRANT\s+SELECT,\s+INSERT,\s+UPDATE,\s+DELETE\s+ON' }
)

foreach ($RoleCheck in $RequiredRoles) {
    if ($SqlContent -match $RoleCheck.Pattern) {
        Write-Host "PASS: SQL defines $($RoleCheck.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: SQL missing $($RoleCheck.Name) (pattern: $($RoleCheck.Pattern))" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check 3: Strict Schema Design & Data Modeling Invariants
Write-Host "`n--- Check 3: Schema Modeling & Constraint Declarations ---" -ForegroundColor Yellow
$RequiredModelingTokens = @(
    @{ Name = "Normalized Accounts Table"; Pattern = 'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?accounts\b' },
    @{ Name = "Normalized Orders Table"; Pattern = 'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?orders\b' },
    @{ Name = "Normalized Order Items Table"; Pattern = 'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?order_items\b' },
    @{ Name = "Explicit TIMESTAMPTZ (UTC) Typing"; Pattern = 'TIMESTAMPTZ\s+NOT\s+NULL' },
    @{ Name = "Exact Monetary Cents (BIGINT)"; Pattern = 'total_amount_cents\s+BIGINT\s+NOT\s+NULL' },
    @{ Name = "Positive Quantity Check Constraint"; Pattern = 'CHECK\s*\(\s*quantity\s*>\s*0\s*\)' },
    @{ Name = "Positive Amount Check Constraint"; Pattern = 'CHECK\s*\(\s*total_amount_cents\s*>=\s*0\s*\)' },
    @{ Name = "Foreign Key with Explicit ON DELETE"; Pattern = 'FOREIGN\s+KEY[\s\S]+?REFERENCES[\s\S]+?ON\s+DELETE\s+(?:RESTRICT|CASCADE|SET\s+NULL)' },
    @{ Name = "Idempotency Key & Payload Hash Foundation"; Pattern = 'idempotency_payload_hash\s+CHAR\(64\)' }
)

foreach ($Token in $RequiredModelingTokens) {
    if ($SqlContent -match $Token.Pattern) {
        Write-Host "PASS: SQL enforces $($Token.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: SQL missing $($Token.Name) (pattern: $($Token.Pattern))" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check 4: Indexing Strategies & Prefix Rules
Write-Host "`n--- Check 4: Indexing Patterns & Coverage ---" -ForegroundColor Yellow
$RequiredIndexPatterns = @(
    @{ Name = "Left-to-Right Composite Index with INCLUDE"; Pattern = 'CREATE\s+INDEX[\s\S]+?ON\s+orders[\s\S]+?INCLUDE\s*\(\s*total_amount_cents\s*\)' },
    @{ Name = "Partial Filtered Index"; Pattern = 'CREATE\s+INDEX[\s\S]+?WHERE\s+is_active\s*=\s*TRUE' },
    @{ Name = "JSONB GIN Index"; Pattern = 'USING\s+GIN\s*\(\s*metadata\s+jsonb_path_ops\s*\)' }
)

foreach ($Idx in $RequiredIndexPatterns) {
    if ($SqlContent -match $Idx.Pattern) {
        Write-Host "PASS: SQL implements $($Idx.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: SQL missing $($Idx.Name) (pattern: $($Idx.Pattern))" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check 5: Safe Expand-and-Contract Migration Discipline
Write-Host "`n--- Check 5: Safe Migration Lifecycle ---" -ForegroundColor Yellow
$RequiredMigrationPatterns = @(
    @{ Name = "Defensive Lock Timeout Configuration"; Pattern = 'SET\s+(?:LOCAL\s+)?lock_timeout\s*=\s*[\x27"]2s[\x27"]' },
    @{ Name = "Defensive Statement Timeout Configuration"; Pattern = 'SET\s+statement_timeout\s*=\s*[\x27"]10s[\x27"]' },
    @{ Name = "Non-Blocking Constraint Addition (NOT VALID)"; Pattern = 'ADD\s+CONSTRAINT[\s\S]+?NOT\s+VALID' },
    @{ Name = "Constraint Validation Pass"; Pattern = 'VALIDATE\s+CONSTRAINT\b' },
    @{ Name = "Non-Blocking Concurrent Index Build"; Pattern = 'CREATE\s+INDEX\s+CONCURRENTLY\b' },
    @{ Name = "Batch Backfill Simulation with LIMIT"; Pattern = 'UPDATE\s+orders[\s\S]+?LIMIT\s+\d+' },
    @{ Name = "Rollback Demonstration Statements"; Pattern = 'DROP\s+COLUMN\s+IF\s+EXISTS\s+discount_amount_cents' }
)

foreach ($Mig in $RequiredMigrationPatterns) {
    if ($SqlContent -match $Mig.Pattern) {
        Write-Host "PASS: Migration implements $($Mig.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Migration missing $($Mig.Name) (pattern: $($Mig.Pattern))" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check 6: Concurrency Control Mechanisms
Write-Host "`n--- Check 6: Concurrency Control Patterns ---" -ForegroundColor Yellow
$RequiredConcurrencyPatterns = @(
    @{ Name = "Optimistic Concurrency Control (OCC Version Check)"; Pattern = 'version\s*=\s*version\s*\+\s*1[\s\S]+?WHERE[\s\S]+?version\s*=\s*\d+' },
    @{ Name = "Pessimistic Row Locking (FOR UPDATE)"; Pattern = 'SELECT[\s\S]+?FOR\s+UPDATE;' },
    @{ Name = "Lock-Free Worker Queue (FOR UPDATE SKIP LOCKED)"; Pattern = 'FOR\s+UPDATE\s+SKIP\s+LOCKED;' }
)

foreach ($Conc in $RequiredConcurrencyPatterns) {
    if ($SqlContent -match $Conc.Pattern) {
        Write-Host "PASS: SQL demonstrates $($Conc.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: SQL missing $($Conc.Name) (pattern: $($Conc.Pattern))" -ForegroundColor Red
        $ErrorCount++
    }
}

# Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "   DATABASE REPRESENTATIVE SQL VERIFICATION PASSED (0 ERRORS)   " -ForegroundColor Green
} else {
    Write-Host "   DATABASE REPRESENTATIVE SQL VERIFICATION FAILED ($ErrorCount ERRORS) " -ForegroundColor Red
}
Write-Host "================================================================" -ForegroundColor Cyan

exit $ErrorCount
