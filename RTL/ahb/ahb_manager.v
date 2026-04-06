module ahb_manager(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Transfer response
    input   wire            HREADY,
    input   wire            HRESP,
    //Data in
    input   wire    [31:0]  WDATA,      //Data in from CPU, not from sub
    input   wire    [31:0]  HWADDR,     //Address from RISCV
    input   wire            HWRITE_REQ,
    input   wire            HVALID,
    input   wire            LOCK_REQ,   //LOCK request from RISCV
    input   wire    [2:0]   HBURST_REQ,
    input   wire    [2:0]   HSIZE_REQ,
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
    //HTRANS, FSM
    parameter   IDLE    = 2'b00;
    parameter   BUSY    = 2'b01;
    parameter   NONSEQ  = 2'b10;
    parameter   SEQ     = 2'b11;
    //BURST VALUE
    parameter   SINGLE  = 3'b000;
    parameter   INCR    = 3'b001;
    parameter   WRAP4   = 3'b010;
    parameter   INCR4   = 3'b011;
    parameter   WRAP8   = 3'b100;
    parameter   INCR8   = 3'b101;
    parameter   WRAP16  = 3'b110;
    parameter   INCR16  = 3'b111;

    reg     [31:0]  HWDATA_reg, WDATA_reg, WDATA_reg_d, HADDR_reg;
    reg     [1:0]   state;
    reg             HWRITE_reg, HWRITE_reg_d;
    reg             lock;
    reg     [3:0]   burst_size, BURST_len, BURST_cnt;
    reg     [2:0]   HSIZE_d, HBURST_d;
    wire    [31:0]  addr_next, wrap_boundary, wrap_addr;
    reg     [31:0]  step_size;
    reg     [1:0]   HTRANS_reg, HTRANS_next;
    wire    [1:0]   HTRANS_eff;

    assign  HWRITE          =   HWRITE_reg;
    assign  HWDATA          =   WDATA_reg;
    assign  HADDR           =   HADDR_reg;
    assign  addr_next       =   HADDR_reg + step_size;
    assign  wrap_boundary   =   step_size * burst_size;
    assign  wrap_addr       =   {HADDR_reg & ~(wrap_boundary - 1)} | ((HADDR_reg + step_size) & (wrap_boundary - 1));
    assign  HBURST          =   HBURST_d;
    assign  HSIZE           =   HSIZE_d;
    assign  HPROT           =   4'b0011; 

    assign  HTRANS          =   HTRANS_reg;
    assign  HTRANS_eff      =   (HREADY) ? HTRANS_next : HTRANS_reg;

    always @(*) begin
        if (!HREADY) begin
            HTRANS_next = HTRANS_reg;  
        end
        else begin
            case(HTRANS_reg)
                IDLE: begin
                    HTRANS_next = HVALID ? NONSEQ : IDLE;
                end
                NONSEQ: begin
                    HTRANS_next = (HBURST_d == SINGLE) ?
                                (HVALID ? NONSEQ : IDLE) : SEQ;
                end
                SEQ: begin
                    if (!HVALID && (HBURST_d != SINGLE))
                        HTRANS_next = BUSY;  
                    else if (HBURST_d == INCR)
                        HTRANS_next = HVALID ? SEQ : IDLE;
                    else if (BURST_cnt > 0)
                        HTRANS_next = SEQ;
                    else
                        HTRANS_next = HVALID ? NONSEQ : IDLE;
                end
                BUSY: begin
                    if (HBURST_d == INCR) begin
                        if (!HVALID)
                            HTRANS_next = BUSY;
                        else if (HVALID && !HWRITE_REQ)
                            HTRANS_next = NONSEQ; // new transfer
                        else
                            HTRANS_next = SEQ;    // continue burst
                    end
                    else begin
                        if (HVALID)
                            HTRANS_next = SEQ;
                        else
                            HTRANS_next = BUSY;
                    end
                end
                default: begin
                    HTRANS_next = IDLE;
                end
            endcase
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn)
            HTRANS_reg <= IDLE;
        else begin
            if (HREADY) begin
                HTRANS_reg <= HTRANS_next;
            end
            else if (HBURST_d == INCR && HTRANS_reg == BUSY) begin
                HTRANS_reg <= HTRANS_next;
            end
            else if (HTRANS_reg == IDLE && HTRANS_next == NONSEQ) begin
                HTRANS_reg <= NONSEQ;
            end
            else if (HTRANS_reg == BUSY && HTRANS_next == SEQ) begin
                HTRANS_reg <= SEQ;
            end
        end
    end

    //Delay Wdata 1 cylce after HWRITE and HADDR
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            WDATA_reg_d   <= 32'b0;
        end
        else if(HREADY && HVALID && HWRITE_REQ) begin
        //else if(HREADY && HVALID && HWRITE_REQ) begin
            WDATA_reg_d   <= WDATA;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            WDATA_reg   <= 32'b0;
        end
        else if(HREADY) begin
            WDATA_reg   <= WDATA_reg_d;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn)
            lock    <= 1'b0;
        else if(HREADY) begin
            if(HVALID && LOCK_REQ) begin
                lock    <= 1'b1;   
            end
            else if(!HVALID) begin
                lock    <= 1'b0;
            end
        end
    end

    assign HMASTLOCK = lock;

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HBURST_d    <= 3'b0;
            HSIZE_d     <= 3'b0;
            HWRITE_reg  <= 1'b0;
        end
        else if(HREADY && HVALID) begin 
            HBURST_d    <= HBURST_REQ;
            HSIZE_d     <= HSIZE_REQ;
            HWRITE_reg  <= HWRITE_REQ;
        end
    end

    always @(*) begin
        case(HBURST_d)
            WRAP4, INCR4:   burst_size = 4;
            WRAP8, INCR8:   burst_size = 8;
            WRAP16,INCR16:  burst_size = 16;
            default:        burst_size = 1;
        endcase
    end

    always @(*) begin
        case(HBURST_d)
            SINGLE:         BURST_len = 1;
            INCR4, WRAP4:   BURST_len = 4;
            INCR8, WRAP8:   BURST_len = 8;
            INCR16, WRAP16: BURST_len = 16;
            default:        BURST_len = 1;
        endcase
    end

    always @(*) begin
        case(HSIZE_d)
            3'b000:  step_size = 32'd1; 
            3'b001:  step_size = 32'd2; 
            3'b010:  step_size = 32'd4; 
            default: step_size = 32'd4;
        endcase
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            BURST_cnt <= 4'b0;
        end
        else if(HREADY) begin
            case(HTRANS_reg)
                NONSEQ: begin
                    if (HVALID) begin
                        BURST_cnt <= (HBURST_d == INCR4)  ? 4'd3 : 
                                    (HBURST_d == INCR8)  ? 4'd7 :
                                    (HBURST_d == INCR16) ? 4'd15 : 0;
                    end
                end
                SEQ: begin
                    if (BURST_cnt > 0)
                        BURST_cnt <= BURST_cnt - 1'b1;
                end
            endcase
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HADDR_reg <= 32'b0;
        end
        else begin
            if (HREADY) begin
                case (HTRANS_next)
                    NONSEQ: HADDR_reg <= HWADDR;
                    SEQ:    HADDR_reg <= (HBURST_d[2:1] == 2'b01 || HBURST_d[2:1] == 2'b10 || HBURST_d[2:1] == 2'b11) ? wrap_addr : addr_next;
                    IDLE:   HADDR_reg <= HWADDR;
                    default: HADDR_reg <= HADDR_reg;
                endcase
            end
            else if (HTRANS_reg == IDLE && HTRANS_next == NONSEQ) begin
                HADDR_reg <= HWADDR;
            end
        end
    end

endmodule
