`include "def_select.v"

module alu_decoder_tb;

    // Inputs
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    
    // Outputs
    wire [3:0] alu_control;
    
    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;

    // Instantiate the Unit Under Test (UUT)
    alu_decoder uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );
    
    // Task to check the result
    task check_result(input [3:0] expected);
        begin
            if (alu_control !== expected) begin
                $error("Test failed: opcode=%b, funct3=%b, funct7=%b, result=%b (expected=%b)", 
                        opcode, funct3, funct7, alu_control, expected);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: opcode=%b, funct3=%b, funct7=%b, result=%b", 
                        opcode, funct3, funct7, alu_control);
                tests_passed = tests_passed + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("test_waves/alu_decoder_tb.vcd");
        $dumpvars(0, alu_decoder_tb);
        
        $display("\n=== ALU Decoder Testbench Started ===");

        // Testing R-Type Instructions
        $display("\nTesting R-Type ADD (opcode=0110011, funct3=000, funct7=0000000)");
        opcode = `OP_R_TYPE; funct3 = 3'b000; funct7 = 7'b0000000;
        #10; check_result(`ALU_ADD);

        $display("\nTesting R-Type SUB (opcode=0110011, funct3=000, funct7=0100000)");
        opcode = `OP_R_TYPE; funct3 = 3'b000; funct7 = 7'b0100000;
        #10; check_result(`ALU_SUB);

        $display("\nTesting R-Type AND (opcode=0110011, funct3=111, funct7=0000000)");
        opcode = `OP_R_TYPE; funct3 = 3'b111; funct7 = 7'b0000000;
        #10; check_result(`ALU_AND);

        $display("\nTesting R-Type OR (opcode=0110011, funct3=110, funct7=0000000)");
        opcode = `OP_R_TYPE; funct3 = 3'b110; funct7 = 7'b0000000;
        #10; check_result(`ALU_OR);

        $display("\nTesting R-Type XOR (opcode=0110011, funct3=100, funct7=0000000)");
        opcode = `OP_R_TYPE; funct3 = 3'b100; funct7 = 7'b0000000;
        #10; check_result(`ALU_XOR);

        // Testing I-Type Instructions
        $display("\nTesting I-Type ADDI (opcode=0010011, funct3=000)");
        opcode = `OP_I_TYPE; funct3 = 3'b000; funct7 = 7'b0000000;
        #10; check_result(`ALU_ADD);

        $display("\nTesting I-Type ORI (opcode=0010011, funct3=110)");
        opcode = `OP_I_TYPE; funct3 = 3'b110; funct7 = 7'b0000000;
        #10; check_result(`ALU_OR);

        $display("\nTesting I-Type SRAI (opcode=0010011, funct3=101, funct7=0100000)");
        opcode = `OP_I_TYPE; funct3 = 3'b101; funct7 = 7'b0100000;
        #10; check_result(`ALU_SRA);

        // Testing Load and Store Instructions
        $display("\nTesting Load (opcode=0000011, funct3=010)");
        opcode = `OP_I_LOAD; funct3 = 3'b010;
        #10; check_result(`ALU_ADD); // Load uses ALU to calculate address

        $display("\nTesting Store (opcode=0100011, funct3=010)");
        opcode = `OP_S_TYPE; funct3 = 3'b010;
        #10; check_result(`ALU_ADD); // Store uses ALU to calculate address

        // Testing Branch Instructions
        $display("\nTesting BEQ (opcode=1100011, funct3=000)");
        opcode = `OP_B_TYPE; funct3 = 3'b000;
        #10; check_result(`ALU_SUB); // BEQ compares values (a - b)

        $display("\nTesting BGE (opcode=1100011, funct3=100)");
        opcode = `OP_B_TYPE; funct3 = 3'b100;
        #10; check_result(`ALU_SLT); // BGE checks signed comparison

        // Testing Jump and Upper Immediate Instructions
        $display("\nTesting JAL (opcode=1101111)");
        opcode = `OP_J_TYPE;
        #10; check_result(`ALU_ADD); // JAL calculates target address

        $display("\nTesting LUI (opcode=0110111)");
        opcode = `OP_U_LUI;
        #10; check_result(`ALU_LUI);

        $display("\nTesting AUIPC (opcode=0010111)");
        opcode = `OP_U_AUIPC;
        #10; check_result(`ALU_ADD); // AUIPC performs PC-relative addition

        // Default case test
        $display("\nTesting Default Case (opcode=1111111)");
        opcode = 7'b1111111;
        #10; check_result(4'bzzzz);

        // Test Summary
        $display("\n=== ALU Decoder Testbench Results ===");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);

        if (tests_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        #10 $finish;
    end

endmodule
