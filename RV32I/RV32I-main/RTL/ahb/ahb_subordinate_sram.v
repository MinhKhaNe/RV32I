module ahb_subordinate_sram(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Select signal
    input   wire            HSEL,
    //Address and control
    input   wire    [31:0]  HADDR,
    input   wire    [1:0]   HTRANS,     //00 idle, 01 BUSY, 10 NONSEQ, 11 SEQ
    input   wire            HWRITE,     //1 WRITE, 0 READ
    input   wire    [2:0]   HSIZE,      //000: 8 bit, 001: 16 bit, 010: 32 bit
    input   wire    [2:0]   HBURST,
    input   wire            HMASTLOCK,
    input   wire            HREADY,
    input   wire    [3:0]   HPROT,
    input   wire    [31:0]  HWDATA,     //Data from CPU
    //Data from SRAM
    input   wire    [31:0]  SRAM_DATA,  //DAta from SRAM
    //Transfer response
    output  wire            HREADYOUT,  //insert a single wait state
    output  wire            HRESP,      //WARINING 
    output  wire            HEXOKAY,
    //Data out
    output  reg     [31:0]  HRDATA,
    output  wire            hwr_en,
    output  wire            hrd_en,
    output  reg     [31:0]  data_to_sram,
    output  wire    [31:0]  address_to_sram

);

    parameter   BYTE        = 3'b000;
    parameter   HALFWORD    = 3'b001;
    parameter   WORD        = 3'b010;
    parameter   DOUBLEWORD  = 3'b011;
    parameter   WORD_LINE_4 = 3'b100;
    parameter   WORD_LINE_8 = 3'b101;

    integer         i;
    //Internal Registers
    reg     [31:0]  HRDATA_reg, HADDR_reg;
    reg             HWRITE_d, HSEL_d, HREADY_d;
    reg     [1:0]   HTRANS_d;
    reg     [2:0]   HSIZE_d;
    reg             wait_state;
    reg     [31:0]  mask, HRDATA_mask;
    wire    [31:0]  mem_word;
    wire            error_1, error_2, error_3, error_4, error_flag;
    reg             error_flag_d, error_reg;
    wire            protocol_error;
    reg             sram_ready;
    reg     [1:0]   delay_cnt; 

    assign  error_1 = HSEL && HTRANS[1] && (HADDR[11:0] > 12'hFFF);
    assign  error_2 = HSEL && HTRANS[1] && (((HSIZE == WORD) && (HADDR[1:0] != 2'b00)) || ((HSIZE == HALFWORD) && (HADDR[0] != 1'b0)));
    //assign  error_3 = HSEL && HTRANS[1] && HWRITE && HADDR[11:8] == 4'h0 && HADDR[7:0] != 8'h0;
    //assign  error_2 = 1'b0;
    assign  error_3 = HSEL && HTRANS[1] && (HADDR < 32'h0000_0040) && (HPROT[1] == 1'b0);
    assign  error_4 = HSEL && HTRANS[1] && (HSIZE > WORD);
    assign  error_flag  = error_1 || error_2 || error_3 || error_4;
    // assign  error_flag = 1'b0;
    //SRAM signals
    assign  hwr_en  = HWRITE_d && HREADY && HTRANS_d[1] && HSEL_d;
    assign  hrd_en  = !HWRITE_d && HREADY && HTRANS_d[1] && HSEL_d;
    
    assign  address_to_sram = HADDR_reg;

    //DELAY HWRITE 1 cycle
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HWRITE_d    <= 1'b0;
            HADDR_reg   <= 32'b0;
            HTRANS_d    <= 2'b0;
            HSEL_d      <= 1'b0;
            HSIZE_d     <= 3'b0;
            HREADY_d    <= 1'b0;
        end
        else if(HREADY) begin
            HWRITE_d    <= HWRITE;
            HADDR_reg   <= HADDR;
            HTRANS_d    <= HTRANS;
            HSEL_d      <= HSEL;
            HSIZE_d     <= HSIZE;
            HREADY_d    <= HREADY;
        end
    end

    // Logic điều khiển error_flag_d (Chu kỳ thứ 2)
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            error_flag_d <= 1'b0;
        end 
        else if (error_reg) begin
            error_flag_d <= 1'b1;
        end 
        else if (error_flag_d) begin
            error_flag_d <= 1'b0;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            error_reg <= 1'b0;
        end 
        else if (error_flag) begin
            error_reg <= 1'b1;
        end 
        else if (error_reg) begin
            error_reg <= 1'b0;
        end
    end
    
    //Read data
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HRDATA_reg  <= 32'b0;
        end
        else if(!error_reg && HREADY) begin
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

    assign  mem_word    = SRAM_DATA;
    assign  HRDATA      = (!error_reg && HREADY) ? HRDATA_mask : 32'b0;
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

     always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            data_to_sram <= 32'b0;
        end
        else if(!error_reg) begin
            if(HWRITE_d && HREADY && HTRANS_d[1] && HSEL_d) begin
                data_to_sram <= (mem_word & ~mask) | (HWDATA & mask);
            end
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            wait_state  <= 1'b0;
        end
        else if(HREADY && HSEL && HTRANS_d[1] && !wait_state && !error_flag) begin
            wait_state  <= 1'b1;
        end
        else if (wait_state) begin
            wait_state  <= 1'b0;
        end
        else if(error_flag_d) begin
            wait_state  <= 1'b0;
        end
    end

    // Sử dụng delay_cnt để quản lý trạng thái chờ tự động
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            delay_cnt <= 2'b0;
        end 
        else begin
            if (HREADYOUT && HSEL_d && HTRANS_d[1] && !error_flag) begin
                if (!HWRITE) begin
                    delay_cnt <= 2'd2; 
                end
                else begin
                    delay_cnt <= 2'd1;
                end
            end
            else if (delay_cnt > 0) begin
                delay_cnt <= delay_cnt - 1'b1;
            end
        end 
    end

    assign HREADYOUT = (error_reg && !error_flag_d) ? 1'b0 : (delay_cnt == 2'b0);
    assign HRESP     = error_reg || error_flag_d;
    assign HEXOKAY   = 1'b1;
endmodule