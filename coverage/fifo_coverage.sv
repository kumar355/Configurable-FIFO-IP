`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// Functional Coverage for Configurable FIFO IP
//
// Tracks coverage for:
// - All FIFO operations (IDLE, WRITE, READ, READ_WRITE, FLUSH, OVERFLOW, UNDERFLOW)
// - Occupancy levels (EMPTY, ALMOST_EMPTY, PARTIAL, ALMOST_FULL, FULL)
// - Status flags and error conditions
// - Cross coverage between operations and occupancy states
//-----------------------------------------------------------------------------
import fifo_pkg::*;

module fifo_coverage
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

    input fifo_operation_t dbg_operation,
    input logic [$clog2(FIFO_DEPTH):0] af_threshold,
    input logic [$clog2(FIFO_DEPTH):0] ae_threshold,
    input logic full,
    input logic empty,
    input logic almost_full,
    input logic almost_empty,
    input logic overflow,
    input logic underflow,
    input logic [$clog2(FIFO_DEPTH):0] occupancy
);

`ifndef SYNTHESIS

    // Procedural coverage tracking counters for simulator compatibility
    int unsigned count_idle       = 0;
    int unsigned count_write      = 0;
    int unsigned count_read       = 0;
    int unsigned count_read_write = 0;
    int unsigned count_flush      = 0;
    int unsigned count_overflow   = 0;
    int unsigned count_underflow  = 0;

    int unsigned count_empty        = 0;
    int unsigned count_almost_empty = 0;
    int unsigned count_partial      = 0;
    int unsigned count_almost_full  = 0;
    int unsigned count_full         = 0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
        end else begin
            case (dbg_operation)
                OP_IDLE:       count_idle++;
                OP_WRITE:      count_write++;
                OP_READ:       count_read++;
                OP_READ_WRITE: count_read_write++;
                OP_FLUSH:      count_flush++;
                OP_OVERFLOW:   count_overflow++;
                OP_UNDERFLOW:  count_underflow++;
            endcase

            if (occupancy == 0)
                count_empty++;
            else if (occupancy <= ae_threshold)
                count_almost_empty++;
            else if (occupancy >= af_threshold && occupancy < FIFO_DEPTH)
                count_almost_full++;
            else if (occupancy == FIFO_DEPTH)
                count_full++;
            else
                count_partial++;
        end
    end

    final begin
        $display("========================================");
        $display("[COVERAGE REPORT] Functional Coverage Summary:");
        $display("  Operations:");
        $display("    OP_IDLE      : %0d", count_idle);
        $display("    OP_WRITE     : %0d", count_write);
        $display("    OP_READ      : %0d", count_read);
        $display("    OP_READ_WRITE: %0d", count_read_write);
        $display("    OP_FLUSH     : %0d", count_flush);
        $display("    OP_OVERFLOW  : %0d", count_overflow);
        $display("    OP_UNDERFLOW : %0d", count_underflow);
        $display("  Occupancy Bins:");
        $display("    EMPTY        : %0d", count_empty);
        $display("    ALMOST_EMPTY : %0d", count_almost_empty);
        $display("    PARTIAL      : %0d", count_partial);
        $display("    ALMOST_FULL  : %0d", count_almost_full);
        $display("    FULL         : %0d", count_full);
        $display("========================================");
    end

`ifdef ENABLE_SV_COVERGROUP
    covergroup cg_fifo @(posedge clk);
        option.per_instance = 1;
        option.name = "fifo_functional_coverage";

        cp_operation: coverpoint dbg_operation {
            bins op_idle       = {OP_IDLE};
            bins op_write      = {OP_WRITE};
            bins op_read       = {OP_READ};
            bins op_read_write = {OP_READ_WRITE};
            bins op_flush      = {OP_FLUSH};
            bins op_overflow   = {OP_OVERFLOW};
            bins op_underflow  = {OP_UNDERFLOW};
        }

        cp_occupancy: coverpoint occupancy {
            bins empty_bin        = {0};
            bins almost_empty_bin = {[1 : 2]};
            bins partial_bin      = {[3 : FIFO_DEPTH-3]};
            bins almost_full_bin  = {[FIFO_DEPTH-2 : FIFO_DEPTH-1]};
            bins full_bin         = {FIFO_DEPTH};
        }

        cp_full: coverpoint full {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_empty: coverpoint empty {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_almost_full: coverpoint almost_full {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_almost_empty: coverpoint almost_empty {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_overflow: coverpoint overflow {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_underflow: coverpoint underflow {
            bins inactive = {0};
            bins active   = {1};
        }

        cross_op_occupancy: cross cp_operation, cp_occupancy;
    endgroup

    cg_fifo inst_cg_fifo;

    initial begin
        inst_cg_fifo = new();
    end
`endif

`endif

endmodule
