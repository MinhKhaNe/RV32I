`timescale 1ns/1ps

module tb_rv32i;

reg clk;
reg rst_n;

wire MEM_READY;
wire [31:0] MEM_RDATA;

assign MEM_READY = 1'b1;
assign MEM_RDATA = 32'b0;

rv32_old DUT (
    .clk(clk),
    .rst_n(rst_n)
);

//clock generation (10ns period)
initial begin
    clk = 0;
    forever #25 clk = ~clk;
end

initial begin
    rst_n = 0;

    //reset
    #20;
    rst_n = 1;

    //run program
    #10000;

    $finish;
end

//monitor signals
initial begin
    $display("time\tpc\t\tinstruction\tALU_result\tmem_data\tWRITE_DATA");

    $monitor("%0t\t%h\t%h\t%h\t%h\t%h",
        $time,
        DUT.pc,
        DUT.Instruction,
        DUT.ALU_result,
        DUT.mem_data,
        DUT.write_data
    );
    
end

endmodule