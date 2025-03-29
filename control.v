module control (
    input  [31:0] instr,
    input         zero,
    output        PCWrite,
    output        AdrSrc,
    output        MemWrite,
    output        IRWrite,
    output [1:0]  ResultSrc,
    output [2:0]  ALUOp,
    output [1:0]  ALUSrcB,
    output [1:0]  AlUSrcA,
    output [2:0]  ImmSrc,
    output        RegDst    
);
    
endmodule