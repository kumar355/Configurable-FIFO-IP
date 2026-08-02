`ifndef FIFO_REFERENCE_MODEL_SV
`define FIFO_REFERENCE_MODEL_SV

import fifo_pkg::*;

class fifo_reference_model #(parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
                             parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH);

    string name;
    mailbox #(fifo_transaction #(DATA_WIDTH)) in_mb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) out_mb;

    logic [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    int unsigned rd_ptr;
    int unsigned wr_ptr;
    int unsigned occupancy;
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
    endfunction

    function void reset();
        rd_ptr = 0;
        wr_ptr = 0;
        occupancy = 0;
        processed_count = 0;
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
        if (occupancy == 0) begin
            success = 0;
            return '0;
        end

        success = 1;
        logic [DATA_WIDTH-1:0] data = fifo_mem[rd_ptr];
        rd_ptr = (rd_ptr + 1) % FIFO_DEPTH;
        occupancy -= 1;
        return data;
    endfunction

    function fifo_transaction #(DATA_WIDTH) build_expected(
        input fifo_transaction #(DATA_WIDTH) observed,
        int unsigned index = 0
    );
        fifo_transaction #(DATA_WIDTH) expected = new($sformatf("%s_expected_%0d", name, index));
        expected.name = $sformatf("%s_expected_%0d", name, index);
        expected.valid = 1'b1;
        expected.operation = observed.operation;
        expected.write_data = observed.write_data;
        expected.read_data = '0;
        expected.status = '{default: '0};
        expected.debug = '{default: '0};

        bit read_success;
        bit write_success;
        expected.debug.wr_ptr = wr_ptr;
        expected.debug.rd_ptr = rd_ptr;
        expected.debug.occupancy = occupancy;
        expected.debug.last_error = ERR_NONE;

        case (observed.operation)
            OP_IDLE: begin
            end
            OP_WRITE,
            OP_OVERFLOW: begin
                write_success = enqueue(observed.write_data);
                if (!write_success) begin
                    expected.status.overflow = 1'b1;
                    expected.debug.last_error = ERR_OVERFLOW;
                end
            end
            OP_READ,
            OP_UNDERFLOW: begin
                expected.read_data = dequeue(read_success);
                if (!read_success) begin
                    expected.status.underflow = 1'b1;
                    expected.debug.last_error = ERR_UNDERFLOW;
                end
            end
            OP_READ_WRITE: begin
                expected.read_data = dequeue(read_success);
                if (!read_success) begin
                    expected.status.underflow = 1'b1;
                    expected.debug.last_error = ERR_UNDERFLOW;
                end
                write_success = enqueue(observed.write_data);
                if (!write_success) begin
                    expected.status.overflow = 1'b1;
                    expected.debug.last_error = ERR_OVERFLOW;
                end
            end
            OP_FLUSH: begin
                rd_ptr = 0;
                wr_ptr = 0;
                occupancy = 0;
            end
            default: begin
            end
        endcase

        expected.status.full = (occupancy == FIFO_DEPTH);
        expected.status.empty = (occupancy == 0);
        expected.status.almost_full = (occupancy >= af_threshold);
        expected.status.almost_empty = (occupancy <= ae_threshold);
        expected.debug.occupancy = occupancy;

        expected.debug.wr_ptr = wr_ptr;
        expected.debug.rd_ptr = rd_ptr;

        return expected;
    endfunction

    task run(int unsigned count = 0);
        if (in_mb == null) begin
            $fatal(1, "%s: input mailbox not initialized", name);
        end
        if (out_mb == null) begin
            $fatal(1, "%s: output mailbox not initialized", name);
        end

        processed_count = 0;
        while (count == 0 || processed_count < count) begin
            fifo_transaction #(DATA_WIDTH) observed;
            in_mb.get(observed);
            fifo_transaction #(DATA_WIDTH) expected = build_expected(observed, processed_count);
            out_mb.put(expected);
            processed_count += 1;
        end
    endtask

    function int unsigned get_processed_count();
        return processed_count;
    endfunction

endclass

`endif // FIFO_REFERENCE_MODEL_SV
