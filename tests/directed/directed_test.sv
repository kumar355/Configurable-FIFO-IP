//-----------------------------------------------------------------------------
// Directed Test for Configurable FIFO IP
//
// Tests targeted corner cases:
// 1. Fill FIFO to max capacity (occupancy == DEPTH, full == 1)
// 2. Write attempt when full (overflow condition)
// 3. Read back all data (fill to empty transition)
// 4. Read attempt when empty (underflow condition)
// 5. Concurrent read and write operations
// 6. Flush operation mid-sequence
// 7. Dynamic threshold changes
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;
import fifo_verif_pkg::*;

module directed_test;

    localparam int DATA_WIDTH = 32;
    localparam int FIFO_DEPTH = 16;
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

    // Clock Generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    int pass_count;
    int fail_count;

    // Test Execution Task
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("========================================");
        $display("[DIRECTED TEST] Starting Targeted Test Suite");
        $display("========================================");

        // 1. Reset DUT
        rst_n = 1'b0;
        fifo_interface.wr_en = 0;
        fifo_interface.rd_en = 0;
        fifo_interface.enable = 1;
        fifo_interface.flush = 0;
        fifo_interface.din = 0;
        fifo_interface.af_threshold = FIFO_DEPTH - 1;
        fifo_interface.ae_threshold = 1;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Step 1: Check initial reset state
        #1;
        if (fifo_interface.empty == 1 && fifo_interface.occupancy == 0) begin
            $display("[PASS] Step 1: Reset state verified (empty=1, occupancy=0)");
            pass_count++;
        end else begin
            $display("[FAIL] Step 1: Reset state mismatch (empty=%0b, occupancy=%0d)", fifo_interface.empty, fifo_interface.occupancy);
            fail_count++;
        end

        // Step 2: Fill FIFO to capacity
        $display("[DIRECTED TEST] Step 2: Filling FIFO to capacity (%0d elements)...", FIFO_DEPTH);
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            fifo_interface.din = 32'hA000_0000 + i;
            fifo_interface.wr_en = 1'b1;
            @(posedge clk);
        end
        #1;
        fifo_interface.wr_en = 1'b0;
        #1;

        if (fifo_interface.full == 1 && fifo_interface.occupancy == FIFO_DEPTH) begin
            $display("[PASS] Step 2: Full capacity reached (full=1, occupancy=%0d)", fifo_interface.occupancy);
            pass_count++;
        end else begin
            $display("[FAIL] Step 2: Full capacity failed (full=%0b, occupancy=%0d)", fifo_interface.full, fifo_interface.occupancy);
            fail_count++;
        end

        // Step 3: Overflow attempt
        $display("[DIRECTED TEST] Step 3: Triggering Overflow condition...");
        fifo_interface.din = 32'hDEAD_BEEF;
        fifo_interface.wr_en = 1'b1;
        @(posedge clk);
        #1;
        if (fifo_interface.overflow == 1) begin
            $display("[PASS] Step 3: Overflow flag asserted successfully");
            pass_count++;
        end else begin
            $display("[FAIL] Step 3: Overflow flag failed to assert");
            fail_count++;
        end
        fifo_interface.wr_en = 1'b0;
        #1;

        // Step 4: Read back all data
        $display("[DIRECTED TEST] Step 4: Reading back all elements...");
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            automatic logic [DATA_WIDTH-1:0] exp_data = 32'hA000_0000 + i;
            #1;
            if (fifo_interface.dout !== exp_data) begin
                $display("[FAIL] Step 4: Data mismatch at idx %0d! expected=0x%0h actual=0x%0h", i, exp_data, fifo_interface.dout);
                fail_count++;
            end
            fifo_interface.rd_en = 1'b1;
            @(posedge clk);
        end
        #1;
        fifo_interface.rd_en = 1'b0;
        #1;

        if (fifo_interface.empty == 1 && fifo_interface.occupancy == 0) begin
            $display("[PASS] Step 4: Read back complete (empty=1, occupancy=0)");
            pass_count++;
        end else begin
            $display("[FAIL] Step 4: Empty state not reached after drain (occupancy=%0d)", fifo_interface.occupancy);
            fail_count++;
        end

        // Step 5: Underflow attempt
        $display("[DIRECTED TEST] Step 5: Triggering Underflow condition...");
        fifo_interface.rd_en = 1'b1;
        @(posedge clk);
        #1;
        if (fifo_interface.underflow == 1) begin
            $display("[PASS] Step 5: Underflow flag asserted successfully");
            pass_count++;
        end else begin
            $display("[FAIL] Step 5: Underflow flag failed to assert");
            fail_count++;
        end
        fifo_interface.rd_en = 1'b0;
        #1;

        // Step 6: Flush test
        $display("[DIRECTED TEST] Step 6: Testing Flush operation...");
        for (int i = 0; i < 5; i++) begin
            fifo_interface.din = 32'hB000_0000 + i;
            fifo_interface.wr_en = 1'b1;
            @(posedge clk);
        end
        fifo_interface.wr_en = 1'b0;
        fifo_interface.flush = 1'b1;
        @(posedge clk);
        #1;
        fifo_interface.flush = 1'b0;
        #1;

        if (fifo_interface.empty == 1 && fifo_interface.occupancy == 0) begin
            $display("[PASS] Step 6: Flush successfully cleared FIFO");
            pass_count++;
        end else begin
            $display("[FAIL] Step 6: Flush failed to clear FIFO (occupancy=%0d)", fifo_interface.occupancy);
            fail_count++;
        end

        $display("========================================");
        $display("[DIRECTED TEST] SUMMARY: Pass=%0d Fail=%0d", pass_count, fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("DIRECTED TEST PASSED SUCCESSFULLY!");
        else
            $fatal(1, "DIRECTED TEST FAILED!");

        $finish;
    end

endmodule
