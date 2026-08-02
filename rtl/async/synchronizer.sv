//-----------------------------------------------------------------------------
// Clock Domain Synchronizer
//
// Parameterized multi-bit synchronizer intended for Gray-coded pointer
// synchronization between clock domains. The module implements an N-stage
// flip-flop synchronizer (default 2 stages). The input bus is sampled on the
// destination clock domain; because the pointers are Gray-coded, sampling the
// whole bus is safe and will not produce metastability-induced corruption of
// multi-bit values.
//
// This module contains only synchronization logic and no FIFO control logic.
//-----------------------------------------------------------------------------
module synchronizer
#(
	parameter int WIDTH  = 4,
	parameter int STAGES = 2
)
(
	input  logic                   clk,
	input  logic                   rst_n,
	input  logic [WIDTH-1:0]       async_in,
	output logic [WIDTH-1:0]       sync_out
);

	// Sanity: require at least two stages. If user parameterizes lower,
	// force a minimum of 2 for internal storage and emit a compile-time
	// message (tool support for $error/$fatal may vary).
	localparam int SYN_STAGES = (STAGES < 2) ? 2 : STAGES;

	// Synchronizer register array: stage 0 captures the async input, and
	// subsequent stages propagate the value. Use an array of logic vectors
	// so each bit is synchronized independently.
	logic [WIDTH-1:0] sync_r [0:SYN_STAGES-1];

	// Sequential synchronization pipeline
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			for (int i = 0; i < SYN_STAGES; i++) begin
				sync_r[i] <= '0;
			end
		end else begin
			sync_r[0] <= async_in;
			for (int i = 1; i < SYN_STAGES; i++) begin
				sync_r[i] <= sync_r[i-1];
			end
		end
	end

	// Output is the last stage of the synchronizer pipeline
	assign sync_out = sync_r[SYN_STAGES-1];

endmodule
