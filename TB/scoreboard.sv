class scoreboard;

    mailbox #(packet)   m2s_mb;
    packet pkt;

    function new(mailbox #(packet)   m2s_mb);
        this.m2s_mb = m2s_mb;
    endfunction

    task run();
        while(1) begin
            pkt = new();
            m2s_mb.get(pkt);
            $display("[Scoreboard] Get packet from Monitor, Address: %h, Data: %h",pkt.addr, pkt.data);
        end
    endtask

endclass