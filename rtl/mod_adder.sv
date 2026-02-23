// ======================================================
// Module: Modular Adder
// Description: Performs (a + b) mod q for Kyber NTT
// Modulus q = 3329
// ======================================================

module mod_adder (
    input  [11:0] a,     // 12-bit input
    input  [11:0] b,     // 12-bit input
    output [11:0] result // 12-bit result
);

    // Kyber modulus
    parameter Q = 3329;

    wire [12:0] sum;  // 13-bit to hold overflow

    assign sum = a + b;

    // Modular reduction
    assign result = (sum >= Q) ? sum - Q : sum;

endmodule