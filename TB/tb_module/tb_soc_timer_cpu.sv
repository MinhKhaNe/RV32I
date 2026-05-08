`timescale 1ns/1ps

module tb_soc_timer_cpu;

    reg clk;
    reg rst_n;

    // DUT
    soc_top dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (dut.valid) begin
            $display("[CPU ACCESS] addr=%h write=%b wdata=%h",
                dut.cpu_addr,
                dut.write_req,
                dut.cpu_wdata
            );
        end
    end

    always @(posedge clk) begin
        if (dut.ahb.tim_psel && dut.ahb.tim_penable) begin
            $display("[APB] addr=%h write=%b wdata=%h rdata=%h",
                dut.ahb.tim_paddr,
                dut.ahb.tim_pwrite,
                dut.ahb.tim_pwdata,
                dut.ahb.tim_prdata
            );
        end
    end

    // always @(posedge clk) begin
    //     $display("Time=%0t | x2 value = %h", $time, dut.rv.RF0.in_registers[2]); 
    // end

    initial begin
        $display("==== START SIM ====");

        $monitor("T=%0t | ADDR_TO_TIMER=%h | WRITE=%b | WDATA=%h | READY=%b | PSEL=%b PENABLE=%b PWRITE=%b PADDR=%h PWDATA=%h| wr_en=%b rd_en=%b | INT=%b",
            $time,
            dut.cpu_addr,
            dut.write_req,
            dut.cpu_wdata,
            dut.ready,

            dut.ahb.tim_psel,
            dut.ahb.tim_penable,
            dut.ahb.tim_pwrite,
            dut.ahb.tim_paddr,
            dut.ahb.tim_pwdata,

            dut.ahb.timer.wr_en,
            dut.ahb.timer.rd_en,
            dut.ahb.tim_int
        );
    end

    // =============================
    // RESET + RUN
    // =============================
    initial begin
        clk = 0;
        rst_n = 0;

        #50;
        rst_n = 1;

        // chạy đủ lâu để thấy timer hoạt động
        #5000;

        $display("==== END SIM ====");
        $finish;
    end

endmodule