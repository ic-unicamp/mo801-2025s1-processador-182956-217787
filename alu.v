`include "def_select.v"

module alu (
    input       [31:0]  a, b,
    input       [3:0]   alu_control,
    output  reg [31:0]  result,
    output              zero,
    output              blt,    // Branch if signed(a) < signed(b)
    output              bge,    // Branch if signed(a) >= signed(b)
    output              bltu,   // Branch if unsigned(a) < unsigned(b)
    output              bgeu    // Branch if unsigned(a) >= unsigned(b)
);

    wire signed_lt = ($signed(a) < $signed(b));
    wire unsigned_lt = (a < b);
    
    assign zero = (result == 32'b0);
    assign blt  = signed_lt;
    assign bge  = ~signed_lt;
    assign bltu = unsigned_lt;
    assign bgeu = ~unsigned_lt;

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
            `ALU_SLT:    result = signed_lt ? 32'b1 : 32'b0;
            `ALU_SLTU:   result = unsigned_lt ? 32'b1 : 32'b0;
            `ALU_LUI:    result = b;
            default:     result = 32'hxxxx_xxxx; // TODO: Think if this is the best default case
        endcase
    end
            
endmodule