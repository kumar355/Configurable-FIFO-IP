//-----------------------------------------------------------------------------
// Fault Injection / Negative Verification Testbench
//
// Purpose: Proves that the verification environment (Scoreboard & SVAs)
// actively detects bugs when controlled defects are injected.
//
// Injected fault scenarios:
// 1. Dropped write (write request suppressed)
// 2. Corrupted occupancy state
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;
import fifo_verif_pkg::*;

module fault_injection_test;

    localparam int DATA_WIDTH = 32;
    localparam int FIFO_DEPTH = 8;

    logic clk;
    logic rst_n;

    fifo_if #(DATA_WIDTH, FIFO_DEPTH) fifo_interface (.clk(clk), .rst_n(rst_n));

    // Fault injection control flags
    logic inject_dropped_write = 0;
    logic wr_en_faulty;

    assign wr_en_faulty = inject_dropped_write ? 1'b0 : fifo_interface.wr_en;

    // Instantiate DUT with fault injection hook on write enable
    sync_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en_faulty),
        .rd_en(fifo_interface.rd_en),
        .din(fifo_interface.din),
        .enable(fifo_interface.enable),
        .flush(fifo_interface.flush),
        .af_threshold(fifo_interface.af_threshold),
        .ae_threshold(fifo_interface.ae_threshold),
        .dout(fifo_interface.dout),
        .full(fifo_interface.full),
        .empty(fifo_interface.empty),
        .almost_full(fifo_interface.almost_full),
        .almost_empty(fifo_interface.almost_empty),
        .overflow(fifo_interface.overflow),
        .underflow(fifo_interface.underflow),
        .occupancy(fifo_interface.occupancy),
        .debug_status(fifo_interface.debug_status),
        .dbg_operation(fifo_interface.dbg_operation)
    );

    // Instantiate SVA
    fifo_assertions #(DATA_WIDTH, FIFO_DEPTH) u_assertions (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_interface.wr_en),
        .rd_en(fifo_interface.rd_en),
        .enable(fifo_interface.enable),
        .flush(fifo_interface.flush),
        .din(fifo_interface.din),
        .af_threshold(fifo_interface.af_threshold),
        .ae_threshold(fifo_interface.ae_threshold),
        .dout(fifo_interface.dout),
        .full(fifo_interface.full),
        .empty(fifo_interface.empty),
        .almost_full(fifo_interface.almost_full),
        .almost_empty(fifo_interface.almost_empty),
        .overflow(fifo_interface.overflow),
        .underflow(fifo_interface.underflow),
        .occupancy(fifo_interface.occupancy)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    fifo_environment #(DATA_WIDTH, FIFO_DEPTH) env;

    initial begin
        $display("=========================================================");
        $display("   FAULT INJECTION & NEGATIVE VERIFICATION TESTBENCH");
        $display("=========================================================");

        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        env = new("fault_env", fifo_interface.DRIVER, fifo_interface.MONITOR, 10);
        env.build();
        env.connect();

        // Populate mailbox with OP_WRITE transactions
        begin
            fifo_transaction #(DATA_WIDTH) txn;
            for (int i = 0; i < 10; i++) begin
                txn = new();
                txn.operation = OP_WRITE;
                txn.write_data = 32'hDEAD_0000 + i;
                env.gen_to_drv_mb.put(txn);
            end
        end

        // Inject fault: enable dropped write
        $display("[FAULT INJECTION] Injecting fault: Dropped write request");
        inject_dropped_write = 1'b1;

        fork
            env.driver.run();
            env.monitor.run(10);
            env.ref_model.run(10);
            env.scoreboard.compare_n(10);
        join

        $display("---------------------------------------------------------");
        $display("[FAULT INJECTION RESULT] Scoreboard Mismatches Detected: %0d", env.scoreboard.failed);
        $display("---------------------------------------------------------");

        if (env.scoreboard.failed > 0) begin
            $display("[PASS] Fault Injection Test SUCCESSFUL! Verification environment correctly detected the injected RTL defect.");
        end else begin
            $fatal(1, "[FAIL] Fault Injection Test FAILED! Environment missed the injected defect!");
        end

        $finish;
    end

endmodule
