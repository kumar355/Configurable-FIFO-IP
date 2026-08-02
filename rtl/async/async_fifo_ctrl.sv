import fifo_pkg::*;

module async_fifo_ctrl
#(
    parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH
)
(
    input  logic                      wr_clk,
    input  logic                      wr_rst_n,
    input  logic                      rd_clk,
    input  logic                      rd_rst_n,

    input  logic                      wr_en,
    input  logic                      rd_en,

    input  logic                      enable,
    input  logic                      flush,

    input  logic [DATA_WIDTH-1:0]     wr_data,

    input  logic [$clog2(FIFO_DEPTH):0] af_threshold,
    input  logic [$clog2(FIFO_DEPTH):0] ae_threshold,

    input  logic [DATA_WIDTH-1:0]     mem_rd_data,

    output logic                      wr_req,
    output logic                      rd_req,

    output logic [$clog2(FIFO_DEPTH)-1:0] mem_wr_addr,
    output logic [$clog2(FIFO_DEPTH)-1:0] mem_rd_addr,

    output logic [DATA_WIDTH-1:0]     mem_wr_data,

    output logic                      full,
    output logic                      empty,

    output logic                      almost_full,
    output logic                      almost_empty,

    output logic                      overflow,
    output logic                      underflow,

    output logic [$clog2(FIFO_DEPTH):0] occupancy,

    output logic [DATA_WIDTH-1:0]     rd_data,

    output logic [31:0]              debug_status
);

    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;

    // Debug packing sizes
    localparam int DEBUG_CORE_WIDTH = 4 + 3 * PTR_WIDTH;
    localparam int DEBUG_PAD = (DEBUG_CORE_WIDTH <= 32) ? 32 - DEBUG_CORE_WIDTH : 0;

    function automatic logic [PTR_WIDTH-1:0] binary_to_gray(
        input logic [PTR_WIDTH-1:0] binary
    );
        binary_to_gray = binary ^ (binary >> 1);
    endfunction

    function automatic logic [PTR_WIDTH-1:0] gray_to_binary(
        input logic [PTR_WIDTH-1:0] gray
    );
        logic [PTR_WIDTH-1:0] binary;
        binary[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
        for (int i = PTR_WIDTH-2; i >= 0; i--) begin
            binary[i] = binary[i+1] ^ gray[i];
        end
        gray_to_binary = binary;
    endfunction

    function automatic logic [PTR_WIDTH-1:0] invert_wrap_bits(
        input logic [PTR_WIDTH-1:0] gray
    );
        logic [PTR_WIDTH-1:0] inverted;
        if (PTR_WIDTH == 1) begin
            inverted[0] = ~gray[0];
        end else begin
            inverted[PTR_WIDTH-1] = ~gray[PTR_WIDTH-1];
            inverted[PTR_WIDTH-2] = ~gray[PTR_WIDTH-2];
            for (int i = PTR_WIDTH-3; i >= 0; i--) begin
                inverted[i] = gray[i];
            end
        end
        invert_wrap_bits = inverted;
    endfunction

    // Domain control signals
    logic enable_wr;
    logic enable_rd;
    logic flush_wr;
    logic flush_rd;

    // Local domain flush latches to safely generate domain-local resets
    logic flush_wr_active;
    logic flush_rd_active;

    logic wr_rst_n_eff;
    logic rd_rst_n_eff;

    // Write domain pointers
    logic [PTR_WIDTH-1:0] wr_bin;
    logic [PTR_WIDTH-1:0] wr_gray;
    logic [PTR_WIDTH-1:0] wr_next_bin;
    logic [PTR_WIDTH-1:0] wr_next_gray;

    // Read domain pointers
    logic [PTR_WIDTH-1:0] rd_bin;
    logic [PTR_WIDTH-1:0] rd_gray;

    // Synchronized remote pointers
    logic [PTR_WIDTH-1:0] rd_gray_sync_in_wr;
    logic [PTR_WIDTH-1:0] wr_gray_sync_in_rd;
    logic [PTR_WIDTH-1:0] rd_bin_sync_in_wr;
    logic [PTR_WIDTH-1:0] wr_bin_sync_in_rd;

    // Occupancy in each domain
    // write_occupancy is the write-domain estimate derived from the local
    // write pointer and the synchronized remote read pointer.
    // read_occupancy is the read-domain estimate derived from the local read
    // pointer and the synchronized remote write pointer.
    // occupancy_wr is the local writer-owned occupancy value exposed on the
    // external occupancy output. This is a domain-local ownership model;
    // the FIFO does not present a single exact cross-domain value.
    logic [PTR_WIDTH-1:0] write_occupancy;
    logic [PTR_WIDTH-1:0] read_occupancy;
    logic [PTR_WIDTH-1:0] occupancy_wr;

    // Domain-local almost threshold indicators
    logic almost_full_wr;
    logic almost_empty_rd;

    // Error state
    fifo_error_t wr_last_error;
    fifo_error_t rd_last_error;

    // Internal statistics
    fifo_stats_t wr_stats;
    fifo_stats_t rd_stats;

    // Pointer synchronization between domains
    synchronizer #(.WIDTH(1)) u_sync_enable_wr (
        .clk(wr_clk),
        .rst_n(wr_rst_n),
        .async_in(enable),
        .sync_out(enable_wr)
    );

    synchronizer #(.WIDTH(1)) u_sync_enable_rd (
        .clk(rd_clk),
        .rst_n(rd_rst_n),
        .async_in(enable),
        .sync_out(enable_rd)
    );

    synchronizer #(.WIDTH(1)) u_sync_flush_wr (
        .clk(wr_clk),
        .rst_n(wr_rst_n),
        .async_in(flush),
        .sync_out(flush_wr)
    );

    synchronizer #(.WIDTH(1)) u_sync_flush_rd (
        .clk(rd_clk),
        .rst_n(rd_rst_n),
        .async_in(flush),
        .sync_out(flush_rd)
    );

    synchronizer #(.WIDTH(PTR_WIDTH)) u_sync_rd_ptr (
        .clk(wr_clk),
        .rst_n(wr_rst_n),
        .async_in(rd_gray),
        .sync_out(rd_gray_sync_in_wr)
    );

    synchronizer #(.WIDTH(PTR_WIDTH)) u_sync_wr_ptr (
        .clk(rd_clk),
        .rst_n(rd_rst_n),
        .async_in(wr_gray),
        .sync_out(wr_gray_sync_in_rd)
    );

    // Effective resets incorporate flush in each domain.
    // flush_wr and flush_rd are synchronized into each clock domain.
    // These local active-flush latches ensure the domain is held in reset
    // long enough for the synchronized flush event to be serviced.
    assign wr_rst_n_eff = wr_rst_n && !flush_wr_active;
    assign rd_rst_n_eff = rd_rst_n && !flush_rd_active;

    // Local pointer arithmetic
    always_comb begin
        wr_next_bin = wr_bin + 1'b1;
        wr_next_gray = binary_to_gray(wr_next_bin);
    end

    // Local flush activation registers
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            flush_wr_active <= 1'b0;
        else
            flush_wr_active <= flush_wr;
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            flush_rd_active <= 1'b0;
        else
            flush_rd_active <= flush_rd;
    end

    // Synchronized remote binary pointers
    assign rd_bin_sync_in_wr = gray_to_binary(rd_gray_sync_in_wr);
    assign wr_bin_sync_in_rd = gray_to_binary(wr_gray_sync_in_rd);

    // Occupancy logic
    // The external occupancy output is writer-owned and represents the local
    // write-domain view of FIFO occupancy. The read domain maintains its own
    // estimate separately and is not exposed directly on the external port.
    assign write_occupancy = wr_bin - rd_bin_sync_in_wr;
    assign read_occupancy  = wr_bin_sync_in_rd - rd_bin;
    assign occupancy       = occupancy_wr;

    // Memory interface
    assign mem_wr_addr = wr_bin[ADDR_WIDTH-1:0];
    assign mem_rd_addr = rd_bin[ADDR_WIDTH-1:0];
    assign mem_wr_data = wr_data;

    // Write and read request generation
    assign full = (wr_next_gray == invert_wrap_bits(rd_gray_sync_in_wr));
    assign empty = (rd_gray == wr_gray_sync_in_rd);

    // Block requests during local flush/reset so the FIFO memory
    // and pointer domains do not see stale operations while reset is active.
    assign wr_req = wr_en && enable_wr && !full && wr_rst_n_eff;
    assign rd_req = rd_en && enable_rd && !empty && rd_rst_n_eff;

    assign almost_full  = almost_full_wr;
    assign almost_empty = almost_empty_rd;

    assign overflow  = (wr_last_error == ERR_OVERFLOW);
    assign underflow = (rd_last_error == ERR_UNDERFLOW);

    assign debug_status = {
        {DEBUG_PAD{1'b0}},
        full,
        empty,
        overflow,
        underflow,
        occupancy_wr,
        wr_bin,
        rd_bin_sync_in_wr
    };

    // Occupancy and almost threshold generation in domain ownership
    always_ff @(posedge wr_clk or negedge wr_rst_n_eff) begin
        if (!wr_rst_n_eff) begin
            occupancy_wr   <= '0;
            almost_full_wr <= 1'b0;
        end else begin
            occupancy_wr   <= write_occupancy;
            almost_full_wr <= (write_occupancy >= af_threshold);
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n_eff) begin
        if (!rd_rst_n_eff) begin
            almost_empty_rd <= 1'b1;
        end else begin
            almost_empty_rd <= (read_occupancy <= ae_threshold);
        end
    end

    // Write domain pointer and error management
    gray_counter #(.WIDTH(PTR_WIDTH)) u_wr_gray_counter (
        .clk(wr_clk),
        .rst_n(wr_rst_n_eff),
        .inc(wr_req),
        .binary(wr_bin),
        .gray(wr_gray)
    );

    always_ff @(posedge wr_clk or negedge wr_rst_n_eff) begin
        if (!wr_rst_n_eff) begin
            wr_last_error <= ERR_NONE;
        end else begin
            if (wr_en && enable_wr && full)
                wr_last_error <= ERR_OVERFLOW;
            else
                wr_last_error <= ERR_NONE;
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n_eff) begin
        if (!wr_rst_n_eff) begin
            wr_stats.write_count    <= '0;
            wr_stats.read_count     <= '0;
            wr_stats.overflow_count <= '0;
            wr_stats.underflow_count<= '0;
            wr_stats.peak_occupancy <= '0;
        end else begin
            if (wr_req)
                wr_stats.write_count <= wr_stats.write_count + 1'b1;

            if (wr_en && enable_wr && full)
                wr_stats.overflow_count <= wr_stats.overflow_count + 1'b1;

            if (write_occupancy > wr_stats.peak_occupancy)
                wr_stats.peak_occupancy <= write_occupancy;
        end
    end

    // Read domain pointer and error management
    gray_counter #(.WIDTH(PTR_WIDTH)) u_rd_gray_counter (
        .clk(rd_clk),
        .rst_n(rd_rst_n_eff),
        .inc(rd_req),
        .binary(rd_bin),
        .gray(rd_gray)
    );

    always_ff @(posedge rd_clk or negedge rd_rst_n_eff) begin
        if (!rd_rst_n_eff) begin
            rd_last_error <= ERR_NONE;
        end else begin
            if (rd_en && enable_rd && empty)
                rd_last_error <= ERR_UNDERFLOW;
            else
                rd_last_error <= ERR_NONE;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n_eff) begin
        if (!rd_rst_n_eff) begin
            rd_stats.write_count    <= '0;
            rd_stats.read_count     <= '0;
            rd_stats.overflow_count <= '0;
            rd_stats.underflow_count<= '0;
            rd_stats.peak_occupancy <= '0;
        end else begin
            if (rd_req)
                rd_stats.read_count <= rd_stats.read_count + 1'b1;

            if (rd_en && enable_rd && empty)
                rd_stats.underflow_count <= rd_stats.underflow_count + 1'b1;

            if (read_occupancy > rd_stats.peak_occupancy)
                rd_stats.peak_occupancy <= read_occupancy;
        end
    end

    // Registered read data
    always_ff @(posedge rd_clk or negedge rd_rst_n_eff) begin
        if (!rd_rst_n_eff) begin
            rd_data <= '0;
        end else if (rd_req) begin
            rd_data <= mem_rd_data;
        end
    end

endmodule
