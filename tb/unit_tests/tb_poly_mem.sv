`timescale 1ns / 1ps
module tb_poly_mem;
    reg clk, we_a, we_b;
    reg [7:0] addr_a, addr_b;
    reg [11:0] din_a, din_b;
    wire [11:0] dout_a, dout_b;

    poly_mem uut (.*);
    always #5 clk = ~clk;

    initial begin
        clk = 0; we_a = 0; we_b = 0; #20;
        // Write
        @(posedge clk); we_a = 1; addr_a = 8'd5; din_a = 12'd123;
        @(posedge clk); we_a = 0;
        // Read Latency Check
        addr_a = 8'd5;
        @(posedge clk); // Sample addr
        @(posedge clk); #1; // Output valid
        $display("Read Addr 5: %d (Exp: 123)", dout_a);
        $finish;
    end
endmodule