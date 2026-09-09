import fifo_pkg::*;

module fifo_mem
#(
    parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH,
    parameter bit SYNC_READ = 1'b1,

    parameter rdw_mode_t READ_DURING_WRITE_MODE = WRITE_FIRST,
    parameter mem_init_mode_t MEMORY_INIT_MODE = INIT_NONE
)
(
    input  logic clk,

    input  logic wr_en,
    input  logic [$clog2(FIFO_DEPTH)-1:0] wr_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic [$clog2(FIFO_DEPTH)-1:0] rd_addr,

    output logic [DATA_WIDTH-1:0] rd_data
);

    import fifo_pkg::*;

    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    logic [DATA_WIDTH-1:0] rd_data_reg;

    integer i;

`ifndef SYNTHESIS

    initial
    begin

        case(MEMORY_INIT_MODE)

            INIT_NONE :
            begin
            end

            INIT_ZERO :
            begin
                for(i=0;i<FIFO_DEPTH;i++)
                    mem[i] <= '0;
            end

            INIT_INCREMENTAL :
            begin
                for(i=0;i<FIFO_DEPTH;i++)
                    mem[i] <= DATA_WIDTH'(i);
            end

            default :
            begin
            end

        endcase

    end

`endif

    always @(posedge clk)
    begin

        if(wr_en)
            mem[wr_addr] <= wr_data;

    end

    generate

        if(SYNC_READ)
        begin : gen_sync_read

            always_ff @(posedge clk)
            begin

                if(wr_en && (wr_addr == rd_addr))
                begin

                    case(READ_DURING_WRITE_MODE)

                        WRITE_FIRST :
                            rd_data_reg <= wr_data;

                        READ_FIRST :
                            rd_data_reg <= mem[rd_addr];

                        NO_CHANGE :
                            rd_data_reg <= rd_data_reg;

                        default :
                            rd_data_reg <= wr_data;

                    endcase

                end

                else
                begin
                    rd_data_reg <= mem[rd_addr];
                end

            end

            assign rd_data = rd_data_reg;

        end

        else
        begin : gen_async_read

            always_comb
            begin

                if(wr_en && (wr_addr == rd_addr))
                begin

                    case(READ_DURING_WRITE_MODE)

                        WRITE_FIRST :
                            rd_data = wr_data;

                        READ_FIRST :
                            rd_data = mem[rd_addr];

                        NO_CHANGE :
                            rd_data = mem[rd_addr];

                        default :
                            rd_data = mem[rd_addr];

                    endcase

                end

                else
                begin
                    rd_data = mem[rd_addr];
                end

            end

        end

    endgenerate

endmodule