`include "def_select.v"

module control (
    input             clk,
    input             rst,
    input      [31:0] instr,
    input             zero,
    output reg        PCWrite,
    output reg        AdrSrc,
    output reg        MemWrite,
    output reg        IRWrite,
    output reg [1:0]  ResultSrc,
    output     [3:0]  ALUControl,
    output reg [1:0]  ALUSrcB,
    output reg [1:0]  ALUSrcA,
    output     [2:0]  ImmSrc,
    output reg        RegWrite
);

    // FSM State Definition
    parameter FETCH   = 4'b0000;
    parameter DECODE  = 4'b0001;
    parameter JAL     = 4'b0010;
    parameter ALU_WB  = 4'b0011;
    parameter MEM_WB  = 4'b0100;
    parameter BEQ     = 4'b0101;
    parameter EXECUTE_I = 4'b0110;
    parameter EXECUTE_R = 4'b0111;
    // TODO: Define the other states

    // Internal signals
    reg [3:0] state, next_state;
    reg [1:0] alu_op;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    
    // Extract fields from instruction
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    
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

    // State register
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0)
            state <= FETCH;
        else
            state <= next_state;
    end


    // Next state logic
    always @(*) begin
        case (state)
            FETCH: 
                next_state = DECODE;
            
            DECODE: begin
                case (opcode)
                    // TODO: Write the logic for other states
                    `OP_R_TYPE:     next_state = EXECUTE_R;
                    `OP_I_TYPE:     next_state = EXECUTE_I;
                    `OP_B_TYPE:     next_state = BEQ;
                    `OP_J_TYPE:     next_state = JAL;
                endcase
            end

            // TODO: Write the logic fot the other states
            EXECUTE_R:
                next_state = ALU_WB;

            EXECUTE_I:
                next_state = ALU_WB;

            JAL:
                next_state = ALU_WB;
            
            ALU_WB:
                next_state = FETCH;
            
            BEQ:
                next_state = FETCH;
            
            MEM_WB:
                next_state = FETCH;

            default:
                next_state = FETCH;
        endcase
    end

    // Output logic
    always @(*) begin
        PCWrite   = 1'b0;
        AdrSrc    = 1'b0;
        MemWrite  = 1'b0;
        IRWrite   = 1'b0;
        ResultSrc = 2'b00;
        ALUSrcB   = 2'b00;
        ALUSrcA   = 2'b00;
        RegWrite  = 1'b0;
        alu_op    = 2'b00;

        case (state)
            FETCH: begin
                AdrSrc   = 1'b0;   // Select PC as memory address
                IRWrite  = 1'b1;   // Enable writing to Instruction Register
                ALUSrcA  = 2'b00;  // Select PC for ALU input A
                ALUSrcB  = 2'b10;  // Select constant 4 for ALU input B
                ResultSrc = 2'b10; // Select ALU Result
                PCWrite  = 1'b1;   // Enable writing to PC
                alu_op   = 2'b00;
            end
            
            DECODE: begin
                ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                ALUSrcB  = 2'b01;  // Select immediate for ALU input B
                alu_op   = 2'b00;
            end
            
            EXECUTE_R: begin
                ALUSrcA = 2'b10;   // Select rs1 value for ALU input A
                ALUSrcB = 2'b00;   // Select rs2 value for ALU input B
                alu_op = 2'b10;     // ALU operation determined by funct3/funct7
            end

            EXECUTE_I: begin
                ALUSrcA = 2'b10;   // Select rs1 value for ALU input A
                ALUSrcB = 2'b01;   // Select rs2 value for ALU input B
                alu_op = 2'b10;     // ALU operation determined by funct3/funct7
            end

            JAL: begin
                ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                ALUSrcB  = 2'b01;  // Select immediate for ALU input B
                ResultSrc = 2'b00; // Select ALU Out for link address
                PCWrite  = 1'b1;   // Enable PC write
                RegWrite = 1'b1;   // Enable register write for link address
                alu_op = 2'b00;
            end
            
            ALU_WB:  begin
                ResultSrc = 2'b00; // Select ALU Out
                RegWrite  = 1'b1;  // Enable register write
            end

            BEQ: begin
                ALUSrcA  = 2'b10;  // Select register data for ALU input A
                ALUSrcB  = 2'b00;  // Select register data for ALU input B
                ResultSrc = 2'b00; // Select Memory Data
                alu_op   = 2'b01;
                if (zero && funct3 == 3'b000) // beq
                    PCWrite = 1'b1; // Enable PC write if branch taken
                if (~zero && funct3 == 3'b001) // bne
                    PCWrite = 1'b1;
            end

            MEM_WB: begin
                ResultSrc = 2'b01; // Select Memory Data
                RegWrite  = 1'b1;  // Enable register write
            end

            default: begin
                // Jump to the next intruction as default
                ALUSrcA  = 2'b00;  // Select PC for ALU input A
                ALUSrcB  = 2'b10;  // Select constant 4 for ALU input B
                ResultSrc = 2'b10; // Select ALU Result
                PCWrite  = 1'b1;   // Enable writing to PC            
            end
        endcase
    end
     
endmodule