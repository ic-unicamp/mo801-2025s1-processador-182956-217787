module mux3 (
    input   [1:0]   select,
    input   [31:0]  src0, src1, src2,
    output  [31:0]  dest   
);
    assign dest = (select == 2'b00) ? src0 :
                  (select == 2'b01) ? src1 :
                  (select == 2'b10) ? src2 :
                                      32'bz;  // undefined for 2'b11


endmodule