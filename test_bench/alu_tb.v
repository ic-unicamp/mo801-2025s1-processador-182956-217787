`include "def_select.v"

module alu_tb;
    reg [31:0] a, b;
    reg [3:0] alu_control;
    wire [31:0] result;
    wire zero;
    
    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    
    alu uut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );
    
    task check_result(input [31:0] expected);
        begin
            if (result !== expected) begin
                $error("Test failed: a=%h, b=%h, control=%h, result=%h (expected=%h)", 
                        a, b, alu_control, result, expected);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: a=%h, b=%h, control=%h, result=%h", 
                        a, b, alu_control, result);
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    task check_zero(input expected_zero);
        begin
            if (zero !== expected_zero) begin
                $error("Zero flag test failed: a=%h, b=%h, zero=%b (expected=%b)", 
                       a, b, zero, expected_zero);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: Zero flag test, a=%h, b=%h, zero=%b", 
                         a, b, zero);
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    // Test various operations with edge cases
    initial begin
        $dumpfile("test_waves/alu_tb.vcd");
        $dumpvars(0, alu_tb);
        
        // Display header
        $display("\n=== ALU Testbench Started ===");
        
        // Test ALU_ADD
        $display("\nTesting ALU_ADD");
        a = 32'h0000_0005; b = 32'h0000_0003; alu_control = `ALU_ADD;
        #10; check_result(32'h0000_0008);
        
        // Test overflow for ADD
        a = 32'h7FFF_FFFF; b = 32'h0000_0001; alu_control = `ALU_ADD;
        #10; check_result(32'h8000_0000);

        a = 32'hFFFF_FFFF; b = 32'h0000_0003; alu_control = `ALU_ADD;
        #10; check_result(32'h0000_0002);
        
        // Test ALU_SUB
        $display("\nTesting ALU_SUB");
        a = 32'h0000_0008; b = 32'h0000_0003; alu_control = `ALU_SUB;
        #10; check_result(32'h0000_0005);
        
        // Test underflow for SUB
        a = 32'h0000_0000; b = 32'h0000_0001; alu_control = `ALU_SUB;
        #10; check_result(32'hFFFF_FFFF);
        
        // Test ALU_AND
        $display("\nTesting ALU_AND");
        a = 32'hF0F0_F0F0; b = 32'h0F0F_0F0F; alu_control = `ALU_AND;
        #10; check_result(32'h0000_0000);
        
        a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF; alu_control = `ALU_AND;
        #10; check_result(32'hFFFF_FFFF);
        
        // Test ALU_OR
        $display("\nTesting ALU_OR");
        a = 32'hF0F0_F0F0; b = 32'h0F0F_0F0F; alu_control = `ALU_OR;
        #10; check_result(32'hFFFF_FFFF);
        
        a = 32'h0000_0000; b = 32'h0000_0000; alu_control = `ALU_OR;
        #10; check_result(32'h0000_0000);

        // Test ALU_XOR
        $display("\nTesting ALU_XOR");
        a = 32'hFFFF_0000; b = 32'h0000_FFFF; alu_control = `ALU_XOR;
        #10; check_result(32'hFFFF_FFFF);
        
        a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF; alu_control = `ALU_XOR;
        #10; check_result(32'h0000_0000);
        
        // Test ALU_SLL
        $display("\nTesting ALU_SLL");
        a = 32'h0000_0001; b = 32'h0000_0004; alu_control = `ALU_SLL;
        #10; check_result(32'h0000_0010);
        
        // Test shift with large value (should only use lower 5 bits)
        a = 32'h0000_0001; b = 32'h0000_0020; alu_control = `ALU_SLL;
        #10; check_result(32'h0000_0001); // Shifting by 32 (0x20) should be same as by 0
        
        // Test ALU_SRL
        $display("\nTesting ALU_SRL");
        a = 32'h0000_0080; b = 32'h0000_0004; alu_control = `ALU_SRL;
        #10; check_result(32'h0000_0008);
        
        // Test logical shift with sign bit set
        a = 32'h8000_0000; b = 32'h0000_001F; alu_control = `ALU_SRL;
        #10; check_result(32'h0000_0001); // Right shift by 31 should leave just the sign bit
        
        // Test ALU_SRA
        $display("\nTesting ALU_SRA");
        a = 32'h8000_0000; b = 32'h0000_0004; alu_control = `ALU_SRA;
        #10; check_result(32'hF800_0000);
        
        // Arithmetic shift with positive number
        a = 32'h7FFF_FFFF; b = 32'h0000_0004; alu_control = `ALU_SRA;
        #10; check_result(32'h07FF_FFFF);
        
        // Test ALU_SLT
        $display("\nTesting ALU_SLT");
        a = 32'hFFFF_FFFF; b = 32'h0000_0001; alu_control = `ALU_SLT; // -1 < 1
        #10; check_result(32'h0000_0001);
        
        a = 32'h0000_0001; b = 32'hFFFF_FFFF; alu_control = `ALU_SLT; // 1 < -1
        #10; check_result(32'h0000_0000);
        
        // Test ALU_SLTU
        $display("\nTesting ALU_SLTU");
        a = 32'h0000_0001; b = 32'hFFFF_FFFF; alu_control = `ALU_SLTU; // 1 < 4294967295 (unsigned)
        #10; check_result(32'h0000_0001);
        
        a = 32'hFFFF_FFFF; b = 32'h0000_0001; alu_control = `ALU_SLTU; // 4294967295 < 1 (unsigned)
        #10; check_result(32'h0000_0000);
        
        // Test ALU_LUI
        $display("\nTesting ALU_LUI");
        a = 32'h0000_0000; b = 32'h1234_5678; alu_control = `ALU_LUI;
        #10; check_result(32'h1234_5678);
        
        // Test Zero flag
        $display("\nTesting Zero Flag");
        a = 32'h0000_0001; b = 32'h0000_0001; alu_control = `ALU_SUB;
        #10; check_result(32'h0000_0000); check_zero(1'b1);
        
        a = 32'h0000_0005; b = 32'h0000_0003; alu_control = `ALU_SUB;
        #10; check_result(32'h0000_0002); check_zero(1'b0);
        
        // Test default behavior
        $display("\nTesting Default Behavior");
        a = 32'h0000_0005; b = 32'h0000_0003; alu_control = 4'b1111; // Undefined operation
        #10; check_result(32'hxxxx_xxxx);
        
        // Display test summary
        $display("\n=== ALU Testbench Results ===");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        
        if (tests_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
            
        $finish;
    end
endmodule