module soc_top(
    input   wire        clk,
    input   wire        rst_n
);

    wire    [3:0]   hprot;
    wire            write_req, privileged, is_data, ready, read_req;
    wire    [31:0]  cpu_addr, cpu_wdata, cpu_rdata;
    wire    [2:0]   size_req, burst_req;
    wire            valid;

    ahb_top ahb (
        .HCLK           (clk),
        .HRESETn        (rst_n),

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
        .CPU_READY      (ready)
    );
    
    rv32i_top rv(
        .clk(clk),
        .rst_n(rst_n),
        .bus_ready(ready),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_write_req(write_req),
        .cpu_valid(valid)
    );

endmodule