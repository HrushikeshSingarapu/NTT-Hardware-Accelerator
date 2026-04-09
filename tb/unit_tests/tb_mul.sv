`timescale 1ns / 1ps
module tb_mul;
    reg [11:0] a, b;
    wire [11:0] out;

    mod_multiplier uut (.a(a), .b(b), .out(out));

    initial begin
        a = 12'd100; b = 12'd50; #10; // 5000 % 3329 = 1671
        $display("Prod: %d (Exp: 1671)", out);
        $finish;
    end
endmodule