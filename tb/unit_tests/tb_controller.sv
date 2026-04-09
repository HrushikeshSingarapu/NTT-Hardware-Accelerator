`timescale 1ns / 1ps
module tb_controller;
    reg clk, rst, start;
    wire [7:0] ram_addr_a, ram_addr_b;
    wire ram_we, done, busy;
    wire [6:0] rom_addr;

    ntt_controller uut (.*);
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0; #100 rst = 0;
        #20 start = 1; #10 start = 0;
        
        repeat(15) begin
            @(posedge clk);
            $display("State: %0d | Addr_A: %d | WE: %b", uut.state, ram_addr_a, ram_we);
        end
        $finish;
    end
endmodule