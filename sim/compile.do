# ==============================================================================
# Configurable FIFO IP - QuestaSim Compilation Script
# ==============================================================================

if {[file exists work]} {
    vlib work
} else {
    vlib work
}

vmap work work

echo "Compiling Common Packages and Memory..."
vlog -sv -stats=none ../rtl/common/fifo_pkg.sv
vlog -sv -stats=none ../rtl/common/fifo_mem.sv

echo "Compiling Synchronous FIFO RTL..."
vlog -sv -stats=none ../rtl/sync/sync_fifo_ctrl.sv
vlog -sv -stats=none ../rtl/sync/sync_fifo_top.sv

echo "Compiling Asynchronous FIFO RTL..."
vlog -sv -stats=none ../rtl/async/gray_counter.sv
vlog -sv -stats=none ../rtl/async/synchronizer.sv
vlog -sv -stats=none ../rtl/async/async_fifo_ctrl.sv
vlog -sv -stats=none ../rtl/async/async_fifo_top.sv

echo "Compiling Interfaces, Assertions, and Coverage..."
vlog -sv -stats=none ../interfaces/fifo_if.sv
vlog -sv -stats=none ../assertions/fifo_assertions.sv
vlog -sv -stats=none ../coverage/fifo_coverage.sv

echo "Compiling Verification Components and Base Test..."
vlog -sv -stats=none ../verification/fifo_verif_pkg.sv
vlog -sv -stats=none ../verification/fifo_base_test.sv

echo "Compiling Test Suite..."
vlog -sv -stats=none ../tests/directed/directed_test.sv
vlog -sv -stats=none ../tests/random/random_test.sv
vlog -sv -stats=none ../tests/async/async_fifo_test.sv

echo "Compilation completed successfully!"
