`timescale 1ns / 1ps
module tb_twiddle_rom;
    reg [6:0] addr;
    wire [11:0] zeta;

    twiddle_rom uut (.addr(addr), .zeta(zeta));

    initial begin
        addr = 7'd0; #10; $display("Addr 0: %d (Exp: 1)", zeta);
        addr = 7'd1; #10; $display("Addr 1: %d (Exp: 1729)", zeta);
        addr = 7'd127; #10; $display("Addr 127: %d (Exp: 2154)", zeta);
        $finish;
    end
endmodule