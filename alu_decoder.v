module alu_decoder (
    input  [1:0] alu_op,
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,   // Used for R-type (and shift immediate) instructions
    output reg [3:0] alu_control
);

    always @(*) begin
        case (alu_op)
            00: alu_control = `ALU_ADD;
            01: alu_control = `ALU_SUB;
            10: begin
                case (opcode)
                    `OP_R_TYPE: begin
                        case (funct3)
                            3'b000: alu_control = (funct7 == 7'b0100000) ? `ALU_SUB : `ALU_ADD;
                            3'b001: alu_control = `ALU_SLL;
                            3'b010: alu_control = `ALU_SLT;
                            3'b011: alu_control = `ALU_SLTU;
                            3'b100: alu_control = `ALU_XOR;
                            3'b101: alu_control = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL;
                            3'b110: alu_control = `ALU_OR;
                            3'b111: alu_control = `ALU_AND;
                            default: alu_control = 4'bzzzz;
                        endcase
                    end
                    `OP_I_TYPE: begin
                        case (funct3)
                            3'b000: alu_control = `ALU_ADD;  // ADDI
                            3'b010: alu_control = `ALU_SLT;  // SLTI
                            3'b011: alu_control = `ALU_SLTU; // SLTU
                            3'b100: alu_control = `ALU_XOR;  // XORI
                            3'b110: alu_control = `ALU_OR;   // ORI
                            3'b111: alu_control = `ALU_AND;  // ANDI
                            3'b001: alu_control = `ALU_SLL;  // SLLI
                            3'b101: alu_control = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL;  // SRLI/SRAI
                            default: alu_control = 4'bzzzz;
                        endcase
                    end
                    `OP_I_LOAD: alu_control = `ALU_ADD;
                    `OP_S_TYPE: alu_control = `ALU_ADD;
                    `OP_B_TYPE: begin
                        case (funct3)
                            3'b000: alu_control = `ALU_SUB;   // BEQ (check if rs1 == rs2)
                            3'b001: alu_control = `ALU_SUB;   // BNE (check if rs1 != rs2)
                            // TODO -> Verify the better way to handle the following branch instructions type
                            // 3'b100: alu_control = `ALU_SLT;   // BLT
                            // 3'b101: alu_control = `ALU_SLTU;  // BGE
                            // 3'b110: alu_control = `ALU_SLT;   // BLTU
                            // 3'b111: alu_control = `ALU_SLTU;  // BGEU
                            default: alu_control = 4'bzzzz;
                        endcase
                    end
                    // Jump and Link Register (JALR - I-type, needs ALU to compute target address)
                    `OP_I_JALR: alu_control = `ALU_ADD; // JALR: target = rs1 + offset
                    `OP_J_TYPE: alu_control = `ALU_ADD;
                    `OP_U_LUI: alu_control = `ALU_LUI;
                    `OP_U_AUIPC: alu_control = `ALU_ADD;
                    default: alu_control = 4'bzzzz; // Default control signal (could be modified as needed)
                endcase
            end
            default: alu_control = 4'bzzzz; // Default control signal (could be modified as needed)
        endcase
    end

endmodule
