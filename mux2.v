module mux2 (
    input           select,
    input  [31:0]  src0, src1,
    output [31:0]  dest
);
    assign dest = select ? src1 : src0;

endmodule