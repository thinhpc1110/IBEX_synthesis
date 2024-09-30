module store_modifier (
    input sb, sh, 
    input [31:0] data_in,
    output reg [31:0] data_out
);
    always @(*)
    begin
        case({sb,sh})
            2'b00: data_out = data_in;                      // sw
            2'b01: data_out = { {16{1'b0}}, data_in[15:0]}; // sh
            2'b10: data_out = { {24{1'b0}}, data_in[7:0]};  // sb
            default: data_out = data_in;                    // sw
        endcase
    end
endmodule

