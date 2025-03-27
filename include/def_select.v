// This files is used to set some general parameterized values

// ALU control select
// Used in: alu.v
`define ALU_ADD     4'b0000
`define ALU_SUB     4'b0001
`define ALU_AND     4'b0010
`define ALU_OR      4'b0011
`define ALU_XOR     4'b0100
`define ALU_SLL     4'b0101 // Shift left
`define ALU_SRL     4'b0110 // Shift right
`define ALU_SRA     4'b0111 // shift right arithmetic
`define ALU_SLT     4'b1000 // set less than
`define ALU_SLTU    4'b1001 // set less than unsigned
`define ALU_LUI     4'b1010 // Load upper immediate

// Instruction format select
// used in: imm_extend.v
`define I_TYPE      3'b000
`define S_TYPE      3'b001
`define B_TYPE      3'b010
`define U_TYPE      3'b011
`define J_TYPE      3'b100 