package fifo_verif_pkg;

    import fifo_pkg::*;

    `include "fifo_transaction.sv"
    `include "fifo_generator.sv"
    `include "fifo_driver.sv"
    `include "fifo_monitor.sv"
    `include "fifo_reference_model.sv"
    `include "fifo_scoreboard.sv"
    `include "fifo_environment.sv"

endpackage