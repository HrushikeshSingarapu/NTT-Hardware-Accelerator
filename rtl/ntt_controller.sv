`timescale 1ns/1ps

module ntt_controller (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    output logic        done,

    output logic        ag_start,
    output logic        ag_en,
    input  logic        ag_valid,
    input  logic        ag_done,
    input  logic [7:0]  ag_addr_a,
    input  logic [7:0]  ag_addr_b,

    output logic        we,
    output logic [7:0]  we_addr_a,
    output logic [7:0]  we_addr_b
);

    typedef enum logic [2:0] {
        IDLE    = 3'd0,
        FETCH   = 3'd1,
        COMPUTE = 3'd2,
        WRITE   = 3'd3,
        ADVANCE = 3'd4,
        DONE_ST = 3'd5
    } state_t;

    state_t state;
    logic [7:0] latch_a, latch_b;
    logic       last_bf;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            done      <= 0;
            ag_start  <= 0;
            ag_en     <= 0;
            we        <= 0;
            latch_a   <= 0;
            latch_b   <= 0;
            we_addr_a <= 0;
            we_addr_b <= 0;
            last_bf   <= 0;
        end
        else begin
            done     <= 0;
            ag_start <= 0;
            ag_en    <= 0;
            we       <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        ag_start <= 1;
                        state    <= FETCH;
                    end
                end

                // addr_gen has valid addr_a/b
                // poly_mem reads this cycle
                // latch addresses for writeback
                FETCH: begin
                    if (ag_valid) begin
                        latch_a <= ag_addr_a;
                        latch_b <= ag_addr_b;
                        last_bf <= ag_done;
                        state   <= COMPUTE;
                    end
                end

                // data_out_a/b ready
                // butterfly computes this cycle
                COMPUTE: begin
                    state <= WRITE;
                end

                // a_out/b_out ready — write back
                WRITE: begin
                    we        <= 1;
                    we_addr_a <= latch_a;
                    we_addr_b <= latch_b;
                    if (last_bf) begin
                        state <= DONE_ST;
                    end
                    else begin
                        ag_en <= 1;      // pulse en — addr_gen advances next cycle
                        state <= ADVANCE;
                    end
                end

                // addr_gen advanced this cycle
                // new addr_a/b now stable combinationally
                // poly_mem reads new addresses this cycle
                ADVANCE: begin
                    latch_a <= ag_addr_a;
                    latch_b <= ag_addr_b;
                    last_bf <= ag_done;
                    state   <= COMPUTE;
                end

                DONE_ST: begin
                    done  <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule