module flip_flop_enble(
    input           clk,
    input           enable,
    input           rst,
    input   [31:0]  src,
    output reg [31:0]  dest
);
    always @(posedge clk or posedge rst) 
    begin
        if (rst == 1'b0) dest = 32'b0;
        if (enable) dest = src;
    end

endmodule