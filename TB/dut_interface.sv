interface dut_interface;

    logic           clk;
    logic           rst_n;

    logic   [31:0]  cpu_addr;
    logic   [31:0]  cpu_wdata;
    logic   [31:0]  cpu_rdata;

    logic           we;

endinterface 