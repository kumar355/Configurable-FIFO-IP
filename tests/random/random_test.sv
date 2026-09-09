//-----------------------------------------------------------------------------
// Random Test for Configurable FIFO IP
//
// Runs high-volume constrained random transactions (1000 operations)
// across Synchronous FIFO DUT using full verification environment,
// reference model, scoreboard, assertions, and coverage.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;
import fifo_verif_pkg::*;

module random_test;

    localparam int DATA_WIDTH = 32;
    localparam int FIFO_DEPTH = 16;
    localparam int NUM_TRANSACTIONS = 1000;
    localparam time CLK_PERIOD = 10ns;

    logic clk;
    logic rst_n;

    fifo_if #(DATA_WIDTH, FIFO_DEPTH) fifo_interface (
        .clk(clk),
        .rst_n(rst_n)
    );

    sync_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
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

    fifo_environment #(DATA_WIDTH, FIFO_DEPTH) env;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("[RANDOM TEST] Starting High-Volume Random Test (%0d txns)", NUM_TRANSACTIONS);
        $display("========================================");

        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        env = new(
            .name_in("random_test_env"),
            .drv_vif_in(fifo_interface.DRIVER),
            .mon_vif_in(fifo_interface.MONITOR),
            .num_transactions_in(NUM_TRANSACTIONS)
        );
        env.build();
        env.connect();
        env.run();

        repeat (10) @(posedge clk);

        if (env.scoreboard.failed == 0 && env.scoreboard.compared == NUM_TRANSACTIONS) begin
            $display("========================================");
            $display("[RANDOM TEST PASSED] %0d / %0d transactions passed successfully!", env.scoreboard.passed, env.scoreboard.compared);
            $display("========================================");
        end else begin
            $fatal(1, "[RANDOM TEST FAILED] Scoreboard reported %0d failures out of %0d transactions", env.scoreboard.failed, env.scoreboard.compared);
        end

        $finish;
    end

endmodule
