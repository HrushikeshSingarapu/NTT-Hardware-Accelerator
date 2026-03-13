module mod_subtractor (
    input  [11:0] a,
    input  [11:0] b,
    output [11:0] result
);

parameter Q = 3329;

assign result = (a >= b) ? (a - b) : (a - b + Q);

endmodule