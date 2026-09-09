`ifndef FIFO_REFERENCE_MODEL_SV
`define FIFO_REFERENCE_MODEL_SV

import fifo_pkg::*;

class fifo_reference_model #(parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
                             parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH);

    string name;
    mailbox #(fifo_transaction #(DATA_WIDTH)) in_mb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) out_mb;

    logic [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    logic [DATA_WIDTH-1:0] last_read_data;

    int unsigned rd_ptr;
    int unsigned wr_ptr;
    int unsigned occupancy;
    fifo_error_t last_error;

    int unsigned af_threshold;
    int unsigned ae_threshold;

    int unsigned processed_count;

    function new(
        string name_in = "fifo_reference_model",
        mailbox #(fifo_transaction #(DATA_WIDTH)) in_mb_in = null,
        mailbox #(fifo_transaction #(DATA_WIDTH)) out_mb_in = null,
        int unsigned af_threshold_in = FIFO_DEPTH - 1,
        int unsigned ae_threshold_in = 1
    );
        name = name_in;
        if (in_mb_in == null)
            in_mb = new();
        else
            in_mb = in_mb_in;

        if (out_mb_in == null)
            out_mb = new();
        else
            out_mb = out_mb_in;

        rd_ptr = 0;
        wr_ptr = 0;
        occupancy = 0;
        processed_count = 0;
        af_threshold = af_threshold_in;
        ae_threshold = ae_threshold_in;
        last_read_data = '0;
        last_error = ERR_NONE;
    endfunction

    function void reset();
        rd_ptr = 0;
        wr_ptr = 0;
        occupancy = 0;
        processed_count = 0;
        last_read_data = '0;
        last_error = ERR_NONE;
    endfunction

    function bit enqueue(input logic [DATA_WIDTH-1:0] data);
        if (occupancy == FIFO_DEPTH)
            return 0;

        fifo_mem[wr_ptr] = data;
        wr_ptr = (wr_ptr + 1) % FIFO_DEPTH;
        occupancy += 1;
        return 1;
    endfunction

    function logic [DATA_WIDTH-1:0] dequeue(output bit success);

        logic [DATA_WIDTH-1:0] data;

        if (occupancy == 0) begin
            success = 0;
            return '0;
        end

        success = 1;

        data = fifo_mem[rd_ptr];
        last_read_data = data;

        rd_ptr = (rd_ptr + 1) % FIFO_DEPTH;
        occupancy -= 1;

        return data;

    endfunction

    function fifo_transaction #(DATA_WIDTH) build_expected(
        input fifo_transaction #(DATA_WIDTH) observed,
        int unsigned index = 0
    );

        fifo_transaction #(DATA_WIDTH) expected;

        bit read_success;
        bit write_success;

        expected = new($sformatf("%s_expected_%0d", name, index));

        expected.name = $sformatf("%s_expected_%0d", name, index);
        expected.valid = 1'b1;
        expected.operation = observed.operation;
        expected.write_data = observed.write_data;
        expected.read_data = '0;

        case (observed.operation)
            OP_IDLE: begin
                last_error = ERR_NONE;
            end

            OP_WRITE: begin
                last_error = ERR_NONE;
                write_success = enqueue(observed.write_data);
                if (!write_success) begin
                    last_error = ERR_OVERFLOW;
                end
            end

            OP_OVERFLOW: begin
                last_error = ERR_OVERFLOW;
            end

            OP_READ: begin
                last_error = ERR_NONE;
                expected.read_data = dequeue(read_success);
                if (!read_success) begin
                    last_error = ERR_UNDERFLOW;
                end
            end

            OP_UNDERFLOW: begin
                last_error = ERR_UNDERFLOW;
                expected.read_data = '0;
            end

            OP_READ_WRITE: begin
                last_error = ERR_NONE;
                if (occupancy == 0) begin
                    // Freeze read, perform write only
                    write_success = enqueue(observed.write_data);
                end
                else begin
                    expected.read_data = dequeue(read_success);
                    write_success = enqueue(observed.write_data);
                    if (!write_success) begin
                        last_error = ERR_OVERFLOW;
                    end
                end
            end

            OP_FLUSH: begin
                rd_ptr = 0;
                wr_ptr = 0;
                occupancy = 0;
                last_read_data = '0;
                last_error = ERR_NONE;
            end

            default: begin
            end
        endcase

        expected.status.full         = (occupancy == FIFO_DEPTH);
        expected.status.empty        = (occupancy == 0);
        expected.status.almost_full  = (occupancy >= af_threshold);
        expected.status.almost_empty = (occupancy <= ae_threshold);
        expected.status.overflow     = (last_error == ERR_OVERFLOW);
        expected.status.underflow    = (last_error == ERR_UNDERFLOW);

        expected.debug.occupancy  = occupancy;
        expected.debug.wr_ptr     = wr_ptr;
        expected.debug.rd_ptr     = rd_ptr;
        expected.debug.last_error = last_error;

        return expected;
    endfunction

    task run(int unsigned count = 0);

        fifo_transaction #(DATA_WIDTH) observed;
        fifo_transaction #(DATA_WIDTH) expected;

        if (in_mb == null)
            $fatal(1,"%s: input mailbox not initialized",name);

        if (out_mb == null)
            $fatal(1,"%s: output mailbox not initialized",name);

        processed_count = 0;

        while (count == 0 || processed_count < count) begin

            in_mb.get(observed);

            expected = build_expected(observed, processed_count);

            out_mb.put(expected);

            processed_count++;

        end

    endtask

    function int unsigned get_processed_count();
        return processed_count;
    endfunction

endclass

`endif // FIFO_REFERENCE_MODEL_SV
