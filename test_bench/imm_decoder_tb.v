`include "def_select.v"

module imm_decoder_tb;

    // Inputs
    reg [6:0] opcode;
    
    // Outputs
    wire [2:0] imm_selection;
    
    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    
    // Instantiate the Unit Under Test (UUT)
    imm_decoder uut (
        .opcode(opcode),
        .imm_selection(imm_selection)
    );
    
    // Task to check the result
    task check_result(input [2:0] expected);
        begin
            if (imm_selection !== expected) begin
                $error("Test failed: opcode=%b, result=%b (expected=%b)", opcode, imm_selection, expected);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: opcode=%b, result=%b", opcode, imm_selection);
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    initial begin
        $dumpfile("imm_decoder_tb.vcd");
        $dumpvars(0, imm_decoder_tb);
        
        $display("\n=== Immediate Decoder Testbench Started ===");
        
        // Testing I_TYPE opcodes
        $display("\nTesting opcode for I_TYPE: 7'b0010011");
        opcode = 7'b0010011;
        #10; check_result(`I_TYPE);
        
        $display("\nTesting opcode for I_TYPE: 7'b0000011");
        opcode = 7'b0000011;
        #10; check_result(`I_TYPE);
        
        $display("\nTesting opcode for I_TYPE: 7'b1100111");
        opcode = 7'b1100111;
        #10; check_result(`I_TYPE);
        
        $display("\nTesting opcode for B_TYPE: 7'b1100011");
        opcode = 7'b1100011;
        #10; check_result(`B_TYPE);
        
        $display("\nTesting opcode for S_TYPE: 7'b0100011");
        opcode = 7'b0100011;
        #10; check_result(`S_TYPE);
        
        $display("\nTesting opcode for J_TYPE: 7'b1101111");
        opcode = 7'b1101111;
        #10; check_result(`J_TYPE);
        
        $display("\nTesting opcode for U_TYPE: 7'b0010111");
        opcode = 7'b0010111;
        #10; check_result(`U_TYPE);
        
        $display("\nTesting opcode for U_TYPE: 7'b0110111");
        opcode = 7'b0110111;
        #10; check_result(`U_TYPE);
        
        $display("\nTesting opcode for default case: 7'b1111111");
        opcode = 7'b1111111;
        #10; check_result(3'bzzz);
        
        $display("\n=== Immediate Decoder Testbench Results ===");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        
        if (tests_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        
        #10 $finish;
    end

endmodule
