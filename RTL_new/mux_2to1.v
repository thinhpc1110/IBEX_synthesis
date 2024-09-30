module mux_2to1 #(
    parameter DATAWIDTH = 32
) (
    input [DATAWIDTH-1:0] inputA, inputB,
    input  select,
    output [DATAWIDTH-1:0] selected_out
);

    assign selected_out = select ? inputA : inputB;
endmodule
