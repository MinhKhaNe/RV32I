class base_test;

    environment env;
    virtual dut_interface dut_if;

    function new();
    endfunction

    function void build();
        env = new(dut_if);
    endfunction

    //Overwrite task
    virtual task run_scenario();
    endtask

    task run();
        build();
        fork
            env.run();
            run_scenario();
        join
        #1us;
        $display("[Base] End simulation");
        $finish;
    endtask

endclass