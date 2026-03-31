module ahb_manager(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Transfer response
    input   wire            HREADY,
    input   wire            HRESP,
    //Data in
    input   wire    [31:0]  HRDATA,     //Data in from CPU, not from sub
    //Address and Control
    output  wire    [31:0]  HADDR,
    output  wire    [2:0]   HBURST,
    output  wire            HMASTLOCK,  //can FSM
    output  wire    [3:0]   HPROT,
    output  wire    [2:0]   HSIZE,
    output  wire    [1:0]   HTRANS,     //Chua co logic xu ly
    output  wire            HWRITE,
    output  wire    [31:0]  HWDATA
);

    parameter IDLE      = 2'b00;
    parameter BUSY      = 2'b01;
    parameter NONSEQ    = 2'b10;
    parameter SEQ       = 2'b11;

    reg     [31:0]  HWDATA_reg;
    reg     [1:0]   state;
    reg             HWRITE_d;

    //DELAY HWRITE 1 cycle
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HWRITE_d    <= 1'b0;
        end
        else if(HREADY) begin   //(HREADY && HSEL)
            HWRITE_d    <= HWRITE;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HWDATA_reg  <= 32'b0;
        end
        else if(HWRITE_d && HREADY) begin
            HWDATA_reg  <= HRDATA;
        end
    end

    assign  HWDATA  = HWDATA_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            state   <= IDLE;
        end
        else if(HREADY) begin
            case(state)
                IDLE:
                BUSY:
                NONSEQ:
                SEQ:
            endcase
        end
    end

    assign  HTRANS =    (state == IDLE)     ? 2'b00 :
                        (state == BUSY)     ? 2'b00 :
                        (state == NONSEQ)   ? 2'b00 :
                                              2'b11 ;

endmodule