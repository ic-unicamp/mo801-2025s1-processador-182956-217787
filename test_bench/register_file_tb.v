module register_file_tb;
    // Inputs
    reg clk;
    reg rst;
    reg write_enable_3;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] write_data_3;
    
    // Outputs
    wire [31:0] rd1, rd2;
    
    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    
    // Instantiate the Unit Under Test (UUT)
    register_file uut (
        .clk(clk),
        .rst(rst),
        .write_enable_3(write_enable_3),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data_3(write_data_3),
        .rd1(rd1),
        .rd2(rd2)
    );
    
    // Task to check a single output
    task check_output;
        input [31:0] actual;
        input [31:0] expected;
        input [8*15:1] output_name;
        begin
            if (actual !== expected) begin
                $error("Test failed: %s=%h (expected=%h)", output_name, actual, expected);
                tests_failed = tests_failed + 1;
                $display("Context: rs1=%d, rs2=%d, rd=%d, write_enable=%b, write_data=%h", 
                         rs1, rs2, rd, write_enable_3, write_data_3);
            end else begin
                $display("PASS: %s=%h", output_name, actual);
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    // Task to check both outputs
    task check_both_outputs;
        input [31:0] expected_rd1;
        input [31:0] expected_rd2;
        begin
            check_output(rd1, expected_rd1, "rd1");
            check_output(rd2, expected_rd2, "rd2");
        end
    endtask
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
    
    // Test sequence
    initial begin
        // Setup VCD file for waveform analysis
        $dumpfile("test_waves/register_file_tb.vcd");
        $dumpvars(0, register_file_tb);
        
        // Display header
        $display("\n=== Register File Testbench Started ===");
        
        // Initialize inputs
        write_enable_3 = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        write_data_3 = 0;
        rst = 1; // Not in reset
        
        // Apply reset
        $display("\nTesting reset behavior (rst=0)");
        rst = 0;
        #10; // Wait > 1 clock cycle
        rst = 1;
        #10;
        
        // Test case 1: Read from register 0
        $display("\nTesting read from register 0 (should always be 0)");
        rs1 = 5'd0;
        rs2 = 5'd0;
        #10;
        check_both_outputs(32'h0, 32'h0);
        
        // Test case 2: Write to register 0 (should be ignored)
        $display("\nTesting write to register 0 (should be ignored)");
        rd = 5'd0;
        write_data_3 = 32'hDEADBEEF;
        write_enable_3 = 1;
        #10;
        rs1 = 5'd0;
        write_enable_3 = 0;
        #10;
        check_both_outputs(32'h0, 32'h0);
        
        // Test case 3: Write to register 1 and read it back
        $display("\nTesting write to register 1 and read back");
        rd = 5'd1;
        write_data_3 = 32'h12345678;
        write_enable_3 = 1;
        #10;
        write_enable_3 = 0;
        rs1 = 5'd1;
        rs2 = 5'd0;
        #10;
        check_both_outputs(32'h12345678, 32'h0);
        
        // Test case 4: Write to multiple registers and read them back
        $display("\nTesting write to multiple registers and read back");
        // Write to register 2
        rd = 5'd2;
        write_data_3 = 32'hAABBCCDD;
        write_enable_3 = 1;
        #10;
        
        // Write to register 3
        rd = 5'd3;
        write_data_3 = 32'h99887766;
        #10;
        
        // Write to register 31 (last register)
        rd = 5'd31;
        write_data_3 = 32'hFFFFFFFF;
        #10;
        
        write_enable_3 = 0;
        
        // Read registers 1 and 2
        rs1 = 5'd1;
        rs2 = 5'd2;
        #10;
        check_both_outputs(32'h12345678, 32'hAABBCCDD);
        
        // Read registers 2 and 3
        rs1 = 5'd2;
        rs2 = 5'd3;
        #10;
        check_both_outputs(32'hAABBCCDD, 32'h99887766);
        
        // Read registers 3 and 31
        rs1 = 5'd3;
        rs2 = 5'd31;
        #10;
        check_both_outputs(32'h99887766, 32'hFFFFFFFF);
        
        // Test case 5: Write disabled should not change registers
        $display("\nTesting write disabled (should not change registers)");
        rd = 5'd1;
        write_data_3 = 32'hDEADBEEF;
        write_enable_3 = 0;
        #10;
        rs1 = 5'd1;
        rs2 = 5'd2;
        #10;
        check_both_outputs(32'h12345678, 32'hAABBCCDD); // Values should remain unchanged
        
        // Test case 6: Reset should clear all registers
        $display("\nTesting reset (should clear all registers)");
        rst = 0;
        #10;
        rst = 1;
        rs1 = 5'd1;
        rs2 = 5'd31;
        #10;
        check_both_outputs(32'h0, 32'h0);
        
        // Test case 7: Simultaneous read and write to same register
        $display("\nTesting simultaneous read and write to same register");
        rd = 5'd10;
        write_data_3 = 32'h55555555;
        rs1 = 5'd10;
        rs2 = 5'd10;
        write_enable_3 = 1;
        #1;
        check_both_outputs(32'h0, 32'h0); // Should still be 0 before the write completes
        
        // Next cycle should have the new value
        #9
        write_enable_3 = 0;
        #10;
        check_both_outputs(32'h55555555, 32'h55555555);
        
        // Display test summary
        $display("\n=== Register File Testbench Results ===");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        
        if (tests_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        
        #10 $finish;
    end
    
endmodule