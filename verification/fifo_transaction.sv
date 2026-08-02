`ifndef FIFO_TRANSACTION_SV
`define FIFO_TRANSACTION_SV

import fifo_pkg::*;

class fifo_transaction #(parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH);

    rand fifo_operation_t operation;
    rand logic [DATA_WIDTH-1:0] write_data;
    rand logic [DATA_WIDTH-1:0] read_data;
    rand fifo_status_t status;
    rand fifo_debug_t debug;

    string name;
    bit valid;

    constraint write_data_if_write {
        if (operation == OP_READ || operation == OP_IDLE || operation == OP_FLUSH || operation == OP_OVERFLOW || operation == OP_UNDERFLOW)
            write_data == '0;
    }

    constraint read_data_if_read {
        if (operation == OP_WRITE || operation == OP_IDLE || operation == OP_FLUSH || operation == OP_OVERFLOW || operation == OP_UNDERFLOW)
            read_data == '0;
    }

    constraint status_sanity {
        if (status.overflow)
            status.full == 1'b1;

        if (status.underflow)
            status.empty == 1'b1;

        if (status.full)
            status.empty == 1'b0;

        if (status.empty)
            status.full == 1'b0;

        if (status.almost_full)
            status.empty == 1'b0;

        if (status.almost_empty)
            status.full == 1'b0;

        if (status.overflow)
            status.underflow == 1'b0;

        if (status.underflow)
            status.overflow == 1'b0;
    }

    function new(string name_in = "fifo_transaction");
        name = name_in;
        valid = 1'b1;
        operation = OP_IDLE;
        write_data = '0;
        read_data = '0;
        status = '{default:'0};
        debug = '{default:'0};
    endfunction

    function void reset();
        operation = OP_IDLE;
        write_data = '0;
        read_data = '0;
        status = '{default:'0};
        debug = '{default:'0};
        valid = 1'b1;
    endfunction

    function bit randomize_transaction();
        return this.randomize();
    endfunction

    function void copy(input fifo_transaction rhs);
        if (rhs == null) begin
            return;
        end

        operation = rhs.operation;
        write_data = rhs.write_data;
        read_data = rhs.read_data;
        status = rhs.status;
        debug = rhs.debug;
        name = rhs.name;
        valid = rhs.valid;
    endfunction

    function bit compare(input fifo_transaction rhs);
        if (rhs == null)
            return 0;

        return (operation == rhs.operation)
            && (write_data == rhs.write_data)
            && (read_data == rhs.read_data)
            && (status == rhs.status)
            && (debug == rhs.debug)
            && (valid == rhs.valid)
            && (name == rhs.name);
    endfunction

    function string to_string();
        return $sformatf(
            "%s: op=%s write=0x%0h read=0x%0h status=%s debug=%s valid=%0b",
            name,
            op_to_string(operation),
            write_data,
            read_data,
            status_to_string(),
            debug_to_string(),
            valid
        );
    endfunction

    task display(string prefix = "");
        $display("%s%s", prefix, to_string());
    endtask

    static function string op_to_string(input fifo_operation_t op);
        case (op)
            OP_IDLE:       return "OP_IDLE";
            OP_WRITE:      return "OP_WRITE";
            OP_READ:       return "OP_READ";
            OP_READ_WRITE: return "OP_READ_WRITE";
            OP_FLUSH:      return "OP_FLUSH";
            OP_OVERFLOW:   return "OP_OVERFLOW";
            OP_UNDERFLOW:  return "OP_UNDERFLOW";
            default:       return "UNKNOWN_OPERATION";
        endcase
    endfunction

    static function string error_to_string(input fifo_error_t err);
        case (err)
            ERR_NONE:      return "ERR_NONE";
            ERR_OVERFLOW:  return "ERR_OVERFLOW";
            ERR_UNDERFLOW: return "ERR_UNDERFLOW";
            ERR_RESET:     return "ERR_RESET";
            ERR_CONFIG:    return "ERR_CONFIG";
            default:       return "UNKNOWN_ERROR";
        endcase
    endfunction

    function string status_to_string();
        return $sformatf(
            "{full=%0b empty=%0b almost_full=%0b almost_empty=%0b overflow=%0b underflow=%0b}",
            status.full,
            status.empty,
            status.almost_full,
            status.almost_empty,
            status.overflow,
            status.underflow
        );
    endfunction

    function string debug_to_string();
        return $sformatf(
            "{wr_ptr=%0d rd_ptr=%0d occupancy=%0d last_error=%s}",
            debug.wr_ptr,
            debug.rd_ptr,
            debug.occupancy,
            error_to_string(debug.last_error)
        );
    endfunction

endclass

`endif // FIFO_TRANSACTION_SV
