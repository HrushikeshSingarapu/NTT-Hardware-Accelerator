`timescale 1ns / 1ps

module poly_mem (
    input  wire        clk,
    input  wire        we_a,
    input  wire        we_b,
    input  wire [7:0]  addr_a,
    input  wire [7:0]  addr_b,
    input  wire [11:0] din_a,
    input  wire [11:0] din_b,
    output reg  [11:0] dout_a,
    output reg  [11:0] dout_b
);
    reg [11:0] mem [0:255];

    integer k;
    initial begin
        for (k = 0; k < 256; k = k + 1)
            mem[k] = 12'd0;
    end

    always @(posedge clk) begin
        // Write port A
        if (we_a)
            mem[addr_a] <= din_a;

        // Write port B
        if (we_b)
            mem[addr_b] <= din_b;

        // Read always (output reflects mem state from this cycle)
        dout_a <= mem[addr_a];
        dout_b <= mem[addr_b];
    end

endmodule