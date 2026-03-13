

// ======================================================
// Module: Polynomial Memory
// Stores 256 coefficients, 12-bit each
// Dual port — reads/writes two addresses at once
// ======================================================

module poly_mem (
    input         clk,
    input         we,           // write enable (1=write, 0=read)
    input  [7:0]  addr_a,       // address for first coefficient
    input  [7:0]  addr_b,       // address for second coefficient
    input  [11:0] data_in_a,    // data to write at addr_a
    input  [11:0] data_in_b,    // data to write at addr_b
    output reg [11:0] data_out_a,  // data read from addr_a
    output reg [11:0] data_out_b   // data read from addr_b
);

    // 256 locations, each 12 bits
    reg [11:0] mem [0:255];

    always @(posedge clk) begin
        if (we) begin
            // write mode
            mem[addr_a] <= data_in_a;
            mem[addr_b] <= data_in_b;
        end else begin
            // read mode
            data_out_a <= mem[addr_a];
            data_out_b <= mem[addr_b];
        end
    end

endmodule