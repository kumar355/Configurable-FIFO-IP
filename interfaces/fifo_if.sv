interface fifo_if
#(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)
(
    input logic clk,
    input logic rst_n
);

    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    //==========================================================
    // Write Interface
    //==========================================================

    logic                    wr_en;
    logic [DATA_WIDTH-1:0]   din;

    //==========================================================
    // Read Interface
    //==========================================================

    logic                    rd_en;
    logic [DATA_WIDTH-1:0]   dout;

    //==========================================================
    // Control
    //==========================================================

    logic enable;
    logic flush;

    //==========================================================
    // Runtime Configuration
    //==========================================================

    logic [ADDR_WIDTH:0] af_threshold;
    logic [ADDR_WIDTH:0] ae_threshold;

    //==========================================================
    // Status
    //==========================================================

    logic full;
    logic empty;
    logic almost_full;
    logic almost_empty;

    logic overflow;
    logic underflow;

    logic [ADDR_WIDTH:0] occupancy;

    logic [31:0] debug_status;

    //==========================================================
    // Driver Clocking Block
    //==========================================================

    clocking drv_cb @(posedge clk);

        default input #1step output #1ns;

        output wr_en;
        output rd_en;
        output din;
        output enable;
        output flush;
        output af_threshold;
        output ae_threshold;

        input dout;
        input full;
        input empty;
        input almost_full;
        input almost_empty;
        input overflow;
        input underflow;
        input occupancy;
        input debug_status;

    endclocking

    //==========================================================
    // Monitor Clocking Block
    //==========================================================

    clocking mon_cb @(posedge clk);

        default input #1step;

        input wr_en;
        input rd_en;
        input din;

        input enable;
        input flush;

        input af_threshold;
        input ae_threshold;

        input dout;

        input full;
        input empty;
        input almost_full;
        input almost_empty;

        input overflow;
        input underflow;

        input occupancy;
        input debug_status;

    endclocking

    //==========================================================
    // DUT Modport
    //==========================================================

    modport DUT
    (
        input  clk,
        input  rst_n,

        input  wr_en,
        input  rd_en,

        input  din,

        input  enable,
        input  flush,

        input  af_threshold,
        input  ae_threshold,

        output dout,

        output full,
        output empty,

        output almost_full,
        output almost_empty,

        output overflow,
        output underflow,

        output occupancy,
        output debug_status
    );

    //==========================================================
    // Driver Modport
    //==========================================================

    modport DRIVER
    (
        clocking drv_cb,

        input clk,
        input rst_n
    );

    //==========================================================
    // Monitor Modport
    //==========================================================

    modport MONITOR
    (
        clocking mon_cb,

        input clk,
        input rst_n
    );

endinterface