module soc_top(
    input   wire        clk,
    input   wire        rst_n,
    
    output  wire        we,

    output  wire [31:0] wdata,
    output  wire [31:0] rdata,
    output  wire [31:0] address
);

    wire    [3:0]   hprot;
    wire            write_req, privileged, is_data, ready, bus_ready, read_req;
    wire    [31:0]  cpu_addr, cpu_wdata, cpu_rdata;
    wire    [2:0]   size_req, burst_req;
    wire            valid;
    wire    [31:0]  trace_ptr;
    wire    [63:0]  trace_out;
    wire            trace_valid;
    wire            trace_we;
    wire    [127:0] sramc_out;
    wire    [2:0]   sram_sel;

    assign bus_ready    = (rst_n) ? ready : 1'b1;
    assign wdata        = cpu_wdata;
    assign rdata        = cpu_rdata;
    assign address      = cpu_addr;
    assign we           = write_req;

    ahb_top ahb (
        .HCLK           (clk),
        .HRESETn        (rst_n),

        .trace_out      (trace_out),
        .trace_ptr      (trace_ptr), 
        .trace_we       (trace_we),   

        .sram_sel       (sram_sel),
        .CPU_WDATA      (cpu_wdata),
        .CPU_ADDR       (cpu_addr),
        .CPU_WRITE_REQ  (write_req),
        .CPU_VALID      (valid),   
        .CPU_BURST_REQ  (3'b000),       
        .CPU_SIZE_REQ   (3'b010),     
        .CPU_PRIVILEGED (privileged),
        .CPU_DATA       (is_data),
        .CPU_HPROT      (hprot),    

        .CPU_RDATA      (cpu_rdata),
        .CPU_READY      (ready),
        .sramc_out      (sramc_out)
    );
    
    rv32i_top rv(
        .clk(clk),
        .rst_n(rst_n),
        .bus_ready(bus_ready),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_write_req(write_req),
        .cpu_valid(valid),
        .trace_we(trace_we),
        .trace_out(trace_out),
        .trace_ptr(trace_ptr)
    );

endmodule