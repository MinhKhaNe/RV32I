class monitor;

    mailbox #(packet) m2s_mb;
    packet pkt;
    virtual dut_interface dut_if;

    function new(virtual dut_interface dut_if, mailbox #(packet) m2s_mb);
        this.dut_if     = dut_if;
        this.m2s_mb     = m2s_mb;
    endfunction

    task run();
        while(1) begin
            @(posedge dut_if.clk);
            #1;
            pkt         = new();
            pkt.addr    = dut_if.cpu_addr;

            if(dut_if.we) begin
                pkt.trans_type  = packet::WRITE;
                pkt.data        = dut_if.cpu_wdata;
            end
            else begin
                pkt.trans_type  = packet::READ;
                pkt.data        = dut_if.cpu_rdata;
            end
            
            m2s_mb.put(pkt);
        end
    endtask

endclass