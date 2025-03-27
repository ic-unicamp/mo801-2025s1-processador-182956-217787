module flip_flop2_enable (
    input           clk, enable, rst,
    input   [31:0]  src0, src1,
    output  reg [31:0]  dest0, dest1
);
    always @(posedge clk or posedge rst) 
    begin
        if (rst == 0)
        begin
            dest0 = 32'b0;
            dest1 = 32'b0;
        end
        if (enable)
        begin
            dest0 = src0;
            dest1 = src1;
        end  
    end

endmodule