module ahb_top(
    input   wire            HCLK,
    input   wire            HRESETn,

    input   wire    [31:0]  CPU_WDATA,
    input   wire    [31:0]  CPU_ADDR,
    input   wire            CPU_WRITE_REQ,
    input   wire            CPU_VALID,
    input   wire    [2:0]   CPU_BURST_REQ,
    input   wire    [2:0]   CPU_SIZE_REQ,
    input   wire            CPU_PRIVILEGED,
    input   wire            CPU_DATA,
    input   wire    [3:0]   CPU_HPROT,

    output  wire    [31:0]  CPU_RDATA,
    output  wire            CPU_READY 
);

    wire    [31:0]  h_addr, h_wdata;
    wire    [3:0]   h_prot;
    wire    [2:0]   h_burst, h_size;
    wire    [1:0]   h_trans;
    wire            h_write, h_mastlock, h_ready, h_resp;
    wire            h_ready_slave;

    ahb_manager u_manager (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .HREADY         (h_ready),    
        .HRESP          (h_resp),
        .WDATA          (CPU_WDATA),
        .HWADDR         (CPU_ADDR),
        .HWRITE_REQ     (CPU_WRITE_REQ),
        .CPU_PRIVILEGED (1'b1),
        .CPU_DATA       (CPU_DATA),
        .CPU_HPROT      (CPU_HPROT),
        .HVALID         (CPU_VALID),
        .LOCK_REQ       (1'b0),
        .HBURST_REQ     (CPU_BURST_REQ),
        .HSIZE_REQ      (CPU_SIZE_REQ),
        .HADDR          (h_addr),
        .HBURST         (h_burst),
        .HMASTLOCK      (h_mastlock),
        .HPROT          (h_prot),
        .HSIZE          (h_size),
        .HTRANS         (h_trans),
        .HWRITE         (h_write),
        .HWDATA         (h_wdata)
    );

    ahb_subordinate u_slave (
        .HCLK       (HCLK),
        .HRESETn    (HRESETn),
        .HSEL       (1'b1),       
        .HWDATA     (h_wdata),
        .HADDR      (h_addr),
        .HTRANS     (h_trans),
        .HWRITE     (h_write),
        .HSIZE      (h_size),
        .HBURST     (h_burst),
        .HMASTLOCK  (h_mastlock),
        .HREADY     (h_ready),   
        .HPROT      (h_prot),
        .HREADYOUT  (h_ready),    
        .HRESP      (h_resp),
        .HEXOKAY    (),
        .HRDATA     (CPU_RDATA)
    );

    assign CPU_READY = h_ready;

endmodule