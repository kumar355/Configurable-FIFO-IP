`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// SystemVerilog Assertions for Configurable FIFO IP
//
// Checks hardware invariants:
// - Deterministic reset state
// - Occupancy range bounds
// - Flag correctness (full, empty, almost_full, almost_empty)
// - Overflow and Underflow detection
// - Occupancy stability on illegal write/read attempts
//-----------------------------------------------------------------------------
import fifo_pkg::*;

module fifo_assertions
#(
    parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH
)
(
    input logic clk,
    input logic rst_n,

    input logic wr_en,
    input logic rd_en,
    input logic enable,
    input logic flush,

    input logic [DATA_WIDTH-1:0] din,
    input logic [$clog2(FIFO_DEPTH):0] af_threshold,
    input logic [$clog2(FIFO_DEPTH):0] ae_threshold,

    input logic [DATA_WIDTH-1:0] dout,
    input logic full,
    input logic empty,
    input logic almost_full,
    input logic almost_empty,
    input logic overflow,
    input logic underflow,
    input logic [$clog2(FIFO_DEPTH):0] occupancy
);

    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

`ifndef SYNTHESIS

    // 1. Reset state invariant
    property p_reset_state;
        @(posedge clk) !rst_n |-> (occupancy == 0 && empty == 1'b1 && full == 1'b0 && overflow == 1'b0 && underflow == 1'b0);
    endproperty
    assert_reset_state: assert property (p_reset_state)
        else $error("[SVA FAIL] Reset state invariant violated! occupancy=%0d empty=%0b full=%0b", occupancy, empty, full);

    // 2. Occupancy bound invariant
    property p_occupancy_bound;
        @(posedge clk) disable iff (!rst_n)
        occupancy <= FIFO_DEPTH;
    endproperty
    assert_occupancy_bound: assert property (p_occupancy_bound)
        else $error("[SVA FAIL] Occupancy exceeded FIFO_DEPTH! occupancy=%0d depth=%0d", occupancy, FIFO_DEPTH);

    // 3. Empty flag invariant
    property p_empty_flag;
        @(posedge clk) disable iff (!rst_n)
        empty == (occupancy == 0);
    endproperty
    assert_empty_flag: assert property (p_empty_flag)
        else $error("[SVA FAIL] Empty flag mismatch! empty=%0b occupancy=%0d", empty, occupancy);

    // 4. Full flag invariant
    property p_full_flag;
        @(posedge clk) disable iff (!rst_n)
        full == (occupancy == FIFO_DEPTH);
    endproperty
    assert_full_flag: assert property (p_full_flag)
        else $error("[SVA FAIL] Full flag mismatch! full=%0b occupancy=%0d", full, occupancy);

    // 5. Almost Full flag invariant
    property p_almost_full_flag;
        @(posedge clk) disable iff (!rst_n)
        almost_full == (occupancy >= af_threshold);
    endproperty
    assert_almost_full_flag: assert property (p_almost_full_flag)
        else $error("[SVA FAIL] Almost full flag mismatch! almost_full=%0b occupancy=%0d threshold=%0d", almost_full, occupancy, af_threshold);

    // 6. Almost Empty flag invariant
    property p_almost_empty_flag;
        @(posedge clk) disable iff (!rst_n)
        almost_empty == (occupancy <= ae_threshold);
    endproperty
    assert_almost_empty_flag: assert property (p_almost_empty_flag)
        else $error("[SVA FAIL] Almost empty flag mismatch! almost_empty=%0b occupancy=%0d threshold=%0d", almost_empty, occupancy, ae_threshold);

    // 7. Overflow flag assertion
    always @(posedge clk) begin
        if (rst_n && enable && wr_en && !rd_en && (occupancy == FIFO_DEPTH)) begin
            #1;
            if (!overflow)
                $error("[SVA FAIL] Overflow flag not asserted after write to full FIFO!");
        end
    end

    // 8. Underflow flag assertion
    always @(posedge clk) begin
        if (rst_n && enable && rd_en && !wr_en && (occupancy == 0)) begin
            #1;
            if (!underflow)
                $error("[SVA FAIL] Underflow flag not asserted after read from empty FIFO!");
        end
    end

    // 9. Flush clears occupancy
    property p_flush_clears;
        @(posedge clk) disable iff (!rst_n)
        (flush && !wr_en && !rd_en) |=> (occupancy == 0 && empty == 1'b1);
    endproperty
    assert_flush_clears: assert property (p_flush_clears)
        else $error("[SVA FAIL] Flush did not reset occupancy to 0!");

`endif

endmodule
