// store_handler_tb.v
// Testbench for the store_handler module

`timescale 1ns / 1ps

module store_handler_tb;

    // Inputs
    reg  [31:0] tb_word_from_mem;
    reg  [31:0] tb_data_from_reg;
    reg  [1:0]  tb_address_offset;
    reg  [2:0]  tb_funct3;

    // Outputs
    wire [31:0] tb_modified_word;

    store_handler uut (
        .word_from_mem(tb_word_from_mem),
        .data_from_reg(tb_data_from_reg),
        .address_offset(tb_address_offset),
        .funct3(tb_funct3),
        .modified_word(tb_modified_word)
    );

    integer tests_passed = 0;
    integer tests_failed = 0;
    integer total_tests  = 0;

    parameter DESC_WIDTH = 8 * 60;
    task check_result;
        input [31:0] expected;
        input [DESC_WIDTH-1:0] test_description;
        begin
            total_tests = total_tests + 1;
            #1; 

            if (tb_modified_word === expected) begin
                $display("PASS: %s", test_description);
                tests_passed = tests_passed + 1;
            end else begin
                $error("FAIL: %s", test_description);
                $display("      Inputs: MemWord=0x%h, RegData=0x%h, Offset=%b, Funct3=%b",
                         tb_word_from_mem, tb_data_from_reg, tb_address_offset, tb_funct3);
                $display("      Expected: 0x%h, Got: 0x%h", expected, tb_modified_word);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("store_handler_tb.vcd");
        $dumpvars(0, store_handler_tb);

        $display("\n=== Store Handler Testbench Started ===");

        $display("\n--- Testing SW (funct3 = 3'b010) ---");
        tb_funct3 = 3'b010;
        tb_word_from_mem = 32'h11223344;
        tb_data_from_reg = 32'hAABBCCDD;
        tb_address_offset = 2'b00; // Offset doesn't matter for SW
        check_result(32'hAABBCCDD, "SW: Basic test");

        tb_data_from_reg = 32'hFFFFFFFF;
        tb_address_offset = 2'b10;
        check_result(32'hFFFFFFFF, "SW: All F's data");

        tb_data_from_reg = 32'h00000000;
        tb_address_offset = 2'b11;
        check_result(32'h00000000, "SW: Zero data");

        $display("\n--- Testing SB (funct3 = 3'b000) ---");
        tb_funct3 = 3'b000;
        tb_word_from_mem = 32'h11223344;
        tb_data_from_reg = 32'hFFFFFFAA; // Only AA matters

        tb_address_offset = 2'b00; // Byte 0
        check_result(32'h112233AA, "SB: Offset 0");

        tb_address_offset = 2'b01; // Byte 1
        check_result(32'h1122AA44, "SB: Offset 1");

        tb_address_offset = 2'b10; // Byte 2
        check_result(32'h11AA3344, "SB: Offset 2");

        tb_address_offset = 2'b11; // Byte 3
        check_result(32'hAA223344, "SB: Offset 3");

        // Test SB with different base word and data
        tb_word_from_mem = 32'hFFFFFFFF;
        tb_data_from_reg = 32'h00000055; // Only 55 matters

        tb_address_offset = 2'b00; // Byte 0
        check_result(32'hFFFFFF55, "SB: Offset 0, Base FFFF");

        tb_address_offset = 2'b01; // Byte 1
        check_result(32'hFFFF55FF, "SB: Offset 1, Base FFFF");

        tb_address_offset = 2'b10; // Byte 2
        check_result(32'hFF55FFFF, "SB: Offset 2, Base FFFF");

        tb_address_offset = 2'b11; // Byte 3
        check_result(32'h55FFFFFF, "SB: Offset 3, Base FFFF");

        $display("\n--- Testing SH (funct3 = 3'b001) ---");
        tb_funct3 = 3'b001;
        tb_word_from_mem = 32'h11223344;
        tb_data_from_reg = 32'hFFFFABCD; // Only ABCD matters

        tb_address_offset = 2'b00; // Halfword 0 (bits 15:0) - Aligned
        check_result(32'h1122ABCD, "SH: Offset 0 (Aligned)");

        tb_address_offset = 2'b10; // Halfword 1 (bits 31:16) - Aligned
        check_result(32'hABCD3344, "SH: Offset 2 (Aligned)");

        // Test SH with different base word and data
        tb_word_from_mem = 32'hFFFFFFFF;
        tb_data_from_reg = 32'h00005566; // Only 5566 matters

        tb_address_offset = 2'b00; // Halfword 0 - Aligned
        check_result(32'hFFFF5566, "SH: Offset 0, Base FFFF (Aligned)");

        tb_address_offset = 2'b10; // Halfword 1 - Aligned
        check_result(32'h5566FFFF, "SH: Offset 2, Base FFFF (Aligned)");

        // Current DUT uses address_offset[1] for selection
        $display("\n--- Testing Misaligned SH (funct3 = 3'b001) ---");
        tb_word_from_mem = 32'h11223344;
        tb_data_from_reg = 32'hFFFFABCD;

        tb_address_offset = 2'b01; // Misaligned - DUT uses offset[1]=0 -> Halfword 0
        check_result(32'h1122ABCD, "SH: Offset 1 (Misaligned - Expects Offset 0 behavior)");

        tb_address_offset = 2'b11; // Misaligned - DUT uses offset[1]=1 -> Halfword 1
        check_result(32'hABCD3344, "SH: Offset 3 (Misaligned - Expects Offset 2 behavior)");


        $display("\n--- Testing Invalid Funct3 ---");
        tb_funct3 = 3'b100; // Example invalid funct3
        tb_word_from_mem = 32'h11223344;
        tb_data_from_reg = 32'hAABBCCDD;
        tb_address_offset = 2'b00;
        check_result(32'hxxxxxxxx, "Invalid Funct3 (100)");

        tb_funct3 = 3'b111; // Another invalid funct3
        check_result(32'hxxxxxxxx, "Invalid Funct3 (111)");


        $display("\n=== Store Handler Testbench Finished ===");
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