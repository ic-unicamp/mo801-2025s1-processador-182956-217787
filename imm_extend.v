`include "def_select.v"

module imm_extend (
    input       [31:0]  instruction, // Can probabily be reduced to [31:12]
    input       [2:0]   imm_selection,
    output  reg [31:0]  imm_extended
);
    always @(*)
    begin
        case (imm_selection)
            `I_TYPE: imm_extended = {{21{instruction[31]}}, instruction[30:20]};
            `S_TYPE: imm_extended = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
            `B_TYPE: imm_extended = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            `U_TYPE: imm_extended = {instruction[31:12], 12'b0};
            `J_TYPE: imm_extended = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            default: imm_extended = 32'bz;
        endcase
    end
    
endmodule