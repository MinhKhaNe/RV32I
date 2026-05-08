class timer_test extends base_test;

    function new();
        super.new();
    endfunction

    virtual task run_scenario();
        wait(dut_if.timer_interrupt);
        $display("Interrupt detected");
    endtask

endclass