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
    parameter FETCH         = 4'b0000;
    parameter DECODE        = 4'b0001;
    parameter JAL           = 4'b0010; 
    parameter ALU_WB        = 4'b0011;
    parameter MEM_WB        = 4'b0100;
    parameter BRANCH        = 4'b0101;
    parameter EXECUTE_I     = 4'b0110;
    parameter EXECUTE_R     = 4'b0111;
    parameter MEM_ADDR      = 4'b1000;
    parameter MEM_READ      = 4'b1001;
    parameter MEM_WRITE     = 4'b1010;
    parameter AUIPC         = 4'b1011; 
    parameter JALR          = 4'b1100;
    parameter UPDATE_PC     = 4'b1101;
    // parameter MEM_WRITE_FIN = 4'b1110;



    reg [3:0] state, next_state;

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
                    `OP_R_TYPE: next_state = EXECUTE_R;
                    `OP_I_TYPE: next_state = EXECUTE_I;
                    `OP_I_LOAD: next_state = MEM_ADDR; // Go to address calculation
                    `OP_S_TYPE: next_state = MEM_ADDR; // Go to address calculation
                    `OP_B_TYPE: next_state = BRANCH;
                    `OP_J_TYPE: next_state = JAL;
                    `OP_I_JALR: next_state = JALR;
                    `OP_U_LUI:  next_state = EXECUTE_I; // LUI uses immediate path
                    `OP_U_AUIPC: next_state = ALU_WB; // AUIPC writes back ALU result
                    default: next_state = FETCH;
                endcase
            end

            EXECUTE_R:
                next_state = ALU_WB;

            EXECUTE_I:
                next_state = ALU_WB;

            JAL:
                next_state = UPDATE_PC; // Needs separate state to allow PC write

            JALR:
                next_state = UPDATE_PC; // Needs separate state to allow PC write

            UPDATE_PC:
                next_state = FETCH;

            MEM_ADDR: begin // Address calculation for Load/Store
                if (opcode == `OP_I_LOAD)
                    next_state = MEM_READ;    
                else if (opcode == `OP_S_TYPE) begin
                    if (funct3 == 3'b000 || funct3 == 3'b001) // SB/SH need read-modify-write
                        next_state = MEM_READ;
                    else if ( funct3 == 3'b010) // SW can write directly
                        next_state = MEM_WRITE;   
                    else
                        next_state = FETCH; // Should not happen
                end
                else
                    next_state = FETCH; // Should not happen
            end

            MEM_READ:  // Read cycle for load or sb/sh
                if (opcode == `OP_I_LOAD)
                    next_state = MEM_WB; // Load instruction
                else if (funct3 == 3'b000 || funct3 == 3'b001) // SB/SH
                    next_state = MEM_WRITE; // Go to write cycle
                else
                    next_state = FETCH; // Should not happen
            
            MEM_WRITE:
                next_state = FETCH; 
            // TODO: Decide if we will use this extra state or modify memory.v

            // MEM_WRITE:
            //     next_state = MEM_WRITE_FIN; 
            // MEM_WRITE_FIN:
            //    next_state = FETCH; 

            ALU_WB: // Write back for R-Type, I-Type, AUIPC
                next_state = FETCH;

            BRANCH: // Branch resolution
                next_state = FETCH;

            MEM_WB: // Write back for Load instructions
                next_state = FETCH;

            default:
                next_state = FETCH;
        endcase
    end

    // Output logic
    always @(*) begin
        // Default values
        PCWrite   = 1'b0;
        AdrSrc    = 1'b0; // Default to PC for address
        MemWrite  = 1'b0;
        IRWrite   = 1'b0;
        ResultSrc = 2'b00; // Default to ALUOut
        ALUSrcB   = 2'b00; // Default to RegReadData2
        ALUSrcA   = 2'b00; // Default to PC
        RegWrite  = 1'b0;
        alu_op    = 2'b00; // Default to ADD

        case (state)
            FETCH: begin
                AdrSrc    = 1'b0;  // PC for memory address 
                IRWrite   = 1'b1;  // Latch instruction
                ALUSrcA   = 2'b00; // PC
                ALUSrcB   = 2'b10; // Constant 4
                ResultSrc = 2'b10; // Use ALU result (PC+4) for next PC
                PCWrite   = 1'b1;  // Write PC+4 to PC
                alu_op    = 2'b00; // ADD
            end

            DECODE: begin
                if (opcode == `OP_I_JALR || opcode == `OP_J_TYPE) begin
                    ALUSrcA   = 2'b01; // Select old PC for ALU input A
                    ALUSrcB   = 2'b10; // Select 4 for ALU input B
                    ResultSrc = 2'b00; // Select ALU Out
                    RegWrite  = 1'b1;  // Enable register write
                    alu_op    = 2'b00; // Add operation
                    // TODO: Think about this, if we are already writing PC + 4 (which is in ALUOut)
                    //       to rd, why are we calculating PC + 4 again?
                    //       Maybe we should just use the ALUOut value
                end else begin
                    ALUSrcA  = 2'b01;  // Select old PC for ALU input A
                    ALUSrcB  = 2'b01;  // Select immediate for ALU input B
                    alu_op   = 2'b00;  // Add operation
                end
            end

            EXECUTE_R: begin
                ALUSrcA = 2'b10;   // rs1
                ALUSrcB = 2'b00;   // rs2
                alu_op  = 2'b10;   // Op depends on funct3/funct7 (decoded by alu_decoder)
            end

            EXECUTE_I: begin // Also handles LUI
                ALUSrcA = 2'b10;   // rs1 (or 0 for LUI)
                ALUSrcB = 2'b01;   // immediate
                alu_op  = 2'b10;   // Op depends on funct3/opcode (decoded by alu_decoder)
            end

            JAL: begin
                ALUSrcA   = 2'b01; // Select old PC for ALU input A
                ALUSrcB   = 2'b01; // Select immediate for ALU input B
                alu_op    = 2'b10; // Special operation (JAL)
                ResultSrc = 2'b00; // Select ALU Out for link address
                PCWrite   = 1'b1;  // Enable PC write
                                    // TODO: Check if this is needed
            end

            JALR: begin
                ALUSrcA   = 2'b10; // Select register file for ALU input A
                ALUSrcB   = 2'b01; // Select immediate for ALU input B
                alu_op    = 2'b10; // Special operation (JAL)
                ResultSrc = 2'b00; // Select ALU Out for link address
                PCWrite   = 1'b1;  // Enable PC write
                                    // TODO: Check if this is needed
            end

            // TODO: Check if this is needed
            UPDATE_PC: begin
                PCWrite = 1'b1;  // Enable PC write
            end

            MEM_ADDR: begin
                ALUSrcA = 2'b10; // Select rs1 value for ALU input A
                ALUSrcB = 2'b01; // Select immediate for ALU input B 
                alu_op  = 2'b10; // ALU performs addition
            end

            MEM_READ: begin
                ALUSrcA   = 2'b10;  // Select rs1 value for ALU input A
                ALUSrcB   = 2'b01;  // Select immediate for ALU input B 
                alu_op    = 2'b10;  // Load operation (Add)
                ResultSrc = 2'b00;  // Select ALU result for address
                AdrSrc    = 1'b1;   // Use ALU result as memory address
                // Memory performs read based on AdrSrc
                // Result will be latched in datapath's data_to_save register next cycle
            end

            MEM_WRITE: begin // Write cycle for Store (SB/SH/SW)
                ALUSrcA   = 2'b10; // Select rs1 value for ALU input A
                ALUSrcB   = 2'b01; // Select immediate for ALU input B 
                alu_op    = 2'b10; // Load operation (Add)
                ResultSrc = 2'b00; // Select ALU result for address
                AdrSrc    = 1'b1;  // Use ALU result as memory address
                MemWrite  = 1'b1;  // Enable memory write
            end

            // MEM_WRITE_FIN: begin
            //     ALUSrcA    = 2'b10;   // Select rs1 value for ALU input A
            //     ALUSrcB    = 2'b01;   // Select immediate for ALU input B 
            //     alu_op     = 2'b10;    // Load operation (Add)
            //     ResultSrc  = 2'b00; // Select ALU result for address
            //     AdrSrc     = 1'b1;     // Use ALU result as memory address
            //     MemWrite   = 1'b1;   // Enable memory write
            // end

            MEM_WB: begin // Write back for Load
                ALUSrcA   = 2'b10; // Select rs1 value for ALU input A
                ALUSrcB   = 2'b01; // Select immediate for ALU input B 
                alu_op    = 2'b10; // Load operation (Add)
                ResultSrc = 2'b01; // Select Memory Data (processed by load_handler)
                RegWrite  = 1'b1;  // Enable register write
            end

            ALU_WB:  begin // Write back for R/I/AUIPC
                ResultSrc = 2'b00; // Select ALU Out
                RegWrite  = 1'b1;  // Enable register write
            end

            // TODO: Check if it's correct
            BRANCH: begin
                // Perform comparison (rs1 - rs2)
                ALUSrcA   = 2'b10;  // rs1
                ALUSrcB   = 2'b00;  // rs2
                alu_op    = 2'b01;  // SUB (or SLT/SLTU via alu_decoder for complex branches)

                // Use branch target calculated in DECODE state (available in ALUOut register)
                ResultSrc = 2'b00; // Select ALU Out (branch target address)

                // PCWrite depends on branch condition
                case (funct3)
                    3'b000: PCWrite = zero;     // BEQ: branch if zero is true
                    3'b001: PCWrite = ~zero;    // BNE: branch if zero is false
                    3'b100: PCWrite = blt;      // BLT: branch if blt is true
                    3'b101: PCWrite = bge;      // BGE: branch if bge is true
                    3'b110: PCWrite = bltu;     // BLTU: branch if bltu is true
                    3'b111: PCWrite = bgeu;     // BGEU: branch if bgeu is true
                    default: PCWrite = 1'b0;    // Invalid funct3
                endcase
            end

            default: begin // Should not happen, default to FETCH-like behavior
                IRWrite   = 1'b1;
                ALUSrcA   = 2'b00;
                ALUSrcB   = 2'b10;
                ResultSrc = 2'b10;
                PCWrite   = 1'b1;
                alu_op    = 2'b00;
            end
        endcase
    end
endmodule