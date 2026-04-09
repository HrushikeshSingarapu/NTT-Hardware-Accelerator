`timescale 1ns / 1ps
module tb_butterfly;
    reg [11:0] a, b, w;
    wire [11:0] even, odd;

    butterfly uut (.*);

    initial begin
        a = 12'd100; b = 12'd50; w = 12'd1; #10;
        $display("Even: %d (150), Odd: %d (50)", even, odd);
        $finish;
    end
endmodule