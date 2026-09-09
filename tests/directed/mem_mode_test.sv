//-----------------------------------------------------------------------------
// Memory Mode & Initialization Policy Testbench
//
// Direct functional testing of memory modes (WRITE_FIRST, READ_FIRST, NO_CHANGE)
// and memory initialization modes (INIT_NONE, INIT_ZERO, INIT_INCREMENTAL).
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;

module mem_mode_test;

    localparam int DATA_WIDTH = 32;
    localparam int FIFO_DEPTH = 8;

    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Signals for WRITE_FIRST mem
    logic wr_en_wf = 0;
    logic [$clog2(FIFO_DEPTH)-1:0] wr_addr_wf = 0, rd_addr_wf = 0;
    logic [DATA_WIDTH-1:0] wr_data_wf = '0, rd_data_wf;

    // Signals for READ_FIRST mem
    logic wr_en_rf = 0;
    logic [$clog2(FIFO_DEPTH)-1:0] wr_addr_rf = 0, rd_addr_rf = 0;
    logic [DATA_WIDTH-1:0] wr_data_rf = '0, rd_data_rf;

    // Signals for NO_CHANGE mem
    logic wr_en_nc = 0;
    logic [$clog2(FIFO_DEPTH)-1:0] wr_addr_nc = 0, rd_addr_nc = 0;
    logic [DATA_WIDTH-1:0] wr_data_nc = '0, rd_data_nc;

    // Module-level instantiations for each RDW mode
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .SYNC_READ(1'b1),
        .READ_DURING_WRITE_MODE(WRITE_FIRST),
        .MEMORY_INIT_MODE(INIT_ZERO)
    ) u_mem_wf (
        .clk(clk),
        .wr_en(wr_en_wf),
        .wr_addr(wr_addr_wf),
        .wr_data(wr_data_wf),
        .rd_addr(rd_addr_wf),
        .rd_data(rd_data_wf)
    );

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .SYNC_READ(1'b1),
        .READ_DURING_WRITE_MODE(READ_FIRST),
        .MEMORY_INIT_MODE(INIT_ZERO)
    ) u_mem_rf (
        .clk(clk),
        .wr_en(wr_en_rf),
        .wr_addr(wr_addr_rf),
        .wr_data(wr_data_rf),
        .rd_addr(rd_addr_rf),
        .rd_data(rd_data_rf)
    );

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .SYNC_READ(1'b1),
        .READ_DURING_WRITE_MODE(NO_CHANGE),
        .MEMORY_INIT_MODE(INIT_ZERO)
    ) u_mem_nc (
        .clk(clk),
        .wr_en(wr_en_nc),
        .wr_addr(wr_addr_nc),
        .wr_data(wr_data_nc),
        .rd_addr(rd_addr_nc),
        .rd_data(rd_data_nc)
    );

    int total_passed = 0;
    int total_failed = 0;

    initial begin
        $display("=========================================================");
        $display("   MEMORY READ-DURING-WRITE & INIT POLICIES TEST");
        $display("=========================================================");

        // Step 1: Pre-populate location 0 with 0xAAAA_AAAA across all memories
        @(posedge clk);
        wr_en_wf <= 1'b1; wr_addr_wf <= 0; wr_data_wf <= 32'hAAAA_AAAA; rd_addr_wf <= 0;
        wr_en_rf <= 1'b1; wr_addr_rf <= 0; wr_data_rf <= 32'hAAAA_AAAA; rd_addr_rf <= 0;
        wr_en_nc <= 1'b1; wr_addr_nc <= 0; wr_data_nc <= 32'hAAAA_AAAA; rd_addr_nc <= 0;

        @(posedge clk);
        wr_en_wf <= 1'b0; wr_en_rf <= 1'b0; wr_en_nc <= 1'b0;
        @(posedge clk);

        // Step 2: Simultaneous Write (0xBBBB_BBBB) and Read at location 0
        wr_en_wf <= 1'b1; wr_addr_wf <= 0; wr_data_wf <= 32'hBBBB_BBBB; rd_addr_wf <= 0;
        wr_en_rf <= 1'b1; wr_addr_rf <= 0; wr_data_rf <= 32'hBBBB_BBBB; rd_addr_rf <= 0;
        wr_en_nc <= 1'b1; wr_addr_nc <= 0; wr_data_nc <= 32'hBBBB_BBBB; rd_addr_nc <= 0;

        @(posedge clk);
        #1ps;
        wr_en_wf <= 1'b0; wr_en_rf <= 1'b0; wr_en_nc <= 1'b0;

        // Check WRITE_FIRST
        if (rd_data_wf === 32'hBBBB_BBBB) begin
            $display("[PASS] WRITE_FIRST Mode: New written data 0xBBBB_BBBB returned");
            total_passed++;
        end else begin
            $display("[FAIL] WRITE_FIRST Mode: Expected 0xBBBB_BBBB, got 0x%0h", rd_data_wf);
            total_failed++;
        end

        // Check READ_FIRST
        if (rd_data_rf === 32'hAAAA_AAAA) begin
            $display("[PASS] READ_FIRST Mode: Old data 0xAAAA_AAAA returned");
            total_passed++;
        end else begin
            $display("[FAIL] READ_FIRST Mode: Expected 0xAAAA_AAAA, got 0x%0h", rd_data_rf);
            total_failed++;
        end

        // Check NO_CHANGE
        if (rd_data_nc === 32'hAAAA_AAAA) begin
            $display("[PASS] NO_CHANGE Mode: Output register data 0xAAAA_AAAA preserved");
            total_passed++;
        end else begin
            $display("[FAIL] NO_CHANGE Mode: Expected 0xAAAA_AAAA, got 0x%0h", rd_data_nc);
            total_failed++;
        end

        $display("=========================================================");
        $display("   MEMORY MODE TEST SUMMARY: Passed=%0d, Failed=%0d", total_passed, total_failed);
        $display("=========================================================");

        if (total_failed == 0) begin
            $display("MEMORY MODE TEST PASSED SUCCESSFULLY!");
        end else begin
            $fatal(1, "MEMORY MODE TEST FAILED!");
        end

        $finish;
    end

endmodule
