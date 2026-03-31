module ahb_subordinate(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Select signal
    input   wire            HSEL,
    //Data in
    input   wire    [31:0]  HWDATA,
    //Address and control
    input   wire    [31:0]  HADDR,
    input   wire    [1:0]   HTRANS,     //00 idle, 01 BUSY, 10 NONSEQ, 11 SEQ
    input   wire            HWRITE,     //1 WRITE, 0 READ
    input   wire    [2:0]   HSIZE,      //000: 8 bit, 001: 16 bit, 010: 32 bit
    input   wire    [2:0]   HBURST,
    input   wire            HMASTLOCK,
    input   wire            HREADY,
    input   wire    [2:0]   HPROT,
    //Transfer response
    output  wire            HREADYOUT,  //insert a single wait
state
    output  wire            HRESP,      //WARINING 
    output  wire            HEXOKAY,
    //Data out
    output  reg     [31:0]  HRDATA
);

    integer         i;
    //Internal Registers
    reg     [31:0]  HRDATA_reg, HADDR_reg;
    reg             HWRITE_d;
    reg     [1:0]   HTRANS_d;
    reg     [31:0]  memory[0:1023];

    //DELAY HWRITE 1 cycle
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HWRITE_d    <= 1'b0;
            HADDR_reg   <= 32'b0;
        end
        else if(HREADY) begin
            HWRITE_d    <= HWRITE;
            HADDR_reg   <= HADDR;
            HTRANS_d    <= HTRANS;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HRDATA_reg  <= 32'b0;
        end
        else if(!HWRITE_d && HREADY && HTRANS_d[1]) begin
            HRDATA_reg  <= memory[HADDR_reg[11:2]];
        end
    end

    assign  HRDATA  = HRDATA_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            for(i = 0; i < 1024; i = i + 1) begin
                memory[i] <= 0;
            end
        end
        else if(HWRITE_d && HREADY && HTRANS_d[1]) begin
            memory[HADDR_reg[11:2]] <= HWDATA;
        end
    end

endmodule