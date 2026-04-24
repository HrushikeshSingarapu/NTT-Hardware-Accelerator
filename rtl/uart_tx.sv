`timescale 1ns/1ps
module uart_tx #(parameter CLKS_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [9:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] tx_byte;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            tx      <= 1;
            busy    <= 0;
            clk_cnt <= 0;
            bit_idx <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    tx   <= 1;
                    busy <= 0;
                    if (start) begin
                        tx_byte <= data;
                        busy    <= 1;
                        clk_cnt <= 0;
                        state   <= START;
                    end
                end
                START: begin
                    tx <= 0;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= DATA;
                    end
                    else
                        clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    tx <= tx_byte[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end
                    else
                        clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    tx <= 1;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= IDLE;
                    end
                    else
                        clk_cnt <= clk_cnt + 1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule