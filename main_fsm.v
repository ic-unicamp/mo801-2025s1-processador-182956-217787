module main_fsm (
    input             clk,
    input             rst,
    input      [6:0]  opcode,
    input      [2:0]  funct3,
    input      [6:0]  funct7,
    input             zero,
    input             bge,
    input             blt,
    input             bgeu,
    input             bltu,
    output reg        PCWrite,
    output reg        AdrSrc,
    output reg        MemWrite,
    output reg        IRWrite,
    output reg [1:0]  ResultSrc,
    output reg [1:0]  ALUSrcB,
    output reg [1:0]  ALUSrcA,
    output reg        RegWrite,
    output reg [1:0]  alu_op
);
    // FSM State Definition
    parameter FETCH     = 4'b0000;
    parameter DECODE    = 4'b0001;
    parameter JAL       = 4'b0010;
    parameter ALU_WB    = 4'b0011;
    parameter MEM_WB    = 4'b0100;
    parameter BRANCH    = 4'b0101;
    parameter EXECUTE_I = 4'b0110;
    parameter EXECUTE_R = 4'b0111;
    parameter MEM_ADDR  = 4'b1000;
    parameter MEM_READ  = 4'b1001;
    parameter MEM_WRITE = 4'b1010;
    parameter AUIPC     = 4'b1100;
    parameter JALR      = 4'b1101;
    parameter UPDATE_PC   = 4'b1110;
    // TODO: Define the other states

    reg [3:0] state, next_state;
    wire is_less_than;
    wire is_less_than_unsigned;

    assign is_less_than           = ~zero;
    assign is_less_than_unsigned  = ~zero;

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
                    `OP_R_TYPE: next_state = EXECUTE_R;
                    `OP_I_TYPE: next_state = EXECUTE_I;
                    `OP_I_LOAD: next_state = MEM_ADDR;
                    `OP_S_TYPE: next_state = MEM_ADDR;
                    `OP_B_TYPE: next_state = BRANCH;
                    `OP_J_TYPE: next_state = JAL;
                    `OP_I_JALR: next_state = JALR;
                    `OP_U_LUI:  next_state = EXECUTE_I;
                    `OP_U_AUIPC: next_state = AUIPC;
                    default: next_state = FETCH; // Default to FETCH for unknown opcodes
                endcase
            end

            // TODO: Write the logic for the other states
            EXECUTE_R:
                next_state = ALU_WB;

            EXECUTE_I:
                next_state = ALU_WB;

            JAL:
                next_state = UPDATE_PC;

            JALR:
                next_state = UPDATE_PC;

            UPDATE_PC:
                next_state = FETCH;

            MEM_ADDR: begin
                if (opcode == `OP_S_TYPE)
                    next_state = MEM_WRITE;
                else
                    next_state = MEM_READ;
            end

            MEM_READ:
                next_state = MEM_WB;
            AUIPC:
                next_state = ALU_WB;
            MEM_WRITE:
                next_state = FETCH;
                
            ALU_WB:
                next_state = FETCH;
            
            BRANCH:
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
                AdrSrc    = 1'b0;   // Select PC as memory address
                IRWrite   = 1'b1;   // Enable writing to Instruction Register
                ALUSrcA   = 2'b00;  // Select PC for ALU input A
                ALUSrcB   = 2'b10;  // Select constant 4 for ALU input B
                ResultSrc = 2'b10; // Select ALU Result
                PCWrite   = 1'b1;   // Enable writing to PC
                alu_op    = 2'b00;
            end
            
            DECODE: begin
                if (opcode == `OP_I_JALR || opcode == `OP_J_TYPE) begin
                    ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                    ALUSrcB  = 2'b10;  // Select 4 for ALU input B
                    ResultSrc = 2'b00; // Select ALU Out
                    RegWrite  = 1'b1;  // Enable register write
                    alu_op   = 2'b00;  // Add operation
                end else begin
                    ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                    ALUSrcB  = 2'b01;  // Select immediate for ALU input B
                    alu_op   = 2'b00;
                end
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
                ALUSrcA = 2'b01;   // Select old PC for ALU input A
                ALUSrcB = 2'b01;   // Select immediate for ALU input B
                alu_op = 2'b10;    // Special operation (JAL)
                ResultSrc = 2'b00; // Select ALU Out for link address
                PCWrite = 1'b1;    // Enable PC write
            end

            JALR: begin
                ALUSrcA = 2'b10;   // Select register file for ALU input A
                ALUSrcB = 2'b01;   // Select immediate for ALU input B
                alu_op = 2'b10;    // Special operation (JAL)
                ResultSrc = 2'b00; // Select ALU Out for link address
                PCWrite = 1'b1;    // Enable PC write
            end

            UPDATE_PC: begin
                PCWrite = 1'b1;    // Enable PC write
            end

            MEM_ADDR: begin
                ALUSrcA = 2'b10;   // Select rs1 value for ALU input A
                ALUSrcB = 2'b01;   // Select immediate for ALU input B 
                alu_op = 2'b00;     // ALU performs addition
            end

            MEM_READ: begin
                ResultSrc = 2'b00; // Select ALU result for address
                AdrSrc = 1'b1;     // Use ALU result as memory address
            end
            
            MEM_WRITE: begin
                ResultSrc = 2'b00; // Select ALU result for address
                AdrSrc = 1'b1;     // Use ALU result as memory address
                MemWrite = 1'b1;   // Enable memory write
            end
            AUIPC: begin
                ALUSrcA = 2'b01;   // Select immediate for ALU input B
                ALUSrcB = 2'b01;   // Select immediate for ALU input B
                alu_op = 2'b10;    // Special operation (LUI)
            end
            ALU_WB:  begin
                ResultSrc = 2'b00; // Select ALU Out
                RegWrite  = 1'b1;  // Enable register write
            end

            BRANCH: begin
                ALUSrcA  = 2'b10;  // Select register data for ALU input A
                ALUSrcB  = 2'b00;  // Select register data for ALU input B
                ResultSrc = 2'b00; // Select Memory Data
                alu_op   = 2'b01;
                case (funct3)
                    3'b000: begin // BEQ
                        PCWrite = zero ? 1'b1 : 1'b0;
                    end
                    3'b001: begin // BNE
                        PCWrite = ~zero ? 1'b1 : 1'b0;
                    end
                    3'b100: begin // BLT (signed)
                        PCWrite = blt ? 1'b1 : 1'b0;
                    end
                    3'b101: begin // BGE (signed)
                        PCWrite = bge ? 1'b1 : 1'b0;
                    end
                    3'b110: begin // BLTU (unsigned)
                        PCWrite = bltu ? 1'b1 : 1'b0;
                    end
                    3'b111: begin // BGEU (unsigned)
                        PCWrite = bgeu ? 1'b1 : 1'b0;
                    end
                    default: begin
                        PCWrite = 1'b0; // Invalid funct3
                    end
                endcase
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