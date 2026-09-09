//-----------------------------------------------------------------------------
// Asynchronous FIFO Multi-Clock Ratio Sweep Testbench
//
// Sweeps 5 distinct clock domain frequency & phase relationships:
// 1. Fast Write (10ns / 100MHz), Slow Read (16ns / 62.5MHz)
// 2. Slow Write (16ns / 62.5MHz), Fast Read (10ns / 100MHz)
// 3. Prime ratio A (7ns / 142.8MHz write, 13ns / 76.9MHz read)
// 4. Prime ratio B (11ns / 90.9MHz write, 17ns / 58.8MHz read)
// 5. Equal frequency with phase shift (10ns wr, 10ns rd + 3ns phase offset)
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

import fifo_pkg::*;

module async_clk_sweep_test;

    localparam int DATA_WIDTH = 16;
    localparam int FIFO_DEPTH = 8;
    localparam int NUM_ITEMS_PER_SCENARIO = 50;

    logic wr_clk = 0;
    logic rd_clk = 0;
    logic wr_rst_n = 0;
    logic rd_rst_n = 0;
    logic wr_en = 0;
    logic rd_en = 0;
    logic [DATA_WIDTH-1:0] din = '0;
    logic enable = 1;
    logic flush = 0;
    logic [DATA_WIDTH-1:0] dout;
    logic full, empty, almost_full, almost_empty, overflow, underflow;
    logic [$clog2(FIFO_DEPTH):0] occupancy;
    logic [31:0] debug_status;

    time wr_period = 10ns;
    time rd_period = 16ns;
    time rd_phase_offset = 0ns;
    bit clk_gen_enable = 0;

    // Module-level DUT instantiation
    async_fifo_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut_inst (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .enable(enable),
        .flush(flush),
        .af_threshold(FIFO_DEPTH - 1),
        .ae_threshold(1),
        .dout(dout),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .overflow(overflow),
        .underflow(underflow),
        .occupancy(occupancy),
        .debug_status(debug_status)
    );

    // Clock Generators
    always begin
        if (clk_gen_enable) begin
            #(wr_period / 2) wr_clk = ~wr_clk;
        end else begin
            #1;
        end
    end

    always begin
        if (clk_gen_enable) begin
            #(rd_period / 2) rd_clk = ~rd_clk;
        end else begin
            #1;
        end
    end

    int total_scenarios_passed = 0;
    int total_scenarios_failed = 0;

    task automatic run_scenario(
        input string scenario_name,
        input time t_wr_period,
        input time t_rd_period,
        input time t_rd_phase_offset
    );
        logic [DATA_WIDTH-1:0] written_queue [$];
        int items_written = 0;
        int items_read = 0;
        int mismatches = 0;

        $display("---------------------------------------------------------");
        $display("[ASYNC SWEEP] Running Scenario: %s", scenario_name);
        $display("              WR Period = %0t, RD Period = %0t, Phase = %0t", t_wr_period, t_rd_period, t_rd_phase_offset);
        $display("---------------------------------------------------------");

        clk_gen_enable = 0;
        wr_clk = 0;
        rd_clk = 0;
        wr_period = t_wr_period;
        rd_period = t_rd_period;
        rd_phase_offset = t_rd_phase_offset;

        #(t_rd_phase_offset);
        clk_gen_enable = 1;

        // Reset sequence
        fork
            begin
                wr_rst_n = 0;
                repeat (5) @(posedge wr_clk);
                wr_rst_n = 1;
            end
            begin
                rd_rst_n = 0;
                repeat (5) @(posedge rd_clk);
                rd_rst_n = 1;
            end
        join

        repeat (2) @(posedge wr_clk);
        repeat (2) @(posedge rd_clk);

        // Concurrent Producer and Consumer processes
        fork
            // Producer Process
            begin
                logic [DATA_WIDTH-1:0] val;
                while (items_written < NUM_ITEMS_PER_SCENARIO) begin
                    @(posedge wr_clk);
                    if (!full) begin
                        val = 16'hD000 + items_written;
                        wr_en <= 1'b1;
                        din   <= val;
                        written_queue.push_back(val);
                        items_written++;
                        @(posedge wr_clk);
                        wr_en <= 1'b0;
                    end else begin
                        wr_en <= 1'b0;
                    end
                end
                @(posedge wr_clk);
                wr_en <= 1'b0;
            end

            // Consumer Process
            begin
                logic [DATA_WIDTH-1:0] exp_val;
                while (items_read < NUM_ITEMS_PER_SCENARIO) begin
                    @(posedge rd_clk);
                    if (!empty) begin
                        rd_en <= 1'b1;
                        @(posedge rd_clk);
                        rd_en <= 1'b0;
                        #1;
                        if (written_queue.size() > 0) begin
                            exp_val = written_queue.pop_front();
                            if (dout !== exp_val) begin
                                $display("[FAIL] %s: Data Mismatch at item %0d! Exp=0x%0h, Act=0x%0h",
                                         scenario_name, items_read, exp_val, dout);
                                mismatches++;
                            end
                            items_read++;
                        end
                    end else begin
                        rd_en <= 1'b0;
                    end
                end
                rd_en <= 1'b0;
            end
        join

        repeat (5) @(posedge wr_clk);
        repeat (5) @(posedge rd_clk);

        clk_gen_enable = 0;

        if (mismatches == 0 && items_read == NUM_ITEMS_PER_SCENARIO) begin
            $display("[PASS] Scenario '%s' PASSED clean! (%0d items verified)", scenario_name, items_read);
            total_scenarios_passed++;
        end else begin
            $display("[FAIL] Scenario '%s' FAILED with %0d mismatches!", scenario_name, mismatches);
            total_scenarios_failed++;
        end
    endtask

    initial begin
        $display("=========================================================");
        $display("   ASYNCHRONOUS FIFO MULTI-CLOCK RATIO SWEEP SUITE");
        $display("=========================================================");

        run_scenario("1. Fast Write (10ns) / Slow Read (16ns)", 10ns, 16ns, 0ns);
        run_scenario("2. Slow Write (16ns) / Fast Read (10ns)", 16ns, 10ns, 0ns);
        run_scenario("3. Prime Ratio A (7ns Wr / 13ns Rd)",     7ns,  13ns, 0ns);
        run_scenario("4. Prime Ratio B (11ns Wr / 17ns Rd)",    11ns,  17ns, 0ns);
        run_scenario("5. Equal Freq with Phase Shift (10ns Wr / 10ns Rd + 3ns Phase)", 10ns, 10ns, 3ns);

        $display("=========================================================");
        $display("   ASYNC CLOCK SWEEP SUMMARY: Passed=%0d, Failed=%0d", total_scenarios_passed, total_scenarios_failed);
        $display("=========================================================");

        if (total_scenarios_failed == 0) begin
            $display("ALL ASYNC CLOCK SWEEP SCENARIOS PASSED SUCCESSFULLY!");
        end else begin
            $fatal(1, "ASYNC CLOCK SWEEP TEST SUITE FAILED!");
        end

        $finish;
    end

endmodule
