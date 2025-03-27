module register_file (
    input           clk,
    input           rst,
    input           write_enable_3,
    input   [4:0]   rs1, rs2, rd,
    input   [31:0]  write_data_3,
    output  [31:0]  rd1, rd2
);
    
    // register bank
    parameter NREGISTER = 32;
    reg [31:0] register [NREGISTER - 1: 0];

    assign rd1 = (rs1 == 5'b0) ? 32'b0 : register[rs1];
    assign rd2 = (rs2 == 5'b0) ? 32'b0 : register[rs2];
    
    integer i;
    always @(posedge clk or posedge rst)
    begin
        if (rst == 1'b0)
        begin
            for (i = 0; i < 32; i = i + 1)
                register[i] = 32'b0;
        end

        if (write_data_3 && rd != 5'b0) register[write_data_3] = rd;
    end

endmodule