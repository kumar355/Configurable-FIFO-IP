# ==============================================================================
# Configurable FIFO IP - Automated Regression Runner
# ==============================================================================

Write-Host "=====================================================" -ForegroundColor DarkCyan
Write-Host " Configurable FIFO IP - Full Regression Test Suite" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor DarkCyan

# 1. Compile Sources
Write-Host "`n[1/5] Compiling SystemVerilog Sources with vlog..." -ForegroundColor Yellow
$vlogCmd = "vlog -sv rtl/common/fifo_pkg.sv rtl/common/fifo_mem.sv rtl/sync/sync_fifo_ctrl.sv rtl/sync/sync_fifo_top.sv rtl/async/gray_counter.sv rtl/async/synchronizer.sv rtl/async/async_fifo_ctrl.sv rtl/async/async_fifo_top.sv interfaces/fifo_if.sv assertions/fifo_assertions.sv coverage/fifo_coverage.sv verification/fifo_verif_pkg.sv verification/fifo_base_test.sv tests/directed/directed_test.sv tests/random/random_test.sv tests/async/async_fifo_test.sv"

Invoke-Expression $vlogCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Compilation clean with 0 errors!" -ForegroundColor Green

# Array of test targets
$tests = @("fifo_base_test", "directed_test", "random_test", "async_fifo_test")
$results = @{}
$passedAll = $true

# 2. Run Each Test
foreach ($test in $tests) {
    Write-Host "`nRunning Test Target: $test..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $logFile = "sim_$test.log"
    vsim -c -voptargs="+acc" -do "run -all; quit" $test | Out-File -Encoding utf8 $logFile

    $logContent = Get-Content $logFile -Raw
    if ($logContent -cmatch "TEST FAILED|Errors: [1-9][0-9]*|failed=[1-9][0-9]*\b|Fatal:") {
        Write-Host "[FAIL] Test target $test FAILED!" -ForegroundColor Red
        $results[$test] = "FAILED"
        $passedAll = $false
    } else {
        Write-Host "[PASS] Test target $test PASSED!" -ForegroundColor Green
        $results[$test] = "PASSED"
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
    Write-Host "`n>>> ALL REGRESSION TESTS PASSED SUCCESSFULLY! Ready for GitHub release! <<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> REGRESSION FAILED! Review test logs for details. <<`n" -ForegroundColor Red
    exit 1
}
