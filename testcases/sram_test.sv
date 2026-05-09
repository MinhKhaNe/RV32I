class sram_test extends base_test;

    function new();
        super.new();
    endfunction

    virtual task run_scenario();
        wait(dut_if.sram_wdata != 0);
        $display("[SRAM TEST] SRAM data = %h, Data to SRAM = %h", dut_if.sram_data, dut_if.sram_wdata);
    endtask

endclass