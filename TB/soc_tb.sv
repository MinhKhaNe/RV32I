`timescale 1ns/1ps

module soc_tb;

    //================ CLOCK & RESET =================//
    reg clk;
    reg rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    //================ DUT =================//
    soc_top dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    //================ SIM CONTROL =================//
    initial begin
        $display("===== START SOC SIM =====");

        // chạy đủ lâu để pipeline ổn định
        #5000;

        $display("===== END SOC SIM =====");
        $finish;
    end

    //================ WAVEFORM =================//
    initial begin
        $dumpfile("soc_wave.vcd");
        $dumpvars(0, soc_tb);
    end

    //================ DEBUG CPU =================//
    always @(posedge clk) begin
        if (rst_n) begin
            $display("TIME=%0t | PC=%h | INST=%h",
                $time,
                dut.rv.pc,
                dut.rv.IF_ID_Instruction
            );
        end
    end

    //================ TRACE WRITE (SRAMC) =================//
    always @(posedge clk) begin
        if (dut.rv.cpu_valid) begin
            $display("TRACE WRITE -> ADDR=%h DATA=%h",
                dut.rv.cpu_addr,
                dut.rv.cpu_wdata
            );
        end
    end

    //================ STALL DEBUG =================//
    always @(posedge clk) begin
        if (dut.rv.Stall) begin
            $display("STALL at PC=%h", dut.rv.pc);
        end
    end

    //================ FINISH WHEN PC LOOP =================//
    reg [31:0] last_pc;
    integer same_pc_count;

    initial begin
        last_pc = 0;
        same_pc_count = 0;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (dut.rv.pc == last_pc)
                same_pc_count = same_pc_count + 1;
            else
                same_pc_count = 0;

            last_pc = dut.rv.pc;

            if (same_pc_count > 20) begin
                $display("PC STUCK -> STOP SIM");
                $finish;
            end
        end
    end

endmodule