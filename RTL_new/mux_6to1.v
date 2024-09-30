module mux_6to1 
#(parameter DATAWIDTH = 32)
(
    input [DATAWIDTH-1:0] inputA, inputB, inputC, inputD, inputE, inputF,
    input [2:0] select,
    output reg [DATAWIDTH-1:0] selected_out
);

    always @(*)
    casex(select)
        3'b000:
            selected_out = inputA;
        3'b001:
            selected_out = inputB;
        3'b010:
            selected_out = inputC;
        3'b011:
            selected_out = inputD;
        3'b100:
            selected_out = inputE;
        3'b101:
            selected_out = inputF;
        default:
            selected_out = 32'bx;
    endcase
endmodule