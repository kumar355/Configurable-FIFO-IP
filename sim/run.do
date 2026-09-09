# ==============================================================================
# Configurable FIFO IP - QuestaSim Execution Script
# ==============================================================================

# Default test is fifo_base_test if TESTNAME variable not set
if {![info exists TESTNAME]} {
    set TESTNAME "fifo_base_test"
}

echo "Running Simulation for target: $TESTNAME"

vsim -c -do "run -all; quit" $TESTNAME
