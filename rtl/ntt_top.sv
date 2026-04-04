`timescale 1ns/1ps

module ntt_top (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    output logic        done,

    input  logic        load_we,
    input  logic [7:0]  load_addr,
    input  logic [11:0] load_data,

    input  logic [7:0]  rd_addr,
    output logic [11:0] rd_data
);

    logic [7:0]  addr_a, addr_b;
    logic [6:0]  twiddle_addr;
    logic        ag_valid, ag_done, ag_start, ag_en;

    logic        we;
    logic [7:0]  we_addr_a, we_addr_b;

    logic [11:0] data_out_a, data_out_b;
    logic [11:0] zeta;
    logic [11:0] a_out, b_out;

    logic        mem_we;
    logic [7:0]  mem_addr_a, mem_addr_b;
    logic [11:0] mem_din_a,  mem_din_b;

    // ntt_running: addr_gen is active
    logic ntt_running;
    assign ntt_running = ag_valid;

    // addr mux:
    // load     → load_addr
    // we       → we_addr (writeback)
    // ntt read → addr_a from addr_gen
    // idle     → rd_addr (readback after done)
    assign mem_we     = load_we | we;
    assign mem_addr_a = load_we    ? load_addr  :
                        we         ? we_addr_a  :
                        ntt_running? addr_a     : rd_addr;
    assign mem_addr_b = we         ? we_addr_b  : addr_b;
    assign mem_din_a  = load_we    ? load_data  : a_out;
    assign mem_din_b  = b_out;

    assign rd_data = data_out_a;

    poly_mem u_mem (
        .clk       (clk),
        .we        (mem_we),
        .addr_a    (mem_addr_a),
        .addr_b    (mem_addr_b),
        .data_in_a (mem_din_a),
        .data_in_b (mem_din_b),
        .data_out_a(data_out_a),
        .data_out_b(data_out_b)
    );

    twiddle_rom u_rom (
        .addr(twiddle_addr),
        .data(zeta)
    );

    butterfly u_bf (
        .a    (data_out_a),
        .b    (data_out_b),
        .zeta (zeta),
        .a_out(a_out),
        .b_out(b_out)
    );

    addr_gen u_ag (
        .clk         (clk),
        .rst         (rst),
        .start       (ag_start),
        .en          (ag_en),
        .addr_a      (addr_a),
        .addr_b      (addr_b),
        .twiddle_addr(twiddle_addr),
        .valid       (ag_valid),
        .done        (ag_done)
    );

    ntt_controller u_ctrl (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .done     (done),
        .ag_start (ag_start),
        .ag_en    (ag_en),
        .ag_valid (ag_valid),
        .ag_done  (ag_done),
        .ag_addr_a(addr_a),
        .ag_addr_b(addr_b),
        .we       (we),
        .we_addr_a(we_addr_a),
        .we_addr_b(we_addr_b)
    );

endmodule