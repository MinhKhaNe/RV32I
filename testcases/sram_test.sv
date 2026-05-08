class sram_test extends base_test;

    function new();
        super.new();
    endfunction

    virtual task run_scenario();
        wait(dut_if.sram_data != 0);
        $display("[SRAM TEST] SRAM data = %h", dut_if.sram_data);
    endtask

endclass