//-----------------------------------------------------------------------------
// Asynchronous FIFO Testbench
//
// Verifies dual-clock domain operation across independent clock frequencies:
// - wr_clk = 100 MHz (10ns period)
// - rd_clk = 62.5 MHz (16ns period)
//
// Producer task pushes data on wr_clk domain; Consumer task pops data on
// rd_clk domain. Checks data integrity, full/empty flag transitions,
// and pointer synchronization across domain boundary.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;

module async_fifo_test;

    localparam int DATA_WIDTH = 32;
    localparam int FIFO_DEPTH = 16;
    localparam int NUM_ITEMS  = 100;

    localparam time WR_CLK_PERIOD = 10ns; // 100 MHz
    localparam time RD_CLK_PERIOD = 16ns; // 62.5 MHz

    logic wr_clk;
    logic wr_rst_n;
    logic rd_clk;
    logic rd_rst_n;

    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;
    logic enable;
    logic flush;

    logic [$clog2(FIFO_DEPTH):0] af_threshold;
    logic [$clog2(FIFO_DEPTH):0] ae_threshold;

    logic [DATA_WIDTH-1:0] dout;
    logic full;
    logic empty;
    logic almost_full;
    logic almost_empty;
    logic overflow;
    logic underflow;
    logic [$clog2(FIFO_DEPTH):0] occupancy;
    logic [31:0] debug_status;

    // Instantiate Asynchronous FIFO Top
    async_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),

        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),

        .enable(enable),
        .flush(flush),

        .af_threshold(af_threshold),
        .ae_threshold(ae_threshold),

        .dout(dout),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .overflow(overflow),
        .underflow(underflow),
        .occupancy(occupancy),
        .debug_status(debug_status)
    );

    // Clock Generation
    initial begin
        wr_clk = 1'b0;
        forever #(WR_CLK_PERIOD/2) wr_clk = ~wr_clk;
    end

    initial begin
        rd_clk = 1'b0;
        forever #(RD_CLK_PERIOD/2) rd_clk = ~rd_clk;
    end

    // Test Variables & Scoreboard Queue
    logic [DATA_WIDTH-1:0] written_queue [$];
    int unsigned items_written = 0;
    int unsigned items_read = 0;
    int unsigned mismatches = 0;

    // Producer Process (Write Domain)
    initial begin
        logic [DATA_WIDTH-1:0] val;
        wr_rst_n = 1'b0;
        wr_en = 1'b0;
        din = '0;
        enable = 1'b1;
        flush = 1'b0;
        af_threshold = FIFO_DEPTH - 1;
        ae_threshold = 1;

        repeat (5) @(posedge wr_clk);
        wr_rst_n = 1'b1;
        repeat (2) @(posedge wr_clk);

        $display("[ASYNC PRODUCER] Started write domain stream...");

        while (items_written < NUM_ITEMS) begin
            @(posedge wr_clk);
            if (!full) begin
                val = 32'hC000_0000 + items_written;
                wr_en = 1'b1;
                din = val;
                written_queue.push_back(val);
                items_written++;
                @(posedge wr_clk);
                wr_en = 1'b0;
            end else begin
                wr_en = 1'b0;
            end
        end

        @(posedge wr_clk);
        wr_en <= 1'b0;
        $display("[ASYNC PRODUCER] Finished writing %0d items.", items_written);
    end

    // Consumer Process (Read Domain)
    initial begin
        logic [DATA_WIDTH-1:0] exp_val;
        rd_rst_n = 1'b0;
        rd_en = 1'b0;

        repeat (5) @(posedge rd_clk);
        rd_rst_n = 1'b1;
        repeat (2) @(posedge rd_clk);

        $display("[ASYNC CONSUMER] Started read domain stream...");

        while (items_read < NUM_ITEMS) begin
            @(posedge rd_clk);
            if (!empty) begin
                rd_en = 1'b1;
                @(posedge rd_clk);
                rd_en = 1'b0;
                #1;
                if (written_queue.size() > 0) begin
                    exp_val = written_queue.pop_front();
                    if (dout !== exp_val) begin
                        $display("[ASYNC CONSUMER FAIL] Item %0d mismatch! Expected 0x%0h, Actual 0x%0h", items_read, exp_val, dout);
                        mismatches++;
                    end
                    items_read++;
                end
            end else begin
                rd_en = 1'b0;
            end
        end

        $display("[ASYNC CONSUMER] Finished reading %0d items.", items_read);

        $display("========================================");
        $display("[ASYNC FIFO TEST] SUMMARY:");
        $display("  Items Written : %0d", items_written);
        $display("  Items Read    : %0d", items_read);
        $display("  Mismatches    : %0d", mismatches);
        $display("========================================");

        if (mismatches == 0 && items_read == NUM_ITEMS) begin
            $display("ASYNC FIFO TEST PASSED SUCCESSFULLY!");
        end else begin
            $fatal(1, "ASYNC FIFO TEST FAILED!");
        end

        $finish;
    end

endmodule
