`timescale 1ns / 1ps
module tb_mod_adder;
    reg [11:0] a, b;
    wire [11:0] out;

    mod_adder uut (.a(a), .b(b), .out(out));

    initial begin
        a = 12'd1000; b = 12'd500;  #10; // 1500
        $display("Sum: %d (Exp: 1500)", out);
        a = 12'd3000; b = 12'd1000; #10; // 4000 -> 671
        $display("Sum: %d (Exp: 671)", out);
        $finish;
    end
endmodule