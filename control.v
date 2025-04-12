`include "def_select.v"

module control (
    input         clk,
    input         rst,
    input  [31:0] instr,
    input         zero,
    input         bge,
    input         blt,
    input         bgeu,
    input         bltu,
    output        PCWrite,
    output        AdrSrc,
    output        MemWrite,
    output        IRWrite,
    output [1:0]  ResultSrc,
    output [3:0]  ALUControl,
    output [1:0]  ALUSrcB,
    output [1:0]  ALUSrcA,
    output [2:0]  ImmSrc,
    output        RegWrite
);

    // Internal signals
    wire [1:0] alu_op;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    
    // Extract fields from instruction
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    main_fsm fsm (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .zero(zero),
        .blt(blt),
        .bge(bge),
        .bltu(bltu),
        .bgeu(bgeu),
        .PCWrite(PCWrite),
        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUSrcB(ALUSrcB),
        .ALUSrcA(ALUSrcA),
        .RegWrite(RegWrite),
        .alu_op(alu_op)
    );
    
    alu_decoder alu_dec (
        .alu_op(alu_op),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(ALUControl)
    );
    
    imm_decoder imm_dec (
        .opcode(opcode),
        .imm_selection(ImmSrc)
    );

endmodule