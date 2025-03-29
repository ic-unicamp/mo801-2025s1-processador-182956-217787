// Decode the instruction to generate control signal for imm_extend.v
`include "def_select.v"

module imm_decoder (
    input  [6:0] opcode,
    output [2:0] imm_selection
);
    reg imm_selection;

    always @(*) begin
       case(opcode) 
            7'b001_0011: imm_selection  = I_TYPE; // R-type
            7'b000_0011: imm_selection  = I_TYPE; // R-type
            7'b110 0111: imm_selection  = I_TYPE; // B-type
            7'b110_0011: imm_selection  = B_TYPE; // B-type
            7'b010_0011: imm_selection  = S_TYPE; // S-type
            7'b110_1111: imm_selection  = J_TYPE; // J-type
            7'b001_0111: imm_selection  = U_TYPE; // U-type
            7'b011 0111: imm_selection  = U_TYPE; // U-type
            default:     imm_selection  = 3'bzzz; // default 
       endcase
    end

endmodule