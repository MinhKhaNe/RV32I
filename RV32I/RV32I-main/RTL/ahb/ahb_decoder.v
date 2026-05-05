module ahb_decoder(
    //Global signals
    input   wire            HCLK,
    input   wire            HRESETn,
    //Control signals
    input   wire    [31:0]  HADDR,
    //Decoder signals
    output  reg             HSEL_SRAM,
    output  reg             HSEL_TIMER,
    output  reg             HSEL_SPI,
    output  reg             HSEL_I2C,
    output  reg             HSEL_UART,
    //Invalid address
    output  reg             HSEL_INVALID
);

    always @(*) begin
        // default = 0
        HSEL_SRAM    = 1'b0;
        HSEL_TIMER   = 1'b0;
        HSEL_SPI     = 1'b0;
        HSEL_I2C     = 1'b0;
        HSEL_UART    = 1'b0;
        HSEL_INVALID = 1'b0;

        if (HRESETn) begin
            case(HADDR[31:16])
                16'h0000: HSEL_SRAM    = 1'b1;
                16'h0001: HSEL_TIMER   = 1'b1;
                16'h0002: HSEL_SPI     = 1'b1;
                16'h0003: HSEL_I2C     = 1'b1;
                16'h0004: HSEL_UART    = 1'b1;
                default:  HSEL_INVALID = 1'b1;
            endcase
        end
    end

endmodule