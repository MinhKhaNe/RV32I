`timescale 1ns/1ps

module tb_soc_sram;

    reg clk;
    reg rst_n;
    reg [2:0] tb_sram_sel;

    // DUT
    soc_top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .sram_sel (tb_sram_sel)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    initial begin
        $display("==== START SIM ====");

        $monitor("Time=%0t | PTR=%h | WE=%b | TRACE_DATA_IN=%h | SRAMC_VAL_OUT=%h | rd_en=%b addr=%h out0=%h rd0=%b wr0=%b cen0=%b | rd1=%b wr1=%b cen1=%b",
            $time,
            dut.trace_ptr,
            dut.trace_we,
            dut.trace_out,    // Dữ liệu đang chuẩn bị ghi vào
            dut.sramc_out,
            dut.ahb.sram.sramc.rd_en_0,
            dut.ahb.sram.sramc.addr_0,
            dut.ahb.sram.sramc.out_data_0,
            dut.ahb.sram.sramc.rd_en_0,
            dut.ahb.sram.sramc.wr_en_0,
            dut.ahb.sram.sramc.cen_0,
            dut.ahb.sram.sramc.rd_en_1,
            dut.ahb.sram.sramc.wr_en_1,
            dut.ahb.sram.sramc.cen_1
        );
    end

    // =============================
    // RESET + RUN
    // =============================
    initial begin
        clk = 0;
        rst_n = 0;
        tb_sram_sel = 3'b100;

        #50;
        rst_n = 1;

        // chạy đủ lâu để thấy timer hoạt động
        #5000;

        $display("==== END SIM ====");
        $finish;
    end

endmodule