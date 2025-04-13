// Performs the data modification for SB and SH instructions
// during the read-modify-write sequence.
module store_handler (
    input      [31:0]  word_from_mem,    // Word read from memory in STORE_READ state
    input      [31:0]  data_from_reg,    // Data from rs2 (source register)
    input      [1:0]   address_offset,   // Lower 2 bits of the calculated address (determines byte/halfword)
    input      [2:0]   funct3,           // Instruction's funct3 field (000=SB, 001=SH, 010=SW)
    output reg [31:0]  modified_word     // The word to be written back in STORE_WRITE state
);

    reg [31:0] byte_mask;
    reg [31:0] half_mask;
    reg [31:0] data_to_insert;

    always @(*) begin
        case (funct3)
            3'b000: begin // SB - Store Byte
                case (address_offset)
                    2'b00:   byte_mask = 32'hFFFFFF00; // Mask for byte 0
                    2'b01:   byte_mask = 32'hFFFF00FF; // Mask for byte 1
                    2'b10:   byte_mask = 32'hFF00FFFF; // Mask for byte 2
                    2'b11:   byte_mask = 32'h00FFFFFF; // Mask for byte 3
                    default: byte_mask = 32'hFFFFFFFF; // Should not happen
                endcase
                // Shift the byte from rs2 to the correct position
                data_to_insert = (data_from_reg & 32'h000000FF) << (address_offset * 8);
                // Combine masked memory word with shifted data byte
                modified_word = (word_from_mem & byte_mask) | data_to_insert;
            end

            3'b001: begin // SH - Store Halfword
                // SH requires address_offset[0] to be 0 (aligned)
                if (address_offset[0] == 1'b0) begin
                    case (address_offset[1]) // Check which halfword
                        1'b0:    half_mask = 32'hFFFF0000; // Mask for halfword 0 (bits 15:0)
                        1'b1:    half_mask = 32'h0000FFFF; // Mask for halfword 1 (bits 31:16)
                        default: half_mask = 32'hFFFFFFFF; // Should not happen
                    endcase
                    // Shift the halfword from rs2 to the correct position
                    data_to_insert = (data_from_reg & 32'h0000FFFF) << (address_offset[1] * 16);
                    // Combine masked memory word with shifted data halfword
                    modified_word = (word_from_mem & half_mask) | data_to_insert;
                end else begin
                    // Misaligned SH.
                    // Re-calculate assuming alignment was intended or handled elsewhere.
                    case (address_offset[1]) // Check which halfword
                        1'b0:    half_mask = 32'hFFFF0000; // Mask for halfword 0 (bits 15:0)
                        1'b1:    half_mask = 32'h0000FFFF; // Mask for halfword 1 (bits 31:16)
                        default: half_mask = 32'hFFFFFFFF; // Should not happen
                    endcase
                    data_to_insert = (data_from_reg & 32'h0000FFFF) << (address_offset[1] * 16);
                    modified_word = (word_from_mem & half_mask) | data_to_insert;
                    $display("Warning: Misaligned SH detected at address offset %b", address_offset);
                end
            end

            3'b010: begin // SW - Store Word
                // No modification needed, just pass through the data from the register
                modified_word = data_from_reg;
            end

            default: begin // Should not happen for valid S-type instructions
                modified_word = 32'hxxxxxxxx; 
            end
        endcase
    end

endmodule