`ifndef FIFO_MONITOR_SV
`define FIFO_MONITOR_SV

import fifo_pkg::*;

class fifo_monitor #(parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH);

    virtual fifo_if.MONITOR vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) out_mb_refmodel;
    mailbox #(fifo_transaction #(DATA_WIDTH)) out_mb_scoreboard;
    string name;
    int unsigned monitor_count;
    int unsigned observed_count;

    function new(
        string name_in = "fifo_monitor",
        virtual fifo_if.MONITOR vif_in = null,
        mailbox #(fifo_transaction #(DATA_WIDTH)) mb_refmodel_in = null,
        mailbox #(fifo_transaction #(DATA_WIDTH)) mb_scoreboard_in = null,
        int unsigned monitor_count_in = 0
    );
        name = name_in;
        vif = vif_in;
        monitor_count = monitor_count_in;
        observed_count = 0;
        if (mb_refmodel_in == null)
            out_mb_refmodel = new();
        else
            out_mb_refmodel = mb_refmodel_in;
        if (mb_scoreboard_in == null)
            out_mb_scoreboard = new();
        else
            out_mb_scoreboard = mb_scoreboard_in;
    endfunction

    function void set_output_mailboxes(
        mailbox #(fifo_transaction #(DATA_WIDTH)) mb_refmodel_in,
        mailbox #(fifo_transaction #(DATA_WIDTH)) mb_scoreboard_in
    );
        out_mb_refmodel = mb_refmodel_in;
        out_mb_scoreboard = mb_scoreboard_in;
    endfunction

    function mailbox #(fifo_transaction #(DATA_WIDTH)) get_mailbox_refmodel();
        return out_mb_refmodel;
    endfunction

    function mailbox #(fifo_transaction #(DATA_WIDTH)) get_mailbox_scoreboard();
        return out_mb_scoreboard;
    endfunction

    function int unsigned get_observed_count();
        return observed_count;
    endfunction

    function fifo_operation_t observed_operation();
        if (vif.mon_cb.flush)
            return OP_FLUSH;
        else if (vif.mon_cb.wr_en && vif.mon_cb.rd_en)
            return OP_READ_WRITE;
        else if (vif.mon_cb.wr_en)
            return OP_WRITE;
        else if (vif.mon_cb.rd_en)
            return OP_READ;
        else if (vif.mon_cb.overflow)
            return OP_OVERFLOW;
        else if (vif.mon_cb.underflow)
            return OP_UNDERFLOW;
        else
            return OP_IDLE;
    endfunction

    function void capture_transaction(output fifo_transaction #(DATA_WIDTH) txn, int unsigned index = 0);
        if (txn == null)
            txn = new($sformatf("%s_txn_%0d", name, index));

        txn.name = $sformatf("%s_txn_%0d", name, index);
        txn.valid = 1'b1;
        txn.operation = observed_operation();
        txn.write_data = (txn.operation == OP_WRITE || txn.operation == OP_READ_WRITE || txn.operation == OP_OVERFLOW)
            ? vif.mon_cb.din
            : '0;
        txn.read_data = (txn.operation == OP_READ || txn.operation == OP_READ_WRITE || txn.operation == OP_UNDERFLOW)
            ? vif.mon_cb.dout
            : '0;
        txn.status.full = vif.mon_cb.full;
        txn.status.empty = vif.mon_cb.empty;
        txn.status.almost_full = vif.mon_cb.almost_full;
        txn.status.almost_empty = vif.mon_cb.almost_empty;
        txn.status.overflow = vif.mon_cb.overflow;
        txn.status.underflow = vif.mon_cb.underflow;
        txn.debug.occupancy = vif.mon_cb.occupancy;
        txn.debug.wr_ptr = '0;
        txn.debug.rd_ptr = '0;
        if (vif.mon_cb.overflow)
            txn.debug.last_error = ERR_OVERFLOW;
        else if (vif.mon_cb.underflow)
            txn.debug.last_error = ERR_UNDERFLOW;
        else
            txn.debug.last_error = ERR_NONE;
    endfunction

    task run(int unsigned count = 0);
        if (vif == null) begin
            $fatal(1, "%s: monitor interface not bound", name);
        end
        if (out_mb_refmodel == null) begin
            $fatal(1, "%s: reference model output mailbox not initialized", name);
        end
        if (out_mb_scoreboard == null) begin
            $fatal(1, "%s: scoreboard output mailbox not initialized", name);
        end

        observed_count = 0;
        while (count == 0 || observed_count < count) begin
            @(vif.mon_cb);
            fifo_transaction #(DATA_WIDTH) txn;
            fifo_transaction #(DATA_WIDTH) txn_refmodel_copy;
            fifo_transaction #(DATA_WIDTH) txn_scoreboard_copy;
            capture_transaction(txn, observed_count);
            // Create independent copies for each consumer
            txn_refmodel_copy = new($sformatf("%s_refmodel_%0d", name, observed_count));
            txn_scoreboard_copy = new($sformatf("%s_scoreboard_%0d", name, observed_count));
            txn_refmodel_copy.copy(txn);
            txn_scoreboard_copy.copy(txn);
            out_mb_refmodel.put(txn_refmodel_copy);
            out_mb_scoreboard.put(txn_scoreboard_copy);
            observed_count++;
        end
    endtask

endclass

`endif // FIFO_MONITOR_SV

