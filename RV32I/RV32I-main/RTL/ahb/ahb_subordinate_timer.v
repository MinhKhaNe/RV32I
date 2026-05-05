module ahb_subordinate_timer(
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
    input   wire    [3:0]   HPROT,
    //Transfer response
    output  reg             HREADYOUT,  //insert a single wait state
    output  wire            HRESP,      //WARINING 
    output  wire            HEXOKAY,
    //Data out
    output  wire    [31:0]  HRDATA,
    //APB Bridge
    input  wire     [31:0]  PRDATA,     //Timer Data
    input  wire             PREADY,

    output  reg             PSEL,
    output  reg             PENABLE,
    output  reg             PWRITE,
    output  reg     [11:0]  PADDR,
    output  reg     [31:0]  PWDATA
    );

    parameter   BYTE        = 3'b000;
    parameter   HALFWORD    = 3'b001;
    parameter   WORD        = 3'b010;
    parameter   DOUBLEWORD  = 3'b011;
    parameter   WORD_LINE_4 = 3'b100;
    parameter   WORD_LINE_8 = 3'b101;
    parameter   IDLE        = 2'd0;
    parameter   SETUP       = 2'd1;
    parameter   ACCESS      = 2'd2;

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
    wire            error_1, error_2, error_3, error_4, error_flag;
    reg             error_flag_d, error_reg;
    wire            protocol_error;
    reg     [1:0]   state;

    assign  error_1 = HSEL && HTRANS[1] && (HADDR[11:0] > 12'hFFF);
    assign  error_2 = HSEL && HTRANS[1] && (((HSIZE == WORD) && (HADDR[1:0] != 2'b00)) || ((HSIZE == HALFWORD) && (HADDR[0] != 1'b0)));
    //assign  error_3 = HSEL && HTRANS[1] && HWRITE && HADDR[11:8] == 4'h0 && HADDR[7:0] != 8'h0;
    //assign  error_2 = 1'b0;
    assign  error_3 = HSEL && HTRANS[1] && (HADDR < 32'h0000_0040) && (HPROT[1] == 1'b0);
    assign  error_4 = HSEL && HTRANS[1] && (HSIZE > WORD);
    assign  error_flag  = error_1 || error_2 || error_3 || error_4;
    // assign  error_flag = 1'b0;

    //APB FSM
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state <= IDLE;
            PSEL <= 0;
            PENABLE <= 0;
            HREADYOUT <= 1;
            PWDATA <= 32'b0;
        end else begin
            case(state)

                IDLE: begin
                    if (HSEL && HTRANS[1] && HREADY) begin
                        PSEL   <= 1;
                        PENABLE<= 0;
                        PADDR  <= HADDR[11:0];
                        PWRITE <= HWRITE;
                        HREADYOUT <= 0;
                        state <= SETUP;
                    end else begin
                        HREADYOUT <= 1;
                    end
                end

                SETUP: begin
                    PENABLE <= 1;
                    state <= ACCESS;
                    if (PWRITE) PWDATA <= HWDATA;
                end

                ACCESS: begin
                    if (PREADY) begin
                        HREADYOUT <= 1;
                        PSEL <= 0;
                        PENABLE <= 0;
                        state <= IDLE;
                    end else begin
                        HREADYOUT <= 0; 
                    end
                end

            endcase
        end
    end

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
            HRDATA_reg <= 32'b0;
        end
        else if(PSEL && PENABLE && PREADY && !PWRITE) begin
            HRDATA_reg <= PRDATA;
        end
    end

    assign  HRDATA  = HRDATA_reg;

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

    assign HRESP     = error_reg || error_flag_d;
    //assign HREADYOUT = (error_reg && !error_flag_d) ? 1'b0 : ~wait_state;

endmodule