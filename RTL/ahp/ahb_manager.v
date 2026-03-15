module ahb_manager(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Manager signals
    input   wire    [7:0]   HADDR,
    input   wire    [2:0]   HBURST,
    input   wire            HMASTLOCK,
    input   wire    [3:0]   HPROT,
    input   wire    [2:0]   HSIZE,
    input   wire            HEXCL,
    input   wire    [7:0]   HMASTER,
    input   wire    [1:0]   HTRANS,
    input   wire    [31:0]  HWDATA,
    input   wire    [3:0]   HWSTRB,
    input   wire            HWRITE,
);


endmodule