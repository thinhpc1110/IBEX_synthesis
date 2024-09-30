module comparator_1bit(
    input a, b,   // 1-bit inputs
    input a_lt_b,  // a less-than b (from previous comparator)
    output out
);
    wire a_inv, a_and_b; // inverted a bit, output of a&b

    assign a_inv = ~a;
    assign a_and_b = a_inv & b;

    assign out = a_and_b | a_lt_b;

endmodule