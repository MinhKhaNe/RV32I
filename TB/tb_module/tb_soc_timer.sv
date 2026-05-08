`timescale 1ns/1ps

module tb_soc_timer;

    reg clk;
    reg rst_n;

    // Fake CPU signals
    reg  [31:0] cpu_addr;
    reg  [31:0] cpu_wdata;
    reg         cpu_write_req;
    reg         cpu_valid;

    wire [31:0] cpu_rdata;
    wire        cpu_ready;

    // DUT
    ahb_top dut (
        .HCLK(clk),
        .HRESETn(rst_n),

        .CPU_WDATA(cpu_wdata),
        .CPU_ADDR(cpu_addr),
        .CPU_WRITE_REQ(cpu_write_req),
        .CPU_VALID(cpu_valid),
        .CPU_BURST_REQ(3'b000),
        .CPU_SIZE_REQ(3'b010),
        .CPU_PRIVILEGED(1'b1),
        .CPU_DATA(1'b1),
        .CPU_HPROT(4'b0011),

        .CPU_RDATA(cpu_rdata),
        .CPU_READY(cpu_ready)
    );

    // Clock
    always #5 clk = ~clk;

    task ahb_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        cpu_addr      <= addr;
        cpu_wdata     <= data;
        cpu_write_req <= 1;
        cpu_valid     <= 1;

        // chờ ready
        while (!cpu_ready) @(posedge clk);

        @(posedge clk);

        cpu_valid     <= 0;
        cpu_write_req <= 0;
    end
    endtask

    task ahb_read(input [31:0] addr);
    begin
        @(posedge clk);
        cpu_addr      <= addr;
        cpu_write_req <= 0;
        cpu_valid     <= 1;

        while (!cpu_ready) @(posedge clk);

        @(posedge clk);

        cpu_valid <= 0;
    end
    endtask

    initial begin
        $monitor("Time=%0t | PSEL=%b PENABLE=%b PWRITE=%b | PADDR=%h | PWDATA=%h | PRDATA=%h | wr_en=%b rd_en=%b | tim_int=%b",
            $time,           
            dut.tim_psel,    
            dut.tim_penable, 
            dut.tim_pwrite, 
            dut.tim_paddr,   
            dut.tim_pwdata,  
            dut.tim_prdata,  
            dut.timer.wr_en, 
            dut.timer.rd_en,
            dut.tim_int        // <-- thêm dòng này
        );
        clk = 0;
        rst_n = 0;

        cpu_addr = 0;
        cpu_wdata = 0;
        cpu_write_req = 0;
        cpu_valid = 0;

        // Reset
        #20;
        rst_n = 1;

        #20;

        ahb_write(32'h0001_0004, 32'hFFFF_FF00); // TDR0
        repeat(3) @(posedge clk);
        //ahb_read (32'h0001_0004);

        ahb_write(32'h0001_0008, 32'hFFFF_FFFF); // TDR1
        repeat(3) @(posedge clk);
        //ahb_read (32'h0001_0008);

        ahb_write(32'h0001_000C, 32'hFFFF_FFFF); // TDR0
        repeat(3) @(posedge clk);
        //ahb_read (32'h0001_000C);

        ahb_write(32'h0001_0010, 32'hFFFF_FFFF); // TDR1
        repeat(3) @(posedge clk);
        //ahb_read (32'h0001_0010);

        ahb_write(32'h0001_0014, 32'h01); // TIER
        repeat(3) @(posedge clk);
        //ahb_read (32'h0001_0014);

        ahb_write(32'h0001_0000, 32'h0000_0001); // TIER
        repeat(3) @(posedge clk);
        //ahb_read (32'h0001_0000);

        repeat(256) @(posedge clk);
        ahb_read (32'h0001_0018);

        #100;

        $finish;
    end

endmodule