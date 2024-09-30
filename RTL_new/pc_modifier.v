module pc_modifier(
    input [31:0] pc_in,
    output [31:0] modified_pc
);

assign modified_pc = {pc_in[31:2], 2'b0};

endmodule