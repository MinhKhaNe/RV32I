interface dut_interface;
    logic           clk;
    logic           rst_n;
    logic   [31:0]  cpu_addr;
    logic   [31:0]  cpu_wdata;
    logic   [31:0]  cpu_rdata;
    logic   [63:0]  sram_wdata;
    logic   [63:0]  sram_data;
    logic           we;
    logic           timer_interrupt;
endinterface 