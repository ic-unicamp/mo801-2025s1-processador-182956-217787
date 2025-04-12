module load_handler
 (
    input      [31:0]  data_in, 
    input      [31:0]  address,
    input      [2:0]   funct3,
    output reg [31:0]  data_out
);

    always @(*) begin
        case (funct3)
            3'b000: // LB
                begin
                    if (address[1:0] == 2'b00) begin
                        data_out = {{24{data_in[7]}}, data_in[7:0]};
                    end else if (address[1:0] == 2'b01) begin
                        data_out = {{24{data_in[15]}}, data_in[15:8]};
                    end else if (address[1:0] == 2'b10) begin
                        data_out = {{24{data_in[23]}}, data_in[23:16]};
                    end else if (address[1:0] == 2'b11) begin
                        data_out = {{24{data_in[31]}}, data_in[31:24]};
                    end else begin
                        data_out = 32'hxxxx_xxxx; // Invalid address
                    end
                end

            3'b100: // LBU
                begin
                    if (address[1:0] == 2'b00) begin
                        data_out = {{24{1'b0}}, data_in[7:0]};
                    end else if (address[1:0] == 2'b01) begin
                        data_out = {{24{1'b0}}, data_in[15:8]};
                    end else if (address[1:0] == 2'b10) begin
                        data_out = {{24{1'b0}}, data_in[23:16]};
                    end else if (address[1:0] == 2'b11) begin
                        data_out = {{24{1'b0}}, data_in[31:24]};
                    end else begin
                        data_out = 32'hxxxx_xxxx; // Invalid address
                    end
                end

            3'b001: // LH
                begin
                    if (address[1:0] == 2'b00) begin
                        data_out = {{16{data_in[15]}}, data_in[15:0]};
                    end else if (address[1:0] == 2'b10) begin
                        data_out = {{16{data_in[31]}}, data_in[31:16]};
                    end else begin
                        data_out = 32'hxxxx_xxxx; // Invalid address
                    end
                end

            3'b101: // LHU
                begin
                    if (address[1:0] == 2'b00) begin
                        data_out = {{16{1'b0}}, data_in[15:0]};
                    end else if (address[1:0] == 2'b10) begin
                        data_out = {{16{1'b0}}, data_in[31:16]};
                    end else begin
                        data_out = 32'hxxxx_xxxx; // Invalid address
                    end
                end

            3'b010:  // LW
                data_out = data_in;
            default:  // Invalid operation
                data_out = 32'hxxxx_xxxx;
        endcase
    end

endmodule