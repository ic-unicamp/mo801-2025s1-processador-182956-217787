module load_handler_tb;

    // Inputs
    reg  [31:0] tb_data_in;
    reg  [31:0] tb_address;
    reg  [2:0]  tb_funct3;

    // Outputs
    wire [31:0] tb_data_out;

    load_handler uut (
        .data_in(tb_data_in),
        .address(tb_address),
        .funct3(tb_funct3),
        .data_out(tb_data_out)
    );

    integer tests_passed = 0;
    integer tests_failed = 0;
    integer total_tests  = 0;

    parameter DESC_WIDTH = 8 * 40;
    task check_result;
        input [31:0] expected;
        input [DESC_WIDTH-1:0] test_description; 
        begin
            total_tests = total_tests + 1;
            #1; 
            if (tb_data_out === expected) begin
                $display("PASS: %s (Addr[1:0]=%b, Funct3=%b, DataIn=%h) -> DataOut=%h",
                         test_description, tb_address[1:0], tb_funct3, tb_data_in, tb_data_out);
                tests_passed = tests_passed + 1;
            end else begin
                $error("FAIL: %s (Addr[1:0]=%b, Funct3=%b, DataIn=%h) -> Expected=%h, Got=%h",
                       test_description, tb_address[1:0], tb_funct3, tb_data_in, expected, tb_data_out);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("load_handler_tb.vcd");
        $dumpvars(0, load_handler_tb);

        $display("\n=== Load Handler Testbench Started ===");

        $display("\n--- Testing LW (funct3 = 3'b010) ---");
        tb_funct3 = 3'b010;
        tb_data_in = 32'hAABBCCDD;
        tb_address = 32'h00001000;
        check_result(32'hAABBCCDD, "LW Positive Value"); 

        tb_data_in = 32'hFF00EE11;
        tb_address = 32'h00001004;
        check_result(32'hFF00EE11, "LW Negative Value");

        $display("\n--- Testing LB (funct3 = 3'b000) ---");
        tb_funct3 = 3'b000;
        tb_data_in = 32'h1122_3344; // Positive bytes

        tb_address = 32'h00001000; // Byte 0 (0x44)
        check_result(32'h0000_0044, "LB Positive Byte 0");

        tb_address = 32'h00001001; // Byte 1 (0x33)
        check_result(32'h0000_0033, "LB Positive Byte 1");

        tb_address = 32'h00001002; // Byte 2 (0x22)
        check_result(32'h0000_0022, "LB Positive Byte 2");

        tb_address = 32'h00001003; // Byte 3 (0x11)
        check_result(32'h0000_0011, "LB Positive Byte 3");

        tb_data_in = 32'h88AA_CCDD; // Negative bytes (MSB set)

        tb_address = 32'h00001000; // Byte 0 (0xDD -> -35)
        check_result(32'hFFFF_FFDD, "LB Negative Byte 0");

        tb_address = 32'h00001001; // Byte 1 (0xCC -> -52)
        check_result(32'hFFFF_FFCC, "LB Negative Byte 1");

        tb_address = 32'h00001002; // Byte 2 (0xAA -> -86)
        check_result(32'hFFFF_FFAA, "LB Negative Byte 2");

        tb_address = 32'h00001003; // Byte 3 (0x88 -> -120)
        check_result(32'hFFFF_FF88, "LB Negative Byte 3");

        $display("\n--- Testing LBU (funct3 = 3'b100) ---");
        tb_funct3 = 3'b100;
        tb_data_in = 32'h88AA_CCDD; // Includes bytes with MSB set

        tb_address = 32'h00001000; // Byte 0 (0xDD)
        check_result(32'h0000_00DD, "LBU Byte 0");

        tb_address = 32'h00001001; // Byte 1 (0xCC)
        check_result(32'h0000_00CC, "LBU Byte 1");

        tb_address = 32'h00001002; // Byte 2 (0xAA)
        check_result(32'h0000_00AA, "LBU Byte 2");

        tb_address = 32'h00001003; // Byte 3 (0x88)
        check_result(32'h0000_0088, "LBU Byte 3");

        $display("\n--- Testing LH (funct3 = 3'b001) ---");
        tb_funct3 = 3'b001;
        tb_data_in = 32'h1122_3344; // Positive halfwords

        tb_address = 32'h00001000; // Halfword 0 (0x3344)
        check_result(32'h0000_3344, "LH Positive Halfword 0");

        tb_address = 32'h00001002; // Halfword 1 (0x1122)
        check_result(32'h0000_1122, "LH Positive Halfword 1");

        tb_data_in = 32'h88AA_CCDD; // Negative halfwords (MSB set)

        tb_address = 32'h00001000; // Halfword 0 (0xCCDD -> -13091)
        check_result(32'hFFFF_CCDD, "LH Negative Halfword 0");

        tb_address = 32'h00001002; // Halfword 1 (0x88AA -> -30540)
        check_result(32'hFFFF_88AA, "LH Negative Halfword 1");

        // Invalid alignment for LH
        tb_address = 32'h00001001; // Invalid Addr[1:0] = 01
        check_result(32'hxxxx_xxxx, "LH Invalid Alignment 1");

        tb_address = 32'h00001003; // Invalid Addr[1:0] = 11
        check_result(32'hxxxx_xxxx, "LH Invalid Alignment 3");

        $display("\n--- Testing LHU (funct3 = 3'b101) ---");
        tb_funct3 = 3'b101;
        tb_data_in = 32'h88AA_CCDD; // Includes halfwords with MSB set

        tb_address = 32'h00001000; // Halfword 0 (0xCCDD)
        check_result(32'h0000_CCDD, "LHU Halfword 0");

        tb_address = 32'h00001002; // Halfword 1 (0x88AA)
        check_result(32'h0000_88AA, "LHU Halfword 1");

        // Invalid alignment for LHU
        tb_address = 32'h00001001; // Invalid Addr[1:0] = 01
        check_result(32'hxxxx_xxxx, "LHU Invalid Alignment 1");

        tb_address = 32'h00001003; // Invalid Addr[1:0] = 11
        check_result(32'hxxxx_xxxx, "LHU Invalid Alignment 3");

        $display("\n--- Testing Invalid Funct3 ---");
        tb_funct3 = 3'b011; // Example invalid funct3 for load
        tb_data_in = 32'hAABBCCDD;
        tb_address = 32'h00001000;
        check_result(32'hxxxx_xxxx, "Invalid Funct3 (011)");

        tb_funct3 = 3'b111; // Another invalid funct3
        check_result(32'hxxxx_xxxx, "Invalid Funct3 (111)");

        $display("\n=== Load Handler Testbench Finished ===");
        $display("Total Tests: %0d", total_tests);
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);

        if (tests_failed == 0) begin
            $display("RESULT: ALL TESTS PASSED!");
        end else begin
            $display("RESULT: SOME TESTS FAILED!");
        end

        #10 $finish;
    end

endmodule