`include "def_select.v"

module main_fsm_tb;

    // Inputs to UUT
    reg           clk;
    reg           rst;
    reg  [6:0]    opcode;
    reg  [2:0]    funct3;
    reg  [6:0]    funct7;
    reg           zero;

    // Outputs from UUT
    wire          PCWrite;
    wire          AdrSrc;
    wire          MemWrite;
    wire          IRWrite;
    wire [1:0]    ResultSrc;
    wire [1:0]    ALUSrcB;
    wire [1:0]    ALUSrcA;
    wire          RegWrite;
    wire [1:0]    alu_op;

    // Expected Output Variables
    reg           exp_PCWrite;
    reg           exp_AdrSrc;
    reg           exp_MemWrite;
    reg           exp_IRWrite;
    reg [1:0]     exp_ResultSrc;
    reg [1:0]     exp_ALUSrcB;
    reg [1:0]     exp_ALUSrcA;
    reg           exp_RegWrite;
    reg [1:0]     exp_alu_op;

    // Track test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;

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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    initial begin
        // Setup VCD file for waveform analysis
        $dumpfile("main_fsm_tb.vcd");
        $dumpvars(0, main_fsm_tb);

        // Display header
        $display("\n=== Main FSM Testbench Started ===");

    end

endmodule