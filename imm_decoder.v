// Decode the instruction to generate control signal for imm_extend.v
`include "def_select.v"

module imm_decoder (
    input  [6:0] opcode,
    output reg [2:0] imm_selection
);

    always @(*) begin
        case(opcode) 
            `OP_I_TYPE:   imm_selection = `I_TYPE;
            `OP_I_LOAD:   imm_selection = `I_TYPE;
            `OP_I_JALR:   imm_selection = `I_TYPE;
            `OP_B_TYPE:   imm_selection = `B_TYPE;
            `OP_S_TYPE:   imm_selection = `S_TYPE;
            `OP_J_TYPE:   imm_selection = `J_TYPE;
            `OP_U_AUIPC:  imm_selection = `U_TYPE;
            `OP_U_LUI:    imm_selection = `U_TYPE;
            default:      imm_selection = 3'bzzz; // default case
        endcase
    end

endmodule