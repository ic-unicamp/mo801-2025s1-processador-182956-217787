`include "def_select.v"

module imm_extended_tb;
    
    // Inputs
    reg [31:0] instruction;
    reg [2:0] imm_selection;
    
    // Outputs
    wire [31:0] imm_extended;
    
    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    
    // Instantiate the Unit Under Test (UUT)
    imm_extend uut (
        .instruction(instruction),
        .imm_selection(imm_selection),
        .imm_extended(imm_extended)
    );
    
    // Task to check the result
    task check_result(input [31:0] expected);
        begin
            if (imm_extended !== expected) begin
                $error("Test failed: instruction=%h, imm_selection=%h, result=%h (expected=%h)", 
                        instruction, imm_selection, imm_extended, expected);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: instruction=%h, imm_selection=%h, result=%h", 
                        instruction, imm_selection, imm_extended);
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    initial begin
        $dumpfile("imm_extend_tb.vcd");
        $dumpvars(0, imm_extended_tb);
        
        $display("\n=== Immediate Extender Testbench Started ===");
        
        $display("\nTesting I-type immediate: addi sp,ra,2000 (0x7d008113)");
        $display("Expected: Immediate value 2000 extracted and sign-extended");
        instruction = 32'h7d008113; 
        imm_selection = `I_TYPE;
        #10; check_result(32'd2000);

        $display("\nTesting I-type immediate: addi tp,gp,-2000 (0x83018213)");
        $display("Expected: Immediate value -2000 extracted and sign-extended");
        instruction = 32'h83018213; 
        imm_selection = `I_TYPE;
        #10; check_result(-32'd2000);
        
        $display("\nTesting S-type immediate: sw sp,1028(gp) (0x4021a223)");
        $display("Expected: Immediate value 1028 extracted from scattered bits and sign-extended");
        instruction = 32'h4021a223;
        imm_selection = `S_TYPE;
        #10; check_result(32'd1028);
        
        $display("\nTesting B-type immediate: beq ra,sp,c (0x00208463)");
        $display("Expected: Branch offset 8 extracted from scattered bits and sign-extended");
        instruction = 32'h00208463;
        imm_selection = `B_TYPE;
        #10; check_result(32'd8);
        
        $display("\nTesting U-type immediate: lui t0,0xffff (0x0ffff2b7)");
        $display("Expected: Upper immediate 0xffff shifted left by 12 bits to 0x0ffff000");
        instruction = 32'h0ffff2b7;
        imm_selection = `U_TYPE;
        #10; check_result(32'h0ffff000);
        
        $display("\nTesting J-type immediate: jal a4,14 (0x0080076f)");
        $display("Expected: Jump offset 8 extracted from scattered bits and sign-extended");
        instruction = 32'h0080076f;
        imm_selection = `J_TYPE;
        #10; check_result(32'd8);
        
        // Display test summary
        $display("\n=== Immediate Extender Testbench Results ===");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        
        if (tests_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        
        #10 $finish;
    end
    
endmodule