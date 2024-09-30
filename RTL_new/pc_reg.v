module pc_reg(
    input i_clk, i_resetn, i_we, 
    input [31:0] i_pc, 
    output reg [31:0] o_pc
);

    always @(posedge i_clk or negedge i_resetn)
    begin
        if(!i_resetn)
            o_pc <= 32'h80;
        else
            o_pc <= i_pc;
    end

endmodule
