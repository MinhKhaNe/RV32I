module rv32i_top(
    input   wire        clk,
    input   wire        rst_n
);
    //Internal Registers and Wires
    wire    [31:0]  Instruction;
    wire            RegWrite, MemRead, MemToReg, MemWrite, Branch, Jump, ALUSrc1, ALUSrc2, LUI, Pcsrc, ZERO;
    wire    [6:0]   opcode;
    wire    [2:0]   ALUOp;
    wire    [3:0]   ALUControl;
    wire    [31:0]  immediate_raw, immediate;
    wire    [31:0]  ALU_result;
    wire    [31:0]  operand_1, operand_2;

    assign opcode   = Instruction[6:0];

    //Register File
    Register_file RF0 (.clk(clk), .rst_n(rst_n), .en(), .rs1(Instruction[19:15]), .rs2(Instruction[24:20]), .rd(Instruction[11:7]), .wd(), .rv1(operand_1), .rv2(operand_2));

    //ALU
    ALU A0 (.A(operand_1), .B(operand_2), .ALUControl(ALUControl), .ALU_result(ALU_result), .ZERO(ZERO));

    //Immediate Generator
    Immediate_generator IG0 (.Instruction(Instruction), .imm_type(Instruction[14:12]), .immediate(immediate_raw));

    //Sign extend for immediate generator result
    Sign_extend SE0 (.immediate(immediate_raw), .imm_type(Instruction[14:12]), .extended_imm(immediate));

    //Control Unit
    Control_unit CU0 (.opcode(opcode), .ALUOp(ALUOp), .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch), .Jump(Jump), .MemToReg(MemToReg), .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .LUI(LUI), .Pcsrc(Pcsrc));

    //ALU Control
    ALU_control AC0 (.ALUOp(ALUOp), .funct3(Instruction[14:12]), .funct7(Instruction[31:25]), .ALU_control(ALUControl));
    
    //PC

    //Instruction Memory

    //Data Memory

    //IF

    //ID

    //EX

    //MEM

    //WB

endmodule