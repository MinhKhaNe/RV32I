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
    output  reg     [31:0]  HRDATA,
);

    integer         i;
    wire            VALID;

    reg     [31:0]  ADDR_reg;
    reg             WRITE_reg,VALID_reg;
    reg     [31:0]  memory [0:1023];
    
    //HTRANS: 00: IDLE, 01: BUSY, 10: NONSEQ, 11: SEQ
    
    assign  VALID       = HSEL && HTRANS[1] && HREADY;
    assign  HREADYOUT   = 1'b1;

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            ADDR_reg    <= 32'b0;
            WRITE_reg   <= 1'b0;
            VALID_reg   <= 1'b0;
        end
        else if(HREADY) begin
            ADDR_reg    <= HADDR;
            WRITE_reg   <= HWRITE;
            VALID_reg   <= VALID;
        end
    end

    //Delay 1 clk wait HWDATA
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            for(i = 0; i < 1024; i = i + 1) begin
                memory[i]    <= 32'b0;
            end
        end
        else if(VALID_reg && WRITE_reg) begin
            case(HSIZE)
                3'b000:     memory[ADDR_reg][7:0]   <= HWDATA[7:0];
                3'b001:     memory[ADDR_reg][15:0]  <= HWDATA[15:0];
                3'b010:     memory[ADDR_reg]        <= HWDATA;
                default:    ;
            endcase
        end
    end

    //READ
    always @(posedge HCLK) begin
        if(!HRESETn) begin
            HRDATA              <= 32'b0;
        end
        if(VALID_reg && ~WRITE_reg) begin
            case(HSIZE)
                3'b000:     HRDATA[7:0]     <= memory[ADDR_reg][7:0];
                3'b001:     HRDATA[15:0]    <= memory[ADDR_reg][15:0];
                3'b010:     HRDATA          <= memory[ADDR_reg];
                default:    ;
            endcase
        end
    end

endmodule