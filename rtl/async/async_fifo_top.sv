import fifo_pkg::*;

module async_fifo_top
#(
    parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH,
    parameter rdw_mode_t READ_DURING_WRITE_MODE = WRITE_FIRST,
    parameter mem_init_mode_t MEMORY_INIT_MODE = INIT_NONE
)
(
    input  logic                      wr_clk,
    input  logic                      wr_rst_n,
    input  logic                      rd_clk,
    input  logic                      rd_rst_n,

    input  logic                      wr_en,
    input  logic                      rd_en,

    input  logic [DATA_WIDTH-1:0]     din,

    input  logic                      enable,
    input  logic                      flush,

    input  logic [$clog2(FIFO_DEPTH):0] af_threshold,
    input  logic [$clog2(FIFO_DEPTH):0] ae_threshold,

    output logic [DATA_WIDTH-1:0]     dout,

    output logic                      full,
    output logic                      empty,
    output logic                      almost_full,
    output logic                      almost_empty,
    output logic                      overflow,
    output logic                      underflow,

    output logic [$clog2(FIFO_DEPTH):0] occupancy,

    output logic [31:0]              debug_status
);

    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    logic                wr_req;
    logic                rd_req;
    logic [ADDR_WIDTH-1:0] mem_wr_addr;
    logic [ADDR_WIDTH-1:0] mem_rd_addr;
    logic [DATA_WIDTH-1:0] mem_wr_data;
    logic [DATA_WIDTH-1:0] mem_rd_data;

    async_fifo_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_async_fifo_ctrl (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .enable(enable),
        .flush(flush),

        .wr_data(din),

        .af_threshold(af_threshold),
        .ae_threshold(ae_threshold),

        .mem_rd_data(mem_rd_data),

        .wr_req(wr_req),
        .rd_req(rd_req),

        .mem_wr_addr(mem_wr_addr),
        .mem_rd_addr(mem_rd_addr),

        .mem_wr_data(mem_wr_data),

        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),

        .overflow(overflow),
        .underflow(underflow),

        .occupancy(occupancy),

        .rd_data(dout),

        .debug_status(debug_status)
    );

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .SYNC_READ(1'b0),
        .READ_DURING_WRITE_MODE(READ_DURING_WRITE_MODE),
        .MEMORY_INIT_MODE(MEMORY_INIT_MODE)
    ) u_fifo_mem (
        .clk(wr_clk),

        .wr_en(wr_req),
        .wr_addr(mem_wr_addr),
        .wr_data(mem_wr_data),

        .rd_addr(mem_rd_addr),

        .rd_data(mem_rd_data)
    );

endmodule
