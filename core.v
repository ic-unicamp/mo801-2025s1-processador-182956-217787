module core( // Core module
  input clk, // clock
  input resetn, // reset on zero
  output reg [31:0] address, // address out
  output reg [31:0] data_out, // data out
  input [31:0] data_in, // data in
  output reg we // write enable
);

  // Internal signals
  wire [31:0] instr; 
  wire zero;                  // Zero flag from ALU
  
  // Control signals
  wire pc_write;
  wire adr_src;
  wire mem_write;
  wire ir_write;
  wire [1:0] result_src;
  wire [3:0] alu_control;
  wire [1:0] alu_src_a;
  wire [1:0] alu_src_b;
  wire [2:0] imm_src;
  wire reg_write;
  
  // Internal memory interface
  wire [31:0] mem_addr;       // Memory address from datapath
  wire [31:0] mem_write_data; // Data to write to memory from datapath
  reg [31:0] mem_read_data;   // Data read from memory to datapath
  
  datapath dp (
    .clk(clk),
    .rst(resetn),
    
    // Control signals
    .pc_write(pc_write),
    .adr_src(adr_src),
    .ir_write(ir_write),
    .result_src(result_src),
    .alu_control(alu_control),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    .imm_src(imm_src),
    .reg_write(reg_write),
    
    // Memory interface
    .mem_addr(mem_addr),
    .mem_write_data(mem_write_data),
    .mem_read_data(mem_read_data),
    
    // Control interconnect
    .instr(instr),
    .zero(zero)
  );
  
  control ctrl (
    .instr(instr),
    .zero(zero),
    .PCWrite(pc_write),
    .AdrSrc(adr_src),
    .MemWrite(mem_write),
    .IRWrite(ir_write),
    .ResultSrc(result_src),
    .ALUControl(alu_control),
    .ALUSrcB(alu_src_b),
    .ALUSrcA(alu_src_a),
    .ImmSrc(imm_src),
    .RegWrite(reg_write)
  );
  
  // Connect datapath to external memory interface
  always @(*) begin
    address = mem_addr;
    data_out = mem_write_data;
    mem_read_data = data_in;
    we = mem_write;
  end


endmodule
