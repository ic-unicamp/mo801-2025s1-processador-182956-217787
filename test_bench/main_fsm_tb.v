`include "def_select.v" // Include definitions for opcodes, etc.

module main_fsm_tb;

    // Inputs to UUT
    reg             clk;
    reg             rst;
    reg      [6:0]  opcode;
    reg      [2:0]  funct3;
    reg      [6:0]  funct7; // Although not directly used by FSM state logic, it's an input
    reg             zero;

    // Outputs from UUT
    wire            PCWrite;
    wire            AdrSrc;
    wire            MemWrite;
    wire            IRWrite;
    wire [1:0]      ResultSrc;
    wire [1:0]      ALUSrcB;
    wire [1:0]      ALUSrcA;
    wire            RegWrite;
    wire [1:0]      alu_op;

    // Expected Output Values (Auxiliary Variables)
    reg             expected_PCWrite;
    reg             expected_AdrSrc;
    reg             expected_MemWrite;
    reg             expected_IRWrite;
    reg [1:0]       expected_ResultSrc;
    reg [1:0]       expected_ALUSrcB;
    reg [1:0]       expected_ALUSrcA;
    reg             expected_RegWrite;
    reg [1:0]       expected_alu_op;

    // Test Statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    integer total_checks = 0;

    // Instantiate the Unit Under Test (UUT)
    main_fsm uut (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .zero(zero),
        .PCWrite(PCWrite),
        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUSrcB(ALUSrcB),
        .ALUSrcA(ALUSrcA),
        .RegWrite(RegWrite),
        .alu_op(alu_op)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Task to check all outputs against expected values
    task check_outputs (input [8*20:1] state_name);
        begin
            total_checks = total_checks + 1;
            $display("[%0t] Checking outputs for state: %s", $time, state_name);
            if (PCWrite !== expected_PCWrite) begin $error("FAIL: PCWrite mismatch. Got %b, Expected %b", PCWrite, expected_PCWrite); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (AdrSrc !== expected_AdrSrc) begin $error("FAIL: AdrSrc mismatch. Got %b, Expected %b", AdrSrc, expected_AdrSrc); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (MemWrite !== expected_MemWrite) begin $error("FAIL: MemWrite mismatch. Got %b, Expected %b", MemWrite, expected_MemWrite); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (IRWrite !== expected_IRWrite) begin $error("FAIL: IRWrite mismatch. Got %b, Expected %b", IRWrite, expected_IRWrite); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (ResultSrc !== expected_ResultSrc) begin $error("FAIL: ResultSrc mismatch. Got %b, Expected %b", ResultSrc, expected_ResultSrc); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (ALUSrcB !== expected_ALUSrcB) begin $error("FAIL: ALUSrcB mismatch. Got %b, Expected %b", ALUSrcB, expected_ALUSrcB); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (ALUSrcA !== expected_ALUSrcA) begin $error("FAIL: ALUSrcA mismatch. Got %b, Expected %b", ALUSrcA, expected_ALUSrcA); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (RegWrite !== expected_RegWrite) begin $error("FAIL: RegWrite mismatch. Got %b, Expected %b", RegWrite, expected_RegWrite); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
            if (alu_op !== expected_alu_op) begin $error("FAIL: alu_op mismatch. Got %b, Expected %b", alu_op, expected_alu_op); tests_failed = tests_failed + 1; end else tests_passed = tests_passed + 1;
        end
    endtask

    // Task to set all expected outputs to a default (usually 0 or 'z')
    task reset_expected_outputs;
        begin
            expected_PCWrite   = 1'b0;
            expected_AdrSrc    = 1'b0;
            expected_MemWrite  = 1'b0;
            expected_IRWrite   = 1'b0;
            expected_ResultSrc = 2'b00;
            expected_ALUSrcB   = 2'b00;
            expected_ALUSrcA   = 2'b00;
            expected_RegWrite  = 1'b0;
            expected_alu_op    = 2'b00;
        end
    endtask

    // Main Test Sequence
    initial begin
        $dumpfile("main_fsm_tb.vcd");
        $dumpvars(0, main_fsm_tb);

        $display("\n=== Main FSM Testbench Started ===");

        // 1. Initialize and Reset
        rst = 1'b0;
        opcode = 7'bxxxxxxx;
        funct3 = 3'bxxx;
        funct7 = 7'bxxxxxxx;
        zero = 1'bx;
        reset_expected_outputs();
        $display("[%0t] Applying Reset...", $time);
        #16; // Hold reset for a bit

        rst = 1'b1;
        $display("[%0t] Reset Released. Entering FETCH state.", $time);

        // --- Test Sequence ---

        // 2. FETCH State
        reset_expected_outputs(); // Start fresh for the state
        expected_AdrSrc    = 1'b0;   // PC for memory address
        expected_IRWrite   = 1'b1;   // Write Instruction Register
        expected_ALUSrcA   = 2'b00;  // PC
        expected_ALUSrcB   = 2'b10;  // Constant 4
        expected_ResultSrc = 2'b10; // ALU Result (PC+4)
        expected_PCWrite   = 1'b1;   // Write PC+4 to PC
        expected_alu_op    = 2'b00;  // ALU Add
        // Check outputs immediately after reset release (should be in FETCH)
        check_outputs("FETCH (Initial)");
        #10; // Wait for next clock edge (moves to DECODE)

        // 3. DECODE State (Simulating R-Type instruction)
        opcode = `OP_R_TYPE; // Set input for R-Type
        funct3 = 3'b000;     // Example: ADD
        funct7 = 7'b0000000; // Example: ADD
        reset_expected_outputs();
        expected_ALUSrcA  = 2'b01;  // Old PC
        expected_ALUSrcB  = 2'b01;  // Immediate (for branch calc, done here)
        expected_alu_op   = 2'b00;  // ALU Add (for branch calc)
        check_outputs("DECODE (R-Type)");
        #10; // Wait for next clock edge (moves to EXECUTE_R)

        // 4. EXECUTE_R State
        reset_expected_outputs();
        expected_ALUSrcA = 2'b10;   // rs1
        expected_ALUSrcB = 2'b00;   // rs2
        expected_alu_op = 2'b10;    // R-Type ALU op
        check_outputs("EXECUTE_R");
        #10; // Wait for next clock edge (moves to ALU_WB)

        // 5. ALU_WB State (Write Back from R-Type)
        reset_expected_outputs();
        expected_ResultSrc = 2'b00; // ALU Out
        expected_RegWrite  = 1'b1;  // Write to Register File
        check_outputs("ALU_WB (from R-Type)");
        #10; // Wait for next clock edge (moves back to FETCH)

        // 6. FETCH State (again)
        reset_expected_outputs();
        expected_AdrSrc   = 1'b0;
        expected_IRWrite  = 1'b1;
        expected_ALUSrcA  = 2'b00;
        expected_ALUSrcB  = 2'b10;
        expected_ResultSrc = 2'b10;
        expected_PCWrite  = 1'b1;
        expected_alu_op   = 2'b00;
        check_outputs("FETCH (Cycle 2)");
        #10; // Wait for next clock edge

        // 7. DECODE State (Simulating Load instruction - LW)
        opcode = `OP_I_LOAD; // Set input for Load
        funct3 = 3'b010;     // LW funct3
        reset_expected_outputs();
        expected_ALUSrcA  = 2'b01;
        expected_ALUSrcB  = 2'b01;
        expected_alu_op   = 2'b00;
        check_outputs("DECODE (Load)");
        #10; // Wait for next clock edge (moves to MEM_ADDR)

        // 8. MEM_ADDR State (Load)
        reset_expected_outputs();
        expected_ALUSrcA = 2'b10;   // rs1 (base address)
        expected_ALUSrcB = 2'b01;   // immediate (offset)
        expected_alu_op = 2'b10;    // ALU Add (calculate address)
        check_outputs("MEM_ADDR (Load)");
        #10; // Wait for next clock edge (moves to MEM_READ)

        // 9. MEM_READ State
        reset_expected_outputs();
        expected_ALUSrcA = 2'b10;   // rs1 (base address)
        expected_ALUSrcB = 2'b01;   // immediate (offset)
        expected_alu_op = 2'b10;    // ALU Add (calculate address)
        expected_ResultSrc = 2'b00; // Use ALU result from previous state
        expected_AdrSrc = 1'b1;     // Use ALU result as memory address
        check_outputs("MEM_READ");
        #10; // Wait for next clock edge (moves to MEM_WB)

        // 10. MEM_WB State (Write Back from Load)
        reset_expected_outputs();
        expected_ALUSrcA = 2'b10;   // rs1 (base address)
        expected_ALUSrcB = 2'b01;   // immediate (offset)
        expected_alu_op = 2'b10;    // ALU Add (calculate address)
        expected_ResultSrc = 2'b01; // Select Memory Data
        expected_RegWrite  = 1'b1;  // Write to Register File
        check_outputs("MEM_WB (from Load)");
        #10; // Wait for next clock edge (moves back to FETCH)

        // 11. FETCH State (again)
        reset_expected_outputs();
        expected_AdrSrc   = 1'b0;
        expected_IRWrite  = 1'b1;
        expected_ALUSrcA  = 2'b00;
        expected_ALUSrcB  = 2'b10;
        expected_ResultSrc = 2'b10;
        expected_PCWrite  = 1'b1;
        expected_alu_op   = 2'b00;
        check_outputs("FETCH (Cycle 3)");
        #10; // Wait for next clock edge

        // 12. DECODE State (Simulating Branch instruction - BEQ, Zero=1 -> Taken)
        opcode = `OP_B_TYPE; // Set input for Branch
        funct3 = 3'b000;     // BEQ funct3
        zero = 1'b1;         // Set zero flag high (condition met)
        reset_expected_outputs();
        expected_ALUSrcA  = 2'b01;
        expected_ALUSrcB  = 2'b01;
        expected_alu_op   = 2'b00;
        check_outputs("DECODE (BEQ, Zero=1)");
        #10; // Wait for next clock edge (moves to BEQ state)

        // 13. BEQ State (Taken)
        reset_expected_outputs();
        expected_ALUSrcA  = 2'b10;  // rs1
        expected_ALUSrcB  = 2'b00;  // rs2 (for comparison in ALU)
        expected_ResultSrc = 2'b00; // Use ALU result (branch target address)
        expected_alu_op   = 2'b01;  // ALU Sub (for comparison)
        expected_PCWrite  = 1'b1;   // Write PC (branch taken)
        check_outputs("BEQ (Taken, Zero=1)");
        #10; // Wait for next clock edge (moves back to FETCH)

        // 14. FETCH State (again)
        reset_expected_outputs();
        expected_AdrSrc   = 1'b0;
        expected_IRWrite  = 1'b1;
        expected_ALUSrcA  = 2'b00;
        expected_ALUSrcB  = 2'b10;
        expected_ResultSrc = 2'b10;
        expected_PCWrite  = 1'b1;
        expected_alu_op   = 2'b00;
        check_outputs("FETCH (Cycle 4)");
        #10; // Wait for next clock edge

        // 15. DECODE State (Simulating Branch instruction - BEQ, Zero=0 -> Not Taken)
        opcode = `OP_B_TYPE; // Set input for Branch
        funct3 = 3'b000;     // BEQ funct3
        zero = 1'b0;         // Set zero flag low (condition not met)
        reset_expected_outputs();
        expected_ALUSrcA  = 2'b01;
        expected_ALUSrcB  = 2'b01;
        expected_alu_op   = 2'b00;
        check_outputs("DECODE (BEQ, Zero=0)");
        #10; // Wait for next clock edge (moves to BEQ state)

        // 16. BEQ State (Not Taken)
        reset_expected_outputs();
        expected_ALUSrcA  = 2'b10;  // rs1
        expected_ALUSrcB  = 2'b00;  // rs2
        expected_ResultSrc = 2'b00; // Use ALU result (branch target, but PCWrite is 0)
        expected_alu_op   = 2'b01;  // ALU Sub
        expected_PCWrite  = 1'b0;   // Do NOT write PC (branch not taken)
        check_outputs("BEQ (Not Taken, Zero=0)");
        #10; // Wait for next clock edge (moves back to FETCH)

        // Add more tests for JAL, Store, I-Type, other branches etc. following the same pattern:
        // - Go to FETCH
        // - Go to DECODE (set opcode, funct3 etc.)
        // - Follow the state transitions, setting expected outputs and checking at each step.

        // --- Test Summary ---
        $display("\n=== Main FSM Testbench Finished ===");
        $display("Total Checks: %0d", total_checks * 9); // 9 outputs per check
        $display("Checks Passed: %0d", tests_passed);
        $display("Checks Failed: %0d", tests_failed);

        if (tests_failed == 0) begin
            $display("RESULT: ALL TESTS PASSED!");
        end else begin
            $display("RESULT: SOME TESTS FAILED!");
        end

        #10 $finish; // End simulation
    end

endmodule