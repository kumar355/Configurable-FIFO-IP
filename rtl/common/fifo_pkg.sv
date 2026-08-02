package fifo_pkg;

    
    parameter int DEFAULT_DATA_WIDTH = 32;
    parameter int DEFAULT_FIFO_DEPTH = 16;

    

    typedef enum logic
    {
        FIFO_STANDARD,
        FIFO_FWFT
    } fifo_mode_t;


    typedef enum logic [2:0]
    {
        ERR_NONE,
        ERR_OVERFLOW,
        ERR_UNDERFLOW,
        ERR_RESET,
        ERR_CONFIG
    } fifo_error_t;

    typedef enum logic [1:0]
        {
            WRITE_FIRST,
            READ_FIRST,
            NO_CHANGE
        } rdw_mode_t;

        typedef enum logic [1:0]
        {
            INIT_NONE,
            INIT_ZERO,
            INIT_INCREMENTAL
        } mem_init_mode_t;
    typedef struct packed
    {
        logic full;
        logic empty;
        logic almost_full;
        logic almost_empty;
        logic overflow;
        logic underflow;
    } fifo_status_t;

  

    typedef struct packed
    {
        logic [31:0] write_count;
        logic [31:0] read_count;
        logic [31:0] overflow_count;
        logic [31:0] underflow_count;
        logic [31:0] peak_occupancy;
    } fifo_stats_t;

   
    typedef struct packed
    {
        logic [15:0] wr_ptr;
        logic [15:0] rd_ptr;
        logic [15:0] occupancy;
        fifo_error_t last_error;
    } fifo_debug_t;

    typedef struct packed
    {
        logic [15:0] wr_ptr;

        logic [15:0] rd_ptr;

        logic [15:0] occupancy;

        fifo_error_t last_error;

    } fifo_ctrl_state_t;
    typedef enum logic [2:0]
    {
        OP_IDLE,

        OP_WRITE,

        OP_READ,

        OP_READ_WRITE,

        OP_FLUSH,

        OP_OVERFLOW,

        OP_UNDERFLOW

    } fifo_operation_t;
    localparam logic TRUE  = 1'b1;
    localparam logic FALSE = 1'b0;

 

    function automatic int max(input int a, input int b);
        if(a > b)
            return a;
        else
            return b;
    endfunction

    function automatic int min(input int a, input int b);
        if(a < b)
            return a;
        else
            return b;
    endfunction

endpackage