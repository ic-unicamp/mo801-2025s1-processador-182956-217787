`include "def_select.v"

module alu (
    input       [31:0]  a, b,
    input       [3:0]   alu_control,
    output  reg [31:0]  result,
    output              zero
);

    assign zero = (result == 32'b0);

    always @(*) begin
        case (alu_control)
            `ALU_ADD:    result = a + b;
            `ALU_SUB:    result = a - b;
            `ALU_AND:    result = a & b;
            `ALU_OR:     result = a | b;
            `ALU_XOR:    result = a ^ b;
            `ALU_SLL:    result = a << b[4:0];
            `ALU_SRL:    result = a >> b[4:0];
            `ALU_SRA:    result = $signed(a) >>> b[4:0];
            `ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            `ALU_SLTU:   result = (a < b) ? 32'b1 : 32'b0;
            `ALU_LUI:    result = b; // TODO: Think if this is necessary
            default:    result = 32'hxxxx_xxxx; // TODO: Think if this is the best default case 
        endcase
    end
            
endmodule
