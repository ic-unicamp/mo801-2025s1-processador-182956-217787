module datapath (
    input clk,
    input rst,

    // input signals
    input pc_write,
    input adr_src,
    input ir_write,
    input [1:0] result_src,
    input [3:0] alu_control,
    input [1:0] alu_src_a, alu_src_b,
    input [2:0] imm_src,
    input reg_write,

    // Memory ports
    output [31:0] mem_addr,
    output [31:0] mem_write_data,
    input [31:0] mem_read_data,

    // Control ports
    output [31:0] instr,
    output zero,
    output blt,
    output bge,
    output bltu,
    output bgeu
);

    // Internal wires and registers
    wire [31:0] result;
    wire [31:0] pc;
    wire [31:0] old_pc, instruc_reg, data_to_save;
    wire [31:0] alu_result, alu_out;
    wire [31:0] imm_extended;
    wire [31:0] read_data1, read_data2;
    wire [31:0] fread_data1, fread_data2;
    wire [31:0] alu_src_inst_a, alu_src_inst_b;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3; // Extract funct3 for load handler

    // *** ADDED: Wire for processed load data ***
    wire [31:0] processed_mem_data;

    // Program Counter Register
    flip_flop_enable pc_reg (
        .clk(clk),
        .rst(rst),
        .enable(pc_write),
        .src(result),
        .dest(pc)
    );

    // Memory Address Mux
    mux2 address_mux (
        .select(adr_src),
        .src0(pc),
        .src1(result), // In MEM_READ/WRITE state, result holds alu_out (calculated address)
        .dest(mem_addr)
    );

    // Instruction Fetch: old_pc and instruc_reg
    flip_flop_enable pc_latch (
        .clk(clk),
        .rst(rst),
        .enable(ir_write),
        .src(pc),
        .dest(old_pc)
    );

    flip_flop_enable instr_latch (
        .clk(clk),
        .rst(rst),
        .enable(ir_write),
        .src(mem_read_data), // Raw instruction from memory
        .dest(instruc_reg)
    );

    assign instr = instruc_reg;
    assign rs1 = instruc_reg[19:15];
    assign rs2 = instruc_reg[24:20];
    assign rd  = instruc_reg[11:7];
    assign funct3 = instruc_reg[14:12]; // Assign funct3

    // Register File
    register_file register_file_unit (
        .clk(clk),
        .rst(rst),
        .write_enable_3(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .write_data_3(result), // Final result to write back
        .rd(rd),
        .rd1(read_data1),
        .rd2(read_data2)
    );

    // Immediate Extension
    imm_extend imm_extend_unit (
        .instruction(instruc_reg),
        .imm_selection(imm_src),
        .imm_extended(imm_extended)
    );

    // Register File Output Latches
    flip_flop_enable reg1_latch (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Always enabled to latch current read values
        .src(read_data1),
        .dest(fread_data1)
    );

    flip_flop_enable reg2_latch (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Always enabled
        .src(read_data2),
        .dest(fread_data2)
    );

    assign mem_write_data = fread_data2; // Data for SW comes from rs2

    // ALU Source A and B Muxes
    mux3 alu_src_a_mux (
        .select(alu_src_a),
        .src0(pc),          // For PC+4 in FETCH
        .src1(old_pc),      // For branch/JAL/AUIPC calculation in DECODE
        .src2(fread_data1), // rs1 value for R/I/S/B/JALR types
        .dest(alu_src_inst_a)
    );

    mux3 alu_src_b_mux (
        .select(alu_src_b),
        .src0(fread_data2), // rs2 value for R/B types
        .src1(imm_extended),// Immediate for I/S/B/U/J types
        .src2(32'd4),       // Constant 4 for PC+4 in FETCH
        .dest(alu_src_inst_b)
    );

    // ALU Unit
    alu alu_unit (
        .a(alu_src_inst_a),
        .b(alu_src_inst_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero),
        .blt(blt),
        .bge(bge),
        .bltu(bltu),
        .bgeu(bgeu)
    );

    // ALU Output Register (latches ALU result for use in subsequent cycles)
    flip_flop_enable alu_out_reg (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Always enabled to latch ALU result
        .src(alu_result),
        .dest(alu_out) // Holds calculated address in MEM_READ/MEM_WRITE/MEM_WB
                       // Holds R/I type result in ALU_WB
    );

    // Memory Data Register (latches data read from memory)
    flip_flop_enable mem_data_latch (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),       // Always enabled to latch memory input
        .src(mem_read_data), // Raw data from memory module
        .dest(data_to_save)  // Holds raw memory data in MEM_WB state
    );

    // Instantiate Load Handler
    // It processes the latched memory data based on the address (from alu_out)
    // and the instruction's funct3 field.
    load_handler load_unit (
        .data_in(data_to_save),       // Raw data read from memory (latched)
        .address(alu_out),            // Address used for the load (latched ALU result)
        .funct3(funct3),              // Funct3 from instruction
        .data_out(processed_mem_data) // Output processed data
    );

    // Final Result Mux (selects data to be written back to register file or PC)
    mux3 result_mux (
        .select(result_src),
        .src0(alu_out),            // Result from ALU operation (R/I-type, address calc)
        .src1(processed_mem_data), // Data from memory (processed by load_handler)
        .src2(alu_result),         // Result for PC+4 (FETCH)
        .dest(result)
    );

endmodule