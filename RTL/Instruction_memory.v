module Instruction_memory(
    input   wire    [31:0]  pc,

    output  wire    [31:0]  Instruction
);

    reg [31:0]  mem [0:1023];

    initial begin
        // Load store test

        mem[0] = 32'h00000093; // addi x1,x0,0

        mem[1] = 32'h00B00113; // addi x2,x0,11
        mem[2] = 32'h0020A023; // sw x2,0(x1)

        mem[3] = 32'h01600193; // addi x3,x0,22
        mem[4] = 32'h0030A223; // sw x3,4(x1)

        mem[5] = 32'h0000A203; // lw x4,0(x1)
        mem[6] = 32'h0040A283; // lw x5,4(x1)

        mem[7] = 32'h00000013; // nop

    end

    assign  Instruction =   mem[pc[31:2]];  //PC >> 2

endmodule