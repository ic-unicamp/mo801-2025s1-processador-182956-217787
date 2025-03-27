module mux3 (
    input   [1:0]   select,
    input   [31:0]  src0, src1, src2,
    output  [31:0]  dest   
);
    assign dest =  select[1] ? src2 : 
                   select[0] ? src1 : 
                               src0;

endmodule