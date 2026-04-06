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
    output  wire            HREADYOUT,  //insert a single wait state
    output  wire            HRESP,      //WARINING 
    output  wire            HEXOKAY,
    //Data out
    output  reg     [31:0]  HRDATA
);

    parameter   BYTE        = 3'b000;
    parameter   HALFWORD    = 3'b001;
    parameter   WORD        = 3'b010;
    parameter   DOUBLEWORD  = 3'b011;
    parameter   WORD_LINE_4 = 3'b100;
    parameter   WORD_LINE_8 = 3'b101;

    integer         i;
    //Internal Registers
    reg     [31:0]  HRDATA_reg, HADDR_reg, HWDATA_reg;
    reg             HWRITE_d, HSEL_d, HREADY_d;
    reg     [1:0]   HTRANS_d;
    reg     [2:0]   HSIZE_d;
    reg     [31:0]  memory[0:1023];
    reg             wait_state;
    reg     [31:0]  mask, HRDATA_mask;
    wire    [31:0]  mem_word;

    //DELAY HWRITE 1 cycle
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HWRITE_d    <= 1'b0;
            HADDR_reg   <= 32'b0;
            HTRANS_d    <= 2'b0;
            HSEL_d      <= 1'b0;
            HSIZE_d     <= 3'b0;
            HREADY_d    <= 1'b0;
            HWDATA_reg  <= 32'b0;
        end
        else if(HREADY) begin
            HWRITE_d    <= HWRITE;
            HADDR_reg   <= HADDR;
            HTRANS_d    <= HTRANS;
            HSEL_d      <= HSEL;
            HSIZE_d     <= HSIZE;
            HREADY_d    <= HREADY;
            HWDATA_reg  <= HWDATA;
        end
    end

    
    //Read data
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HRDATA_reg  <= 32'b0;
        end
        else if(!HWRITE && HREADY && HTRANS[1] && HSEL) begin
            HRDATA_reg  <= HRDATA_mask;
        end
    end

    always @(*) begin
        case(HSIZE_d)
            3'b000: begin 
                case(HADDR_reg[1:0])
                    2'b00: HRDATA_mask = {24'b0, mem_word[7:0]};
                    2'b01: HRDATA_mask = {24'b0, mem_word[15:8]};
                    2'b10: HRDATA_mask = {24'b0, mem_word[23:16]};
                    2'b11: HRDATA_mask = {24'b0, mem_word[31:24]};
                endcase
            end
            3'b001: begin 
                case(HADDR_reg[1])
                    1'b0: HRDATA_mask = {16'b0, mem_word[15:0]};
                    1'b1: HRDATA_mask = {16'b0, mem_word[31:16]};
                endcase
            end
            default:
                HRDATA_mask = mem_word;
        endcase
    end

    assign  HRDATA  = HRDATA_reg;
    // assign HRDATA = (!HWRITE_d && HSEL_d && HTRANS_d[1]) ? HRDATA_mask : 32'h0;

    always @(*) begin
        case(HSIZE_d)
            3'b000: begin // BYTE
                case(HADDR_reg[1:0])
                    2'b00: mask = 32'h000000FF;
                    2'b01: mask = 32'h0000FF00;
                    2'b10: mask = 32'h00FF0000;
                    2'b11: mask = 32'hFF000000;
                endcase
            end
            3'b001: begin // HALFWORD
                case(HADDR_reg[1])
                    1'b0: mask = 32'h0000FFFF;
                    1'b1: mask = 32'hFFFF0000;
                endcase
            end
            3'b010: begin // WORD
                mask = 32'hFFFFFFFF;
            end
            default: begin
                mask = 32'hFFFFFFFF; 
            end
        endcase
    end

    assign  mem_word    = memory[HADDR[11:2]];

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            for(i = 0; i < 1024; i = i + 1) begin
                memory[i] <= 0;
            end
        end
        else if(HWRITE_d && HREADY && HTRANS_d[1] && HSEL_d) begin
            memory[HADDR_reg[11:2]] <= (mem_word & ~mask) | (HWDATA & mask);
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            wait_state  <= 1'b0;
        end
        else if(HREADY && HSEL && HTRANS_d[1] && !wait_state) begin
            wait_state  <= 1'b1;
        end
        else if (wait_state) begin
            wait_state  <= 1'b0;
        end
    end

    assign HREADYOUT    = ~wait_state;
    assign HRESP        = (HSEL && HTRANS[1] && (HADDR[31:12] != 0)) ? 1'b1 : 1'b0; 

endmodule
