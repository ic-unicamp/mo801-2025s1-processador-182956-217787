// tb_regdump.v - Testbench for Register File Dump Verification (Verilog-2001/2005 compatible)
module tb_regdump();

  reg clk;
  reg resetn; // Active-high reset for consistency with core.v? Check core.v usage.
              // If core.v uses active-low, keep original tb.v logic (resetn=0 for reset)

  wire we;
  wire [31:0] address, data_out, data_in;

  // Instantiate the core and memory
  core dut(
    .clk(clk),
    .resetn(resetn), // Ensure this matches core's expectation
    .address(address),
    .data_out(data_out),
    .data_in(data_in),
    .we(we)
  );

  memory m(
    .address(address),
    .data_in(data_out),
    .data_out(data_in),
    .we(we)
  );

  // --- Register Dumping Logic ---
  integer dump_file;
  integer i;

  // Hierarchical paths
  wire        reg_write_from_dut;
  wire [4:0]  rd_from_dut;
  wire [31:0] instruction_from_dut;

  assign reg_write_from_dut   = dut.dp.register_file_unit.write_enable_3;
  assign rd_from_dut          = dut.dp.rd;                               
  assign instruction_from_dut = dut.dp.instr;

  // Registers within the testbench to latch control signals
  reg        reg_write_latched = 1'b0;
  reg [4:0]  rd_latched = 5'b0;

  // Latch control signals on the positive edge
  always @(posedge clk or negedge resetn) begin 
      if (!resetn) begin // Reset condition
          reg_write_latched <= 1'b0;
          rd_latched        <= 5'b0;
      end else begin
          // Latch the signals coming from the DUT
          reg_write_latched <= reg_write_from_dut;
          rd_latched        <= rd_from_dut;
      end
  end

  // --- EBREAK Detection ---
  parameter EBREAK = 32'h00100073; 

  // Simulation Control and File Handling
  initial begin
    dump_file = $fopen("reg_dump.txt", "w");
    if (dump_file == 0) begin
        $display("Error: Could not open reg_dump.txt for writing.");
        $finish;
    end
    $display("Opened reg_dump.txt for writing.");

    $dumpfile("regdump_wave.vcd");
    $dumpvars(0, tb_regdump);

    for (i = 0; i < dut.dp.register_file_unit.NREGISTER; i = i + 1) begin
        $dumpvars(0, dut.dp.register_file_unit.register[i]); // Dump all registers
    end


    clk = 1'b0;
    resetn = 1'b0;
    #13 resetn = 1'b1;

    $display("*** Starting Register Dump Simulation ***");

    // Set a timeout for the simulation
  #200000 $display("Simulation Timeout Reached."); $finish;
  end

  // Clock generator
  always #10 clk = ~clk; 

  // Monitor for EBREAK instruction on the positive edge
  always @(*) begin
      if (resetn) begin
          // Check the instruction currently held in the datapath's instruction register
          // This assumes 'instruction_from_dut' reflects the instruction being decoded/executed
          if (instruction_from_dut == EBREAK) begin
              $display("[%0t] EBREAK instruction (0x%h) detected. Finishing simulation.", $time, EBREAK);
              // Optional: Perform one last register dump before finishing?
              // if (reg_write_latched && rd_latched != 5'b0) begin ... end // Dump if write occurred just before EBREAK
              #1; // Allow potential final events in this timestep
              $finish;
          end
      end
  end

  always @(negedge clk) begin
    // Use the values latched on the *previous* posedge
    if (resetn && reg_write_latched && rd_latched != 5'b0) begin
        $display("Time %0t: Writing to R%0d", $time, rd_latched);
        $fdisplay(dump_file, "Write to R%0d", rd_latched); // Use latched rd
        $fdisplay(dump_file, "R%0d: 0x%08h", rd_latched, dut.dp.register_file_unit.register[rd_latched]);
        $fdisplay(dump_file, "===");
        $fflush(dump_file);
    end
  end

endmodule