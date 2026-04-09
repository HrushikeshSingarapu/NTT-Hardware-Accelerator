`timescale 1ns / 1ps

module butterfly(
    input  logic [11:0] a,
    input  logic [11:0] b,
    input  logic [11:0] w,
    output logic [11:0] even,
    output logic [11:0] odd
);
    wire [11:0] t;
    
    // Note: We use the port name 'out' to match the mod modules
    mod_multiplier mult (
        .a(b), 
        .b(w), 
        .out(t)
    );

    mod_adder add (
        .a(a), 
        .b(t), 
        .out(even)
    );

    mod_subtractor sub (
        .a(a), 
        .b(t), 
        .out(odd)
    );
endmodule