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
    wire            Branch_taken;
    wire    [31:0]  pc;

    wire            Stall, Flush, enable;
    wire    [31:0]  ALU_B, ALU_A;
    wire    [2:0]   funct3;
    wire    [31:0]  write_data;
    wire    [31:0]  mem_data;
    wire    [31:0]  pc_plus4;
    wire    [2:0]   imm_type;

    assign  pc_plus4    =   pc + 32'd4;
    assign  write_data  =   (MemToReg) ?    mem_data :
                            (Jump)     ?    pc_plus4:
                            (LUI)      ?    immediate :
                                            ALU_result;

    assign  ALU_A       =   (ALUSrc1) ? pc : operand_1;
    assign  ALU_B       =   (ALUSrc2) ? immediate : operand_2;
    assign  opcode      =   Instruction[6:0];
    assign  enable      =   ~Stall && ~Flush;
    assign  funct3      =   Instruction[14:12];

    //Register File
    Register_file RF0 (.clk(clk), .rst_n(rst_n), .en(RegWrite), .rs1(Instruction[19:15]), .rs2(Instruction[24:20]), .rd(Instruction[11:7]), .wd(write_data), .rv1(operand_1), .rv2(operand_2));

    //ALU
    ALU A0 (.A(ALU_A), .B(ALU_B), .ALUControl(ALUControl), .ALU_result(ALU_result), .ZERO(ZERO));

    //Immediate Generator
    Immediate_generator IG0 (.Instruction(Instruction), .imm_type(imm_type), .immediate(immediate_raw));

    //Sign extend for immediate generator result
    Sign_extend SE0 (.immediate(immediate_raw), .imm_type(imm_type), .extended_imm(immediate));

    //Control Unit
    Control_unit CU0 (.opcode(opcode), .ALUOp(ALUOp), .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch), .Jump(Jump), .MemToReg(MemToReg), .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .LUI(LUI), .Pcsrc(Pcsrc), .imm_type(imm_type));

    //ALU Control
    ALU_control AC0 (.ALUOp(ALUOp), .funct3(funct3), .funct7(Instruction[31:25]), .ALU_control(ALUControl));
    
    //PC
    PC PC0 (.clk(clk), .rst_n(rst_n), .Branch(Branch), .Pcsrc(Pcsrc), .Jump(Jump), .Branch_taken(Branch_taken), .offset(immediate), .rs1_data(operand_1), .pc(pc));
    
    //Branch Prediction
    Branch_prediction BE0 (.funct3(funct3), .ALU_result(ALU_result), .ZERO(ZERO), .Branch_taken(Branch_taken));

    //Instruction Memory
    Instruction_memory IM0 (.pc(pc), .Instruction(Instruction));

    //Data Memory
    Data_memory DM0 (.clk(clk), .MemRead(MemRead), .MemWrite(MemWrite), .addr(ALU_result), .write_data(operand_2), .read_data(mem_data));

    //IF

    //ID

    //EX

    //MEM

    //WB

    //Forwarding Unit

    //Hazard Detection

endmodule