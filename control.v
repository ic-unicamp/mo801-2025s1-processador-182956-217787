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
    output reg [3:0]  ALUControl,
    output reg [1:0]  ALUSrcB,
    output reg [1:0]  ALUSrcA,
    output reg [2:0]  ImmSrc,
    output reg        RegWrite
);

    // FSM State Definition
    parameter FETCH   = 4'b0000;
    parameter DECODE  = 4'b0001
    parameter JAL     = 4'b0010;
    // TODO: Define the other states

    // Internal signals
    reg [3:0] state, next_state;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    
    // Extract fields from instruction
    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    
    alu_decoder alu_dec (
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
                    `OP_J_TYPE:  next_state = JAL;
                endcase
            end

            // TODO: Write the logic fot the other states
            JAL:
                next_state = FETCH;

            default:
                next_state = FETCH;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            FETCH: begin
                AdrSrc   = 1'b0;   // Select PC as memory address
                IRWrite  = 1'b1;   // Enable writing to Instruction Register
                ALUSrcA  = 2'b00;  // Select PC for ALU input A
                ALUSrcB  = 2'b10;  // Select constant 4 for ALU input B
                ResultSrc = 2'b10; // Select ALU Result
                PCWrite  = 1'b1;   // Enable writing to PC
            end
            
            DECODE: begin
                ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                ALUSrcB  = 2'b01;  // Select immediate for ALU input B
            end

            JAL: begin
                ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                ALUSrcB  = 2'b01;  // Select immediate for ALU input B
                ResultSrc = 2'b00; // Select ALU Out for link address
                PCWrite  = 1'b1;   // Enable PC write
                RegWrite = 1'b1;   // Enable register write for link address
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