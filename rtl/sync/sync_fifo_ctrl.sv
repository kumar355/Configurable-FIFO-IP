import fifo_pkg::*;

module sync_fifo_ctrl
#(
    parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH
)
(
    input  logic clk,
    input  logic rst_n,

    input  logic wr_en,
    input  logic rd_en,

    input  logic enable,
    input  logic flush,

    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic [$clog2(FIFO_DEPTH):0] af_threshold,
    input  logic [$clog2(FIFO_DEPTH):0] ae_threshold,

    input  logic [DATA_WIDTH-1:0] mem_rd_data,

    output logic wr_req,
    output logic rd_req,

    output logic [$clog2(FIFO_DEPTH)-1:0] mem_wr_addr,
    output logic [$clog2(FIFO_DEPTH)-1:0] mem_rd_addr,

    output logic [DATA_WIDTH-1:0] mem_wr_data,

    output logic full,
    output logic empty,

    output logic almost_full,
    output logic almost_empty,

    output logic overflow,
    output logic underflow,

    output logic [$clog2(FIFO_DEPTH):0] occupancy,

    output logic [DATA_WIDTH-1:0] rd_data,

    output logic [31:0] debug_status,
    output fifo_operation_t dbg_operation
);

    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Debug packing sizes
    // Clamped to avoid illegal negative replication counts for large
    // FIFO_DEPTH configurations (mirrors the guard already used in
    // async_fifo_ctrl.sv for the same DEBUG_PAD computation).
    localparam int DEBUG_CORE_WIDTH = 4 + 3 * (ADDR_WIDTH + 1);
    localparam int DEBUG_PAD = (DEBUG_CORE_WIDTH <= 32) ? (32 - DEBUG_CORE_WIDTH) : 0;

    // Elaboration-time parameter check: FIFO_DEPTH < 2 produces an
    // illegal zero-width address ($clog2(1) = 0), which is not a
    // supported configuration for this controller.
    initial
    begin
        if (FIFO_DEPTH < 2)
        begin
            $fatal("sync_fifo_ctrl: FIFO_DEPTH must be >= 2 (got %0d)", FIFO_DEPTH);
        end
    end

    typedef struct packed
    {
        logic [ADDR_WIDTH:0] wr_ptr;
        logic [ADDR_WIDTH:0] rd_ptr;
        logic [ADDR_WIDTH:0] occupancy;
        fifo_error_t last_error;
    } sync_fifo_ctrl_state_t;

    sync_fifo_ctrl_state_t state;
    sync_fifo_ctrl_state_t next_state;

    fifo_operation_t operation;

    // Frozen simultaneous read/write indicators
    logic frozen_read;
    logic frozen_write;

    logic do_write;
    logic do_read;

    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;

    assign wr_addr = state.wr_ptr[ADDR_WIDTH-1:0];
    assign rd_addr = state.rd_ptr[ADDR_WIDTH-1:0];

    always_comb
    begin

        wr_req = 1'b0;

        rd_req = 1'b0;

        mem_wr_addr = wr_addr;

        mem_rd_addr = rd_addr;

        mem_wr_data = wr_data;

        case(operation)

            OP_WRITE :
            begin

                wr_req = 1'b1;

            end

            OP_READ :
            begin

                rd_req = 1'b1;

            end

            OP_READ_WRITE :
            begin

                wr_req = 1'b1;

                rd_req = 1'b1;

            end

            default :
            begin
            end

        endcase

        if (rd_req)
        begin
            mem_rd_addr = next_state.rd_ptr[ADDR_WIDTH-1:0];
        end

    end

    always_comb
    begin

        do_write = wr_en && enable;

        do_read = rd_en && enable;

        operation = OP_IDLE;

        // default frozen indicators
        frozen_read = 1'b0;
        frozen_write = 1'b0;

        unique case ({flush, do_write, do_read})

            3'b100 :
                operation = OP_FLUSH;

            3'b010 :
            begin
                if(state.occupancy == FIFO_DEPTH)
                    operation = OP_OVERFLOW;
                else
                    operation = OP_WRITE;
            end

            3'b001 :
            begin
                if(state.occupancy == 0)
                    operation = OP_UNDERFLOW;
                else
                    operation = OP_READ;
            end

            // simultaneous write & read
            3'b011 :
            begin
                // If FIFO empty, freeze the read and perform only write
                if(state.occupancy == 0)
                begin
                    frozen_read = 1'b1;
                    operation = OP_WRITE;
                end
                // If FIFO full, allow simultaneous read/write (occupancy unchanged)
                else if(state.occupancy == FIFO_DEPTH)
                    operation = OP_READ_WRITE;
                // Partial: allow simultaneous read/write
                else
                    operation = OP_READ_WRITE;
            end

            default :
                operation = OP_IDLE;

        endcase

    end

    // Next State Logic

    always_comb
    begin

        next_state = state;

        case(operation)

            OP_IDLE :
            begin
                next_state.last_error  = ERR_NONE;
            end

            OP_FLUSH :
            begin

                next_state.wr_ptr      = '0;
                next_state.rd_ptr      = '0;
                next_state.occupancy   = '0;
                next_state.last_error  = ERR_NONE;

            end

            OP_WRITE :
            begin

                next_state.wr_ptr =
                    state.wr_ptr + 1'b1;

                next_state.occupancy =
                    state.occupancy + 1'b1;

                next_state.last_error =
                    ERR_NONE;

            end

            OP_READ :
            begin

                next_state.rd_ptr =
                    state.rd_ptr + 1'b1;

                next_state.occupancy =
                    state.occupancy - 1'b1;

                next_state.last_error =
                    ERR_NONE;

            end

            OP_READ_WRITE :
            begin

                next_state.wr_ptr =
                    state.wr_ptr + 1'b1;

                next_state.rd_ptr =
                    state.rd_ptr + 1'b1;

                next_state.last_error =
                    ERR_NONE;

            end

            OP_OVERFLOW :
            begin

                next_state.last_error =
                    ERR_OVERFLOW;

            end

            OP_UNDERFLOW :
            begin

                next_state.last_error =
                    ERR_UNDERFLOW;

            end

            default :
            begin
            end

        endcase

    end

    always_comb
    begin

        occupancy = next_state.occupancy;

        empty =

            (next_state.occupancy == 0);

        full =

            (next_state.occupancy == FIFO_DEPTH);

        almost_full =

            (next_state.occupancy >= af_threshold);

        almost_empty =

            (next_state.occupancy <= ae_threshold);

        overflow =

            (next_state.last_error == ERR_OVERFLOW);

        underflow =

            (next_state.last_error == ERR_UNDERFLOW);


    end

    always_comb
    begin

        // Export actual operation executed by controller
        dbg_operation = operation;

        // Pack debug status
        debug_status = { {DEBUG_PAD{1'b0}},
                        frozen_read,
                        frozen_write,
                        overflow,
                        underflow,
                        next_state.occupancy,
                        next_state.wr_ptr,
                        next_state.rd_ptr };

    end

    // Read data: driven combinationally from the memory read data.
    // fifo_mem (SYNC_READ=1) already registers the read data internally
    // on posedge clk; re-registering it here would add a second, undocumented
    // pipeline stage and break single-cycle read latency. rd_data therefore
    // reflects mem_rd_data directly, valid on the same cycle mem_rd_data
    // becomes valid from fifo_mem.
    assign rd_data = mem_rd_data;

    // Sequential State Update

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            state.wr_ptr      <= '0;
            state.rd_ptr      <= '0;
            state.occupancy   <= '0;
            state.last_error  <= ERR_NONE;

        end

        else
        begin

            state <= next_state;

        end

    end

endmodule