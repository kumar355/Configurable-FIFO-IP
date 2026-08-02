module gray_counter
#(
    parameter int WIDTH = 4
)
(
    input  logic               clk,
    input  logic               rst_n,
    input  logic               inc,
    output logic [WIDTH-1:0]   binary,
    output logic [WIDTH-1:0]   gray
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary <= '0;
        end else if (inc) begin
            binary <= binary + 1'b1;
        end
    end

    always_comb begin
        gray = binary ^ (binary >> 1);
    end

endmodule
