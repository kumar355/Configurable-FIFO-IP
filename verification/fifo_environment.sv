`ifndef FIFO_ENVIRONMENT_SV
`define FIFO_ENVIRONMENT_SV

import fifo_pkg::*;

class fifo_environment #(parameter int DATA_WIDTH = DEFAULT_DATA_WIDTH,
                         parameter int FIFO_DEPTH = DEFAULT_FIFO_DEPTH);

    virtual fifo_if.DRIVER   drv_vif;
    virtual fifo_if.MONITOR  mon_vif;

    fifo_generator #(DATA_WIDTH) generator;
    fifo_driver #(DATA_WIDTH, FIFO_DEPTH) driver;
    fifo_monitor #(DATA_WIDTH) monitor;
    fifo_reference_model #(DATA_WIDTH, FIFO_DEPTH) ref_model;
    fifo_scoreboard #(DATA_WIDTH) scoreboard;

    mailbox #(fifo_transaction #(DATA_WIDTH)) gen_to_drv_mb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon_to_refmodel_mb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) refmodel_to_sb_mb;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon_to_sb_mb;

    int unsigned num_transactions;
    string name;

    function new(string name_in = "fifo_environment",
                 virtual fifo_if.DRIVER drv_vif_in = null,
                 virtual fifo_if.MONITOR mon_vif_in = null,
                 int unsigned num_transactions_in = 100);
        name = name_in;
        drv_vif = drv_vif_in;
        mon_vif = mon_vif_in;
        num_transactions = num_transactions_in;
    endfunction

    function void build();
        // Create mailboxes
        gen_to_drv_mb = new();
        mon_to_refmodel_mb = new();
        refmodel_to_sb_mb = new();
        mon_to_sb_mb = new();

        // Instantiate generator
        generator = new(.name_in({name, "_gen"}),
                       .transaction_count_in(num_transactions),
                       .mailbox_in(gen_to_drv_mb));

        // Instantiate driver
        driver = new(.name_in({name, "_drv"}),
                    .vif_in(drv_vif),
                    .mb_in(gen_to_drv_mb),
                    .transaction_count_in(num_transactions));

        // Instantiate monitor
        monitor = new(.name_in({name, "_mon"}),
                     .vif_in(mon_vif),
                     .mb_refmodel_in(mon_to_refmodel_mb),
                     .mb_scoreboard_in(mon_to_sb_mb),
                     .monitor_count_in(num_transactions));

        // Instantiate reference model
        ref_model = new(.name_in({name, "_ref"}),
                       .in_mb_in(mon_to_refmodel_mb),
                       .out_mb_in(refmodel_to_sb_mb));

        // Instantiate scoreboard
        scoreboard = new(.name_in({name, "_sb"}));

        $display("[%s] Environment built successfully", name);
    endfunction

    function void connect();
        // Connect reference model output (expected) and monitor output (actual) to scoreboard
        scoreboard.set_mailboxes(refmodel_to_sb_mb, mon_to_sb_mb);

        $display("[%s] Environment connected successfully", name);
    endfunction

    task run();
        $display("[%s] Starting environment simulation", name);

        fork
            generator.run();
            driver.run();
            monitor.run(num_transactions);
            ref_model.run(num_transactions);
            scoreboard.compare_n(num_transactions);
        join

        $display("[%s] Environment simulation completed", name);
        $display("[%s] Generator generated %0d transactions", name, generator.get_generated_count());
        $display("[%s] Driver drove %0d transactions", name, driver.get_driven_count());
        $display("[%s] Monitor observed %0d transactions", name, monitor.get_observed_count());
        $display("[%s] Reference model processed %0d transactions", name, ref_model.get_processed_count());
        scoreboard.report();
    endtask
    task report();

        $display("========================================");
        $display("[%s] ENVIRONMENT REPORT", name);
        $display("========================================");

        $display("Generator generated      : %0d",
                generator.get_generated_count());

        $display("Driver drove             : %0d",
                driver.get_driven_count());

        $display("Monitor observed         : %0d",
                monitor.get_observed_count());

        $display("Reference Model processed: %0d",
                ref_model.get_processed_count());

        scoreboard.report();

        $display("========================================");

    endtask

endclass

`endif // FIFO_ENVIRONMENT_SV
