module alu (
    input [31:0] a,
    input [31:0] b,
    input [4:0] aluc,
    output reg [31:0] result
);
    reg [63:0] result_64bit;
    reg [31:0] quotient;

    always @(aluc, a, b) 
        begin
            case (aluc)
                5'b00000: result = a & b;  // AND
                5'b00001: result = a | b;  // OR
                5'b00010: result = a + b;  // ADD
                5'b00011: result = a - b;  // SUB
                5'b00100: result = a << b; // SLL (Shift left logical) 
                5'b00101: result = a >> b; // SRL (Shift right logical)
                5'b00110: result = $signed(a) >>> b;// SRA (Shift right arith)
                5'b00111: result = a ^ b;  // XOR 
                5'b01000: result = b;      // dùng cho LUI
                5'b01001: 
                    begin 
                        result_64bit = $signed(a) * $signed(b);
                        result = result_64bit[31:0]; // MUL
                    end
                5'b01010: 
                    begin
                        result_64bit = $signed(a) * $signed(b);
                        result = result_64bit[63:32];// MULH
                    end
                // 5'b01011: result = //MULSU
                5'b01100: 
                    begin
                        result_64bit = a * b;
                        result = result_64bit[63:32];// MULU
                    end
                5'b01101: result = $signed(a) >>> b; // DIV
                5'b01110: result = a >> b;           // DIVU
                // 5'b01111: result =                //REM
                // 5'b10000:
                //     begin:
                //         quotient = a >> b;
                //         result = a - (quotient << b); // REMU
                //     end 
                default: result = 32'b0;
            endcase
        end
endmodule