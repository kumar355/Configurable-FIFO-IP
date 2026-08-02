mailbox #(fifo_transaction #(DATA_WIDTH)) expected_mbx;
mailbox #(fifo_transaction #(DATA_WIDTH)) actual_mbx;

string name;
int unsigned passed;
int unsigned failed;
int unsigned compared;

function new(string name_in = "fifo_scoreboard");
    name = name_in;
    expected_mbx = null;
    actual_mbx = null;
    passed = 0;
    failed = 0;
    compared = 0;
endfunction

function void set_expected_mailbox(mailbox #(fifo_transaction #(DATA_WIDTH)) mbx);
    expected_mbx = mbx;
endfunction

function void set_actual_mailbox(mailbox #(fifo_transaction #(DATA_WIDTH)) mbx);
    actual_mbx = mbx;
endfunction

function void set_mailboxes(
    mailbox #(fifo_transaction #(DATA_WIDTH)) exp_mbx,
    mailbox #(fifo_transaction #(DATA_WIDTH)) act_mbx
);
    expected_mbx = exp_mbx;
    actual_mbx = act_mbx;
endfunction

function void reset();
    passed = 0;
    failed = 0;
    compared = 0;
endfunction

function bit compare_transaction(
    input fifo_transaction #(DATA_WIDTH) expected,
    input fifo_transaction #(DATA_WIDTH) actual
);
    string diff = "";
    bit match = 1;

    if (expected.operation != actual.operation) begin
        match = 0;
        diff = {
            diff,
            "operation expected=",
            expected.op_to_string(expected.operation),
            " actual=",
            actual.op_to_string(actual.operation),
            "; "
        };
    end

    if (expected.read_data != actual.read_data) begin
        match = 0;
        diff = {
            diff,
            "read_data expected=0x",
            $sformatf("%0h", expected.read_data),
            " actual=0x",
            $sformatf("%0h", actual.read_data),
            "; "
        };
    end

    if (expected.status != actual.status) begin
        match = 0;
        diff = {
            diff,
            "status expected=",
            expected.status_to_string(),
            " actual=",
            actual.status_to_string(),
            "; "
        };
    end

    if (expected.debug != actual.debug) begin
        match = 0;
        diff = {
            diff,
            "debug expected=",
            expected.debug_to_string(),
            " actual=",
            actual.debug_to_string(),
            "; "
        };
    end

    if ((expected.operation == OP_WRITE || expected.operation == OP_READ_WRITE)
        && (expected.write_data != actual.write_data)) begin
        match = 0;
        diff = {
            diff,
            "write_data expected=0x",
            $sformatf("%0h", expected.write_data),
            " actual=0x",
            $sformatf("%0h", actual.write_data),
            "; "
        };
    end

    compared++;
    if (match) begin
        passed++;
    end else begin
        failed++;
        $display("[%s] SCOREBOARD MISMATCH #%0d", name, compared);
        $display("[%s]   expected: %s", name, expected.to_string());
        $display("[%s]   actual  : %s", name, actual.to_string());
        $display("[%s]   diff    : %s", name, diff);
    end

    return match;
endfunction

task compare_next();
    if (expected_mbx == null || actual_mbx == null) begin
        $error("[%s] Mailboxes must be assigned before compare_next()", name);
        return;
    end

    fifo_transaction #(DATA_WIDTH) expected;
    fifo_transaction #(DATA_WIDTH) actual;

    expected_mbx.get(expected);
    actual_mbx.get(actual);

    compare_transaction(expected, actual);
endtask

task compare_n(int unsigned count);
    for (int unsigned i = 0; i < count; i++) begin
        compare_next();
    end
endtask

task report();
    $display("[%s] SCOREBOARD SUMMARY: compared=%0d passed=%0d failed=%0d",
             name, compared, passed, failed);
endtask

function string summary_string();
    return $sformatf(
        "[%s] compared=%0d passed=%0d failed=%0d",
        name,
        compared,
        passed,
        failed
    );
endfunction