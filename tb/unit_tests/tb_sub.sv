`timescale 1ns / 1ps
module tb_sub;
    reg [11:0] a, b;
    wire [11:0] out;

    mod_subtractor uut (.a(a), .b(b), .out(out));

    initial begin
        a = 12'd1000; b = 12'd500;  #10; // 500
        $display("Diff: %d (Exp: 500)", out);
        a = 12'd500;  b = 12'd1000; #10; // -500 -> 2829
        $display("Diff: %d (Exp: 2829)", out);
        $finish;
    end
endmodule