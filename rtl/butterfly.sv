module butterfly(
    input [11:0] a,
    input [11:0] b,
    input [11:0] zeta,
    output [11:0] a_out,
    output [11:0] b_out
);

wire [[11:0] t;
mod_multiplier mult(
    .a(zeta),
    .b(b),
    .result(t)
);

mod_adder add(
    .a(a),
    .b(t),
    .result(a_out)
);

mod_subtractor sub(
    .a(a),
    .b(t),
    .result(b_out)
);

endmodule