class environment;

    monitor     mon;
    scoreboard  sb;

    mailbox #(packet)   m2s_mb;
    virtual dut_interface dut_if;

    function new(virtual dut_interface dut_if);
        $display("[Environment] Environment is building");
        this.dut_if = dut_if;
        m2s_mb  = new();
        
        mon     = new(dut_if, m2s_mb);
        sb      = new(m2s_mb);
    endfunction

    task run();
        fork
            mon.run();
            sb.run();
        join
    endtask

endclass