`ifndef FIFO_GENERATOR_SV
`define FIFO_GENERATOR_SV

import fifo_pkg::*;

class fifo_generator #(parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH);

    string name;
    mailbox #(fifo_transaction #(DATA_WIDTH)) out_mb;
    int unsigned transaction_count;
    int unsigned generated_count;

    function new(string name_in = "fifo_generator", int unsigned transaction_count_in = 0,
                 mailbox #(fifo_transaction #(DATA_WIDTH)) mailbox_in = null);
        name = name_in;
        transaction_count = transaction_count_in;
        generated_count = 0;
        if (mailbox_in == null)
            out_mb = new();
        else
            out_mb = mailbox_in;
    endfunction

    function void set_transaction_count(int unsigned count);
        transaction_count = count;
    endfunction

    function int unsigned get_transaction_count();
        return transaction_count;
    endfunction

    function mailbox #(fifo_transaction #(DATA_WIDTH)) get_mailbox();
        return out_mb;
    endfunction

    function int unsigned get_generated_count();
        return generated_count;
    endfunction

    function fifo_operation_t random_operation();
        case ($urandom_range(0, 6))
            0: return OP_IDLE;
            1: return OP_WRITE;
            2: return OP_READ;
            3: return OP_READ_WRITE;
            4: return OP_FLUSH;
            5: return OP_OVERFLOW;
            default: return OP_UNDERFLOW;
        endcase
    endfunction

    function bit generate_transaction(output fifo_transaction #(DATA_WIDTH) txn, int unsigned index = 0);
        if (txn == null)
            txn = new($sformatf("%s_txn_%0d", name, index));

        txn.reset();
        txn.operation = random_operation();
        txn.name = $sformatf("%s_txn_%0d", name, index);
        txn.valid = 1'b1;

        if (!txn.randomize() with { operation == txn.operation; }) begin
            return 0;
        end

        return 1;
    endfunction

    task generate();
        if (out_mb == null)
            out_mb = new();

        generated_count = 0;

        for (int unsigned i = 0; i < transaction_count; i++) begin
            fifo_transaction #(DATA_WIDTH) txn;
            if (!generate_transaction(txn, i)) begin
                $fatal(1, "%s: failed to randomize transaction %0d", name, i);
            end
            out_mb.put(txn);
            generated_count++;
        end
    endtask

    task run();
        generate();
    endtask

endclass

`endif // FIFO_GENERATOR_SV
