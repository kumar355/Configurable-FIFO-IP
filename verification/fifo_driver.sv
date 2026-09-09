`ifndef FIFO_DRIVER_SV
`define FIFO_DRIVER_SV

import fifo_pkg::*;

class fifo_driver #(
    parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
    parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH
);

    virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH).DRIVER vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) in_mb;
    string name;
    int unsigned transaction_count;
    int unsigned driven_count;

    function new(
        string name_in = "fifo_driver",
        virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH).DRIVER vif_in = null,
        mailbox #(fifo_transaction #(DATA_WIDTH)) mb_in = null,
        int unsigned transaction_count_in = 0
    );
        name = name_in;
        vif = vif_in;
        transaction_count = transaction_count_in;
        driven_count = 0;
        if (mb_in == null)
            in_mb = new();
        else
            in_mb = mb_in;
    endfunction

    function void set_transaction_count(int unsigned count);
        transaction_count = count;
    endfunction

    function int unsigned get_driven_count();
        return driven_count;
    endfunction

    function mailbox #(fifo_transaction #(DATA_WIDTH)) get_mailbox();
        return in_mb;
    endfunction

    task reset_outputs();
        if (vif == null) begin
            $fatal(1, "%s: interface not bound", name);
        end

        vif.drv_cb.wr_en <= 1'b0;
        vif.drv_cb.rd_en <= 1'b0;
        vif.drv_cb.din <= '0;
        vif.drv_cb.enable <= 1'b0;
        vif.drv_cb.flush <= 1'b0;
        vif.drv_cb.af_threshold <= DATA_WIDTH'(16-1);   // or FIFO_DEPTH-1 if you add FIFO_DEPTH as a parameter
        vif.drv_cb.ae_threshold <= DATA_WIDTH'(1);
    endtask

    task drive_transaction(fifo_transaction #(DATA_WIDTH) txn);
        if (vif == null) begin
            $fatal(1, "%s: interface not bound", name);
        end
        if (txn == null) begin
            $fatal(1, "%s: null transaction", name);
        end

        vif.drv_cb.wr_en <= 1'b0;
        vif.drv_cb.rd_en <= 1'b0;
        vif.drv_cb.din <= '0;
        vif.drv_cb.enable <= 1'b1;
        vif.drv_cb.flush <= 1'b0;
        vif.drv_cb.af_threshold <= FIFO_DEPTH-1;
        vif.drv_cb.ae_threshold <= 1;
        // TODO: integrate threshold fields into fifo_transaction and drive them here.
        // Leave af_threshold/ae_threshold at their default values unless the transaction carries explicit settings.

        case (txn.operation)
            OP_IDLE: begin end
            OP_WRITE: begin
                vif.drv_cb.wr_en <= 1'b1;
                vif.drv_cb.din <= txn.write_data;
            end
            OP_READ: begin
                vif.drv_cb.rd_en <= 1'b1;
            end
            OP_READ_WRITE: begin
                vif.drv_cb.wr_en <= 1'b1;
                vif.drv_cb.rd_en <= 1'b1;
                vif.drv_cb.din <= txn.write_data;
            end
            OP_FLUSH: begin
                vif.drv_cb.flush <= 1'b1;
            end
            OP_OVERFLOW: begin
                vif.drv_cb.wr_en <= 1'b1;
                vif.drv_cb.din <= txn.write_data;
            end
            OP_UNDERFLOW: begin
                vif.drv_cb.rd_en <= 1'b1;
            end
            default: begin end
        endcase
    endtask

    task run();
        if (in_mb == null) begin
            $fatal(1, "%s: mailbox not initialized", name);
        end

        driven_count = 0;

        for (int unsigned i = 0; i < transaction_count; i++) begin
            fifo_transaction #(DATA_WIDTH) txn;
            in_mb.get(txn);

            @(vif.drv_cb);

            drive_transaction(txn);

            @(vif.drv_cb);

            reset_outputs();
            driven_count++;
        end
    endtask

endclass

`endif // FIFO_DRIVER_SV
