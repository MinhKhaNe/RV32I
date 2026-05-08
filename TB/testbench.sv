module testbench;

    import soc_packet::*;
    import test_pkg::*;

    string  mem_file;

    dut_interface dut_if();

    soc_top dut(
        .clk(dut_if.clk),
        .rst_n(dut_if.rst_n),
        .we(dut_if.we),
        .wdata(dut_if.cpu_wdata),
        .rdata(dut_if.cpu_rdata),
        .address(dut_if.cpu_addr)
    );

    initial begin
        dut_if.clk = 0;
        forever #25 dut_if.clk = ~dut_if.clk;
    end

    base_test   base;
    timer_test  timer;
    sram_test   sram;

    initial begin
        dut_if.rst_n = 1'b0;
        @(posedge dut_if.clk);
        dut_if.rst_n = 1'b1;

        base    = new();
        timer   = new();
        sram    = new();

        if($test$plusargs("timer_test")) begin
            base        = timer;
            mem_file    = "timer.mem";
        end
        else if($test$plusargs("sram_test")) begin
            base        = sram;
            mem_file    = "sram.mem";
        end

        base.dut_if     = dut_if;

        $display("[Testbench] Loading instruction file: %s", mem_file);
        $readmemh(mem_file, dut.rv.IM0.mem);
        base.run();
    end

    initial begin

        #2000;

        $display("[TB] TIMEOUT");

        $finish;

    end

endmodule