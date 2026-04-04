`timescale 1ns/1ps

module poly_mem (
    input         clk,
    input         we,
    input  [7:0]  addr_a,
    input  [7:0]  addr_b,
    input  [11:0] data_in_a,
    input  [11:0] data_in_b,
    output reg [11:0] data_out_a,
    output reg [11:0] data_out_b
);

    reg [11:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 0;
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr_a] <= data_in_a;
            if (addr_b != addr_a)
                mem[addr_b] <= data_in_b;
        end
        data_out_a <= mem[addr_a];
        data_out_b <= mem[addr_b];
    end

endmodule