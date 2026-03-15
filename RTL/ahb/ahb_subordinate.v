module ahb_subordinate(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Subordinate signals
    input   wire    [31:0]  HWDATA,
    input   wire    [31:0]  HADDR,
    input   wire    [1:0]   HTRANS,
    input   wire            HWRITE,
    input   wire    [2:0]   HSIZE,      //000: 8 bit, 001: 16 bit, 010: 32 bit
    input   wire    [2:0]   HBURST,
    input   wire            HSEL,
    input   wire            HREADY,

    output  wire            HREADYOUT,
    output  wire            HRESP,      //WARINING
    output  reg     [31:0]  HRDATA
);

    integer         i;
    wire            VALID;
    wire    [3:0]   byte_en;
    wire            align_error;

    reg     [31:0]  ADDR_reg;
    reg             WRITE_reg,VALID_reg;
    reg     [2:0]   HSIZE_reg;
    reg     [31:0]  memory [0:1023];
    
    //HTRANS: 00: IDLE, 01: BUSY, 10: NONSEQ, 11: SEQ
    
    assign  VALID       = HSEL && HTRANS[1] && HREADY;
    assign  HREADYOUT   = 1'b1;
    assign  HRESP       = allign_error;
    assign  byte_en     = (HSIZE_reg == 3'b010) ?   4'b1111 :
                          (HSIZE_reg == 3'b000) ?   (4'b001 << ADDR_reg[1:0]) :
                          (HSIZE_reg == 3'b001) ?   (ADDR_reg[1] ? 4'b1100: 4'b0011) :
                                                    4'b000;

    assign align_error =    (HSIZE == 3'b010 && HADDR[1:0] != 2'b00) ||
                            (HSIZE == 3'b001 && HADDR[0]   != 1'b0);

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            ADDR_reg    <= 32'b0;
            WRITE_reg   <= 1'b0;
            VALID_reg   <= 1'b0;
            HSIZE_reg   <= 3'b0;
        end
        else if(HREADY) begin
            ADDR_reg    <= HADDR;
            WRITE_reg   <= HWRITE;
            VALID_reg   <= VALID;
            HSIZE_reg   <= HSIZE;
        end
    end

    //Delay 1 clk wait HWDATA
    always @(posedge HCLK) begin
        if(VALID_reg && WRITE_reg) begin
            if(byte_en[0]) memory[ADDR_reg[31:2]][7:0]   <= HWDATA[7:0];
            if(byte_en[1]) memory[ADDR_reg[31:2]][15:8]  <= HWDATA[15:8];
            if(byte_en[2]) memory[ADDR_reg[31:2]][23:16] <= HWDATA[23:16];
            if(byte_en[3]) memory[ADDR_reg[31:2]][31:24] <= HWDATA[31:24];
        end
    end

    //READ
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HRDATA  <= 32'b0;
        end
        else begin
            if(VALID_reg && ~WRITE_reg) begin
                HRDATA  <= memory[ADDR_reg[31:2]];
            end
        end
    end

endmodule