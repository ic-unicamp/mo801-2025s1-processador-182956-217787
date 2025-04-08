
module flip_flop_enable_tb;
    // Inputs
    reg clk;
    reg enable;
    reg rst;
    reg [31:0] src;
    
    // Outputs
    wire [31:0] dest;
    
    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    
    // Instantiate the Unit Under Test (UUT)
    flip_flop_enable uut (
        .clk(clk),
        .enable(enable),
        .rst(rst),
        .src(src),
        .dest(dest)
    );
    
    // Task to check the result
    task check_result;
        input [31:0] expected;
        begin
            if (dest !== expected) begin
                $error("Test failed: enable=%b, rst=%b, src=%h, dest=%h (expected=%h)", 
                        enable, rst, src, dest, expected);
                tests_failed = tests_failed + 1;
            end else begin
                $display("PASS: enable=%b, rst=%b, src=%h, dest=%h", 
                        enable, rst, src, dest);
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end
    
    // Test sequence
    initial begin
        // Setup VCD file for waveform analysis
        $dumpfile("flip_flop_enable_tb.vcd");
        $dumpvars(0, flip_flop_enable_tb);
        
        // Display header
        $display("\n=== Flip Flop with Enable Testbench Started ===");
        
        // Initialize inputs
        enable = 0;
        rst = 0;
        src = 32'h00000000;
        
        // Wait for global reset
        #22;
        
        // Test case 1: Reset behavior
        $display("\nTesting reset behavior (rst=0)");
        rst = 0;
        enable = 1;
        src = 32'h12345678;
        #10; // Wait for clock edge
        check_result(32'h00000000);
        
        // Test case 2: Enable=1, load value
        $display("\nTesting enable=1, should load source value");
        rst = 1;
        enable = 1;
        src = 32'hAABBCCDD;
        #10; // Wait for clock edge
        check_result(32'hAABBCCDD);
        
        // Test case 3: Enable=0, should retain value
        $display("\nTesting enable=0, should retain previous value");
        enable = 0;
        src = 32'h11223344;
        #10; // Wait for clock edge
        check_result(32'hAABBCCDD); // Should still be the previous value
        
        // Test case 4: Enable=1 again, load new value
        $display("\nTesting enable=1 again, should load new value");
        enable = 1;
        src = 32'h55667788;
        #10; // Wait for clock edge
        check_result(32'h55667788);
        
        // Test case 5: Reset while running
        $display("\nTesting reset while running (rst=0)");
        rst = 0;
        #10; // Wait for clock edge
        check_result(32'h00000000);
        
        // Test case 6: Reset release
        $display("\nTesting after reset release (rst=1)");
        rst = 1;
        enable = 0;
        src = 32'h99AABBCC;
        #10; // Wait for clock edge
        check_result(32'h00000000); // Should still be 0 because enable=0
        
        // Test case 7: Enable after reset
        $display("\nTesting enable after reset");
        enable = 1;
        #10; // Wait for clock edge
        check_result(32'h99AABBCC);
        
        // Display test summary
        $display("\n=== Flip Flop with Enable Testbench Results ===");
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        
        if (tests_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        
        #10 $finish;
    end
    
endmodule