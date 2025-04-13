module datapath (
    input clk,
    input rst,

    // input signals from control
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

    // Control ports (outputs to control)
    output [31:0] instr,
    output zero,
    output blt,
    output bge,
    output bltu,
    output bgeu
);

    // Internal wires and registers
    wire [31:0] result; // Final result mux output (to PC or RegFile)
    wire [31:0] pc;
    wire [31:0] old_pc, instruc_reg;
    wire [31:0] data_to_save; // data_to_save latches mem_read_data
    wire [31:0] alu_result, alu_out; // alu_out latches alu_result
    wire [31:0] imm_extended;
    wire [31:0] read_data1, read_data2; // Direct from RegFile
    wire [31:0] fread_data1, fread_data2; // Latched RegFile outputs
    wire [31:0] alu_src_inst_a, alu_src_inst_b;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3; // Extract funct3 for load/store handlers

    // Load Handler output
    wire [31:0] processed_mem_data;

    // Store Handler output
    wire [31:0] modified_word_out;

    // Program Counter Register
    flip_flop_enable pc_reg (
        .clk(clk),
        .rst(rst),
        .enable(pc_write),
        .src(result), // Result mux selects PC+4 or branch/jump target
        .dest(pc)
    );

    // Memory Address Mux
    mux2 address_mux (
        .select(adr_src), // 0: PC (Fetch), 1: ALUOut (Load/Store address)
        .src0(pc),
        .src1(result), // In MEM_READ/WRITE state, result holds alu_out (calculated address)
        .dest(mem_addr)
    );

    // Instruction Fetch Latches: old_pc and instruc_reg
    flip_flop_enable pc_latch (
        .clk(clk),
        .rst(rst),
        .enable(ir_write), // Enabled only during FETCH
        .src(pc),
        .dest(old_pc)
    );

    flip_flop_enable instr_latch (
        .clk(clk),
        .rst(rst),
        .enable(ir_write), // Enabled only during FETCH
        .src(mem_read_data), // Raw instruction from memory
        .dest(instruc_reg)
    );

    // Decode instruction fields
    assign instr = instruc_reg;
    assign rs1 = instruc_reg[19:15];
    assign rs2 = instruc_reg[24:20];
    assign rd  = instruc_reg[11:7];
    assign funct3 = instruc_reg[14:12]; 

    // Register File
    register_file register_file_unit (
        .clk(clk),
        .rst(rst),
        .write_enable_3(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .write_data_3(result), // Final result mux output goes here
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

    // Register File Output Latches (fread_data1/2 hold values for current cycle)
    flip_flop_enable reg1_latch (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Always latching
        .src(read_data1),
        .dest(fread_data1)
    );

    flip_flop_enable reg2_latch (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Always latching
        .src(read_data2),
        .dest(fread_data2)
    );

    // ALU Source A and B Muxes
    mux3 alu_src_a_mux (
        .select(alu_src_a), // Controlled by FSM
        .src0(pc),          // 00: PC (for FETCH PC+4)
        .src1(old_pc),      // 01: Old PC (for branch calc, JAL/JALR link)
        .src2(fread_data1), // 10: rs1 value (for R/I/S/B/JALR types)
        .dest(alu_src_inst_a)
    );

    mux3 alu_src_b_mux (
        .select(alu_src_b), // Controlled by FSM
        .src0(fread_data2), // 00: rs2 value (for R/B types)
        .src1(imm_extended),// 01: Immediate (for I/S/B/U/J types, address calc)
        .src2(32'd4),       // 10: Constant 4 (for FETCH PC+4, JAL/JALR link)
        .dest(alu_src_inst_b)
    );

    // ALU Unit
    alu alu_unit (
        .a(alu_src_inst_a),
        .b(alu_src_inst_b),
        .alu_control(alu_control), // From alu_decoder via control
        .result(alu_result),
        .zero(zero),
        .blt(blt),
        .bge(bge),
        .bltu(bltu),
        .bgeu(bgeu)
    );

    // ALU Output Register (latches ALU result)
    // Holds R/I type result in ALU_WB
    // Holds branch target in BRANCH state
    flip_flop_enable alu_out_reg (
        .clk(clk),
        .rst(rst),
        .enable(1'b1), // Always latching
        .src(alu_result),
        .dest(alu_out)
    );

    // Memory Data Register (latches data read from memory)
    // Holds raw memory data in MEM_WB (for Load)
    flip_flop_enable mem_data_latch (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),       // Always latching
        .src(mem_read_data), // Raw data from memory module
        .dest(data_to_save)
    );

    // Instantiate Load Handler (Processes data read from memory for Load instructions)
    load_handler load_unit (
        .data_in(data_to_save),       // Raw data read from memory (latched)
        .address(alu_result),         // Address used for the load 
        .funct3(funct3),              // Funct3 from instruction
        .data_out(processed_mem_data) // Output processed data (byte/half/word)
    );

    // Processes data for Store instructions before writing
    store_handler store_unit (
        .word_from_mem(data_to_save),       // Word read during STORE_READ (latched)
        .data_from_reg(fread_data2),        // Data from rs2 (latched)
        .address_offset(alu_result[1:0]),   // Lower bits of calculated address
        .funct3(funct3),                    // Funct3 from instruction
        .modified_word(modified_word_out)   // Output word ready for STORE_WRITE
    );

    // Assign data to be written to memory
    assign mem_write_data = modified_word_out;

    // Final Result Mux (selects data to be written back to register file or PC)
    mux3 result_mux (
        .select(result_src),       // Controlled by FSM
        .src0(alu_out),            // 
        .src1(processed_mem_data), // 01: Data from memory (processed by load_handler for LW/LH/LB)
        .src2(alu_result),         // 10: Result for PC+4 (FETCH)
        .dest(result)
    );

endmodule