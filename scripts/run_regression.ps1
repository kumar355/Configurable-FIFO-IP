# ==============================================================================
# Configurable FIFO IP - Industrial Automated Regression Runner
# ==============================================================================

if (!(Test-Path "reports")) {
    New-Item -ItemType Directory -Path "reports" | Out-Null
}

Write-Host "=====================================================" -ForegroundColor DarkCyan
Write-Host " Configurable FIFO IP - Comprehensive Industrial Regression" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor DarkCyan

# 1. Compile Sources with SystemVerilog Coverage Enablement
Write-Host "`n[1/2] Compiling SystemVerilog Sources with vlog..." -ForegroundColor Yellow
$vlogCmd = "vlog -sv rtl/common/fifo_pkg.sv rtl/common/fifo_mem.sv rtl/sync/sync_fifo_ctrl.sv rtl/sync/sync_fifo_top.sv rtl/async/gray_counter.sv rtl/async/synchronizer.sv rtl/async/async_fifo_ctrl.sv rtl/async/async_fifo_top.sv interfaces/fifo_if.sv assertions/fifo_assertions.sv coverage/fifo_coverage.sv verification/fifo_verif_pkg.sv verification/fifo_base_test.sv tests/directed/directed_test.sv tests/random/random_test.sv tests/async/async_fifo_test.sv tests/async/async_clk_sweep_test.sv tests/directed/mem_mode_test.sv tests/directed/param_sweep_test.sv tests/directed/fault_injection_test.sv"

Invoke-Expression $vlogCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Compilation clean with 0 errors!" -ForegroundColor Green

# Array of test targets
$tests = @(
    "fifo_base_test",
    "directed_test",
    "random_test",
    "async_fifo_test",
    "async_clk_sweep_test",
    "mem_mode_test",
    "param_sweep_test",
    "fault_injection_test"
)

$results = @{}
$passedAll = $true

# 2. Run Each Test Target
foreach ($test in $tests) {
    Write-Host "`nRunning Test Target: $test..." -ForegroundColor Yellow
    $logFile = "reports/sim_$test.log"
    vsim -c -voptargs="+acc" -do "run -all; quit" $test | Out-File -Encoding utf8 $logFile

    $logContent = Get-Content $logFile -Raw

    if ($test -eq "fault_injection_test") {
        # Fault injection test expects environment to catch the injected defect
        if ($logContent -match "Fault Injection Test SUCCESSFUL") {
            Write-Host "[PASS] Test target $test PASSED! (Injected fault successfully detected)" -ForegroundColor Green
            $results[$test] = "PASSED"
        } else {
            Write-Host "[FAIL] Test target $test FAILED!" -ForegroundColor Red
            $results[$test] = "FAILED"
            $passedAll = $false
        }
    } else {
        if ($logContent -match "Fatal:|\[FAIL\]|\[SVA FAIL\]|SCOREBOARD MISMATCH|Errors: [1-9]") {
            Write-Host "[FAIL] Test target $test FAILED!" -ForegroundColor Red
            $results[$test] = "FAILED"
            $passedAll = $false
        } else {
            Write-Host "[PASS] Test target $test PASSED!" -ForegroundColor Green
            $results[$test] = "PASSED"
        }
    }
}

# 3. Final Summary Report
Write-Host "`n=====================================================" -ForegroundColor DarkCyan
Write-Host " REGRESSION SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor DarkCyan
foreach ($test in $tests) {
    $status = $results[$test]
    if ($status -eq "PASSED") {
        Write-Host "  $test : [PASSED]" -ForegroundColor Green
    } else {
        Write-Host "  $test : [FAILED]" -ForegroundColor Red
    }
}
Write-Host "=====================================================" -ForegroundColor DarkCyan

if ($passedAll) {
    Write-Host "`n>>> ALL REGRESSION TESTS PASSED SUCCESSFULLY! Verified and Sign-off Ready! <<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> REGRESSION FAILED! Review test logs in reports/ for details. <<`n" -ForegroundColor Red
    exit 1
}
