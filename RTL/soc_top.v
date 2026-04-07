module soc_top(
    input   wire        clk,
    input   wire        rst_n
);

    wire    [3:0]   hprot;
    wire            write_req, valid_req, privileged, is_data, ready;
    wire    [31:0]  cpu_addr, cpu_wdata, cpu_rdata;
    wire    [2:0]   size_req, burst_req;

    ahb_top ahb (
        .HCLK           (clk),
        .HRESETn        (rst_n),

        .CPU_WDATA      (cpu_wdata),
        .CPU_ADDR       (cpu_addr),
        .CPU_WRITE_REQ  (write_req),
        .CPU_VALID      (valid_req),   
        .CPU_BURST_REQ  (3'b000),       
        .CPU_SIZE_REQ   (3'b010),     
        .CPU_PRIVILEGED (privileged),
        .CPU_DATA       (is_data),
        .CPU_HPROT      (hprot[0]),    

        .CPU_RDATA      (cpu_rdata),
        .CPU_READY      (ready)
    );
    
    rv32i_top rv(
        .clk            (clk),
        .rst_n          (rst_n),
        .CPU_DATA       (is_data),
        .CPU_PRIVILEGED (privileged),
        .HPROT          (hprot),

        .MEM_ADDR       (cpu_addr),     
        .MEM_WDATA      (cpu_wdata),    
        .MEM_WRITE      (write_req),    
        .MEM_READ       (valid_req),    
        
        .MEM_RDATA      (cpu_rdata),    
        .MEM_READY      (ready)       
    );

endmodule