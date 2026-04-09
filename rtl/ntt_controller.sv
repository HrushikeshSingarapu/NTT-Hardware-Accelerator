`timescale 1ns / 1ps

module ntt_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output reg  [7:0]  ram_addr_a,
    output reg  [7:0]  ram_addr_b,
    output reg         ram_we,
    output reg  [6:0]  rom_addr,
    output reg         done,
    output wire        busy
);

    reg [9:0] global_idx;
    reg [2:0] state;
    reg       running;

    assign busy = running;

    wire [2:0] stage  = global_idx[9:7];
    wire [6:0] bf_num = global_idx[6:0];
    wire [7:0] length = 8'd128 >> stage;
    wire [6:0] group  = bf_num >> (3'd7 - stage);
    wire [6:0] offset = bf_num & (length - 8'd1);
    wire [8:0] start_pos = group * ({1'b0, length} << 1);
    wire [7:0] addr_a_logic = start_pos[7:0] + offset;
    wire [7:0] addr_b_logic = addr_a_logic + length;

    reg [6:0] k_base;
    always @(*) begin
        case(stage)
            3'd0: k_base = 7'd1;
            3'd1: k_base = 7'd2;
            3'd2: k_base = 7'd4;
            3'd3: k_base = 7'd8;
            3'd4: k_base = 7'd16;
            3'd5: k_base = 7'd32;
            3'd6: k_base = 7'd64;
            default: k_base = 7'd1;
        endcase
    end

    localparam IDLE   = 3'd0,
               LOAD   = 3'd1,
               WAIT   = 3'd2,
               STORE  = 3'd3,
               FINISH = 3'd4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            global_idx <= 10'd0;
            running    <= 1'b0;
            ram_we     <= 1'b0;
            done       <= 1'b0;
            ram_addr_a <= 8'd0;
            ram_addr_b <= 8'd0;
            rom_addr   <= 7'd0;
        end
        else begin
            done   <= 1'b0;
            ram_we <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        running    <= 1'b1;
                        global_idx <= 10'd0;
                        state      <= LOAD;
                    end
                end

                LOAD: begin
                    // Latch addresses, issue read (we=0)
                    ram_addr_a <= addr_a_logic;
                    ram_addr_b <= addr_b_logic;
                    rom_addr   <= k_base + group;
                    ram_we     <= 1'b0;
                    state      <= WAIT;
                end

                WAIT: begin
                    // 1 cycle for RAM read latency
                    // dout_a, dout_b, twiddle all ready next cycle
                    ram_we <= 1'b0;
                    state  <= STORE;
                end

                STORE: begin
                    // butterfly result ready, write back
                    ram_we <= 1'b1;
                    if (global_idx == 10'd895) begin
                        state <= FINISH;
                    end
                    else begin
                        global_idx <= global_idx + 10'd1;
                        state      <= LOAD;
                    end
                end

                FINISH: begin
                    ram_we  <= 1'b0;
                    running <= 1'b0;
                    done    <= 1'b1;
                    state   <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule