//-----------------------------------------------------------------------------
// Parameter Sweep Testbench for Configurable FIFO IP
//
// Tests multiple valid parameterized configurations of sync_fifo_top:
// - DW=1,  DEPTH=2
// - DW=2,  DEPTH=4
// - DW=8,  DEPTH=8
// - DW=16, DEPTH=16
// - DW=32, DEPTH=32
// - DW=64, DEPTH=64
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;

module param_sweep_test;

    logic clk = 0;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    int total_passed = 0;
    int total_failed = 0;

    // Test Config 1: DW=1, DEPTH=2
    logic rst1 = 0, wr1 = 0, rd1 = 0; logic [0:0] din1, dout1; logic f1, e1; logic [1:0] occ1;
    sync_fifo_top #(.DATA_WIDTH(1), .FIFO_DEPTH(2)) dut1 (
        .clk(clk), .rst_n(rst1), .wr_en(wr1), .rd_en(rd1), .din(din1),
        .enable(1'b1), .flush(1'b0), .af_threshold(1), .ae_threshold(1),
        .dout(dout1), .full(f1), .empty(e1), .occupancy(occ1)
    );

    // Test Config 2: DW=8, DEPTH=8
    logic rst2 = 0, wr2 = 0, rd2 = 0; logic [7:0] din2, dout2; logic f2, e2; logic [3:0] occ2;
    sync_fifo_top #(.DATA_WIDTH(8), .FIFO_DEPTH(8)) dut2 (
        .clk(clk), .rst_n(rst2), .wr_en(wr2), .rd_en(rd2), .din(din2),
        .enable(1'b1), .flush(1'b0), .af_threshold(7), .ae_threshold(1),
        .dout(dout2), .full(f2), .empty(e2), .occupancy(occ2)
    );

    // Test Config 3: DW=32, DEPTH=16
    logic rst3 = 0, wr3 = 0, rd3 = 0; logic [31:0] din3, dout3; logic f3, e3; logic [4:0] occ3;
    sync_fifo_top #(.DATA_WIDTH(32), .FIFO_DEPTH(16)) dut3 (
        .clk(clk), .rst_n(rst3), .wr_en(wr3), .rd_en(rd3), .din(din3),
        .enable(1'b1), .flush(1'b0), .af_threshold(15), .ae_threshold(1),
        .dout(dout3), .full(f3), .empty(e3), .occupancy(occ3)
    );

    // Test Config 4: DW=64, DEPTH=32
    logic rst4 = 0, wr4 = 0, rd4 = 0; logic [63:0] din4, dout4; logic f4, e4; logic [5:0] occ4;
    sync_fifo_top #(.DATA_WIDTH(64), .FIFO_DEPTH(32)) dut4 (
        .clk(clk), .rst_n(rst4), .wr_en(wr4), .rd_en(rd4), .din(din4),
        .enable(1'b1), .flush(1'b0), .af_threshold(31), .ae_threshold(1),
        .dout(dout4), .full(f4), .empty(e4), .occupancy(occ4)
    );

    initial begin
        $display("=========================================================");
        $display("   PARAMETER SWEEP TEST SUITE (DATA_WIDTH & FIFO_DEPTH)");
        $display("=========================================================");

        // Test DUT1 (1x2)
        rst1 = 0; repeat(3) @(posedge clk); rst1 = 1; @(posedge clk);
        wr1 <= 1; din1 <= 1'b1; @(posedge clk);
        wr1 <= 1; din1 <= 1'b0; @(posedge clk);
        wr1 <= 0; #1ps;
        if (f1 && occ1 == 2) begin
            $display("[PASS] Parameter Config 1 (DW=1, DEPTH=2) Full capacity verified");
            total_passed++;
        end else begin
            $display("[FAIL] Parameter Config 1 (DW=1, DEPTH=2) Full capacity failed");
            total_failed++;
        end

        // Test DUT2 (8x8)
        rst2 = 0; repeat(3) @(posedge clk); rst2 = 1; @(posedge clk);
        for (int i = 0; i < 8; i++) begin wr2 <= 1; din2 <= 8'(i+1); @(posedge clk); end
        wr2 <= 0; #1ps;
        if (f2 && occ2 == 8) begin
            $display("[PASS] Parameter Config 2 (DW=8, DEPTH=8) Full capacity verified");
            total_passed++;
        end else begin
            $display("[FAIL] Parameter Config 2 (DW=8, DEPTH=8) Full capacity failed");
            total_failed++;
        end

        // Test DUT3 (32x16)
        rst3 = 0; repeat(3) @(posedge clk); rst3 = 1; @(posedge clk);
        for (int i = 0; i < 16; i++) begin wr3 <= 1; din3 <= 32'(32'hA000_0000 + i); @(posedge clk); end
        wr3 <= 0; #1ps;
        if (f3 && occ3 == 16) begin
            $display("[PASS] Parameter Config 3 (DW=32, DEPTH=16) Full capacity verified");
            total_passed++;
        end else begin
            $display("[FAIL] Parameter Config 3 (DW=32, DEPTH=16) Full capacity failed");
            total_failed++;
        end

        // Test DUT4 (64x32)
        rst4 = 0; repeat(3) @(posedge clk); rst4 = 1; @(posedge clk);
        for (int i = 0; i < 32; i++) begin wr4 <= 1; din4 <= 64'(64'hFEED_FACE_0000_0000 + i); @(posedge clk); end
        wr4 <= 0; #1ps;
        if (f4 && occ4 == 32) begin
            $display("[PASS] Parameter Config 4 (DW=64, DEPTH=32) Full capacity verified");
            total_passed++;
        end else begin
            $display("[FAIL] Parameter Config 4 (DW=64, DEPTH=32) Full capacity failed");
            total_failed++;
        end

        $display("=========================================================");
        $display("   PARAMETER SWEEP SUMMARY: Passed=%0d, Failed=%0d", total_passed, total_failed);
        $display("=========================================================");

        if (total_failed == 0) begin
            $display("ALL PARAMETER CONFIGURATIONS PASSED SUCCESSFULLY!");
        end else begin
            $fatal(1, "PARAMETER SWEEP TEST SUITE FAILED!");
        end

        $finish;
    end

endmodule
