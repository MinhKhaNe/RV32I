module ahb_multiplexor(
    input  wire        hsel_sram,
    input  wire        hsel_timer,

    input  wire [31:0] hrdata_sram,
    input  wire [31:0] hrdata_timer,

    input  wire        hready_sram,
    input  wire        hready_timer,

    input  wire        hresp_sram,
    input  wire        hresp_timer,

    output reg  [31:0] HRDATA,
    output reg         HREADY,
    output reg         HRESP
);

    always @(*) begin
        if (hsel_sram) begin
            HRDATA = hrdata_sram;
            HREADY = hready_sram;
            HRESP  = hresp_sram;
        end 
        else if (hsel_timer) begin
            HRDATA = hrdata_timer;
            HREADY = hready_timer;
            HRESP  = hresp_timer;
        end 
        else begin
            HRDATA = 32'h0;
            HREADY = 1'b1;
            HRESP  = 1'b0;
        end
    end

endmodule