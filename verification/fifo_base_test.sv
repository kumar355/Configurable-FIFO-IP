`timescale 1ns/1ps

`ifndef FIFO_BASE_TEST_SV
`define FIFO_BASE_TEST_SV

import fifo_pkg::*;
import fifo_verif_pkg::*;
module fifo_base_test
#(
    parameter int DATA_WIDTH = fifo_pkg::DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = fifo_pkg::DEFAULT_FIFO_DEPTH
);

    // Clock and reset signals
    logic clk;
    logic rst_n;

    // Instantiate the FIFO interface
    fifo_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_interface (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Instantiate the DUT (sync_fifo_top)
    sync_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .READ_DURING_WRITE_MODE(WRITE_FIRST),
        .MEMORY_INIT_MODE(INIT_NONE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_interface.wr_en),
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

    // Instantiate SystemVerilog Assertions
    fifo_assertions #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_assertions (
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

    // Instantiate Functional Coverage
    fifo_coverage #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_coverage (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_interface.wr_en),
        .rd_en(fifo_interface.rd_en),
        .enable(fifo_interface.enable),
        .flush(fifo_interface.flush),
        .dbg_operation(fifo_interface.dbg_operation),
        .af_threshold(fifo_interface.af_threshold),
        .ae_threshold(fifo_interface.ae_threshold),
        .full(fifo_interface.full),
        .empty(fifo_interface.empty),
        .almost_full(fifo_interface.almost_full),
        .almost_empty(fifo_interface.almost_empty),
        .overflow(fifo_interface.overflow),
        .underflow(fifo_interface.underflow),
        .occupancy(fifo_interface.occupancy)
    );

    // Instantiate the verification environment
    fifo_environment #(DATA_WIDTH,FIFO_DEPTH) env;

    //=========================================================
    // Clock Generation
    //=========================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 10ns period clock
    end

    //=========================================================
    // Reset Generation
    //=========================================================
    initial begin
        rst_n = 1'b0;
        #20 rst_n = 1'b1;
    end

    //=========================================================
    // Test Execution
    //=========================================================
    initial begin
        $display("========================================");
        $display("FIFO Base Test Starting");
        $display("========================================");
        $display("Configuration:");
        $display("  DATA_WIDTH = %0d", DATA_WIDTH);
        $display("  FIFO_DEPTH = %0d", FIFO_DEPTH);
        $display("========================================");

        // Wait for reset to complete
        @(posedge rst_n);
        #10;

        // Create the environment
        env = new(
            .name_in("fifo_base_test_env"),
            .drv_vif_in(fifo_interface.DRIVER),
            .mon_vif_in(fifo_interface.MONITOR),
            .num_transactions_in(100)
        );

        // Build the environment
        $display("[TEST] Building environment...");
        env.build();

        // Connect the environment
        $display("[TEST] Connecting environment...");
        env.connect();

        // Run the environment
        $display("[TEST] Running environment...");
        env.run();

        // Print final simulation summary
        $display("========================================");
        $display("FIFO Base Test Summary");
        $display("========================================");
        $display("Test Configuration:");
        $display("  DATA_WIDTH     = %0d", DATA_WIDTH);
        $display("  FIFO_DEPTH     = %0d", FIFO_DEPTH);
        $display("========================================");
        env.report();
        $display("========================================");
        $display("Simulation completed successfully!");
        $display("========================================");

        $finish;
    end

endmodule

`endif // FIFO_BASE_TEST_SV
