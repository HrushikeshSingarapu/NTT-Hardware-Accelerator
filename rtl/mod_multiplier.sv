
module mod_multiplier(
    input  [11:0] a,
    input  [11:0] b,
    output [11:0] y
);
    parameter Q = 3329;
    wire [23:0] product;
    assign product = a * b;
    assign y = product % Q;

endmodule