// ======================================================
// Module: Butterfly Unit
// Description: Performs NTT butterfly operation
// t = (b * zeta) mod q
// a_out = (a + t) mod q
// b_out = (a - t) mod q
// ======================================================

module butterfly(
    input  [11:0] a,
    input  [11:0] b,
    input  [11:0] zeta,
    output [11:0] a_out,
    output [11:0] b_out
);

wire [11:0] t;

// t = b * zeta mod q
mod_multiplier mult(
    .a(zeta),
    .b(b),
    .result(t)
);

// a_out = (a + t) mod q
mod_adder add(
    .a(a),
    .b(t),
    .result(a_out)
);

// b_out = (a - t) mod q
mod_subtractor sub(
    .a(a),
    .b(t),
    .result(b_out)
);

endmodule