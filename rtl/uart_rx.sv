`timescale 1ns/1ps
module uart_rx #(parameter CLKS_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg        data_valid,
    output reg  [7:0] data
);
    // 868 = 100MHz / 115200 baud
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0]  state;
    reg [9:0]  clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  rx_byte;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            data_valid <= 0;
            clk_cnt    <= 0;
            bit_idx    <= 0;
            data       <= 0;
            rx_byte    <= 0;
        end
        else begin
            data_valid <= 0;
            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx == 0)
                        state <= START;
                end
                START: begin
                    if (clk_cnt == (CLKS_PER_BIT/2)) begin
                        if (rx == 0) begin
                            clk_cnt <= 0;
                            state   <= DATA;
                        end
                        else
                            state <= IDLE;
                    end
                    else
                        clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt            <= 0;
                        rx_byte[bit_idx]   <= rx;
                        if (bit_idx == 7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end
                    else
                        clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        data_valid <= 1;
                        data       <= rx_byte;
                        clk_cnt    <= 0;
                        state      <= IDLE;
                    end
                    else
                        clk_cnt <= clk_cnt + 1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule