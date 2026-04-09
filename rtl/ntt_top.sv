`timescale 1ns / 1ps

module ntt_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire        done,
    input  wire        load_we,
    input  wire [7:0]  load_addr,
    input  wire [11:0] load_data,
    input  wire [7:0]  rd_addr,
    output wire [11:0] rd_data
);

    wire [7:0]  addr_a, addr_b;
    wire [11:0] ram_out_a, ram_out_b;
    wire [11:0] bfly_even, bfly_odd;
    wire [11:0] twiddle_factor;
    wire        ctrl_we, busy;
    wire [6:0]  rom_addr;

    // Port A: load takes priority, then NTT write/read, then readback
    wire we_port_a   = load_we | ctrl_we;
    wire we_port_b   = ctrl_we;

    wire [7:0] final_addr_a = load_we ? load_addr :
                              busy    ? addr_a     : rd_addr;
    wire [7:0] final_addr_b = addr_b;

    wire [11:0] final_din_a = load_we ? load_data : bfly_even;
    wire [11:0] final_din_b = bfly_odd;

    assign rd_data = ram_out_a;

    ntt_controller control_unit (
        .clk(clk), .rst(rst), .start(start),
        .ram_addr_a(addr_a), .ram_addr_b(addr_b),
        .ram_we(ctrl_we), .rom_addr(rom_addr),
        .done(done), .busy(busy)
    );

    poly_mem ram_unit (
        .clk(clk),
        .we_a(we_port_a), .we_b(we_port_b),
        .addr_a(final_addr_a), .addr_b(final_addr_b),
        .din_a(final_din_a), .din_b(final_din_b),
        .dout_a(ram_out_a), .dout_b(ram_out_b)
    );

    twiddle_rom rom_unit (
        .addr(rom_addr),
        .zeta(twiddle_factor)
    );

    butterfly math_engine (
        .a(ram_out_a), .b(ram_out_b), .w(twiddle_factor),
        .even(bfly_even), .odd(bfly_odd)
    );

endmodule